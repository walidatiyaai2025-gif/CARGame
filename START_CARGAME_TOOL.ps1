param(
    [string]$ProjectPath = ""
)

$ErrorActionPreference = 'Stop'

function Test-CargoProject([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return (
        (Test-Path (Join-Path $Path 'pubspec.yaml')) -and
        (Test-Path (Join-Path $Path 'android\gradlew.bat')) -and
        (Test-Path (Join-Path $Path 'COLD_BOOT_AND_RUN.ps1'))
    )
}

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' CARGO SORT - SAFE TOOL LAUNCHER' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan

    $candidates = @(
        $ProjectPath,
        $PSScriptRoot,
        (Get-Location).Path,
        'C:\Apps\CARGame',
        'D:\Apps\CARGame',
        'D:\Android\cargo_sort_game_v1'
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    $resolved = $null
    foreach ($candidate in $candidates) {
        try {
            $full = [System.IO.Path]::GetFullPath($candidate)
            if (Test-CargoProject $full) {
                $resolved = $full
                break
            }
        } catch { }
    }

    while (-not $resolved) {
        Write-Host ''
        Write-Warning 'Cargo Sort project was not found automatically.'
        $entered = Read-Host 'Enter the full project folder path (example C:\Apps\CARGame)'
        if ([string]::IsNullOrWhiteSpace($entered)) {
            throw 'No project path was entered.'
        }

        $entered = $entered.Trim().Trim('"')
        try {
            $full = [System.IO.Path]::GetFullPath($entered)
        } catch {
            Write-Warning 'The entered path is invalid.'
            continue
        }

        if (Test-CargoProject $full) {
            $resolved = $full
        } else {
            Write-Warning "This is not a valid Cargo Sort project: $full"
            Write-Host 'Required files:' -ForegroundColor Yellow
            Write-Host '  pubspec.yaml'
            Write-Host '  android\gradlew.bat'
            Write-Host '  COLD_BOOT_AND_RUN.ps1'
        }
    }

    $tool = Join-Path $resolved 'COLD_BOOT_AND_RUN.ps1'
    Write-Host ''
    Write-Host "Project found: $resolved" -ForegroundColor Green
    Write-Host "Starting tool: $tool" -ForegroundColor Cyan

    Set-Location $resolved
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tool -ProjectPath $resolved
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Cargo Sort tool exited with code $exitCode."
    }
}
catch {
    Write-Host ''
    Write-Host 'LAUNCHER FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close')
}
