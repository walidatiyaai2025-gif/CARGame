param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 8765,
    [string]$ProjectPath = $PSScriptRoot,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$ProjectPath = [IO.Path]::GetFullPath($ProjectPath)
$DashboardPath = Join-Path $ProjectPath 'docs\dashboard\index.html'
$CatalogPath = Join-Path $ProjectPath 'docs\FEATURE_CATALOG.md'
$ServerScript = Join-Path $ProjectPath 'DASHBOARD_HTTP_SERVER.ps1'
$LogDirectory = Join-Path $ProjectPath 'logs'
$LogPath = Join-Path $LogDirectory 'development_dashboard.log'
$ServerLogPath = Join-Path $LogDirectory 'development_dashboard_server.log'
$StdOutPath = Join-Path $LogDirectory 'development_dashboard_server.stdout.log'
$StdErrPath = Join-Path $LogDirectory 'development_dashboard_server.stderr.log'
$PidPath = Join-Path $LogDirectory 'development_dashboard_server.pid'
$Url = "http://127.0.0.1:$Port/docs/dashboard/"
$serverProcess = $null

function Write-Log {
    param([Parameter(Mandatory)][string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Test-PortListening {
    param([int]$LocalPort)
    try {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync('127.0.0.1', $LocalPort)
            if (-not $task.Wait(600)) { return $false }
            return $client.Connected
        }
        finally { $client.Dispose() }
    }
    catch { return $false }
}

function Test-DashboardHttp {
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -eq 200 -and $response.Content -match 'CARGame'
    }
    catch { return $false }
}

function Show-Logs {
    Write-Host ''
    foreach ($item in @(
        @{ Name = 'SERVER LOG'; Path = $ServerLogPath },
        @{ Name = 'SERVER STDOUT'; Path = $StdOutPath },
        @{ Name = 'SERVER STDERR'; Path = $StdErrPath }
    )) {
        Write-Host "---------------- $($item.Name) ----------------" -ForegroundColor DarkCyan
        if (Test-Path -LiteralPath $item.Path) {
            Get-Content -LiteralPath $item.Path -Tail 80 -ErrorAction SilentlyContinue
        }
        else { Write-Host '(no log)' -ForegroundColor DarkGray }
    }
}

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '       CARGAME DEVELOPMENT DASHBOARD' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''

    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Set-Content -LiteralPath $LogPath -Value '' -Encoding UTF8

    Write-Log "Project path: $ProjectPath" Cyan
    Write-Log "Dashboard file: $DashboardPath" Cyan
    Write-Log "Dashboard URL: $Url" Cyan
    Write-Log "Launcher log: $LogPath" Cyan

    foreach ($required in @($DashboardPath, $CatalogPath, $ServerScript)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required dashboard file was not found: $required"
        }
    }

    if (Test-DashboardHttp) {
        Write-Log "A working CARGame dashboard is already running on port $Port." Green
    }
    else {
        if (Test-PortListening $Port) {
            throw "Port $Port is already used by another application. Run: .\OPEN_DEVELOPMENT_DASHBOARD.ps1 -Port 9000"
        }

        Remove-Item -LiteralPath $ServerLogPath, $StdOutPath, $StdErrPath, $PidPath -Force -ErrorAction SilentlyContinue

        $hostExe = (Get-Process -Id $PID).Path
        if ([string]::IsNullOrWhiteSpace($hostExe) -or -not (Test-Path $hostExe)) {
            $hostExe = (Get-Command powershell.exe -ErrorAction Stop).Source
        }

        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $ServerScript,
            '-Port', [string]$Port,
            '-RootPath', $ProjectPath,
            '-ServerLogPath', $ServerLogPath
        )

        Write-Log 'Starting dependency-free PowerShell HTTP server...' Yellow
        Write-Log "$hostExe $($arguments -join ' ')" DarkGray

        $serverProcess = Start-Process `
            -FilePath $hostExe `
            -ArgumentList $arguments `
            -WorkingDirectory $ProjectPath `
            -RedirectStandardOutput $StdOutPath `
            -RedirectStandardError $StdErrPath `
            -WindowStyle Hidden `
            -PassThru

        Set-Content -LiteralPath $PidPath -Value $serverProcess.Id -Encoding ASCII
        Write-Log "Server process ID: $($serverProcess.Id)" Cyan

        $deadline = (Get-Date).AddSeconds(25)
        $ready = $false
        do {
            Start-Sleep -Milliseconds 500
            $serverProcess.Refresh()
            if ($serverProcess.HasExited) {
                Show-Logs
                throw "The PowerShell dashboard server exited before startup. Exit code: $($serverProcess.ExitCode)"
            }
            $ready = Test-DashboardHttp
        } while (-not $ready -and (Get-Date) -lt $deadline)

        if (-not $ready) {
            Show-Logs
            throw 'The dashboard server did not become ready within 25 seconds.'
        }

        Write-Log 'Dashboard server started successfully.' Green
    }

    if (-not $NoBrowser) {
        Write-Log 'Opening dashboard in the default browser...' Green
        Start-Process $Url
    }

    Write-Host ''
    Write-Host 'Dashboard is running.' -ForegroundColor Green
    Write-Host "URL: $Url" -ForegroundColor White
    Write-Host "Log: $LogPath" -ForegroundColor White
    Write-Host ''
    Write-Host 'Keep this window open. Press Enter to stop the server.' -ForegroundColor Yellow
    [void](Read-Host)

    if ($serverProcess -and -not $serverProcess.HasExited) {
        Write-Log "Stopping server process $($serverProcess.Id)..." Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Log 'Dashboard server stopped.' Green
    }
}
catch {
    Write-Host ''
    Write-Host 'DASHBOARD START FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    try {
        Write-Log "FAILED: $($_.Exception.Message)" Red
        Add-Content -LiteralPath $LogPath -Value $_.ScriptStackTrace -Encoding UTF8
    }
    catch {}
    Show-Logs
    Write-Host ''
    Write-Host "Full launcher log: $LogPath" -ForegroundColor Yellow
    [void](Read-Host 'Press Enter to close')
    exit 1
}
