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

function Assert-ProductionAdUnitId {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name is required when -EnableAds is used."
    }

    $trimmed = $Value.Trim()
    if ($trimmed.StartsWith('ca-app-pub-3940256099942544/')) {
        throw "$Name uses a Google test AdMob unit ID. Production test IDs are forbidden in an RC build."
    }
}

function Assert-ProductionAdMobAppId {
    param([Parameter(Mandatory)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw 'AndroidAdMobAppId is required for every RC build. Pass the production AdMob Android application ID.'
    }

    $trimmed = $Value.Trim()
    if ($trimmed.StartsWith('ca-app-pub-3940256099942544~')) {
        throw 'AndroidAdMobAppId uses Google''s test application ID. Production test IDs are forbidden in an RC build.'
    }
}

function Assert-ReleaseSigningConfigured {
    $keyPropertiesPath = Join-Path $PSScriptRoot 'android\key.properties'
    if (Test-Path $keyPropertiesPath) {
        return
    }

    $requiredEnvironment = @(
        'ANDROID_KEYSTORE_PATH',
        'ANDROID_KEYSTORE_PASSWORD',
        'ANDROID_KEY_ALIAS',
        'ANDROID_KEY_PASSWORD'
    )
    $missing = @(
        $requiredEnvironment | Where-Object {
            [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))
        }
    )
    if ($missing.Count -gt 0) {
        throw "Android release signing is not configured. Create android\key.properties from android\key.properties.example or set all signing environment variables. Missing: $($missing -join ', ')"
    }
}

$previousAdMobAppId = $env:ADMOB_ANDROID_APP_ID

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' CARGO SORT - ANDROID RELEASE CANDIDATE BUILDER' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan

    if (-not (Test-Path '.\pubspec.yaml')) {
        throw "pubspec.yaml was not found in $PSScriptRoot"
    }

    Assert-ProductionAdMobAppId $AndroidAdMobAppId
    Assert-ReleaseSigningConfigured

    if ($EnableAds) {
        Assert-ProductionAdUnitId 'AndroidBannerId' $AndroidBannerId
        Assert-ProductionAdUnitId 'AndroidRewardedId' $AndroidRewardedId
        Assert-ProductionAdUnitId 'AndroidInterstitialId' $AndroidInterstitialId
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
