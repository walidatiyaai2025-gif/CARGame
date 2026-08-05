param(
    [string]$AvdName = "",
    [string]$PackageId = "com.walka.cargosort",
    [string]$ApkPath = ".\build\app\outputs\flutter-apk\app-release.apk",
    [switch]$BuildFirst,
    [int]$VerifySeconds = 12
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

function Save-CrashLog {
    param([string]$AdbPath, [string]$AppId)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fullLog = Join-Path $PSScriptRoot "emulator_crash_$timestamp.log"
    $filteredLog = Join-Path $PSScriptRoot "emulator_crash_filtered_$timestamp.log"

    Write-Host "Collecting emulator crash log..." -ForegroundColor Yellow
    & $AdbPath logcat -d -v threadtime 2>&1 | Set-Content $fullLog -Encoding UTF8

    $patterns = @(
        $AppId,
        "FATAL EXCEPTION",
        "AndroidRuntime",
        "E/flutter",
        "FlutterError",
        "PlatformException",
        "Caused by:",
        "Process:",
        "google_mobile_ads",
        "shared_preferences"
    )

    $regex = ($patterns | ForEach-Object { [regex]::Escape($_) }) -join "|"
    $lines = Get-Content $fullLog
    $selected = New-Object System.Collections.Generic.HashSet[int]

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match $regex) {
            $start = [Math]::Max(0, $index - 12)
            $end = [Math]::Min($lines.Count - 1, $index + 40)
            for ($lineIndex = $start; $lineIndex -le $end; $lineIndex++) {
                [void]$selected.Add($lineIndex)
            }
        }
    }

    if ($selected.Count -gt 0) {
        foreach ($lineNumber in ($selected | Sort-Object)) {
            $lines[$lineNumber]
        } | Set-Content $filteredLog -Encoding UTF8
    }
    else {
        @(
            "No matching crash lines were found.",
            "Review the complete log: $fullLog"
        ) | Set-Content $filteredLog -Encoding UTF8
    }

    Write-Host "Complete log: $fullLog" -ForegroundColor Yellow
    Write-Host "Filtered log: $filteredLog" -ForegroundColor Yellow
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

& $adb logcat -c | Out-Null

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

Write-Host "Verifying application process for $VerifySeconds seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds $VerifySeconds
$pid = (& $adb shell pidof $PackageId 2>$null).Trim()

if (-not $pid) {
    Save-CrashLog -AdbPath $adb -AppId $PackageId
    throw "The application exited immediately after launch. Review the generated emulator_crash_filtered log."
}

Write-Host ""
Write-Host "APPLICATION STARTED ON EMULATOR" -ForegroundColor Green
Write-Host "PID: $pid" -ForegroundColor Green
Write-Host "APK: $resolvedApk" -ForegroundColor Green
