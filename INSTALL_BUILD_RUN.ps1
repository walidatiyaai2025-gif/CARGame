param(
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )

    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Command @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
    }
}

function Assert-Command([string]$Name, [string]$Message) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
}

function Get-SafeProjectPath {
    while ($true) {
        Write-Host ""
        Write-Host "Enter the FULL folder where the fresh project should be installed." -ForegroundColor Yellow
        Write-Host "Example: D:\Android\CARGame_Fresh" -ForegroundColor DarkGray
        $value = Read-Host "Project path"
        $value = [Environment]::ExpandEnvironmentVariables($value.Trim().Trim('"'))

        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Warning "Path cannot be empty."
            continue
        }

        try {
            $full = [System.IO.Path]::GetFullPath($value)
        }
        catch {
            Write-Warning "Invalid path: $value"
            continue
        }

        $root = [System.IO.Path]::GetPathRoot($full)
        if ($full.TrimEnd('\') -eq $root.TrimEnd('\')) {
            Write-Warning "Do not use a drive root such as D:\. Choose a subfolder."
            continue
        }

        return $full.TrimEnd('\')
    }
}

$scriptSucceeded = $false
$transcriptStarted = $false
$projectPath = $null
$logPath = $null
$apkPath = $null
$crashLog = $null

try {
    Clear-Host
    Write-Host "CAR GAME - FRESH DOWNLOAD, BUILD, EMULATOR RUN" -ForegroundColor Green
    Write-Host "This window always remains open so you can read any error." -ForegroundColor Yellow

    Assert-Command "git" "Git was not found in PATH. Install Git for Windows first."
    Assert-Command "flutter" "Flutter was not found in PATH. Add C:\flutter\bin to PATH."

    $projectPath = Get-SafeProjectPath
    $parentPath = Split-Path $projectPath -Parent

    if (-not (Test-Path $parentPath)) {
        Write-Step "Creating parent folder"
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    if (Test-Path $projectPath) {
        Write-Host ""
        Write-Warning "The following folder already exists:"
        Write-Host $projectPath -ForegroundColor Yellow
        Write-Warning "All contents must be deleted to install a truly fresh copy."
        $answer = Read-Host "Type DELETE to permanently remove it, or press Enter to cancel"
        if ($answer -cne "DELETE") {
            throw "Operation cancelled. Existing folder was not changed."
        }

        Write-Step "Removing existing local project"
        Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        attrib -R -S -H "$projectPath\*" /S /D 2>$null
        Remove-Item $projectPath -Recurse -Force
    }

    Write-Step "Cloning a completely fresh copy from GitHub"
    Invoke-Native -Command "git" -Arguments @(
        "clone", "--branch", $Branch, "--single-branch", $RepositoryUrl, $projectPath
    )

    Set-Location $projectPath
    $logPath = Join-Path $projectPath ("install_build_run_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcriptStarted = $true

    Write-Step "Confirming exact repository state"
    Invoke-Native -Command "git" -Arguments @("fetch", "origin")
    Invoke-Native -Command "git" -Arguments @("reset", "--hard", "origin/$Branch")
    Invoke-Native -Command "git" -Arguments @("clean", "-xfd")

    Write-Step "Checking Flutter and Android environment"
    Invoke-Native -Command "flutter" -Arguments @("doctor", "-v")

    Write-Step "Building a fresh Android release APK"
    $rebuildScript = Join-Path $projectPath "REBUILD_FRESH_ANDROID.ps1"
    if (-not (Test-Path $rebuildScript)) {
        throw "REBUILD_FRESH_ANDROID.ps1 was not found after cloning."
    }

    & $rebuildScript -SkipGitSync

    $apkPath = Join-Path $projectPath "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkPath)) {
        throw "APK was not found after the build: $apkPath"
    }

    Write-Step "Starting emulator, installing APK and verifying application startup"
    $runScript = Join-Path $projectPath "RUN_ON_EMULATOR.ps1"
    if (-not (Test-Path $runScript)) {
        throw "RUN_ON_EMULATOR.ps1 was not found after cloning."
    }

    & $runScript -ApkPath $apkPath

    $latestCrash = Get-ChildItem $projectPath -Filter "emulator_crash_filtered_*.log" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestCrash -and $latestCrash.LastWriteTime -gt (Get-Date).AddMinutes(-5)) {
        $crashLog = $latestCrash.FullName
        throw "The application closed after launch. Automatic crash log: $crashLog"
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "DOWNLOAD, BUILD AND RUN COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Project: $projectPath" -ForegroundColor Green
    Write-Host "APK:     $apkPath" -ForegroundColor Green
    Write-Host "Log:     $logPath" -ForegroundColor Green
    $scriptSucceeded = $true
}
catch {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "PROCESS FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    if ($_.ScriptStackTrace) {
        Write-Host ""
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }

    if ($projectPath -and -not $crashLog) {
        $latestCrash = Get-ChildItem $projectPath -Filter "emulator_crash_filtered_*.log" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($latestCrash) {
            $crashLog = $latestCrash.FullName
        }
    }

    if ($logPath) {
        Write-Host ""
        Write-Host "Complete operation log:" -ForegroundColor Yellow
        Write-Host $logPath -ForegroundColor Yellow
    }

    if ($crashLog) {
        Write-Host ""
        Write-Host "Automatic emulator crash log:" -ForegroundColor Yellow
        Write-Host $crashLog -ForegroundColor Yellow
        Write-Host "Upload this filtered log for diagnosis." -ForegroundColor Yellow
    }
}
finally {
    if ($transcriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }

    Write-Host ""
    if ($scriptSucceeded) {
        Write-Host "The application should now be open on the Android Emulator." -ForegroundColor Green
    }
    else {
        Write-Host "Review the error and log paths above. This window will not close automatically." -ForegroundColor Yellow
    }

    if ($projectPath -and (Test-Path $projectPath)) {
        Write-Host "Project folder: $projectPath" -ForegroundColor Cyan
    }

    [void](Read-Host "Press Enter to close this window")
}
