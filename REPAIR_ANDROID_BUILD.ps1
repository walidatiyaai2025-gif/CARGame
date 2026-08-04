param(
    [switch]$BuildApk
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".\pubspec.yaml")) {
    throw "Run this script from the Flutter project root containing pubspec.yaml."
}

$settingsKts = ".\android\settings.gradle.kts"
$settingsGroovy = ".\android\settings.gradle"

if (Test-Path $settingsGroovy) {
    Write-Host "Removing stale android/settings.gradle so Flutter uses settings.gradle.kts..." -ForegroundColor Yellow
    Remove-Item $settingsGroovy -Force
}

if (-not (Test-Path $settingsKts)) {
    throw "android/settings.gradle.kts was not found. Run git pull origin main first."
}

$settings = Get-Content $settingsKts -Raw
$settings = $settings -replace 'id\("com\.android\.application"\)\s+version\s+"[^"]+"', 'id("com.android.application") version "8.11.1"'
$settings = $settings -replace 'id\("org\.jetbrains\.kotlin\.android"\)\s+version\s+"[^"]+"', 'id("org.jetbrains.kotlin.android") version "2.3.20"'
[System.IO.File]::WriteAllText((Resolve-Path $settingsKts), $settings, [System.Text.UTF8Encoding]::new($false))

$wrapper = ".\android\gradle\wrapper\gradle-wrapper.properties"
if (Test-Path $wrapper) {
    $wrapperText = Get-Content $wrapper -Raw
    $wrapperText = $wrapperText -replace 'distributionUrl=.*gradle-[\d.]+-(bin|all)\.zip', 'distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip'
    [System.IO.File]::WriteAllText((Resolve-Path $wrapper), $wrapperText, [System.Text.ASCIIEncoding]::new())
}

$gradleProperties = ".\android\gradle.properties"
if (-not (Test-Path $gradleProperties)) {
    New-Item -ItemType File -Path $gradleProperties -Force | Out-Null
}

$props = Get-Content $gradleProperties -Raw
$required = [ordered]@{
    "org.gradle.jvmargs" = "-Xmx6144m -XX:MaxMetaspaceSize=1536m -Dfile.encoding=UTF-8"
    "org.gradle.workers.max" = "2"
    "org.gradle.parallel" = "false"
    "org.gradle.caching" = "false"
    "kotlin.incremental" = "false"
    "kotlin.incremental.useClasspathSnapshot" = "false"
    "kotlin.compiler.execution.strategy" = "in-process"
    "android.useAndroidX" = "true"
    "android.enableJetifier" = "false"
}

foreach ($key in $required.Keys) {
    $props = $props -replace "(?m)^$([regex]::Escape($key))=.*\r?\n?", ""
}
$props = $props.TrimEnd()
foreach ($key in $required.Keys) {
    $props += "`r`n$key=$($required[$key])"
}
$props += "`r`n"
[System.IO.File]::WriteAllText((Resolve-Path $gradleProperties), $props, [System.Text.UTF8Encoding]::new($false))

Write-Host "Stopping Gradle and Java processes..." -ForegroundColor Cyan
Push-Location ".\android"
try { .\gradlew.bat --stop } catch {}
Pop-Location
Get-Process java,javaw,kotlinc,gradle -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Cleaning stale caches..." -ForegroundColor Cyan
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\app\build" -Recurse -Force -ErrorAction SilentlyContinue

flutter clean
flutter pub get
flutter gen-l10n

Write-Host "Running analyzer..." -ForegroundColor Cyan
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze found warnings or errors that must be fixed."
}

Write-Host "Gradle versions:" -ForegroundColor Cyan
Push-Location ".\android"
.\gradlew.bat --version
Pop-Location

if ($BuildApk) {
    flutter build apk --release --target-platform android-arm64
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter APK build failed."
    }
}

Write-Host "Repair completed successfully." -ForegroundColor Green
