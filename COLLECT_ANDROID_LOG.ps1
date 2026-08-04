param(
    [string]$PackageName = "com.walka.cargosort",
    [string]$OutputFile = ".\android_runtime.log",
    [int]$Seconds = 30
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "adb was not found in PATH. Install Android SDK Platform-Tools or add platform-tools to PATH."
}

$devices = adb devices
if ($LASTEXITCODE -ne 0 -or ($devices -notmatch "\tdevice")) {
    throw "No authorized Android device is connected. Enable USB debugging and accept the authorization prompt."
}

Write-Host "Clearing old Logcat buffer..." -ForegroundColor Cyan
adb logcat -c

Write-Host "Starting $PackageName if installed..." -ForegroundColor Cyan
adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Null

Write-Host "Collecting Android logs for $Seconds seconds..." -ForegroundColor Cyan
Write-Host "Reproduce the crash now." -ForegroundColor Yellow

$job = Start-Job -ScriptBlock {
    param($Path)
    adb logcat -v threadtime 2>&1 | Out-File -FilePath $Path -Encoding utf8
} -ArgumentList (Join-Path $PSScriptRoot $OutputFile)

Start-Sleep -Seconds $Seconds
Stop-Job $job -ErrorAction SilentlyContinue
Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
Remove-Job $job -Force -ErrorAction SilentlyContinue

$fullPath = Resolve-Path $OutputFile
Write-Host "Log created:" -ForegroundColor Green
Write-Host $fullPath -ForegroundColor Green
Write-Host "Open it and copy the section around FATAL EXCEPTION, AndroidRuntime, flutter, or your package name." -ForegroundColor Yellow
