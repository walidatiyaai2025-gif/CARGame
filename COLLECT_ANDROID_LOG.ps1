param(
    [string]$PackageName = "com.walka.cargosort",
    [string]$OutputFile = ".\android_runtime.log",
    [string]$FilteredOutputFile = ".\android_runtime_filtered.log",
    [int]$Seconds = 45
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Assert-Command([string]$Name, [string]$Message) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
}

Assert-Command "adb" "adb was not found in PATH. Add Android SDK platform-tools to PATH."

$devices = adb devices
if ($LASTEXITCODE -ne 0 -or ($devices -notmatch "\tdevice")) {
    throw "No authorized Android device is connected. Enable USB debugging and accept the authorization prompt."
}

$fullOutputPath = Join-Path $PSScriptRoot $OutputFile
$filteredOutputPath = Join-Path $PSScriptRoot $FilteredOutputFile

Remove-Item $fullOutputPath, $filteredOutputPath -Force -ErrorAction SilentlyContinue

Write-Host "Clearing old Logcat buffer..." -ForegroundColor Cyan
adb logcat -c

Write-Host "Starting package: $PackageName" -ForegroundColor Cyan
adb shell am force-stop $PackageName | Out-Null
adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Seconds 2

$pidText = (adb shell pidof $PackageName 2>$null).Trim()
if ($pidText) {
    Write-Host "Application PID: $pidText" -ForegroundColor Green
}
else {
    Write-Warning "The application PID was not found. The app may have crashed before PID detection. Full Logcat will still be collected."
}

Write-Host "Collecting Android logs for $Seconds seconds..." -ForegroundColor Cyan
Write-Host "Reproduce the crash now. Do not disconnect the device." -ForegroundColor Yellow

$job = Start-Job -ScriptBlock {
    param($Path)
    adb logcat -v threadtime 2>&1 | Out-File -FilePath $Path -Encoding utf8
} -ArgumentList $fullOutputPath

Start-Sleep -Seconds $Seconds
Stop-Job $job -ErrorAction SilentlyContinue
Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
Remove-Job $job -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $fullOutputPath)) {
    throw "Logcat output was not created."
}

$patterns = @(
    $PackageName,
    "FATAL EXCEPTION",
    "AndroidRuntime",
    "E/flutter",
    "FlutterError",
    "PlatformException",
    "Caused by:",
    "Process:",
    "SIGABRT",
    "SIGSEGV",
    "google_mobile_ads",
    "shared_preferences"
)

$regex = ($patterns | ForEach-Object { [regex]::Escape($_) }) -join "|"
$lines = Get-Content $fullOutputPath

$selectedLineNumbers = New-Object System.Collections.Generic.HashSet[int]
for ($index = 0; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -match $regex) {
        $start = [Math]::Max(0, $index - 12)
        $end = [Math]::Min($lines.Count - 1, $index + 35)
        for ($lineIndex = $start; $lineIndex -le $end; $lineIndex++) {
            [void]$selectedLineNumbers.Add($lineIndex)
        }
    }
}

if ($selectedLineNumbers.Count -gt 0) {
    $ordered = $selectedLineNumbers | Sort-Object
    $filtered = foreach ($lineNumber in $ordered) {
        $lines[$lineNumber]
    }
    $filtered | Set-Content $filteredOutputPath -Encoding UTF8
}
else {
    @(
        "No matching crash lines were found.",
        "Review the complete log: $fullOutputPath"
    ) | Set-Content $filteredOutputPath -Encoding UTF8
}

Write-Host "" 
Write-Host "Complete log:" -ForegroundColor Green
Write-Host $fullOutputPath -ForegroundColor Green
Write-Host "" 
Write-Host "Filtered crash log:" -ForegroundColor Green
Write-Host $filteredOutputPath -ForegroundColor Green
Write-Host "" 
Write-Host "Send android_runtime_filtered.log first. If it is incomplete, send android_runtime.log." -ForegroundColor Yellow
