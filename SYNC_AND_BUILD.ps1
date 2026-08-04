param(
    [string]$Branch = "main",
    [switch]$SkipAnalyze
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

Set-Location $PSScriptRoot

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    & $Command @Arguments
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "Command failed with exit code $code: $Command $($Arguments -join ' ')"
    }
}

Write-Host "========== CAR GAME CLEAN SYNC AND BUILD ==========" -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    throw "The project root is not a Git repository."
}
if (-not (Test-Path "pubspec.yaml")) {
    throw "pubspec.yaml was not found in the project root."
}

Write-Host "Stopping Gradle and Java processes..." -ForegroundColor Yellow
if (Test-Path ".\android\gradlew.bat") {
    Push-Location ".\android"
    try { & .\gradlew.bat --stop 2>&1 | Write-Host } catch {}
    Pop-Location
}
Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Replacing all local files with origin/$Branch..." -ForegroundColor Yellow
Invoke-Native git fetch origin $Branch
Invoke-Native git reset --hard "origin/$Branch"
Invoke-Native git clean -xfd

# Remove a stale Groovy settings file so Gradle uses settings.gradle.kts.
if (Test-Path ".\android\settings.gradle") {
    Remove-Item ".\android\settings.gradle" -Force
}

# Force supported Gradle wrapper after syncing.
$wrapper = ".\android\gradle\wrapper\gradle-wrapper.properties"
if (-not (Test-Path $wrapper)) {
    throw "Gradle wrapper file was not found: $wrapper"
}
$wrapperText = Get-Content $wrapper -Raw
$wrapperText = $wrapperText -replace 'distributionUrl=.*gradle-[\d.]+-(bin|all)\.zip', 'distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip'
[System.IO.File]::WriteAllText((Resolve-Path $wrapper), $wrapperText, [System.Text.ASCIIEncoding]::new())

Write-Host "Cleaning generated files..." -ForegroundColor Yellow
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\app\build" -Recurse -Force -ErrorAction SilentlyContinue

Invoke-Native flutter clean
Invoke-Native flutter pub get
Invoke-Native flutter gen-l10n

if (-not $SkipAnalyze) {
    Write-Host "Analyzing project..." -ForegroundColor Yellow
    Invoke-Native flutter analyze --no-fatal-infos
}

# Flutter may upgrade Android files during build; force wrapper once more immediately before Gradle starts.
$wrapperText = Get-Content $wrapper -Raw
$wrapperText = $wrapperText -replace 'distributionUrl=.*gradle-[\d.]+-(bin|all)\.zip', 'distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip'
[System.IO.File]::WriteAllText((Resolve-Path $wrapper), $wrapperText, [System.Text.ASCIIEncoding]::new())

Write-Host "Gradle wrapper:" -ForegroundColor Cyan
Get-Content $wrapper | Select-String "distributionUrl"

Write-Host "Building Android ARM64 release APK..." -ForegroundColor Green
Invoke-Native flutter build apk --release --target-platform android-arm64 --no-pub

$apk = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apk)) {
    throw "Build command succeeded but APK was not found at: $apk"
}

Write-Host "" 
Write-Host "BUILD SUCCESS" -ForegroundColor Green
Write-Host $apk -ForegroundColor Green
