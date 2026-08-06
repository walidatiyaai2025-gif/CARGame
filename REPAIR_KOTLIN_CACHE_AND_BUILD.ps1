param(
    [string]$ProjectPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Pause-Tool {
    Write-Host ''
    [void](Read-Host 'Press Enter to close')
}

function Run-Native {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ''
    )

    if ($WorkingDirectory) { Push-Location $WorkingDirectory }
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($WorkingDirectory) { Pop-Location }
    }
}

function Remove-DirectoryRobust([string]$Path) {
    if (-not (Test-Path $Path)) { return }

    Write-Host "Removing: $Path" -ForegroundColor DarkYellow
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            attrib -R -S -H "$Path\*" /S /D 2>$null | Out-Null
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -eq 5) {
                Write-Warning "PowerShell could not remove $Path. Trying robocopy mirror cleanup."
                $empty = Join-Path $env:TEMP ('empty_' + [guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path $empty -Force | Out-Null
                robocopy $empty $Path /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $empty -Recurse -Force -ErrorAction SilentlyContinue
                if (Test-Path $Path) {
                    throw "Unable to delete locked directory: $Path"
                }
                return
            }
            Start-Sleep -Seconds 2
        }
    }
}

function Set-GradleProperty {
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $content = if (Test-Path $File) { Get-Content $File -Raw } else { '' }
    $line = "$Name=$Value"
    $pattern = '(?m)^' + [regex]::Escape($Name) + '=.*$'

    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, $line)
    }
    else {
        if ($content -and -not $content.EndsWith("`n")) { $content += "`r`n" }
        $content += "$line`r`n"
    }

    [System.IO.File]::WriteAllText($File, $content, [System.Text.UTF8Encoding]::new($false))
}

try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' CARGO SORT - KOTLIN CACHE REPAIR AND BUILD' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan

    $ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) {
        $entered = Read-Host "Flutter project path [$ProjectPath]"
        if ($entered) { $ProjectPath = [System.IO.Path]::GetFullPath($entered.Trim('"')) }
    }

    if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) {
        throw "pubspec.yaml was not found in: $ProjectPath"
    }

    $androidPath = Join-Path $ProjectPath 'android'
    $gradlew = Join-Path $androidPath 'gradlew.bat'
    if (-not (Test-Path $gradlew)) { throw "Gradle wrapper not found: $gradlew" }

    Write-Host "Project: $ProjectPath" -ForegroundColor Cyan
    Write-Host ''
    Write-Host '1 - Repair and build Debug APK'
    Write-Host '2 - Repair and build Release APK'
    Write-Host '3 - Repair only'
    Write-Host '0 - Exit'
    $choice = Read-Host 'Choose'
    if ($choice -eq '0') { return }
    if ($choice -notin @('1','2','3')) { throw 'Invalid selection.' }

    Write-Host ''
    Write-Host 'Stopping Gradle daemons and build processes...' -ForegroundColor Yellow
    try { & $gradlew --stop 2>&1 | Out-Host } catch { }

    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -in @('java.exe','javaw.exe','dart.exe','flutter.exe') -and
            $_.CommandLine -match 'GradleDaemon|KotlinCompileDaemon|gradle-launcher|flutter_tools'
        } |
        ForEach-Object {
            Write-Host "Stopping PID $($_.ProcessId): $($_.Name)" -ForegroundColor DarkYellow
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }

    Start-Sleep -Seconds 2

    Write-Host 'Configuring stable Kotlin compilation...' -ForegroundColor Yellow
    $properties = Join-Path $androidPath 'gradle.properties'
    Set-GradleProperty $properties 'kotlin.incremental' 'false'
    Set-GradleProperty $properties 'kotlin.incremental.useClasspathSnapshot' 'false'
    Set-GradleProperty $properties 'kotlin.compiler.execution.strategy' 'in-process'
    Set-GradleProperty $properties 'org.gradle.daemon' 'false'
    Set-GradleProperty $properties 'org.gradle.parallel' 'false'
    Set-GradleProperty $properties 'org.gradle.caching' 'false'
    Set-GradleProperty $properties 'org.gradle.workers.max' '1'

    Write-Host 'Deleting project build caches...' -ForegroundColor Yellow
    foreach ($path in @(
        (Join-Path $ProjectPath 'build'),
        (Join-Path $ProjectPath '.dart_tool'),
        (Join-Path $ProjectPath '.gradle'),
        (Join-Path $androidPath '.gradle'),
        (Join-Path $androidPath 'build'),
        (Join-Path $androidPath 'app\build')
    )) {
        Remove-DirectoryRobust $path
    }

    Write-Host 'Deleting Kotlin daemon/cache remnants...' -ForegroundColor Yellow
    foreach ($path in @(
        (Join-Path $env:USERPROFILE '.kotlin'),
        (Join-Path $env:LOCALAPPDATA 'kotlin')
    )) {
        Remove-DirectoryRobust $path
    }

    Write-Host ''
    Run-Native 'flutter' @('clean') $ProjectPath
    Run-Native 'flutter' @('pub','get') $ProjectPath

    if ($choice -eq '3') {
        Write-Host 'Repair completed. No build was requested.' -ForegroundColor Green
        return
    }

    if ($choice -eq '1') {
        Run-Native 'flutter' @('build','apk','--debug','--no-pub') $ProjectPath
        $output = Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-debug.apk'
    }
    else {
        Run-Native 'flutter' @('build','apk','--release','--no-pub') $ProjectPath
        $output = Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-release.apk'
    }

    if (-not (Test-Path $output)) { throw "Build completed but APK was not found: $output" }

    Write-Host ''
    Write-Host 'BUILD SUCCESSFUL' -ForegroundColor Green
    Write-Host "APK: $output" -ForegroundColor Cyan
    Start-Process explorer.exe -ArgumentList "/select,`"$output`"" | Out-Null
}
catch {
    Write-Host ''
    Write-Host 'REPAIR/BUILD FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed }
}
finally {
    Pause-Tool
}
