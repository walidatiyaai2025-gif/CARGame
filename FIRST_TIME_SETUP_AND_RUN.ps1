param(
    [string]$TargetPath = "C:\Apps\CARGame",
    [string]$AvdName = ""
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$RepoUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git"
$MinimumDartVersion = [version]"3.10.0"

function Step([int]$Number, [string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "STEP $Number - $Text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Run([string]$Command, [string[]]$Arguments, [string]$Folder = "") {
    if ($Folder) { Push-Location $Folder }
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($Folder) { Pop-Location }
    }
}

function Get-FlutterInfo {
    $jsonText = (& flutter --version --machine 2>$null) -join "`n"
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -or [string]::IsNullOrWhiteSpace($jsonText)) {
        throw "Could not read Flutter version information."
    }
    try { return $jsonText | ConvertFrom-Json }
    catch { throw "Flutter returned invalid version information: $($_.Exception.Message)" }
}

function Ensure-CompatibleFlutter {
    $info = Get-FlutterInfo
    $dartVersionText = ([string]$info.dartSdkVersion).Split(' ')[0].Split('-')[0]
    $flutterVersionText = ([string]$info.frameworkVersion).Split('-')[0]
    try { $dartVersion = [version]$dartVersionText }
    catch { throw "Could not parse Dart SDK version: $dartVersionText" }

    Write-Host "Flutter: $flutterVersionText" -ForegroundColor Cyan
    Write-Host "Dart:    $dartVersion" -ForegroundColor Cyan
    Write-Host "Required Dart: $MinimumDartVersion or newer" -ForegroundColor Cyan

    if ($dartVersion -ge $MinimumDartVersion) {
        Write-Host "Flutter/Dart version is compatible." -ForegroundColor Green
        return
    }

    Write-Host "Installed Dart is too old. Upgrading Flutter stable..." -ForegroundColor Yellow
    Run "flutter" @("channel", "stable")
    Run "flutter" @("upgrade")
    Run "flutter" @("doctor", "-v")

    $updatedInfo = Get-FlutterInfo
    $updatedDartText = ([string]$updatedInfo.dartSdkVersion).Split(' ')[0].Split('-')[0]
    $updatedDart = [version]$updatedDartText
    Write-Host "Updated Flutter: $($updatedInfo.frameworkVersion)" -ForegroundColor Green
    Write-Host "Updated Dart:    $updatedDart" -ForegroundColor Green

    if ($updatedDart -lt $MinimumDartVersion) {
        throw "Flutter upgrade completed, but Dart $updatedDart is still below required $MinimumDartVersion. Install Flutter 3.44.8 or newer, then run this script again."
    }
}

function AndroidSdkRoot {
    $items = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, (Join-Path $env:LOCALAPPDATA "Android\Sdk")) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($item in $items) {
        if (Test-Path (Join-Path $item "platform-tools\adb.exe")) {
            return [System.IO.Path]::GetFullPath($item)
        }
    }
    throw "Android SDK not found. Open Android Studio > SDK Manager and install Android SDK Platform, Platform-Tools and Emulator."
}

function OnlineDevice([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') { return $Matches[1] }
    }
    return $null
}

function StartEmulator([string]$SdkRoot, [string]$RequestedAvd) {
    $adb = Join-Path $SdkRoot "platform-tools\adb.exe"
    $emulator = Join-Path $SdkRoot "emulator\emulator.exe"
    & $adb start-server | Out-Null
    $device = OnlineDevice $adb
    if ($device) { return $device }

    if (-not (Test-Path $emulator)) { throw "Android Emulator not found: $emulator" }
    $avds = @(& $emulator -list-avds | Where-Object { $_.Trim() })
    if ($avds.Count -eq 0) { throw "No AVD found. Create one from Android Studio > Device Manager." }

    $selected = if ($RequestedAvd) { $RequestedAvd } else { $avds[0] }
    if ($avds -notcontains $selected) { throw "AVD not found: $selected. Available: $($avds -join ', ')" }

    Write-Host "Starting emulator: $selected" -ForegroundColor Yellow
    Start-Process -FilePath $emulator -ArgumentList @("-avd", $selected, "-no-snapshot-save") | Out-Null

    $limit = (Get-Date).AddMinutes(7)
    do {
        Start-Sleep -Seconds 3
        $device = OnlineDevice $adb
        if ((Get-Date) -gt $limit) { throw "Timed out waiting for emulator." }
    } until ($device)

    Run $adb @("-s", $device, "wait-for-device")
    do {
        Start-Sleep -Seconds 3
        $boot = (& $adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $limit) { throw "Timed out waiting for Android boot." }
    } until ($boot -eq "1")
    return $device
}

