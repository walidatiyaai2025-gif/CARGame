param(
    [switch]$BuildAppBundle
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Remove-LongPathDirectory([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    $full = [System.IO.Path]::GetFullPath($Path)
    Write-Host "Deleting: $full" -ForegroundColor DarkYellow
    & cmd.exe /d /c "rd /s /q \\?\$full"
}

try {
    Clear-Host
    Write-Host 'CAR GAME - ISOLATED RELEASE BUILD V2' -ForegroundColor Green
    Write-Host 'This window remains open after success or failure.' -ForegroundColor Yellow

    $isolatedGradle = Join-Path $PSScriptRoot '.gradle-user-home-release'

    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Remove-LongPathDirectory '.\build'
    Remove-LongPathDirectory '.\.dart_tool'
    Remove-LongPathDirectory '.\android\.gradle'
    Remove-LongPathDirectory '.\android\app\build'
    Remove-LongPathDirectory $isolatedGradle

    New-Item -ItemType Directory -Path $isolatedGradle -Force | Out-Null
    $env:GRADLE_USER_HOME = $isolatedGradle

    Write-Host "GRADLE_USER_HOME: $env:GRADLE_USER_HOME" -ForegroundColor Cyan

    $script = Join-Path $PSScriptRoot 'BUILD_RELEASE.ps1'
    if (-not (Test-Path $script)) {
        throw "BUILD_RELEASE.ps1 was not found: $script"
    }

    if ($BuildAppBundle) {
        & $script -BuildAppBundle
    } else {
        & $script
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Release build failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host 'ISOLATED RELEASE BUILD FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close this window')
}
