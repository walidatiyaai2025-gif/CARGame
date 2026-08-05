param(
    [string]$DeviceId = ""
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

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )

    Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Command @Arguments
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')"
    }
}

function Remove-LongPathDirectory([string]$Path) {
    if (-not (Test-Path $Path)) { return }

    $full = [System.IO.Path]::GetFullPath($Path)
    Write-Host "Deleting: $full" -ForegroundColor DarkYellow

    & cmd.exe /d /c "rd /s /q \\?\$full"
    if (Test-Path $full) {
        Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    Clear-Host
    Write-Host "CAR GAME - CLEAN DEBUG RUN" -ForegroundColor Green
    Write-Host "This window remains open after success or failure." -ForegroundColor Yellow

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter was not found in PATH."
    }

    if (-not (Test-Path ".\pubspec.yaml")) {
        throw "pubspec.yaml was not found in: $PSScriptRoot"
    }

    Write-Step "Stopping Gradle, Kotlin, Java and Dart processes"
    if (Test-Path ".\android\gradlew.bat") {
        Push-Location ".\android"
        try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
        Pop-Location
    }

    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2

    Write-Step "Applying stable non-incremental Kotlin settings"
    $gradleProperties = Join-Path $PSScriptRoot "android\gradle.properties"
    $required = @(
        "org.gradle.daemon=false",
        "org.gradle.parallel=false",
        "org.gradle.caching=false",
        "org.gradle.workers.max=1",
        "kotlin.incremental=false",
        "kotlin.incremental.useClasspathSnapshot=false",
        "kotlin.compiler.execution.strategy=in-process",
        "kotlin.daemon.enabled=false"
    )

    $existing = if (Test-Path $gradleProperties) {
        Get-Content $gradleProperties -Raw
    } else {
        ""
    }

    foreach ($line in $required) {
        $key = $line.Split('=')[0]
        if ($existing -match "(?m)^$([regex]::Escape($key))=") {
            $existing = [regex]::Replace(
                $existing,
                "(?m)^$([regex]::Escape($key))=.*$",
                $line
            )
        } else {
            $existing += "`r`n$line"
        }
    }

    [System.IO.File]::WriteAllText(
        $gradleProperties,
        $existing.Trim() + "`r`n",
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Step "Deleting Flutter, Gradle and Kotlin build caches"
    Remove-LongPathDirectory ".\build"
    Remove-LongPathDirectory ".\.dart_tool"
    Remove-LongPathDirectory ".\android\.gradle"
    Remove-LongPathDirectory ".\android\app\build"

    $userKotlin = Join-Path $env:USERPROFILE ".kotlin"
    Remove-LongPathDirectory $userKotlin

    Write-Step "Restoring Flutter packages"
    Invoke-Checked "flutter" @("clean")
    Invoke-Checked "flutter" @("pub", "get")

    try {
        Invoke-Checked "flutter" @("gen-l10n")
    } catch {
        Write-Warning "flutter gen-l10n was skipped."
    }

    Write-Step "Running the application in Debug mode"
    $arguments = @("run", "--no-pub")
    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        $arguments += @("-d", $DeviceId)
    }

    Invoke-Checked "flutter" $arguments
}
catch {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "DEBUG RUN FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close this window")
}
