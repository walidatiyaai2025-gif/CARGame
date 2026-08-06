param(
    [switch]$BuildAppBundle,
    [switch]$InstallAndRun,
    [string]$PackageId = 'com.walka.cargosort'
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
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
    }
}

function Remove-SafeDirectory([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    Write-Host "Deleting: $fullPath" -ForegroundColor DarkYellow
    & cmd.exe /d /c "rd /s /q `"\\?\$fullPath`"" | Out-Null
    if (Test-Path $fullPath) {
        Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Write-BuildLog {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    & $Action 2>&1 | Tee-Object -FilePath $FilePath
    return $LASTEXITCODE
}

function Invoke-ReleaseBuild {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $flutterLog = Join-Path $PSScriptRoot "release_build_$stamp.log"

    $flutterArgs = if ($BuildAppBundle) {
        @('build', 'appbundle', '--release', '--no-pub', '--verbose')
    } else {
        @('build', 'apk', '--release', '--no-pub', '--verbose')
    }

    Write-Host "> flutter $($flutterArgs -join ' ')" -ForegroundColor DarkGray
    $flutterExit = Write-BuildLog -FilePath $flutterLog -Action { & flutter @flutterArgs }

    if ($flutterExit -eq 0) {
        return
    }

    Write-Host ''
    Write-Host 'Flutter build failed. Running Gradle directly with stacktrace...' -ForegroundColor Yellow

    $gradleLog = Join-Path $PSScriptRoot "release_gradle_stacktrace_$stamp.log"
    Push-Location (Join-Path $PSScriptRoot 'android')
    try {
        $task = if ($BuildAppBundle) { 'bundleRelease' } else { 'assembleRelease' }
        $gradleArgs = @(
            $task,
            '--stacktrace',
            '--info',
            '--no-daemon',
            '--max-workers=1'
        )
        Write-Host "> .\gradlew.bat $($gradleArgs -join ' ')" -ForegroundColor DarkGray
        $gradleExit = Write-BuildLog -FilePath $gradleLog -Action { & .\gradlew.bat @gradleArgs }
    }
    finally {
        Pop-Location
    }

    Write-Host ''
    Write-Host "Flutter log: $flutterLog" -ForegroundColor Yellow
    Write-Host "Gradle stacktrace: $gradleLog" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Most relevant Gradle lines:' -ForegroundColor Yellow
    Get-Content $gradleLog -ErrorAction SilentlyContinue |
        Select-String -Pattern 'What went wrong|Execution failed|Caused by:|Exception|Error:|FAILURE:' |
        Select-Object -Last 40 |
        ForEach-Object { Write-Host $_.Line -ForegroundColor Red }

    throw "Release build failed. Send this file: $gradleLog"
}

function Get-AdbPath {
    $sdkRoot = if ($env:ANDROID_SDK_ROOT) {
        $env:ANDROID_SDK_ROOT
    } elseif ($env:ANDROID_HOME) {
        $env:ANDROID_HOME
    } else {
        Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    }

    $adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
    if (-not (Test-Path $adb)) {
        throw "adb.exe was not found at: $adb"
    }
    return $adb
}

try {
    Clear-Host
    Write-Host 'CAR GAME - RELEASE BUILD WITH FULL DIAGNOSTICS' -ForegroundColor Green
    Write-Host 'The window remains open after success or failure.' -ForegroundColor Yellow

    if (-not (Test-Path '.\pubspec.yaml')) {
        throw "pubspec.yaml was not found in $PSScriptRoot"
    }
    if (-not (Test-Path '.\android\gradlew.bat')) {
        throw 'android\gradlew.bat was not found.'
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter was not found in PATH.'
    }

    Write-Step 'Stopping Gradle, Kotlin, Java and Dart processes'
    Push-Location '.\android'
    try { & .\gradlew.bat --stop 2>$null | Out-Null } catch {}
    Pop-Location
    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Write-Step 'Applying stable Gradle and Kotlin settings'
    $gradleProperties = Join-Path $PSScriptRoot 'android\gradle.properties'
    $properties = if (Test-Path $gradleProperties) { Get-Content $gradleProperties -Raw } else { '' }
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

    foreach ($line in $required) {
        $key = $line.Split('=')[0]
        if ($properties -match "(?m)^$([regex]::Escape($key))=") {
            $properties = [regex]::Replace($properties, "(?m)^$([regex]::Escape($key))=.*$", $line)
        } else {
            $properties += "`r`n$line"
        }
    }
    [System.IO.File]::WriteAllText($gradleProperties, $properties.Trim() + "`r`n", [System.Text.UTF8Encoding]::new($false))

    Write-Step 'Cleaning Flutter, Gradle and Kotlin caches'
    Remove-SafeDirectory '.\build'
    Remove-SafeDirectory '.\.dart_tool'
    Remove-SafeDirectory '.\android\.gradle'
    Remove-SafeDirectory '.\android\app\build'

    Invoke-Checked 'flutter' @('clean')
    Invoke-Checked 'flutter' @('pub', 'get')
    try { Invoke-Checked 'flutter' @('gen-l10n') } catch { Write-Warning 'flutter gen-l10n was skipped.' }

    Write-Step 'Analyzing project'
    Invoke-Checked 'flutter' @('analyze', '--no-fatal-infos', '--no-fatal-warnings')

    Write-Step $(if ($BuildAppBundle) { 'Building release AAB' } else { 'Building universal release APK' })
    Invoke-ReleaseBuild

    $output = if ($BuildAppBundle) {
        Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
    } else {
        Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
    }

    if (-not (Test-Path $output)) {
        throw "Build reported success but output was not found: $output"
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host 'RELEASE BUILD SUCCESS' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host $output -ForegroundColor Green

    if ($InstallAndRun -and -not $BuildAppBundle) {
        $adb = Get-AdbPath
        & $adb start-server | Out-Null
        $devices = @((& $adb devices) | Select-String -Pattern '^\S+\s+device$')
        if ($devices.Count -eq 0) {
            throw 'No authorized Android device was found.'
        }
        & $adb uninstall $PackageId 2>$null | Out-Null
        Invoke-Checked $adb @('install', '-r', $output)
        Invoke-Checked $adb @('shell', 'am', 'start', '-n', "$PackageId/.MainActivity")
    }

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
