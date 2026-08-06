param(
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
    [pscustomobject]@{ Sdk = $sdk; Adb = $adb; Emulator = $emulator }
}

function Get-PropertyValue {
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Name, $Default = $null)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Get-FlutterAndroidDevices {
    $json = & flutter devices --machine 2>$null | Out-String
    if ([string]::IsNullOrWhiteSpace($json)) { return @() }
    try { $devices = @($json | ConvertFrom-Json) } catch { throw 'Could not parse Flutter device list.' }

    $supportedAndroid = foreach ($device in $devices) {
        $targetPlatform = [string](Get-PropertyValue $device 'targetPlatform' '')
        $id = [string](Get-PropertyValue $device 'id' '')
        $name = [string](Get-PropertyValue $device 'name' $id)
        $isSupportedValue = Get-PropertyValue $device 'isSupported' $true
        $unsupportedValue = Get-PropertyValue $device 'unsupported' $false
        $isSupported = ($isSupportedValue -ne $false) -and ($unsupportedValue -ne $true)
        $isAndroid = $targetPlatform -like 'android*'

        if ($isAndroid -and $isSupported -and -not [string]::IsNullOrWhiteSpace($id)) {
            $emulatorFlag = Get-PropertyValue $device 'isEmulator' $null
            $isEmulator = if ($null -ne $emulatorFlag) { [bool]$emulatorFlag } else { $id -like 'emulator-*' -or $name -match '(?i)emulator|sdk gphone|android sdk built for' }
            [pscustomobject]@{ id = $id; name = $name; targetPlatform = $targetPlatform; isEmulator = $isEmulator }
        }
    }
    return @($supportedAndroid)
}

function Get-SupportedAndroidDeviceId {
    $devices = @(Get-FlutterAndroidDevices)
    if ($devices.Count -eq 0) { return $null }
    if ($devices.Count -eq 1) { return [string]$devices[0].id }

    Write-Host ''; Write-Host 'Supported Android devices:' -ForegroundColor Cyan
    for ($i = 0; $i -lt $devices.Count; $i++) {
        $kind = if ($devices[$i].isEmulator) { 'Emulator' } else { 'Physical device' }
        Write-Host "[$($i + 1)] $($devices[$i].name) - $($devices[$i].id) - $($devices[$i].targetPlatform) - $kind"
    }
    $choice = Read-Host 'Choose device number'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $devices.Count) { throw 'Invalid device selection.' }
    return [string]$devices[$index - 1].id
}

function Get-AdbDeviceState([string]$Adb, [string]$DeviceId) {
    $state = (& $Adb -s $DeviceId get-state 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { return 'missing' }
    return $state
}

function Wait-ForAdbOnline([string]$Adb, [string]$DeviceId, [int]$TimeoutSeconds = 90) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $state = Get-AdbDeviceState $Adb $DeviceId
        if ($state -eq 'device') {
            $boot = (& $Adb -s $DeviceId shell getprop sys.boot_completed 2>$null | Out-String).Trim()
            if ($boot -eq '1') { return $true }
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}

function Restart-AdbServer([string]$Adb) {
    & $Adb reconnect offline 2>$null | Out-Null
    Start-Sleep -Seconds 2
    & $Adb kill-server 2>$null | Out-Null
    Start-Sleep -Seconds 2
    & $Adb start-server | Out-Null
    Start-Sleep -Seconds 3
}

function Recover-AdbConnection([string]$Adb, [string]$DeviceId) {
    Write-Warning 'ADB connection went offline. Attempting recovery...'
    Restart-AdbServer $Adb
    return (Wait-ForAdbOnline $Adb $DeviceId 60)
}

function Test-AppRunning([string]$Adb, [string]$DeviceId) {
    $pidText = (& $Adb -s $DeviceId shell pidof $PackageId 2>$null | Out-String).Trim()
    return -not [string]::IsNullOrWhiteSpace($pidText)
}

function Run-DebugWithRecovery([string]$DeviceId) {
    $tools = Get-AndroidTools
    Repair-KotlinBuildCache $ProjectPath
    Invoke-NativeChecked 'flutter' @('pub', 'get') $ProjectPath

    Write-Host "> flutter run --no-pub -d $DeviceId" -ForegroundColor DarkGray
    & flutter run --no-pub -d $DeviceId
    $runExitCode = $LASTEXITCODE

    if ($runExitCode -eq 0) { return }

    $state = Get-AdbDeviceState $tools.Adb $DeviceId
    if ($state -eq 'offline' -or $state -eq 'missing') {
        if (Recover-AdbConnection $tools.Adb $DeviceId) {
            if (Test-AppRunning $tools.Adb $DeviceId) {
                Write-Host 'The Android device reconnected and Cargo Sort is still running.' -ForegroundColor Green
                return
            }

            Write-Host 'ADB recovered. Relaunching the application without rebuilding...' -ForegroundColor Yellow
            & $tools.Adb -s $DeviceId shell am start -n "$PackageId/.MainActivity"
            Start-Sleep -Seconds 5
            if (Test-AppRunning $tools.Adb $DeviceId) {
                Write-Host 'Cargo Sort relaunched successfully after ADB recovery.' -ForegroundColor Green
                return
            }
        }
    }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logPath = Join-Path $ProjectPath "android_runtime_$stamp.log"
    & $tools.Adb -s $DeviceId logcat -d -v time 2>$null | Set-Content $logPath -Encoding UTF8
    throw "Flutter debug session ended with exit code $runExitCode. Runtime log: $logPath"
}

function Select-Avd([string]$EmulatorExe) {
    $avds = @(& $EmulatorExe -list-avds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($avds.Count -eq 0) { throw 'No Android emulator exists. Create one in Android Studio Device Manager.' }

    Write-Host ''; Write-Host 'Available AVDs:' -ForegroundColor Cyan
    for ($i = 0; $i -lt $avds.Count; $i++) { Write-Host "[$($i + 1)] $($avds[$i])" }
    $choice = Read-Host 'Choose an AVD number to start'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $avds.Count) { throw 'Invalid AVD selection.' }
    return [string]$avds[$index - 1]
}

function Start-Device([switch]$ColdBoot) {
    $tools = Get-AndroidTools
    & $tools.Adb start-server | Out-Null

    $supported = Get-SupportedAndroidDeviceId
    if ($supported) {
        if (-not (Wait-ForAdbOnline $tools.Adb $supported 60)) {
            [void](Recover-AdbConnection $tools.Adb $supported)
        }
        return $supported
    }

    if (-not (Test-Path $tools.Emulator)) { throw 'Android Emulator was not found.' }
    $selected = Select-Avd $tools.Emulator

    $args = @('-avd', $selected, '-no-boot-anim', '-no-snapshot-save')
    if ($ColdBoot) { $args += @('-no-snapshot-load', '-wipe-data') }
    Write-Host "Starting selected emulator: $selected" -ForegroundColor Yellow
    Start-Process $tools.Emulator -ArgumentList $args | Out-Null

    $deadline = (Get-Date).AddMinutes(8)
    do {
        Start-Sleep -Seconds 3
        $supported = Get-SupportedAndroidDeviceId
        if (-not $supported) {
            $adbStates = @(& $tools.Adb devices)
            if ($adbStates -match '\boffline\b') { Restart-AdbServer $tools.Adb }
        }
        if ((Get-Date) -gt $deadline) { throw 'Timed out waiting for a Flutter-supported Android device.' }
    } until ($supported)

    if (-not (Wait-ForAdbOnline $tools.Adb $supported 120)) { throw 'The selected emulator did not become stable in ADB.' }
    return $supported
}

function Install-And-Run([string]$Apk) {
    if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }
    $tools = Get-AndroidTools
    $device = Start-Device
    Invoke-NativeChecked $tools.Adb @('-s', $device, 'install', '-r', $Apk) $ProjectPath
    Invoke-NativeChecked $tools.Adb @('-s', $device, 'shell', 'am', 'start', '-n', "$PackageId/.MainActivity") $ProjectPath
}

