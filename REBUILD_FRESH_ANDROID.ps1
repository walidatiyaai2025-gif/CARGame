param(
    [string]$Branch = "main",
    [string]$PackageId = "com.walka.cargosort",
    [switch]$SkipGitSync,
    [switch]$InstallApk
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Command @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
    }
}

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

if (-not (Test-Path ".\pubspec.yaml")) {
    throw "pubspec.yaml was not found. Run the script from the Flutter project root."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter was not found in PATH."
}

Write-Step "Stopping Gradle, Java and Dart processes"
if (Test-Path ".\android\gradlew.bat") {
    Push-Location ".\android"
    try { .\gradlew.bat --stop 2>$null } catch {}
    Pop-Location
}
Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

if (-not $SkipGitSync) {
    Write-Step "Replacing all local files with origin/$Branch"
    if (-not (Test-Path ".\.git")) {
        throw "The project is not a Git repository."
    }
    Invoke-Native git fetch origin
    Invoke-Native git reset --hard "origin/$Branch"
    Invoke-Native git clean -xfd
}

Write-Step "Backing up the existing Android folder"
$backupRoot = Join-Path $PSScriptRoot "_android_backup"
Remove-Item $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path ".\android") {
    Move-Item ".\android" $backupRoot -Force
}

Write-Step "Generating a fresh Android project with the installed Flutter SDK"
Invoke-Native flutter create --platforms=android --org com.walka --project-name cargo_sort_game .

$appGradle = ".\android\app\build.gradle.kts"
$settingsGradle = ".\android\settings.gradle.kts"
$wrapperFile = ".\android\gradle\wrapper\gradle-wrapper.properties"
$gradleProperties = ".\android\gradle.properties"
$manifestFile = ".\android\app\src\main\AndroidManifest.xml"

Write-Step "Applying stable Android, Kotlin and Gradle settings"

if (Test-Path $settingsGradle) {
    $settings = Get-Content $settingsGradle -Raw
    $settings = $settings -replace 'id\("com\.android\.application"\)\s+version\s+"[^"]+"', 'id("com.android.application") version "8.11.1"'
    $settings = $settings -replace 'id\("org\.jetbrains\.kotlin\.android"\)\s+version\s+"[^"]+"', 'id("org.jetbrains.kotlin.android") version "2.3.20"'
    [System.IO.File]::WriteAllText((Resolve-Path $settingsGradle), $settings, [System.Text.UTF8Encoding]::new($false))
}

if (Test-Path $wrapperFile) {
    $wrapper = Get-Content $wrapperFile -Raw
    $wrapper = $wrapper -replace 'distributionUrl=.*gradle-[\d.]+-(bin|all)\.zip', 'distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip'
    [System.IO.File]::WriteAllText((Resolve-Path $wrapperFile), $wrapper, [System.Text.ASCIIEncoding]::new())
}

if (Test-Path $appGradle) {
    $app = Get-Content $appGradle -Raw
    if ($app -notmatch 'import org\.jetbrains\.kotlin\.gradle\.dsl\.JvmTarget') {
        $app = "import org.jetbrains.kotlin.gradle.dsl.JvmTarget`r`n" + $app
    }
    $app = $app -replace 'namespace\s*=\s*"[^"]+"', "namespace = `"$PackageId`""
    $app = $app -replace 'applicationId\s*=\s*"[^"]+"', "applicationId = `"$PackageId`""
    $app = [regex]::Replace($app, '(?s)\s*kotlinOptions\s*\{.*?\}', '')
    if ($app -notmatch '(?s)kotlin\s*\{\s*compilerOptions') {
        $kotlinBlock = @"

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

"@
        $app = $app -replace '(?m)^android\s*\{', ($kotlinBlock + 'android {')
    }
    $app = $app -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
    [System.IO.File]::WriteAllText((Resolve-Path $appGradle), $app, [System.Text.UTF8Encoding]::new($false))
}

$props = @"
org.gradle.jvmargs=-Xmx6144m -XX:MaxMetaspaceSize=1536m -Dfile.encoding=UTF-8
org.gradle.workers.max=2
org.gradle.parallel=false
org.gradle.caching=false
kotlin.incremental=false
kotlin.incremental.useClasspathSnapshot=false
kotlin.compiler.execution.strategy=in-process
android.useAndroidX=true
android.enableJetifier=false
"@
[System.IO.File]::WriteAllText((Resolve-Path $gradleProperties), $props.Trim() + "`r`n", [System.Text.UTF8Encoding]::new($false))

Write-Step "Configuring Android permissions and AdMob test application ID"
if (Test-Path $manifestFile) {
    $manifest = Get-Content $manifestFile -Raw
    if ($manifest -notmatch 'android.permission.INTERNET') {
        $manifest = $manifest -replace '<manifest xmlns:android="http://schemas.android.com/apk/res/android">', "<manifest xmlns:android=`"http://schemas.android.com/apk/res/android`">`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />`r`n    <uses-permission android:name=`"android.permission.ACCESS_NETWORK_STATE`" />"
    }
    if ($manifest -notmatch 'com.google.android.gms.ads.APPLICATION_ID') {
        $meta = @"
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713" />
"@
        $manifest = $manifest -replace '(?s)(<application\b[^>]*>)', ('$1' + "`r`n" + $meta)
    }
    [System.IO.File]::WriteAllText((Resolve-Path $manifestFile), $manifest, [System.Text.UTF8Encoding]::new($false))
}

Write-Step "Cleaning generated caches"
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\android\app\build" -Recurse -Force -ErrorAction SilentlyContinue

Invoke-Native flutter clean
Invoke-Native flutter pub get
try {
    Invoke-Native flutter gen-l10n
} catch {
    Write-Warning "flutter gen-l10n was skipped or failed because localization generation is not enabled."
}
Invoke-Native flutter analyze --no-fatal-infos

Write-Step "Checking generated Gradle and Java versions"
Push-Location ".\android"
Invoke-Native .\gradlew.bat --version
Pop-Location

Write-Step "Building the ARM64 release APK"
Invoke-Native flutter build apk --release --target-platform android-arm64 --no-pub

$apkPath = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    throw "The build command completed but the APK was not found at: $apkPath"
}

Write-Host ""
Write-Host "BUILD SUCCESS" -ForegroundColor Green
Write-Host $apkPath -ForegroundColor Green

if ($InstallApk) {
    $sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "$env:LOCALAPPDATA\Android\Sdk" }
    $adb = Join-Path $sdkRoot "platform-tools\adb.exe"
    if (-not (Test-Path $adb)) {
        throw "adb.exe was not found at $adb"
    }
    Write-Step "Installing the APK on the connected Android device"
    & $adb uninstall $PackageId 2>$null | Out-Null
    & $adb install -r $apkPath
    if ($LASTEXITCODE -ne 0) {
        throw "APK installation failed."
    }
    Write-Host "APK installed successfully." -ForegroundColor Green
}

Write-Host ""
Write-Host "The old Android folder is preserved temporarily at:" -ForegroundColor Yellow
Write-Host $backupRoot -ForegroundColor Yellow
