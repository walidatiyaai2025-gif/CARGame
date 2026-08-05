param(
    [string]$DeviceId = "",
    [string]$AvdName = ""
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )

    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Command @Arguments
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')"
    }
}

function Remove-LongPathDirectory([string]$Path) {
    if (-not (Test-Path $Path)) { return }

    $full = [System.IO.Path]::GetFullPath($Path)
    Write-Host "Deleting: $full" -ForegroundColor DarkYellow

    & cmd.exe /d /c "rd /s /q \\?\$full"
    if (Test-Path $full) {
        Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-AndroidSdkRoot {
    $candidates = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate "platform-tools\adb.exe")) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    throw "Android SDK was not found. Expected adb.exe under LOCALAPPDATA\Android\Sdk\platform-tools."
}

function Get-OnlineEmulatorId {
    param([Parameter(Mandatory = $true)][string]$Adb)

    $lines = & $Adb devices
    foreach ($line in $lines) {
        if ($line -match '^(emulator-\d+)\s+device$') {
            return $Matches[1]
        }
    }
    return $null
}

function Start-And-WaitForEmulator {
    param(
        [Parameter(Mandatory = $true)][string]$SdkRoot,
        [string]$RequestedAvd = ""
    )

    $adb = Join-Path $SdkRoot "platform-tools\adb.exe"
    $emulator = Join-Path $SdkRoot "emulator\emulator.exe"

    if (-not (Test-Path $emulator)) {
        throw "Android Emulator executable was not found: $emulator"
    }

    & $adb start-server | Out-Null

    $online = Get-OnlineEmulatorId -Adb $adb
    if ($online) {
        Write-Host "Emulator already connected: $online" -ForegroundColor Green
        return $online
    }

    $avds = @(& $emulator -list-avds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($avds.Count -eq 0) {
        throw "No Android Virtual Device was found. Create one from Android Studio Device Manager."
    }

    $selectedAvd = if (-not [string]::IsNullOrWhiteSpace($RequestedAvd)) {
        if ($avds -notcontains $RequestedAvd) {
            throw "Requested AVD '$RequestedAvd' was not found. Available: $($avds -join ', ')"
        }
        $RequestedAvd
    } else {
        $avds[0]
    }

    Write-Host "Starting emulator: $selectedAvd" -ForegroundColor Yellow
    Start-Process -FilePath $emulator -ArgumentList @(
        "-avd", $selectedAvd,
        "-no-snapshot-save"
    ) | Out-Null

    Write-Host "Waiting for emulator connection..." -ForegroundColor Yellow
    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 3
        $online = Get-OnlineEmulatorId -Adb $adb
        if ((Get-Date) -gt $deadline) {
            throw "Timed out waiting for the Android Emulator to connect."
        }
    } until ($online)

    Invoke-Checked $adb @("-s", $online, "wait-for-device")

    Write-Host "Waiting for Android boot completion..." -ForegroundColor Yellow
    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 3
        $boot = (& $adb -s $online shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $deadline) {
            throw "Timed out waiting for Android to finish booting."
        }
    } until ($boot -eq "1")

    & $adb -s $online shell input keyevent 82 2>$null | Out-Null
    Write-Host "Emulator ready: $online" -ForegroundColor Green
    return $online
}

try {
    Clear-Host
    Write-Host "CAR GAME - CLEAN DEBUG RUN" -ForegroundColor Green
    Write-Host "This window remains open after success or failure." -ForegroundColor Yellow

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter was not found in PATH."
    }

    if (-not (Test-Path ".\pubspec.yaml")) {
        throw "pubspec.yaml was not found in: $PSScriptRoot"
    }

    $sdkRoot = Get-AndroidSdkRoot
    $adb = Join-Path $sdkRoot "platform-tools\adb.exe"

    Write-Step "Stopping Gradle, Kotlin, Java and Dart processes"
    if (Test-Path ".\android\gradlew.bat") {
        Push-Location ".\android"
        try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
        Pop-Location
    }

    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2

    Write-Step "Applying stable non-incremental Kotlin settings"
    $gradleProperties = Join-Path $PSScriptRoot "android\gradle.properties"
    $required = @(
        "org.gradle.daemon=false",
        "org.gradle.parallel=false",
        "org.gradle.caching=false",
        "org.gradle.workers.max=1",
        "kotlin.incremental=false",
        "kotlin.incremental.useClasspathSnapshot=false",
        "kotlin.compiler.execution.strategy=in-process",
        "kotlin.daemon.enabled=false"
    )

    $existing = if (Test-Path $gradleProperties) {
        Get-Content $gradleProperties -Raw
    } else {
        ""
    }

    foreach ($line in $required) {
        $key = $line.Split('=')[0]
        if ($existing -match "(?m)^$([regex]::Escape($key))=") {
            $existing = [regex]::Replace(
                $existing,
                "(?m)^$([regex]::Escape($key))=.*$",
                $line
            )
        } else {
            $existing += "`r`n$line"
        }
    }

    [System.IO.File]::WriteAllText(
        $gradleProperties,
        $existing.Trim() + "`r`n",
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Step "Deleting Flutter, Gradle and Kotlin build caches"
    Remove-LongPathDirectory ".\build"
    Remove-LongPathDirectory ".\.dart_tool"
    Remove-LongPathDirectory ".\android\.gradle"
    Remove-LongPathDirectory ".\android\app\build"

    $userKotlin = Join-Path $env:USERPROFILE ".kotlin"
    Remove-LongPathDirectory $userKotlin

    Write-Step "Restoring Flutter packages"
    Invoke-Checked "flutter" @("clean")
    Invoke-Checked "flutter" @("pub", "get")

    try {
        Invoke-Checked "flutter" @("gen-l10n")
    } catch {
        Write-Warning "flutter gen-l10n was skipped."
    }

    Write-Step "Preparing Android Emulator"
    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        $DeviceId = Start-And-WaitForEmulator -SdkRoot $sdkRoot -RequestedAvd $AvdName
    } else {
        Invoke-Checked $adb @("-s", $DeviceId, "wait-for-device")
    }

    Write-Step "Running the application in Debug mode on $DeviceId"
    Invoke-Checked "flutter" @("run", "--no-pub", "-d", $DeviceId)
}
catch {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "DEBUG RUN FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close this window")
}
