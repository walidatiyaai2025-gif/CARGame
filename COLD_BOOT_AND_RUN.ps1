param(
    [string]$AvdName = '',
    [string]$ProjectPath = $PSScriptRoot,
    [string]$PackageId = 'com.walka.cargosort'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$ProjectPath = [IO.Path]::GetFullPath($ProjectPath)
Set-Location $ProjectPath
. (Join-Path $ProjectPath 'BUILD_COMMON.ps1')

function Pause-Tool { Write-Host ''; [void](Read-Host 'Press Enter to continue') }

function Get-AndroidTools {
    $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    $emulator = Join-Path $sdk 'emulator\emulator.exe'
    if (-not (Test-Path $adb)) { throw "adb.exe was not found: $adb" }
    [pscustomobject]@{ Sdk=$sdk; Adb=$adb; Emulator=$emulator }
}

function Get-OnlineDevice([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') { return $Matches[1] }
    }
    return $null
}

function Start-Device([switch]$ColdBoot) {
    $tools = Get-AndroidTools
    & $tools.Adb start-server | Out-Null
    $device = Get-OnlineDevice $tools.Adb
    if ($device) { return $device }
    if (-not (Test-Path $tools.Emulator)) { throw 'Android Emulator was not found.' }
    $avds = @(& $tools.Emulator -list-avds | Where-Object { $_.Trim() })
    if ($avds.Count -eq 0) { throw 'No Android emulator exists.' }
    $selected = if ($AvdName) { $AvdName } else { $avds[0] }
    $args = @('-avd',$selected,'-no-boot-anim')
    if ($ColdBoot) { $args += @('-no-snapshot-load','-no-snapshot-save','-wipe-data') }
    Start-Process $tools.Emulator -ArgumentList $args | Out-Null
    $deadline = (Get-Date).AddMinutes(8)
    do {
        Start-Sleep -Seconds 3
        $device = Get-OnlineDevice $tools.Adb
        if ((Get-Date) -gt $deadline) { throw 'Timed out waiting for emulator.' }
    } until ($device)
    do {
        Start-Sleep -Seconds 3
        $boot = (& $tools.Adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $deadline) { throw 'Timed out waiting for Android boot.' }
    } until ($boot -eq '1')
    return $device
}

function Install-And-Run([string]$Apk) {
    if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }
    $tools = Get-AndroidTools
    $device = Start-Device
    Invoke-NativeChecked $tools.Adb @('-s',$device,'install','-r',$Apk) $ProjectPath
    Invoke-NativeChecked $tools.Adb @('-s',$device,'shell','am','start','-n',"$PackageId/.MainActivity") $ProjectPath
}

function Show-Menu {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '       CARGO SORT DEVELOPMENT TOOL' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "Project: $ProjectPath"
    Write-Host ''
    Write-Host ' 1  - Run Debug on device/emulator'
    Write-Host ' 2  - Build Debug APK'
    Write-Host ' 3  - Build Release APK'
    Write-Host ' 4  - Build Release App Bundle (AAB)'
    Write-Host ' 5  - Build + Install Debug APK'
    Write-Host ' 6  - Build + Install Release APK'
    Write-Host ' 7  - Repair Kotlin/Gradle caches only'
    Write-Host ' 8  - Flutter analyze'
    Write-Host ' 9  - Start emulator only'
    Write-Host '10  - Cold boot emulator'
    Write-Host '11  - Update project from GitHub'
    Write-Host '12  - Update + repair + run Debug'
    Write-Host ' 0  - Exit'
    Write-Host ''
}

if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) { throw "Invalid Flutter project: $ProjectPath" }
if (-not (Test-Path (Join-Path $ProjectPath 'BUILD_COMMON.ps1'))) { throw 'BUILD_COMMON.ps1 was not found.' }

while ($true) {
    Show-Menu
    $choice = Read-Host 'Choose an option'
    try {
        switch ($choice) {
            '1' {
                $device = Start-Device
                Repair-KotlinBuildCache $ProjectPath
                Invoke-NativeChecked 'flutter' @('pub','get') $ProjectPath
                Invoke-NativeChecked 'flutter' @('run','--no-pub','-d',$device) $ProjectPath
            }
            '2' { Invoke-FlutterBuildWithRetry $ProjectPath 'debug' }
            '3' { Invoke-FlutterBuildWithRetry $ProjectPath 'release' }
            '4' { Invoke-FlutterBuildWithRetry $ProjectPath 'aab' }
            '5' {
                Invoke-FlutterBuildWithRetry $ProjectPath 'debug'
                Install-And-Run (Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-debug.apk')
            }
            '6' {
                Invoke-FlutterBuildWithRetry $ProjectPath 'release'
                Install-And-Run (Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-release.apk')
            }
            '7' { Repair-KotlinBuildCache $ProjectPath -Deep; Write-Host 'Cache repair completed.' -ForegroundColor Green }
            '8' { Invoke-NativeChecked 'flutter' @('analyze','--no-fatal-infos','--no-fatal-warnings') $ProjectPath }
            '9' { [void](Start-Device); Write-Host 'Device is ready.' -ForegroundColor Green }
            '10' { [void](Start-Device -ColdBoot); Write-Host 'Cold-boot emulator is ready.' -ForegroundColor Green }
            '11' {
                Invoke-NativeChecked 'git' @('fetch','origin') $ProjectPath
                Invoke-NativeChecked 'git' @('reset','--hard','origin/main') $ProjectPath
                Write-Host 'Project updated.' -ForegroundColor Green
            }
            '12' {
                Invoke-NativeChecked 'git' @('fetch','origin') $ProjectPath
                Invoke-NativeChecked 'git' @('reset','--hard','origin/main') $ProjectPath
                $device = Start-Device
                Repair-KotlinBuildCache $ProjectPath -Deep
                Invoke-NativeChecked 'flutter' @('pub','get') $ProjectPath
                Invoke-NativeChecked 'flutter' @('run','--no-pub','-d',$device) $ProjectPath
            }
            '0' { break }
            default { Write-Warning 'Invalid choice.' }
        }
    } catch {
        Write-Host "`nOPERATION FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }
    if ($choice -eq '0') { break }
    Pause-Tool
}
