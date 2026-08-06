param(
    [string]$AvdName = "",
    [string]$ProjectPath = $PSScriptRoot,
    [string]$PackageId = "com.walka.cargosort"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Find-AndroidSdk {
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
    throw "Android SDK was not found."
}

function Get-OnlineDevice([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') {
            return $Matches[1]
        }
    }
    return $null
}

function Save-CrashLog([string]$Adb, [string]$Device, [string]$Destination) {
    Write-Host "Collecting Android crash log..." -ForegroundColor Yellow
    & $Adb -s $Device logcat -d -v time `
        "AndroidRuntime:E" `
        "flutter:E" `
        "ActivityManager:E" `
        "*:S" 2>&1 | Out-File -FilePath $Destination -Encoding utf8
    Write-Host "Crash log: $Destination" -ForegroundColor Cyan
}

try {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " CARGO SORT - COLD BOOT AND RUN" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan

    $ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    Set-Location $ProjectPath

    $sdk = Find-AndroidSdk
    $adb = Join-Path $sdk "platform-tools\adb.exe"
    $emulator = Join-Path $sdk "emulator\emulator.exe"

    if (-not (Test-Path $emulator)) {
        throw "Android Emulator was not found: $emulator"
    }

    & $adb start-server | Out-Null
    $device = Get-OnlineDevice $adb

    if (-not $device) {
        $avds = @(& $emulator -list-avds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($avds.Count -eq 0) {
            throw "No Android Virtual Device exists. Create one in Android Studio Device Manager."
        }

        $selectedAvd = if ($AvdName) { $AvdName } else { $avds[0] }
        if ($avds -notcontains $selectedAvd) {
            throw "AVD '$selectedAvd' was not found. Available: $($avds -join ', ')"
        }

        $snapshotFolder = Join-Path $env:USERPROFILE ".android\avd\$selectedAvd.avd\snapshots"
        if (Test-Path $snapshotFolder) {
            Write-Host "Removing incompatible snapshots: $snapshotFolder" -ForegroundColor Yellow
            Remove-Item $snapshotFolder -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Starting $selectedAvd with a clean cold boot..." -ForegroundColor Yellow
        Start-Process -FilePath $emulator -ArgumentList @(
            "-avd", $selectedAvd,
            "-no-snapshot-load",
            "-no-snapshot-save",
            "-no-boot-anim"
        ) | Out-Null

        $deadline = (Get-Date).AddMinutes(8)
        do {
            Start-Sleep -Seconds 3
            $device = Get-OnlineDevice $adb
            if ((Get-Date) -gt $deadline) {
                throw "Timed out waiting for the emulator device."
            }
        } until ($device)

        & $adb -s $device wait-for-device | Out-Null
        do {
            Start-Sleep -Seconds 3
            $bootCompleted = (& $adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
            if ((Get-Date) -gt $deadline) {
                throw "Timed out waiting for Android to finish booting."
            }
        } until ($bootCompleted -eq "1")
    }

    Write-Host "Device ready: $device" -ForegroundColor Green
    & $adb -s $device logcat -c

    Write-Host "Restoring packages..." -ForegroundColor Cyan
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed with exit code $LASTEXITCODE" }

    Write-Host "Running application..." -ForegroundColor Cyan
    & flutter run --no-pub -d $device
    $runExitCode = $LASTEXITCODE

    if ($runExitCode -ne 0) {
        $logPath = Join-Path $ProjectPath "android_crash_log.txt"
        Save-CrashLog $adb $device $logPath
        throw "flutter run failed with exit code $runExitCode"
    }
}
catch {
    Write-Host "" 
    Write-Host "COLD BOOT RUN FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    try {
        if ($adb -and $device) {
            $fallbackLog = Join-Path $ProjectPath "android_crash_log.txt"
            Save-CrashLog $adb $device $fallbackLog
        }
    } catch {
        Write-Warning "Could not collect Logcat: $($_.Exception.Message)"
    }
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close")
}