function Apply-SourceCompatibilityFixes([string]$ProjectPath) {
    $gameFile = Join-Path $ProjectPath "lib\features\game\game_screen.dart"
    if (Test-Path $gameFile) {
        $content = Get-Content $gameFile -Raw
        $updated = $content.Replace(
            "Icons.favorite_broken_rounded",
            "Icons.heart_broken_rounded"
        )
        if ($updated -ne $content) {
            [System.IO.File]::WriteAllText(
                $gameFile,
                $updated,
                [System.Text.UTF8Encoding]::new($false)
            )
            Write-Host "Replaced unsupported favorite_broken icon." -ForegroundColor Green
        }
    }
}

try {
    Clear-Host
    Write-Host "CAR GAME - FIRST TIME SETUP AND RUN" -ForegroundColor Green
    Write-Host "The window stays open after success or failure." -ForegroundColor Yellow

    Step 1 "Choose project folder"
    $entered = Read-Host "Project path [$TargetPath]"
    if ($entered) { $TargetPath = $entered }
    $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

    Step 2 "Check Git, Flutter and Dart compatibility"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is not available in PATH." }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter is not available in PATH." }
    Run "git" @("--version")
    Ensure-CompatibleFlutter

    Step 3 "Locate Android SDK"
    $sdk = AndroidSdkRoot
    Write-Host "Android SDK: $sdk" -ForegroundColor Green

    Step 4 "Download or update project"
    $parent = Split-Path $TargetPath -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    if (Test-Path (Join-Path $TargetPath ".git")) {
        Run "git" @("fetch", "origin") $TargetPath
        Run "git" @("reset", "--hard", "origin/main") $TargetPath
    }
    elseif (Test-Path $TargetPath) {
        $hasFiles = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count -gt 0
        if ($hasFiles) {
            $TargetPath = "$TargetPath`_Fresh_$(Get-Date -Format yyyyMMdd_HHmmss)"
            Write-Host "Selected folder was not empty. Using: $TargetPath" -ForegroundColor Yellow
        }
        Run "git" @("clone", $RepoUrl, $TargetPath)
    }
    else {
        Run "git" @("clone", $RepoUrl, $TargetPath)
    }

    Set-Location $TargetPath
    git config core.longpaths true

    Step 5 "Configure Flutter and accept Android licenses"
    Run "flutter" @("config", "--android-sdk", $sdk)
    Write-Host "Answer y to any Android license questions." -ForegroundColor Yellow
    & flutter doctor --android-licenses
    Run "flutter" @("doctor", "-v")

    Step 6 "Restore project packages"
    Ensure-CompatibleFlutter
    $env:GRADLE_USER_HOME = Join-Path $TargetPath ".gradle-user-home-first-run"
    New-Item -ItemType Directory -Path $env:GRADLE_USER_HOME -Force | Out-Null
    Apply-SourceCompatibilityFixes $TargetPath
    Run "flutter" @("clean")
    Run "flutter" @("pub", "get")
    try { Run "flutter" @("gen-l10n") } catch { Write-Warning "gen-l10n was skipped." }

    Step 7 "Analyze project before starting emulator"
    Run "flutter" @("analyze", "--no-fatal-infos")

    Step 8 "Start Android emulator"
    $device = StartEmulator $sdk $AvdName
    Write-Host "Device ready: $device" -ForegroundColor Green

    Step 9 "Run Cargo Sort"
    Run "flutter" @("run", "--no-pub", "-d", $device)
}
catch {
    Write-Host ""
    Write-Host "FIRST TIME SETUP FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close")
}
