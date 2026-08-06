param(
    [string]$TargetPath = "C:\Apps\CARGame",
    [string]$AvdName = ""
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$RepoUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git"

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
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($Folder) { Pop-Location }
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

try {
    Clear-Host
    Write-Host "CAR GAME - FIRST TIME SETUP AND RUN" -ForegroundColor Green
    Write-Host "The window stays open after success or failure." -ForegroundColor Yellow

    Step 1 "Choose project folder"
    $entered = Read-Host "Project path [$TargetPath]"
    if ($entered) { $TargetPath = $entered }
    $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

    Step 2 "Check Git and Flutter"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is not available in PATH." }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter is not available in PATH." }
    Run "git" @("--version")
    Run "flutter" @("--version")

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
    $env:GRADLE_USER_HOME = Join-Path $TargetPath ".gradle-user-home-first-run"
    New-Item -ItemType Directory -Path $env:GRADLE_USER_HOME -Force | Out-Null
    Run "flutter" @("clean")
    Run "flutter" @("pub", "get")
    try { Run "flutter" @("gen-l10n") } catch { Write-Warning "gen-l10n was skipped." }

    Step 7 "Start Android emulator"
    $device = StartEmulator $sdk $AvdName
    Write-Host "Device ready: $device" -ForegroundColor Green

    Step 8 "Run Cargo Sort"
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
