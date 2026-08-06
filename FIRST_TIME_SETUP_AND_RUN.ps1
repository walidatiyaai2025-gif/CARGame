param(
    [string]$TargetPath = 'C:\Apps\CARGame'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$RepoUrl = 'https://github.com/walidatiyaai2025-gif/CARGame.git'

function Step([int]$Number, [string]$Text) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "STEP $Number - $Text" -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}

function Run {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [string]$Folder = ''
    )

    if ($Folder) { Push-Location $Folder }
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($Folder) { Pop-Location }
    }
}

function Get-AndroidSdk {
    foreach ($candidate in @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { $_ }) {
        if (Test-Path (Join-Path $candidate 'platform-tools\adb.exe')) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    throw 'Android SDK was not found.'
}

function Get-PropertyValue {
    param($Object, [string]$Name, $Default = $null)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Get-SupportedAndroidDeviceId {
    $json = (& flutter devices --machine 2>$null) -join "`n"
    if ([string]::IsNullOrWhiteSpace($json)) { return $null }

    try { $devices = @($json | ConvertFrom-Json) }
    catch { return $null }

    foreach ($device in $devices) {
        $platform = [string](Get-PropertyValue $device 'targetPlatform' '')
        $id = [string](Get-PropertyValue $device 'id' '')
        $isSupported = Get-PropertyValue $device 'isSupported' $true
        $unsupported = Get-PropertyValue $device 'unsupported' $false

        if ($platform -like 'android*' -and
            $isSupported -ne $false -and
            $unsupported -ne $true -and
            -not [string]::IsNullOrWhiteSpace($id)) {
            return $id
        }
    }
    return $null
}

function Select-Avd {
    param([string]$EmulatorExe)

    $avds = @(& $EmulatorExe -list-avds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($avds.Count -eq 0) {
        throw 'No Android emulator exists. Create one in Android Studio Device Manager.'
    }

    Write-Host ''
    Write-Host 'Available Android emulators:' -ForegroundColor Cyan
    for ($i = 0; $i -lt $avds.Count; $i++) {
        Write-Host "[$($i + 1)] $($avds[$i])"
    }

    $choice = Read-Host 'Choose emulator number'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or
        $index -lt 1 -or
        $index -gt $avds.Count) {
        throw 'Invalid emulator selection.'
    }

    return [string]$avds[$index - 1]
}

function Restart-AdbIfNeeded {
    param([string]$Adb)

    $states = @(& $Adb devices)
    if ($states -match '\boffline\b') {
        Write-Host 'ADB reports an offline device. Restarting ADB server...' -ForegroundColor Yellow
        & $Adb kill-server 2>$null | Out-Null
        Start-Sleep -Seconds 2
        & $Adb start-server | Out-Null
        Start-Sleep -Seconds 2
    }
}

function Start-SupportedEmulator {
    param([string]$SdkRoot)

    $adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
    $emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
    if (-not (Test-Path $emulator)) { throw "Emulator was not found: $emulator" }

    & $adb start-server | Out-Null
    Restart-AdbIfNeeded -Adb $adb

    $supported = Get-SupportedAndroidDeviceId
    if ($supported) {
        Write-Host "Supported Android device already available: $supported" -ForegroundColor Green
        return $supported
    }

    $selected = Select-Avd -EmulatorExe $emulator
    Write-Host "Starting selected emulator: $selected" -ForegroundColor Yellow
    Start-Process -FilePath $emulator -ArgumentList @(
        '-avd', $selected,
        '-no-boot-anim',
        '-no-snapshot-load',
        '-no-snapshot-save'
    ) | Out-Null

    $deadline = (Get-Date).AddMinutes(10)
    do {
        Start-Sleep -Seconds 4
        Restart-AdbIfNeeded -Adb $adb
        $supported = Get-SupportedAndroidDeviceId
        if ((Get-Date) -gt $deadline) {
            throw 'The selected emulator started, but Flutter did not report a supported Android device.'
        }
    } until ($supported)

    & $adb -s $supported wait-for-device | Out-Null
    do {
        Start-Sleep -Seconds 3
        $state = (& $adb -s $supported get-state 2>$null | Out-String).Trim()
        if ($state -eq 'offline') {
            Restart-AdbIfNeeded -Adb $adb
            continue
        }
        $boot = (& $adb -s $supported shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ((Get-Date) -gt $deadline) { throw 'Timed out waiting for Android boot.' }
    } until ($boot -eq '1')

    Start-Sleep -Seconds 8
    return $supported
}

try {
    Clear-Host
    Write-Host 'CAR GAME - FIRST TIME SETUP AND RUN' -ForegroundColor Green
    Write-Host 'No device or emulator name is hardcoded in this script.' -ForegroundColor Yellow

    Step 1 'Choose project folder'
    $entered = Read-Host "Project path [$TargetPath]"
    if ($entered) { $TargetPath = $entered }
    $TargetPath = [IO.Path]::GetFullPath($TargetPath)

    Step 2 'Check prerequisites'
    foreach ($command in @('git', 'flutter')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "$command was not found in PATH."
        }
    }
    Run 'git' @('--version')
    Run 'flutter' @('--version')

    Step 3 'Locate Android SDK'
    $sdk = Get-AndroidSdk
    Write-Host "Android SDK: $sdk" -ForegroundColor Green

    Step 4 'Download or update project'
    $parent = Split-Path $TargetPath -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    $targetExists = Test-Path $TargetPath
    $targetHasFiles = $false
    if ($targetExists) {
        $existingItems = @(Get-ChildItem -LiteralPath $TargetPath -Force -ErrorAction SilentlyContinue)
        $targetHasFiles = $existingItems.Count -gt 0
    }

    if (Test-Path (Join-Path $TargetPath '.git')) {
        Run 'git' @('fetch', 'origin') $TargetPath
        Run 'git' @('reset', '--hard', 'origin/main') $TargetPath
    }
    elseif ($targetExists -and $targetHasFiles) {
        $TargetPath = "${TargetPath}_Fresh_$(Get-Date -Format yyyyMMdd_HHmmss)"
        Run 'git' @('clone', $RepoUrl, $TargetPath)
    }
    else {
        Run 'git' @('clone', $RepoUrl, $TargetPath)
    }

    Set-Location $TargetPath
    & git config core.longpaths true

    Step 5 'Configure Flutter Android SDK'
    Run 'flutter' @('config', '--android-sdk', $sdk)
    Run 'flutter' @('doctor', '-v')

    Step 6 'Restore packages and repair build caches'
    if (Test-Path (Join-Path $TargetPath 'BUILD_COMMON.ps1')) {
        . (Join-Path $TargetPath 'BUILD_COMMON.ps1')
        Repair-KotlinBuildCache $TargetPath -Deep
    }
    else {
        Run 'flutter' @('clean') $TargetPath
    }
    Run 'flutter' @('pub', 'get') $TargetPath
    try { Run 'flutter' @('gen-l10n') $TargetPath }
    catch { Write-Warning 'flutter gen-l10n was skipped.' }

    Step 7 'Analyze project'
    Run 'flutter' @('analyze', '--no-fatal-infos', '--no-fatal-warnings') $TargetPath

    Step 8 'Select and start an Android emulator'
    $device = Start-SupportedEmulator -SdkRoot $sdk
    Write-Host "Flutter device ready: $device" -ForegroundColor Green

    Step 9 'Run Cargo Sort'
    Run 'flutter' @('run', '--no-pub', '-d', $device) $TargetPath
}
catch {
    Write-Host ''
    Write-Host 'FIRST TIME SETUP FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close')
}
