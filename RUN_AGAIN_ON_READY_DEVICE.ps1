param(
    [string]$ProjectPath = $PSScriptRoot,
    [string]$AvdName = "",
    [switch]$Release,
    [switch]$SkipGitUpdate
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$PackageId = 'com.walka.cargosort'

function Write-Step([string]$Text) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @(),
        [string]$Folder = ''
    )

    if ($Folder) { Push-Location $Folder }
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($Folder) { Pop-Location }
    }
}

function Get-AndroidSdkRoot {
    $candidates = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate 'platform-tools\adb.exe')) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    throw 'Android SDK was not found.'
}

function Get-OnlineDevice([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') {
            return $Matches[1]
        }
    }
    return $null
}

function Start-Or-GetDevice([string]$SdkRoot, [string]$RequestedAvd) {
    $adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
    $emulator = Join-Path $SdkRoot 'emulator\emulator.exe'

    & $adb start-server | Out-Null
    $device = Get-OnlineDevice $adb
    if ($device) {
        Write-Host "Using connected device: $device" -ForegroundColor Green
        return $device
    }

    if (-not (Test-Path $emulator)) {
        throw 'No connected phone was found and Android Emulator is not installed.'
    }

    $avds = @(& $emulator -list-avds | Where-Object { $_.Trim() })
    if ($avds.Count -eq 0) {
        throw 'No connected device and no Android Virtual Device was found.'
    }

    $selectedAvd = if ($RequestedAvd) { $RequestedAvd } else { $avds[0] }
    if ($avds -notcontains $selectedAvd) {
        throw "AVD not found: $selectedAvd. Available: $($avds -join ', ')"
    }

    Write-Host "Starting emulator: $selectedAvd" -ForegroundColor Yellow
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $selectedAvd, '-no-snapshot-save') | Out-Null

    $deadline = (Get-Date).AddMinutes(7)
    do {
        Start-Sleep -Seconds 3
        $device = Get-OnlineDevice $adb
        if ((Get-Date) -gt $deadline) {
            throw 'Timed out waiting for the emulator to connect.'
        }
    } until ($device)

    Invoke-Checked $adb @('-s', $device, 'wait-for-device')
    do {
        Start-Sleep -Seconds 3
        $bootCompleted = (& $adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $deadline) {
            throw 'Timed out waiting for Android to finish booting.'
        }
    } until ($bootCompleted -eq '1')

    return $device
}

try {
    Clear-Host
    Write-Host 'CAR GAME - RUN AGAIN ON READY DEVICE' -ForegroundColor Green
    Write-Host 'Use this script on a computer that was already prepared before.' -ForegroundColor Yellow

    $ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) {
        throw "Flutter project was not found at: $ProjectPath"
    }

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter was not found in PATH.'
    }

    Set-Location $ProjectPath

    if (-not $SkipGitUpdate -and (Test-Path '.git')) {
        Write-Step 'Updating project from GitHub main'
        Invoke-Checked 'git' @('fetch', 'origin')
        Invoke-Checked 'git' @('reset', '--hard', 'origin/main')
    }

    Write-Step 'Restoring Flutter packages'
    $env:GRADLE_USER_HOME = Join-Path $ProjectPath '.gradle-user-home-rerun'
    New-Item -ItemType Directory -Path $env:GRADLE_USER_HOME -Force | Out-Null
    Invoke-Checked 'flutter' @('pub', 'get')
    Invoke-Checked 'flutter' @('analyze', '--no-fatal-infos')

    Write-Step 'Preparing Android device'
    $sdkRoot = Get-AndroidSdkRoot
    $deviceId = Start-Or-GetDevice $sdkRoot $AvdName
    Write-Host "Device ready: $deviceId" -ForegroundColor Green

    if ($Release) {
        Write-Step 'Building release APK'
        Invoke-Checked 'flutter' @('build', 'apk', '--release', '--no-pub')
        $apk = Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-release.apk'
        if (-not (Test-Path $apk)) {
            throw "Release APK was not found: $apk"
        }

        $adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
        Write-Step 'Installing release APK'
        & $adb -s $deviceId uninstall $PackageId 2>$null | Out-Null
        Invoke-Checked $adb @('-s', $deviceId, 'install', '-r', $apk)
        Invoke-Checked $adb @('-s', $deviceId, 'shell', 'am', 'start', '-n', "$PackageId/.MainActivity")

        Start-Sleep -Seconds 10
        $appProcessId = (& $adb -s $deviceId shell pidof $PackageId 2>$null).Trim()
        if ([string]::IsNullOrWhiteSpace($appProcessId)) {
            $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $logPath = Join-Path $ProjectPath "rerun_release_crash_$stamp.log"
            & $adb -s $deviceId logcat -d -v time |
                Select-String -Pattern 'FATAL EXCEPTION|AndroidRuntime|Caused by|flutter|Dart|com.walka.cargosort' |
                Set-Content $logPath -Encoding UTF8
            throw "The release app closed after launch. Crash log: $logPath"
        }

        Write-Host "Release app is running. PID: $appProcessId" -ForegroundColor Green
    }
    else {
        Write-Step 'Running Debug application'
        Invoke-Checked 'flutter' @('run', '--no-pub', '-d', $deviceId)
    }
}
catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host 'RUN AGAIN FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close this window')
}
