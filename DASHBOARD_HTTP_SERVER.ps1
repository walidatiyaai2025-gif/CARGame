param(
    [Parameter(Mandatory)]
    [ValidateRange(1024, 65535)]
    [int]$Port,

    [Parameter(Mandatory)]
    [string]$RootPath,

    [string]$ServerLogPath = ''
)

$ErrorActionPreference = 'Stop'
$RootPath = [IO.Path]::GetFullPath($RootPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
$prefix = "http://127.0.0.1:$Port/"

function Write-ServerLog {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($ServerLogPath)) { return }
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -LiteralPath $ServerLogPath -Value $line -Encoding UTF8
}

function Get-ContentType {
    param([string]$Path)
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
        '.woff' { 'font/woff' }
        '.woff2'{ 'font/woff2' }
        default { 'application/octet-stream' }
    }
}

$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-ServerLog "PowerShell HTTP server listening on $prefix; root=$RootPath"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $relativeUrl = [Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
            if ([string]::IsNullOrWhiteSpace($relativeUrl)) {
                $relativeUrl = 'docs/dashboard/index.html'
            }
            elseif ($relativeUrl.EndsWith('/')) {
                $relativeUrl += 'index.html'
            }

            $relativePath = $relativeUrl.Replace('/', [IO.Path]::DirectorySeparatorChar)
            $candidate = [IO.Path]::GetFullPath((Join-Path $RootPath $relativePath))

            if (-not $candidate.StartsWith($RootPath, [StringComparison]::OrdinalIgnoreCase)) {
                $response.StatusCode = 403
                $bytes = [Text.Encoding]::UTF8.GetBytes('Forbidden')
            }
            elseif (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $response.StatusCode = 404
                $bytes = [Text.Encoding]::UTF8.GetBytes('Not Found')
            }
            else {
                $response.StatusCode = 200
                $response.ContentType = Get-ContentType $candidate
                $response.Headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
                $bytes = [IO.File]::ReadAllBytes($candidate)
            }

            $response.ContentLength64 = $bytes.Length
            if ($request.HttpMethod -ne 'HEAD') {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        }
        catch {
            Write-ServerLog "Request failed: $($_.Exception.Message)"
            if ($response.OutputStream.CanWrite) {
                $response.StatusCode = 500
                $bytes = [Text.Encoding]::UTF8.GetBytes('Internal Server Error')
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        }
        finally {
            $response.OutputStream.Close()
        }
    }
}
catch {
    Write-ServerLog "SERVER FAILED: $($_.Exception.Message)"
    Write-Error $_
    exit 1
}
finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
    Write-ServerLog 'PowerShell HTTP server stopped.'
}
