param(
    [string]$AvdName = "",
    [string]$PackageId = "com.walka.cargosort",
    [string]$ApkPath = ".\build\app\outputs\flutter-apk\app-release.apk",
    [switch]$BuildFirst
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Find-AndroidTool {
    param([string]$RelativePath, [string]$CommandName)

    $fromPath = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }

    $sdkCandidates = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        "$env:LOCALAPPDATA\Android\Sdk"
    ) | Where-Object { $_ }

    foreach ($sdk in $sdkCandidates) {
        $candidate = Join-Path $sdk $RelativePath
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
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

$adb = Find-AndroidTool "platform-tools\adb.exe" "adb"
$emulator = Find-AndroidTool "emulator\emulator.exe" "emulator"

if (-not $adb) { throw "adb.exe was not found. Install Android SDK Platform-Tools." }
if (-not $emulator) { throw "emulator.exe was not found. Install Android Emulator from SDK Manager." }

if ($BuildFirst) {
    Write-Host "Building release APK first..." -ForegroundColor Cyan
    Invoke-Checked -Command "flutter" -Arguments @("clean")
    Invoke-Checked -Command "flutter" -Arguments @("pub", "get")
    try {
        Invoke-Checked -Command "flutter" -Arguments @("gen-l10n")
    }
    catch {
        Write-Warning "gen-l10n skipped."
    }
    Invoke-Checked -Command "flutter" -Arguments @(
        "build", "apk", "--release", "--target-platform", "android-arm64"
    )
}

$resolvedApk = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $ApkPath))
if (-not (Test-Path $resolvedApk)) {
    throw "APK was not found at: $resolvedApk"
}

$runningEmulator = (& $adb devices) |
    Select-String '^emulator-\d+\s+device$' |
    Select-Object -First 1

if (-not $runningEmulator) {
    $avds = & $emulator -list-avds | Where-Object { $_.Trim() }
    if (-not $avds) {
        throw "No Android Virtual Device was found. Create one in Android Studio > Device Manager."
    }

    if (-not $AvdName) {
        $AvdName = $avds | Select-Object -First 1
    }

    if ($avds -notcontains $AvdName) {
        throw "AVD '$AvdName' was not found. Available AVDs: $($avds -join ', ')"
    }

    Write-Host "Starting emulator: $AvdName" -ForegroundColor Cyan
    Start-Process -FilePath $emulator -ArgumentList @(
        "-avd", $AvdName, "-netdelay", "none", "-netspeed", "full"
    ) | Out-Null
}
else {
    Write-Host "An emulator is already running." -ForegroundColor Green
}

Write-Host "Waiting for emulator connection..." -ForegroundColor Cyan
Invoke-Checked -Command $adb -Arguments @("wait-for-device")

$timeoutSeconds = 240
$startedAt = Get-Date
while ($true) {
    $bootCompleted = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    $bootAnimation = (& $adb shell getprop init.svc.bootanim 2>$null).Trim()

    if ($bootCompleted -eq "1" -and $bootAnimation -eq "stopped") {
        break
    }

    if (((Get-Date) - $startedAt).TotalSeconds -ge $timeoutSeconds) {
        throw "The emulator did not finish booting within $timeoutSeconds seconds."
    }

    Start-Sleep -Seconds 3
}

Write-Host "Emulator is ready." -ForegroundColor Green
Write-Host "Installing APK..." -ForegroundColor Cyan
& $adb uninstall $PackageId 2>$null | Out-Null
Invoke-Checked -Command $adb -Arguments @("install", "-r", $resolvedApk)

Write-Host "Launching application..." -ForegroundColor Cyan
Invoke-Checked -Command $adb -Arguments @(
    "shell",
    "monkey",
    "-p",
    $PackageId,
    "-c",
    "android.intent.category.LAUNCHER",
    "1"
)

Write-Host ""
Write-Host "APPLICATION STARTED ON EMULATOR" -ForegroundColor Green
Write-Host "APK: $resolvedApk" -ForegroundColor Green
