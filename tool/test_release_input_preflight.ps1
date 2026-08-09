[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$preflightScript = Join-Path $repoRoot 'VERIFY_RELEASE_INPUTS.ps1'
$signingEnvironment = @(
    'ANDROID_KEYSTORE_PATH',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD'
)

function Clear-SigningEnvironment {
    foreach ($name in $signingEnvironment) {
        [Environment]::SetEnvironmentVariable($name, $null)
    }
}

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$CaseName
    )

    try {
        & $Action
        throw "Expected failure did not occur: $CaseName"
    }
    catch {
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Unexpected failure for $CaseName. Message: $($_.Exception.Message)"
        }
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cargame-release-preflight-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot 'android/app') | Out-Null
    Set-Content -LiteralPath (Join-Path $tempRoot 'pubspec.yaml') -Value 'name: release_preflight_fixture'

    $keystore = Join-Path $tempRoot 'fixture-upload.jks'
    Set-Content -LiteralPath $keystore -Value 'fixture-only-not-a-real-keystore'

    Clear-SigningEnvironment
    Assert-ThrowsLike -CaseName 'missing signing inputs' -Pattern 'Android release signing is incomplete' -Action {
        & $preflightScript -ProjectRoot $tempRoot -AndroidAdMobAppId 'ca-app-pub-0000000000000000~0000000000' -Quiet
    }

    [Environment]::SetEnvironmentVariable('ANDROID_KEYSTORE_PATH', $keystore)
    [Environment]::SetEnvironmentVariable('ANDROID_KEYSTORE_PASSWORD', 'fixture-store-secret')
    [Environment]::SetEnvironmentVariable('ANDROID_KEY_ALIAS', 'fixture-upload')
    [Environment]::SetEnvironmentVariable('ANDROID_KEY_PASSWORD', 'fixture-key-secret')

    $ready = & $preflightScript -ProjectRoot $tempRoot -AndroidAdMobAppId 'ca-app-pub-0000000000000000~0000000000' -Quiet
    if (-not $ready.Ready -or $ready.SigningSource -ne 'environment' -or -not $ready.KeystoreExists) {
        throw 'Environment-backed signing fixture did not pass preflight as expected.'
    }

    Assert-ThrowsLike -CaseName 'Google test application ID' -Pattern 'Google test configuration' -Action {
        & $preflightScript -ProjectRoot $tempRoot -AndroidAdMobAppId 'ca-app-pub-3940256099942544~3347511713' -Quiet
    }

    Assert-ThrowsLike -CaseName 'Google test ad unit' -Pattern 'Google test ad-unit ID' -Action {
        $adArguments = @{
            ProjectRoot = $tempRoot
            AndroidAdMobAppId = 'ca-app-pub-0000000000000000~0000000000'
            EnableAds = $true
            AndroidBannerId = 'ca-app-pub-3940256099942544/6300978111'
            AndroidRewardedId = 'ca-app-pub-0000000000000000/0000000001'
            AndroidInterstitialId = 'ca-app-pub-0000000000000000/0000000002'
            Quiet = $true
        }
        & $preflightScript @adArguments
    }

    Clear-SigningEnvironment
    $relativeKeystore = Join-Path $tempRoot 'android/app/fixture-relative.jks'
    Set-Content -LiteralPath $relativeKeystore -Value 'fixture-only-not-a-real-keystore'
    @(
        'storeFile=fixture-relative.jks',
        'storePassword=fixture-store-secret',
        'keyAlias=fixture-upload',
        'keyPassword=fixture-key-secret'
    ) | Set-Content -LiteralPath (Join-Path $tempRoot 'android/key.properties')

    $fileReady = & $preflightScript -ProjectRoot $tempRoot -AndroidAdMobAppId 'ca-app-pub-0000000000000000~0000000000' -Quiet
    if (-not $fileReady.Ready -or $fileReady.SigningSource -ne 'key.properties') {
        throw 'key.properties signing fixture did not pass preflight as expected.'
    }

    Write-Host 'Release input preflight contract: PASSED' -ForegroundColor Green
}
finally {
    Clear-SigningEnvironment
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
