param(
    [string]$AvdName = "",
    [string]$PackageId = "com.walka.cargosort",
    [string]$ApkPath = ".\build\app\outputs\flutter-apk\app-release.apk",
    [switch]$BuildFirst,
    [int]$StartupCheckSeconds = 15
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Find-AndroidTool {
    param([string]$RelativePath, [string]$CommandName)

    $fromPath = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }

    $roots = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        "$env:LOCALAPPDATA\Android\Sdk"
    ) | Where-Object { $_ }

    foreach ($root in $roots) {
        $candidate = Join-Path $root $RelativePath
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

function Save-CrashLogs {
    param([string]$AdbPath, [string]$Package)

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $full = Join-Path $PSScriptRoot "emulator_crash_$stamp.log"
    $filtered = Join-Path $PSScriptRoot "emulator_crash_filtered_$stamp.log"

    & $AdbPath logcat -d -v threadtime 2>&1 | Set-Content $full -Encoding UTF8

    $patterns = @(
        [regex]::Escape($Package),
        "FATAL EXCEPTION",
        "AndroidRuntime",
        "E/flutter",
        "FlutterError",
        "PlatformException",
        "Caused by:",
        "Process:",
        "SIGABRT",
        "SIGSEGV"
    ) -join "|"

    $lines = Get-Content $full
    $matches = New-Object System.Collections.Generic.HashSet[int]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $patterns) {
            $start = [Math]::Max(0, $i - 12)
            $end = [Math]::Min($lines.Count - 1, $i + 40)
            for ($j = $start; $j -le $end; $j++) { [void]$matches.Add($j) }
        }
    }

    if ($matches.Count -gt 0) {
        ($matches | Sort-Object | ForEach-Object { $lines[$_] }) |
            Set-Content $filtered -Encoding UTF8
    }
    else {
        "No matching crash lines were found. Review: $full" |
            Set-Content $filtered -Encoding UTF8
    }

    Write-Host "Full log: $full" -ForegroundColor Yellow
    Write-Host "Filtered log: $filtered" -ForegroundColor Yellow
    return $filtered
}

$adb = Find-AndroidTool "platform-tools\adb.exe" "adb"
$emulator = Find-AndroidTool "emulator\emulator.exe" "emulator"

if (-not $adb) { throw "adb.exe was not found." }
if (-not $emulator) { throw "emulator.exe was not found." }

if ($BuildFirst) {
    Invoke-Checked -Command "flutter" -Arguments @("clean")
    Invoke-Checked -Command "flutter" -Arguments @("pub", "get")
    try { Invoke-Checked -Command "flutter" -Arguments @("gen-l10n") } catch { Write-Warning "gen-l10n skipped." }
    Invoke-Checked -Command "flutter" -Arguments @("build", "apk", "--release", "--target-platform", "android-arm64")
}

$resolvedApk = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $ApkPath))
if (-not (Test-Path $resolvedApk)) { throw "APK was not found at: $resolvedApk" }

$running = (& $adb devices) | Select-String '^emulator-\d+\s+device$' | Select-Object -First 1
if (-not $running) {
    $avds = & $emulator -list-avds | Where-Object { $_.Trim() }
    if (-not $avds) { throw "No Android Virtual Device was found." }
    if (-not $AvdName) { $AvdName = $avds | Select-Object -First 1 }
    if ($avds -notcontains $AvdName) { throw "AVD '$AvdName' was not found." }

    Write-Host "Starting emulator: $AvdName" -ForegroundColor Cyan
    Start-Process -FilePath $emulator -ArgumentList @("-avd", $AvdName, "-netdelay", "none", "-netspeed", "full") | Out-Null
}
else {
    Write-Host "An emulator is already running." -ForegroundColor Green
}

Invoke-Checked -Command $adb -Arguments @("wait-for-device")

$deadline = (Get-Date).AddSeconds(240)
while ((Get-Date) -lt $deadline) {
    $bootCompleted = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    $bootAnimation = (& $adb shell getprop init.svc.bootanim 2>$null).Trim()
    if ($bootCompleted -eq "1" -and $bootAnimation -eq "stopped") { break }
    Start-Sleep -Seconds 3
}

if ((& $adb shell getprop sys.boot_completed 2>$null).Trim() -ne "1") {
    throw "The emulator did not finish booting within 240 seconds."
}

Write-Host "Emulator is ready." -ForegroundColor Green
& $adb logcat -c | Out-Null
& $adb uninstall $PackageId 2>$null | Out-Null
Invoke-Checked -Command $adb -Arguments @("install", "-r", $resolvedApk)

Write-Host "Resolving launcher activity..." -ForegroundColor Cyan
$component = (& $adb shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER $PackageId 2>$null | Select-Object -Last 1).Trim()
if (-not $component -or $component -notmatch "/") {
    $component = "$PackageId/.MainActivity"
}

Write-Host "Launching: $component" -ForegroundColor Cyan
Invoke-Checked -Command $adb -Arguments @("shell", "am", "force-stop", $PackageId)
Invoke-Checked -Command $adb -Arguments @("shell", "am", "start", "-W", "-n", $component)

Write-Host "Checking whether the application remains alive..." -ForegroundColor Cyan
Start-Sleep -Seconds $StartupCheckSeconds
$pid = (& $adb shell pidof $PackageId 2>$null).Trim()

if (-not $pid) {
    $log = Save-CrashLogs -AdbPath $adb -Package $PackageId
    throw "The application stopped after launch. Crash log: $log"
}

Write-Host "" 
Write-Host "APPLICATION STARTED ON EMULATOR" -ForegroundColor Green
Write-Host "PID: $pid" -ForegroundColor Green
Write-Host "APK: $resolvedApk" -ForegroundColor Green
