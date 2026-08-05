param(
    [switch]$InstallApk
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Remove-LongPathDirectory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    Write-Host "Removing: $fullPath" -ForegroundColor DarkGray

    # cmd.exe + the Win32 extended path prefix can delete paths beyond MAX_PATH.
    $extendedPath = if ($fullPath.StartsWith('\\')) {
        '\\?\UNC\' + $fullPath.TrimStart('\')
    } else {
        '\\?\' + $fullPath
    }

    & cmd.exe /d /c "rd /s /q `"$extendedPath`"" 2>$null

    if (Test-Path -LiteralPath $Path) {
        # Fallback: mirror an empty folder, then remove the target.
        $empty = Join-Path $env:TEMP ("empty_" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $empty -Force | Out-Null
        try {
            & robocopy.exe $empty $fullPath /MIR /R:0 /W:0 /NFL /NDL /NJH /NJS /NP | Out-Null
            & cmd.exe /d /c "rd /s /q `"$extendedPath`"" 2>$null
        }
        finally {
            Remove-Item $empty -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if (Test-Path -LiteralPath $Path) {
        throw "Could not remove long-path directory: $fullPath"
    }
}

try {
    Clear-Host
    Write-Host "CAR GAME - FIX LONG PATHS AND REBUILD" -ForegroundColor Green

    if (-not (Test-Path ".git")) {
        throw "This folder is not a Git repository: $PSScriptRoot"
    }
    if (-not (Test-Path ".\REBUILD_FRESH_ANDROID.ps1")) {
        throw "REBUILD_FRESH_ANDROID.ps1 was not found."
    }

    Write-Step "Enabling Git and Windows long-path handling"
    & git config --global core.longpaths true
    & git config core.longpaths true
    & git config core.fileMode false

    Write-Step "Stopping processes that may lock generated files"
    if (Test-Path ".\android\gradlew.bat") {
        Push-Location ".\android"
        try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
        finally { Pop-Location }
    }
    Get-Process java,javaw,gradle,kotlinc,dart,adb -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Write-Step "Removing generated folders with long file names"
    Remove-LongPathDirectory (Join-Path $PSScriptRoot "build")
    Remove-LongPathDirectory (Join-Path $PSScriptRoot ".dart_tool")
    Remove-LongPathDirectory (Join-Path $PSScriptRoot "android\.gradle")
    Remove-LongPathDirectory (Join-Path $PSScriptRoot "android\app\build")

    Write-Step "Confirming repository files without deleting generated paths again"
    & git reset --hard HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "git reset failed with exit code $LASTEXITCODE"
    }

    Write-Step "Running the corrected fresh Android rebuild"
    if ($InstallApk) {
        & ".\REBUILD_FRESH_ANDROID.ps1" -SkipGitSync -InstallApk
    } else {
        & ".\REBUILD_FRESH_ANDROID.ps1" -SkipGitSync
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Rebuild failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "LONG-PATH CLEANUP AND BUILD COMPLETED" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    exit 1
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close this window")
}
