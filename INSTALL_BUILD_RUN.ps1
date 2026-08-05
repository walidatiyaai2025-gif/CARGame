param(
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main",
    [string]$DefaultProjectName = "CARGame"
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
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
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
        Write-Host "Enter the FULL project folder path." -ForegroundColor Yellow
        Write-Host "Example: D:\Android\CARGame" -ForegroundColor DarkGray
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
            Write-Warning "For safety, do not use a drive root such as D:\. Choose a subfolder."
            continue
        }

        return $full.TrimEnd('\')
    }
}

$scriptSucceeded = $false
$transcriptStarted = $false
$projectPath = $null
$logPath = $null

try {
    Clear-Host
    Write-Host "CAR GAME - FRESH DOWNLOAD, BUILD AND RUN" -ForegroundColor Green
    Write-Host "The window will remain open when the process finishes or fails." -ForegroundColor Yellow

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
        Write-Warning "Its complete contents must be deleted to install a clean copy."
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

    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    $logPath = Join-Path $projectPath ("install_build_run_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcriptStarted = $true

    Write-Step "Cloning a completely fresh copy from GitHub"
    Remove-Item $projectPath -Recurse -Force
    Invoke-Native git clone --branch $Branch --single-branch $RepositoryUrl $projectPath

    Set-Location $projectPath

    Write-Step "Confirming repository state"
    Invoke-Native git fetch origin
    Invoke-Native git reset --hard "origin/$Branch"
    Invoke-Native git clean -xfd

    Write-Step "Checking Flutter environment"
    Invoke-Native flutter doctor -v

    Write-Step "Building a fresh Android release APK"
    $rebuildScript = Join-Path $projectPath "REBUILD_FRESH_ANDROID.ps1"
    if (-not (Test-Path $rebuildScript)) {
        throw "REBUILD_FRESH_ANDROID.ps1 was not found after cloning."
    }

    & $rebuildScript -SkipGitSync
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh Android rebuild failed with exit code $LASTEXITCODE."
    }

    $apkPath = Join-Path $projectPath "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkPath)) {
        throw "APK was not found after the build: $apkPath"
    }

    Write-Step "Starting emulator, installing APK and launching the application"
    $runScript = Join-Path $projectPath "RUN_ON_EMULATOR.ps1"
    if (-not (Test-Path $runScript)) {
        throw "RUN_ON_EMULATOR.ps1 was not found after cloning."
    }

    & $runScript -ApkPath $apkPath
    if ($LASTEXITCODE -ne 0) {
        throw "Emulator run failed with exit code $LASTEXITCODE."
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
    Write-Host ""
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    if ($logPath) {
        Write-Host ""
        Write-Host "Log file: $logPath" -ForegroundColor Yellow
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
        Write-Host "Review the error above. This window will not close automatically." -ForegroundColor Yellow
    }
    [void](Read-Host "Press Enter to close this window")
}