function Show-Menu {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '       CARGO SORT DEVELOPMENT TOOL' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "Project: $ProjectPath"
    Write-Host 'No device or emulator name is hardcoded.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host ' 1  - Run Debug with ADB recovery'
    Write-Host ' 2  - Build Debug APK'
    Write-Host ' 3  - Build Release APK'
    Write-Host ' 4  - Build Release App Bundle (AAB)'
    Write-Host ' 5  - Build + Install Debug APK'
    Write-Host ' 6  - Build + Install Release APK'
    Write-Host ' 7  - Repair Kotlin/Gradle caches only'
    Write-Host ' 8  - Flutter analyze'
    Write-Host ' 9  - Select and start emulator only'
    Write-Host '10  - Select and cold boot emulator'
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
            '1' { $device = Start-Device; Run-DebugWithRecovery $device }
            '2' { Invoke-FlutterBuildWithRetry $ProjectPath 'debug' }
            '3' { Invoke-FlutterBuildWithRetry $ProjectPath 'release' }
            '4' { Invoke-FlutterBuildWithRetry $ProjectPath 'aab' }
            '5' { Invoke-FlutterBuildWithRetry $ProjectPath 'debug'; Install-And-Run (Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-debug.apk') }
            '6' { Invoke-FlutterBuildWithRetry $ProjectPath 'release'; Install-And-Run (Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-release.apk') }
            '7' { Repair-KotlinBuildCache $ProjectPath -Deep; Write-Host 'Cache repair completed.' -ForegroundColor Green }
            '8' { Invoke-NativeChecked 'flutter' @('analyze', '--no-fatal-infos', '--no-fatal-warnings') $ProjectPath }
            '9' { [void](Start-Device); Write-Host 'Android device is ready.' -ForegroundColor Green }
            '10' { [void](Start-Device -ColdBoot); Write-Host 'Cold-boot Android device is ready.' -ForegroundColor Green }
            '11' { Invoke-NativeChecked 'git' @('fetch', 'origin') $ProjectPath; Invoke-NativeChecked 'git' @('reset', '--hard', 'origin/main') $ProjectPath; Write-Host 'Project updated.' -ForegroundColor Green }
            '12' { Invoke-NativeChecked 'git' @('fetch', 'origin') $ProjectPath; Invoke-NativeChecked 'git' @('reset', '--hard', 'origin/main') $ProjectPath; $device = Start-Device; Repair-KotlinBuildCache $ProjectPath -Deep; Run-DebugWithRecovery $device }
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
