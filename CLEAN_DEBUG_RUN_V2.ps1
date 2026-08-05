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
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
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
    foreach ($candidate in @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, (Join-Path $env:LOCALAPPDATA "Android\Sdk"))) {
        if ($candidate -and (Test-Path (Join-Path $candidate "platform-tools\adb.exe"))) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    throw "Android SDK was not found."
}

function Get-OnlineEmulatorId([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^(emulator-\d+)\s+device$') { return $Matches[1] }
    }
    return $null
}

function Start-And-WaitForEmulator([string]$SdkRoot, [string]$RequestedAvd) {
    $adb = Join-Path $SdkRoot "platform-tools\adb.exe"
    $emulator = Join-Path $SdkRoot "emulator\emulator.exe"
    & $adb start-server | Out-Null

    $online = Get-OnlineEmulatorId $adb
    if ($online) { return $online }

    $avds = @(& $emulator -list-avds | Where-Object { $_.Trim() })
    if ($avds.Count -eq 0) { throw "No Android Virtual Device was found." }
    $selected = if ($RequestedAvd) { $RequestedAvd } else { $avds[0] }

    Start-Process -FilePath $emulator -ArgumentList @("-avd", $selected, "-no-snapshot-save") | Out-Null
    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 3
        $online = Get-OnlineEmulatorId $adb
        if ((Get-Date) -gt $deadline) { throw "Timed out waiting for emulator connection." }
    } until ($online)

    Invoke-Checked $adb @("-s", $online, "wait-for-device")
    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 3
        $boot = (& $adb -s $online shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $deadline) { throw "Timed out waiting for emulator boot." }
    } until ($boot -eq "1")

    return $online
}

try {
    Clear-Host
    Write-Host "CAR GAME - ISOLATED CLEAN DEBUG RUN" -ForegroundColor Green
    Write-Host "This window remains open after success or failure." -ForegroundColor Yellow

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter was not found in PATH." }
    if (-not (Test-Path ".\pubspec.yaml")) { throw "pubspec.yaml was not found." }

    $sdkRoot = Get-AndroidSdkRoot
    $adb = Join-Path $sdkRoot "platform-tools\adb.exe"

    Write-Step "Stopping Gradle, Kotlin, Java and Dart"
    if (Test-Path ".\android\gradlew.bat") {
        Push-Location ".\android"
        try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
        Pop-Location
    }
    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    Write-Step "Using a fresh isolated Gradle user home"
    $isolatedGradleHome = Join-Path $PSScriptRoot ".gradle-user-home-clean"
    Remove-LongPathDirectory $isolatedGradleHome
    New-Item -ItemType Directory -Path $isolatedGradleHome -Force | Out-Null
    $env:GRADLE_USER_HOME = $isolatedGradleHome
    Write-Host "GRADLE_USER_HOME=$env:GRADLE_USER_HOME" -ForegroundColor Green

    Write-Step "Disabling Kotlin incremental caches"
    $gradleProperties = Join-Path $PSScriptRoot "android\gradle.properties"
    $properties = if (Test-Path $gradleProperties) { Get-Content $gradleProperties -Raw } else { "" }
    $required = @(
        "org.gradle.daemon=false",
        "org.gradle.parallel=false",
        "org.gradle.caching=false",
        "org.gradle.configuration-cache=false",
        "org.gradle.workers.max=1",
        "kotlin.incremental=false",
        "kotlin.incremental.useClasspathSnapshot=false",
        "kotlin.compiler.execution.strategy=in-process",
        "kotlin.daemon.enabled=false",
        "kotlin.caching.enabled=false"
    )
    foreach ($line in $required) {
        $key = $line.Split('=')[0]
        if ($properties -match "(?m)^$([regex]::Escape($key))=") {
            $properties = [regex]::Replace($properties, "(?m)^$([regex]::Escape($key))=.*$", $line)
        } else {
            $properties += "`r`n$line"
        }
    }
    [System.IO.File]::WriteAllText($gradleProperties, $properties.Trim() + "`r`n", [System.Text.UTF8Encoding]::new($false))

    Write-Step "Deleting Flutter and plugin build caches"
    foreach ($path in @(
        ".\build",
        ".\.dart_tool",
        ".\android\.gradle",
        ".\android\app\build",
        ".\build\shared_preferences_android",
        ".\build\webview_flutter_android",
        (Join-Path $env:USERPROFILE ".kotlin")
    )) {
        Remove-LongPathDirectory $path
    }

    Write-Step "Restoring packages"
    Invoke-Checked "flutter" @("clean")
    Invoke-Checked "flutter" @("pub", "get")
    try { Invoke-Checked "flutter" @("gen-l10n") } catch { Write-Warning "flutter gen-l10n was skipped." }

    Write-Step "Preparing Android emulator"
    if (-not $DeviceId) { $DeviceId = Start-And-WaitForEmulator $sdkRoot $AvdName }
    else { Invoke-Checked $adb @("-s", $DeviceId, "wait-for-device") }

    Write-Step "Running Debug on $DeviceId"
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
