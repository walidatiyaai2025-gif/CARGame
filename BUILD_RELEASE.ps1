param(
    [switch]$BuildAppBundle
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

function Write-Step([string]$Text) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
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
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    Write-Host "Deleting: $fullPath" -ForegroundColor DarkYellow
    & cmd.exe /d /c "rd /s /q \\?\$fullPath"
}

try {
    Clear-Host
    Write-Host 'CAR GAME - RELEASE BUILD' -ForegroundColor Green
    Write-Host 'The window remains open after success or failure.' -ForegroundColor Yellow

    if (-not (Test-Path '.\pubspec.yaml')) {
        throw "pubspec.yaml was not found in $PSScriptRoot"
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter was not found in PATH.'
    }

    Write-Step 'Stopping Gradle, Kotlin, Java and Dart processes'
    if (Test-Path '.\android\gradlew.bat') {
        Push-Location '.\android'
        try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
        Pop-Location
    }
    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Write-Step 'Applying stable release build settings'
    $gradleProperties = '.\android\gradle.properties'
    $required = @(
        'org.gradle.daemon=false',
        'org.gradle.parallel=false',
        'org.gradle.caching=false',
        'org.gradle.workers.max=1',
        'kotlin.incremental=false',
        'kotlin.incremental.useClasspathSnapshot=false',
        'kotlin.compiler.execution.strategy=in-process',
        'kotlin.daemon.enabled=false'
    )

    $properties = if (Test-Path $gradleProperties) {
        Get-Content $gradleProperties -Raw
    } else {
        ''
    }

    foreach ($line in $required) {
        $key = $line.Split('=')[0]
        if ($properties -match "(?m)^$([regex]::Escape($key))=") {
            $properties = [regex]::Replace(
                $properties,
                "(?m)^$([regex]::Escape($key))=.*$",
                $line
            )
        } else {
            $properties += "`r`n$line"
        }
    }

    [System.IO.File]::WriteAllText(
        (Join-Path $PSScriptRoot 'android\gradle.properties'),
        $properties.Trim() + "`r`n",
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Step 'Cleaning previous release and Kotlin caches'
    Remove-LongPathDirectory '.\build'
    Remove-LongPathDirectory '.\.dart_tool'
    Remove-LongPathDirectory '.\android\.gradle'
    Remove-LongPathDirectory '.\android\app\build'

    Write-Step 'Restoring Flutter packages'
    Invoke-Checked 'flutter' @('clean')
    Invoke-Checked 'flutter' @('pub', 'get')
    try { Invoke-Checked 'flutter' @('gen-l10n') } catch {
        Write-Warning 'flutter gen-l10n was skipped.'
    }
    Invoke-Checked 'flutter' @('analyze', '--no-fatal-infos')

    if ($BuildAppBundle) {
        Write-Step 'Building Google Play release AAB'
        Invoke-Checked 'flutter' @('build', 'appbundle', '--release', '--no-pub')
        $output = Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
    } else {
        Write-Step 'Building ARM64 release APK'
        Invoke-Checked 'flutter' @(
            'build', 'apk', '--release', '--target-platform', 'android-arm64', '--no-pub'
        )
        $output = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
    }

    if (-not (Test-Path $output)) {
        throw "Build completed but output was not found: $output"
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host 'RELEASE BUILD SUCCESS' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host $output -ForegroundColor Green
    Start-Process explorer.exe -ArgumentList "/select,`"$output`""
}
catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host 'RELEASE BUILD FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Write-Host ''
    [void](Read-Host 'Press Enter to close this window')
}
