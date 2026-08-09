param(
    [switch]$BuildAppBundle,
    [switch]$EnableAds,
    [string]$AndroidAdMobAppId = '',
    [string]$AndroidBannerId = '',
    [string]$AndroidRewardedId = '',
    [string]$AndroidInterstitialId = ''
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot
. (Join-Path $PSScriptRoot 'BUILD_COMMON.ps1')

$previousAdMobAppId = $env:ADMOB_ANDROID_APP_ID

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' CARGO SORT - ANDROID RELEASE CANDIDATE BUILDER' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan

    if (-not (Test-Path '.\pubspec.yaml')) {
        throw "pubspec.yaml was not found in $PSScriptRoot"
    }

    $preflightScript = Join-Path $PSScriptRoot 'VERIFY_RELEASE_INPUTS.ps1'
    if (-not (Test-Path -LiteralPath $preflightScript -PathType Leaf)) {
        throw "Release input preflight was not found: $preflightScript"
    }

    $preflightArguments = @{
        ProjectRoot = $PSScriptRoot
        AndroidAdMobAppId = $AndroidAdMobAppId
        EnableAds = $EnableAds
        AndroidBannerId = $AndroidBannerId
        AndroidRewardedId = $AndroidRewardedId
        AndroidInterstitialId = $AndroidInterstitialId
    }
    $preflight = & $preflightScript @preflightArguments
    if (-not $preflight.Ready) {
        throw 'Android release input preflight did not report a ready configuration.'
    }

    $env:ADMOB_ANDROID_APP_ID = $AndroidAdMobAppId.Trim()

    [void](Initialize-AndroidBuildEnvironment $PSScriptRoot)
    Repair-KotlinBuildCache $PSScriptRoot
    Invoke-NativeChecked 'flutter' @('clean') $PSScriptRoot
    Invoke-NativeChecked 'flutter' @('pub','get') $PSScriptRoot
    Invoke-NativeChecked 'flutter' @('analyze','--no-fatal-infos','--no-fatal-warnings') $PSScriptRoot
    Invoke-NativeChecked 'flutter' @('test') $PSScriptRoot

    $target = if ($BuildAppBundle) { 'appbundle' } else { 'apk' }
    $args = @(
        'build', $target, '--release', '--no-pub',
        '--dart-define=APP_ENV=release',
        "--dart-define=ENABLE_ADS=$($EnableAds.IsPresent.ToString().ToLowerInvariant())"
    )

    if ($EnableAds) {
        $args += "--dart-define=ADMOB_ANDROID_BANNER_ID=$($AndroidBannerId.Trim())"
        $args += "--dart-define=ADMOB_ANDROID_REWARDED_ID=$($AndroidRewardedId.Trim())"
        $args += "--dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=$($AndroidInterstitialId.Trim())"
    }

    try {
        Invoke-NativeChecked 'flutter' $args $PSScriptRoot
    }
    catch {
        Write-Warning 'RC build failed once. Repairing Gradle/Kotlin caches and retrying.'
        Repair-KotlinBuildCache $PSScriptRoot -Deep
        Invoke-NativeChecked 'flutter' @('pub','get') $PSScriptRoot
        Invoke-NativeChecked 'flutter' $args $PSScriptRoot
    }

    $output = if ($BuildAppBundle) {
        Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
    } else {
        Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
    }

    if (-not (Test-Path $output)) {
        throw "RC build completed without the expected artifact: $output"
    }

    Write-Host "`nRC BUILD SUCCESS: $output" -ForegroundColor Green
    Write-Host "Ads enabled: $($EnableAds.IsPresent)" -ForegroundColor Green
    Write-Host 'Environment: release' -ForegroundColor Green
    Write-Host 'Signing: external release configuration' -ForegroundColor Green
}
catch {
    Write-Host "`n============================================================" -ForegroundColor Red
    Write-Host 'RC BUILD FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    exit 1
}
finally {
    if ($null -eq $previousAdMobAppId) {
        Remove-Item Env:ADMOB_ANDROID_APP_ID -ErrorAction SilentlyContinue
    }
    else {
        $env:ADMOB_ANDROID_APP_ID = $previousAdMobAppId
    }
}
