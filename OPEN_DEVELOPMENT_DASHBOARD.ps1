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
$LogDirectory = Join-Path $ProjectPath 'logs'
$LogPath = Join-Path $LogDirectory 'development_dashboard.log'
$StdOutPath = Join-Path $LogDirectory 'development_dashboard_server.stdout.log'
$StdErrPath = Join-Path $LogDirectory 'development_dashboard_server.stderr.log'
$PidPath = Join-Path $LogDirectory 'development_dashboard_server.pid'
$Url = "http://127.0.0.1:$Port/docs/dashboard/"

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Test-PortListening {
    param([int]$LocalPort)

    try {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $async = $client.BeginConnect('127.0.0.1', $LocalPort, $null, $null)
            if (-not $async.AsyncWaitHandle.WaitOne(500)) { return $false }
            $client.EndConnect($async)
            return $true
        }
        finally {
            $client.Dispose()
        }
    }
    catch {
        return $false
    }
}

function Test-DashboardHttp {
    param([string]$Address)

    try {
        $response = Invoke-WebRequest -Uri $Address -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
    }
    catch {
        return $false
    }
}

function Resolve-PythonCommand {
    foreach ($candidate in @('python', 'py', 'python3')) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command }
    }
    return $null
}

function Show-ServerLogs {
    Write-Host ''
    Write-Host '---------------- SERVER STDOUT ----------------' -ForegroundColor DarkCyan
    if (Test-Path $StdOutPath) {
        Get-Content -LiteralPath $StdOutPath -Tail 80 -ErrorAction SilentlyContinue
    }
    else {
        Write-Host '(no stdout log)' -ForegroundColor DarkGray
    }

    Write-Host '---------------- SERVER STDERR ----------------' -ForegroundColor DarkCyan
    if (Test-Path $StdErrPath) {
        Get-Content -LiteralPath $StdErrPath -Tail 80 -ErrorAction SilentlyContinue
    }
    else {
        Write-Host '(no stderr log)' -ForegroundColor DarkGray
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
    Write-Log "Log file: $LogPath" Cyan

    if (-not (Test-Path -LiteralPath $DashboardPath)) {
        throw "Development dashboard was not found: $DashboardPath"
    }

    $catalogPath = Join-Path $ProjectPath 'docs\FEATURE_CATALOG.md'
    if (-not (Test-Path -LiteralPath $catalogPath)) {
        throw "Feature catalog was not found: $catalogPath"
    }

    $serverAlreadyRunning = Test-DashboardHttp $Url
    $serverProcess = $null

    if ($serverAlreadyRunning) {
        Write-Log "A working dashboard server is already running on port $Port." Green
    }
    else {
        if (Test-PortListening $Port) {
            throw "Port $Port is already in use by another application, but it is not serving the CARGame dashboard. Run with another port, for example: .\OPEN_DEVELOPMENT_DASHBOARD.ps1 -Port 9000"
        }

        $python = Resolve-PythonCommand
        if (-not $python) {
            throw 'Python was not found in PATH. Install Python 3, or verify that python.exe/py.exe is available from PowerShell.'
        }

        Write-Log "Python command: $($python.Source)" Cyan

        Remove-Item -LiteralPath $StdOutPath, $StdErrPath, $PidPath -Force -ErrorAction SilentlyContinue

        $arguments = if ($python.Name -in @('py.exe', 'py')) {
            @('-3', '-m', 'http.server', [string]$Port, '--bind', '127.0.0.1', '--directory', $ProjectPath)
        }
        else {
            @('-m', 'http.server', [string]$Port, '--bind', '127.0.0.1', '--directory', $ProjectPath)
        }

        Write-Log "Starting local HTTP server..." Yellow
        Write-Log "$($python.Source) $($arguments -join ' ')" DarkGray

        $serverProcess = Start-Process `
            -FilePath $python.Source `
            -ArgumentList $arguments `
            -WorkingDirectory $ProjectPath `
            -RedirectStandardOutput $StdOutPath `
            -RedirectStandardError $StdErrPath `
            -PassThru

        Set-Content -LiteralPath $PidPath -Value $serverProcess.Id -Encoding ASCII
        Write-Log "Server process ID: $($serverProcess.Id)" Cyan

        $deadline = (Get-Date).AddSeconds(25)
        do {
            Start-Sleep -Milliseconds 500
            $serverProcess.Refresh()

            if ($serverProcess.HasExited) {
                Show-ServerLogs
                throw "The dashboard server exited before startup. Exit code: $($serverProcess.ExitCode)"
            }

            $ready = Test-DashboardHttp $Url
        } while (-not $ready -and (Get-Date) -lt $deadline)

        if (-not $ready) {
            Show-ServerLogs
            throw "The dashboard server did not become ready within 25 seconds."
        }

        Write-Log 'Dashboard server started successfully.' Green
    }

    if (-not $NoBrowser) {
        Write-Log 'Opening the dashboard in the default browser...' Green
        Start-Process $Url
    }

    Write-Host ''
    Write-Host 'Dashboard is running.' -ForegroundColor Green
    Write-Host "URL: $Url" -ForegroundColor White
    Write-Host "Main log: $LogPath" -ForegroundColor White
    Write-Host "Server stderr: $StdErrPath" -ForegroundColor White
    Write-Host ''
    Write-Host 'Keep this window open while using the dashboard.' -ForegroundColor Yellow
    Write-Host 'Press Enter to stop the server and close this window.' -ForegroundColor Yellow
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
    catch {
        # Avoid hiding the original failure if logging also fails.
    }

    Show-ServerLogs
    Write-Host ''
    Write-Host "Full launcher log: $LogPath" -ForegroundColor Yellow
    [void](Read-Host 'Press Enter to close')
    exit 1
}
