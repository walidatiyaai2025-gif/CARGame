[CmdletBinding()]
param(
    [string]$ProjectRoot = $PSScriptRoot,
    [Parameter(Mandatory)][string]$AndroidAdMobAppId,
    [switch]$EnableAds,
    [string]$AndroidBannerId = '',
    [string]$AndroidRewardedId = '',
    [string]$AndroidInterstitialId = '',
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Read-KeyProperties {
    param([Parameter(Mandatory)][string]$Path)

    $values = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $values
    }

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }

        $separator = $line.IndexOf('=')
        if ($separator -le 0) {
            continue
        }

        $name = $line.Substring(0, $separator).Trim()
        $value = $line.Substring($separator + 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            $values[$name] = $value
        }
    }
    return $values
}

function Get-ConfiguredValue {
    param(
        [Parameter(Mandatory)][hashtable]$Properties,
        [Parameter(Mandatory)][string]$PropertyName,
        [Parameter(Mandatory)][string]$EnvironmentName
    )

    $environmentValue = [Environment]::GetEnvironmentVariable($EnvironmentName)
    if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
        return [pscustomobject]@{
            Value = $environmentValue.Trim()
            Source = 'environment'
        }
    }

    $propertyValue = $Properties[$PropertyName]
    if (-not [string]::IsNullOrWhiteSpace($propertyValue)) {
        return [pscustomobject]@{
            Value = $propertyValue.Trim()
            Source = 'key.properties'
        }
    }

    return [pscustomobject]@{
        Value = ''
        Source = 'missing'
    }
}

function Assert-ProductionAdMobApplicationId {
    param([Parameter(Mandatory)][string]$Value)

    $trimmed = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        throw 'AndroidAdMobAppId is required for every RC build.'
    }
    if ($trimmed -notmatch '^ca-app-pub-[0-9]{16}~[0-9]{10}$') {
        throw 'AndroidAdMobAppId is not a valid Android AdMob application ID format.'
    }
    if ($trimmed.StartsWith('ca-app-pub-3940256099942544~')) {
        throw 'AndroidAdMobAppId uses Google test configuration, which is forbidden in an RC build.'
    }
}

function Assert-ProductionAdUnitId {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $trimmed = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        throw "$Name is required when ads are enabled."
    }
    if ($trimmed -notmatch '^ca-app-pub-[0-9]{16}/[0-9]{10}$') {
        throw "$Name is not a valid AdMob ad-unit ID format."
    }
    if ($trimmed.StartsWith('ca-app-pub-3940256099942544/')) {
        throw "$Name uses a Google test ad-unit ID, which is forbidden in an RC build."
    }
}

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$androidRoot = Join-Path $resolvedProjectRoot 'android'
$appRoot = Join-Path $androidRoot 'app'
$keyPropertiesPath = Join-Path $androidRoot 'key.properties'

if (-not (Test-Path -LiteralPath (Join-Path $resolvedProjectRoot 'pubspec.yaml') -PathType Leaf)) {
    throw "ProjectRoot does not contain pubspec.yaml: $resolvedProjectRoot"
}

Assert-ProductionAdMobApplicationId $AndroidAdMobAppId
if ($EnableAds) {
    Assert-ProductionAdUnitId 'AndroidBannerId' $AndroidBannerId
    Assert-ProductionAdUnitId 'AndroidRewardedId' $AndroidRewardedId
    Assert-ProductionAdUnitId 'AndroidInterstitialId' $AndroidInterstitialId
}

$properties = Read-KeyProperties $keyPropertiesPath
$signingFields = @(
    [pscustomobject]@{ Property = 'storeFile'; Environment = 'ANDROID_KEYSTORE_PATH' },
    [pscustomobject]@{ Property = 'storePassword'; Environment = 'ANDROID_KEYSTORE_PASSWORD' },
    [pscustomobject]@{ Property = 'keyAlias'; Environment = 'ANDROID_KEY_ALIAS' },
    [pscustomobject]@{ Property = 'keyPassword'; Environment = 'ANDROID_KEY_PASSWORD' }
)

$configured = @{}
$missing = [System.Collections.Generic.List[string]]::new()
$sources = [System.Collections.Generic.HashSet[string]]::new()
foreach ($field in $signingFields) {
    $value = Get-ConfiguredValue -Properties $properties -PropertyName $field.Property -EnvironmentName $field.Environment
    $configured[$field.Property] = $value
    if ($value.Source -eq 'missing') {
        $missing.Add("$($field.Property)/$($field.Environment)")
    }
    else {
        [void]$sources.Add($value.Source)
    }
}

if ($missing.Count -gt 0) {
    throw "Android release signing is incomplete. Missing: $($missing -join ', '). Configure android/key.properties and/or the documented signing environment variables."
}

$storePath = $configured['storeFile'].Value
$resolvedStorePath = if ([System.IO.Path]::IsPathRooted($storePath)) {
    [System.IO.Path]::GetFullPath($storePath)
}
else {
    # Gradle's file(releaseStorePath) runs in the android/app project, so match it exactly.
    [System.IO.Path]::GetFullPath((Join-Path $appRoot $storePath))
}

if (-not (Test-Path -LiteralPath $resolvedStorePath -PathType Leaf)) {
    throw 'Android release keystore path is configured but the file does not exist.'
}

$signingSource = if ($sources.Count -eq 1) {
    @($sources)[0]
}
else {
    'mixed environment/key.properties'
}

$result = [pscustomobject]@{
    Ready = $true
    SigningSource = $signingSource
    KeystoreExists = $true
    AdsEnabled = $EnableAds.IsPresent
    AdMobApplicationConfigured = $true
    AdUnitsConfigured = if ($EnableAds) { $true } else { $null }
}

if (-not $Quiet) {
    Write-Host 'Android release input preflight: PASSED' -ForegroundColor Green
    Write-Host "Signing source: $signingSource" -ForegroundColor Green
    Write-Host 'Keystore: configured and present' -ForegroundColor Green
    Write-Host 'AdMob application ID: configured (value redacted)' -ForegroundColor Green
    Write-Host "Runtime ads enabled: $($EnableAds.IsPresent)" -ForegroundColor Green
    if ($EnableAds) {
        Write-Host 'Production ad-unit IDs: configured (values redacted)' -ForegroundColor Green
    }
}

$result
