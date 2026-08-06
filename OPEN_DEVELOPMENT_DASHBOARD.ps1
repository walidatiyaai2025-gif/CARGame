param(
    [int]$Port = 8765,
    [string]$ProjectPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$ProjectPath = [IO.Path]::GetFullPath($ProjectPath)
$DashboardPath = Join-Path $ProjectPath 'docs\dashboard\index.html'

if (-not (Test-Path $DashboardPath)) {
    throw "Development dashboard was not found: $DashboardPath"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $python) {
    throw 'Python was not found in PATH. Install Python or run another local HTTP server from the repository root.'
}

$portInUse = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $portInUse) {
    $arguments = if ($python.Name -eq 'py.exe' -or $python.Name -eq 'py') {
        @('-3', '-m', 'http.server', $Port, '--directory', $ProjectPath)
    } else {
        @('-m', 'http.server', $Port, '--directory', $ProjectPath)
    }

    Write-Host "Starting CARGame dashboard server on port $Port..." -ForegroundColor Cyan
    Start-Process -FilePath $python.Source -ArgumentList $arguments -WindowStyle Minimized | Out-Null

    $deadline = (Get-Date).AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 400
        $portInUse = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ((Get-Date) -gt $deadline) {
            throw "The local dashboard server did not start on port $Port."
        }
    } until ($portInUse)
}

$url = "http://localhost:$Port/docs/dashboard/"
Write-Host "Opening: $url" -ForegroundColor Green
Start-Process $url
