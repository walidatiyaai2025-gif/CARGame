param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 8765,
    [string]$ProjectPath = $PSScriptRoot,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$ProjectPath = [IO.Path]::GetFullPath($ProjectPath)
$DashboardPath = Join-Path $ProjectPath 'docs\dashboard\index.html'
$CatalogPath = Join-Path $ProjectPath 'docs\FEATURE_CATALOG.md'
$LogDirectory = Join-Path $ProjectPath 'logs'
$LogPath = Join-Path $LogDirectory 'development_dashboard.log'
$ServerLogPath = Join-Path $LogDirectory 'development_dashboard_server.log'
$Url = "http://127.0.0.1:$Port/docs/dashboard/"
$serverJob = $null

function Write-Log {
    param([Parameter(Mandatory)][string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Test-DashboardHttp {
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -eq 200 -and $response.Content -match 'CARGame'
    }
    catch { return $false }
}

function Test-PortListening {
    try {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync('127.0.0.1', $Port)
            if (-not $task.Wait(500)) { return $false }
            return $client.Connected
        }
        finally { $client.Dispose() }
    }
    catch { return $false }
}

function Show-JobErrors {
    if (-not $serverJob) { return }
    Write-Host ''
    Write-Host '---------------- SERVER JOB OUTPUT ----------------' -ForegroundColor DarkCyan
    Receive-Job -Job $serverJob -Keep -ErrorAction SilentlyContinue | Select-Object -Last 80
    $reason = $serverJob.ChildJobs[0].JobStateInfo.Reason
    if ($reason) {
        Write-Host '---------------- SERVER JOB ERROR -----------------' -ForegroundColor DarkCyan
        Write-Host $reason -ForegroundColor Red
    }
}

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '       CARGAME DEVELOPMENT PORTAL' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''

    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Set-Content -LiteralPath $LogPath -Value '' -Encoding UTF8
    Set-Content -LiteralPath $ServerLogPath -Value '' -Encoding UTF8

    Write-Log "Project path: $ProjectPath" Cyan
    Write-Log "Dashboard file: $DashboardPath" Cyan
    Write-Log "Dashboard URL: $Url" Cyan
    Write-Log "Launcher log: $LogPath" Cyan

    foreach ($required in @($DashboardPath, $CatalogPath)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required dashboard file was not found: $required"
        }
    }

    if (Test-DashboardHttp) {
        Write-Log "A working CARGame dashboard is already running on port $Port." Green
    }
    else {
        if (Test-PortListening) {
            throw "Port $Port is already used by another application. Run: .\OPEN_DEVELOPMENT_DASHBOARD.ps1 -Port 9000"
        }

        Write-Log 'Starting built-in PowerShell HTTP server...' Yellow

        $serverJob = Start-Job -Name "CARGameDashboard_$Port" -ArgumentList $ProjectPath, $Port, $ServerLogPath -ScriptBlock {
            param($RootPath, $ListenPort, $ServerLog)

            $ErrorActionPreference = 'Stop'
            $listener = [Net.HttpListener]::new()
            $listener.Prefixes.Add("http://127.0.0.1:$ListenPort/")

            function Write-ServerLog([string]$Message) {
                $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
                Add-Content -LiteralPath $ServerLog -Value $line -Encoding UTF8
                Write-Output $line
            }

            function Get-MimeType([string]$Path) {
                switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
                    '.html' { 'text/html; charset=utf-8' }
                    '.htm'  { 'text/html; charset=utf-8' }
                    '.css'  { 'text/css; charset=utf-8' }
                    '.js'   { 'application/javascript; charset=utf-8' }
                    '.json' { 'application/json; charset=utf-8' }
                    '.md'   { 'text/markdown; charset=utf-8' }
                    '.svg'  { 'image/svg+xml' }
                    '.png'  { 'image/png' }
                    '.jpg'  { 'image/jpeg' }
                    '.jpeg' { 'image/jpeg' }
                    '.webp' { 'image/webp' }
                    '.ico'  { 'image/x-icon' }
                    default { 'application/octet-stream' }
                }
            }

            try {
                $listener.Start()
                Write-ServerLog "Listening on http://127.0.0.1:$ListenPort/"

                while ($listener.IsListening) {
                    $context = $listener.GetContext()
                    try {
                        $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
                        if ([string]::IsNullOrWhiteSpace($relative)) {
                            $relative = 'docs/dashboard/index.html'
                        }
                        if ($relative.EndsWith('/')) {
                            $relative += 'index.html'
                        }

                        $candidate = [IO.Path]::GetFullPath((Join-Path $RootPath $relative.Replace('/', [IO.Path]::DirectorySeparatorChar)))
                        $rootFull = [IO.Path]::GetFullPath($RootPath).TrimEnd('\') + '\'

                        if (-not $candidate.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
                            $context.Response.StatusCode = 403
                            $payload = [Text.Encoding]::UTF8.GetBytes('Forbidden')
                        }
                        elseif (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                            $context.Response.StatusCode = 404
                            $payload = [Text.Encoding]::UTF8.GetBytes('Not Found')
                        }
                        else {
                            $context.Response.StatusCode = 200
                            $context.Response.ContentType = Get-MimeType $candidate
                            $context.Response.Headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
                            $payload = [IO.File]::ReadAllBytes($candidate)
                        }

                        $context.Response.ContentLength64 = $payload.Length
                        $context.Response.OutputStream.Write($payload, 0, $payload.Length)
                    }
                    catch {
                        try {
                            $context.Response.StatusCode = 500
                            $payload = [Text.Encoding]::UTF8.GetBytes("Server error: $($_.Exception.Message)")
                            $context.Response.ContentLength64 = $payload.Length
                            $context.Response.OutputStream.Write($payload, 0, $payload.Length)
                        }
                        catch {}
                        Write-ServerLog "Request failed: $($_.Exception.Message)"
                    }
                    finally {
                        try { $context.Response.OutputStream.Close() } catch {}
                        try { $context.Response.Close() } catch {}
                    }
                }
            }
            finally {
                if ($listener.IsListening) { $listener.Stop() }
                $listener.Close()
                Write-ServerLog 'Server stopped.'
            }
        }

        Write-Log "Server job ID: $($serverJob.Id)" Cyan

        $deadline = (Get-Date).AddSeconds(20)
        do {
            Start-Sleep -Milliseconds 400
            $serverJob = Get-Job -Id $serverJob.Id
            if ($serverJob.State -in @('Failed', 'Stopped', 'Completed')) {
                Show-JobErrors
                throw "The dashboard server job stopped before startup. State: $($serverJob.State)"
            }
            $ready = Test-DashboardHttp
        } while (-not $ready -and (Get-Date) -lt $deadline)

        if (-not $ready) {
            Show-JobErrors
            throw 'The dashboard server did not become ready within 20 seconds.'
        }

        Write-Log 'Dashboard server started successfully.' Green
    }

    if (-not $NoBrowser) {
        Write-Log 'Opening dashboard in the default browser...' Green
        Start-Process $Url
    }

    Write-Host ''
    Write-Host 'Development portal is running.' -ForegroundColor Green
    Write-Host "URL: $Url" -ForegroundColor White
    Write-Host "Launcher log: $LogPath" -ForegroundColor White
    Write-Host "Server log: $ServerLogPath" -ForegroundColor White
    Write-Host ''
    Write-Host 'Keep this window open while viewing the portal.' -ForegroundColor Yellow
    Write-Host 'Press Enter to stop the local server.' -ForegroundColor Yellow
    [void](Read-Host)
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
    Show-JobErrors
    Write-Host ''
    Write-Host "Full launcher log: $LogPath" -ForegroundColor Yellow
    [void](Read-Host 'Press Enter to close')
    exit 1
}
finally {
    if ($serverJob) {
        try {
            Stop-Job -Job $serverJob -ErrorAction SilentlyContinue
            Remove-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
        }
        catch {}
    }
}
