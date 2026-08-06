param(
    [switch]$BuildAppBundle,
    [switch]$InstallAndRun,
    [string]$PackageId = 'com.walka.cargosort'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot
. (Join-Path $PSScriptRoot 'BUILD_COMMON.ps1')

function Get-AdbPath {
    $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    if (-not (Test-Path $adb)) { throw "adb.exe was not found: $adb" }
    return $adb
}

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' CARGO SORT - STABLE RELEASE BUILDER' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan

    if (-not (Test-Path '.\pubspec.yaml')) { throw "pubspec.yaml was not found in $PSScriptRoot" }
    if (-not (Test-Path '.\BUILD_COMMON.ps1')) { throw 'BUILD_COMMON.ps1 was not found.' }

    $mode = if ($BuildAppBundle) { 'aab' } else { 'release' }
    Invoke-FlutterBuildWithRetry -ProjectRoot $PSScriptRoot -Mode $mode

    $output = if ($BuildAppBundle) {
        Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
    } else {
        Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
    }
    if (-not (Test-Path $output)) { throw "Build succeeded but output was not found: $output" }

    Write-Host "`nBUILD SUCCESS: $output" -ForegroundColor Green

    if ($InstallAndRun -and -not $BuildAppBundle) {
        $adb = Get-AdbPath
        $devices = @(& $adb devices | Select-String '^\S+\s+device$')
        if ($devices.Count -eq 0) { throw 'No authorized Android device is connected.' }
        Invoke-NativeChecked $adb @('install','-r',$output) $PSScriptRoot
        Invoke-NativeChecked $adb @('shell','am','start','-n',"$PackageId/.MainActivity") $PSScriptRoot
    }

    Start-Process explorer.exe -ArgumentList "/select,`"$output`""
}
catch {
    Write-Host "`n============================================================" -ForegroundColor Red
    Write-Host 'RELEASE BUILD FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close this window')
}
