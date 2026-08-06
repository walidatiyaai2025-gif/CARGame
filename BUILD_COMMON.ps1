Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = $PSScriptRoot
    )
    Push-Location $WorkingDirectory
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $code = $LASTEXITCODE
        if ($code -ne 0) { throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')" }
    } finally { Pop-Location }
}

function Remove-DirectorySafe {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return }
    $full = [IO.Path]::GetFullPath($Path)
    Write-Host "Removing: $full" -ForegroundColor DarkYellow
    & cmd.exe /d /c "rd /s /q `"\\?\$full`"" 2>$null
    if (Test-Path $full) { Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue }
}

function Set-StableGradleProperties {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Join-Path $ProjectRoot 'android\gradle.properties'
    $content = if (Test-Path $path) { Get-Content $path -Raw } else { '' }
    $settings = [ordered]@{
        'org.gradle.daemon' = 'false'
        'org.gradle.parallel' = 'false'
        'org.gradle.caching' = 'false'
        'org.gradle.configureondemand' = 'false'
        'org.gradle.workers.max' = '1'
        'kotlin.incremental' = 'false'
        'kotlin.incremental.java' = 'false'
        'kotlin.incremental.useClasspathSnapshot' = 'false'
        'kotlin.caching.enabled' = 'false'
        'kotlin.compiler.execution.strategy' = 'in-process'
        'kotlin.daemon.enabled' = 'false'
    }
    foreach ($key in $settings.Keys) {
        $line = "$key=$($settings[$key])"
        $pattern = "(?m)^$([regex]::Escape($key))=.*$"
        if ($content -match $pattern) { $content = [regex]::Replace($content, $pattern, $line) }
        else { $content = $content.TrimEnd() + "`r`n$line`r`n" }
    }
    [IO.File]::WriteAllText($path, $content.Trim() + "`r`n", [Text.UTF8Encoding]::new($false))
}

function Stop-AndroidBuildProcesses {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $gradlew = Join-Path $ProjectRoot 'android\gradlew.bat'
    if (Test-Path $gradlew) {
        try { Invoke-NativeChecked $gradlew @('--stop') (Join-Path $ProjectRoot 'android') } catch {}
    }
    Get-Process java,javaw,gradle,kotlinc,dart -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Repair-KotlinBuildCache {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$Deep
    )
    Stop-AndroidBuildProcesses $ProjectRoot
    Set-StableGradleProperties $ProjectRoot
    foreach ($relative in @('build','.dart_tool','.gradle','android\.gradle','android\build','android\app\build')) {
        Remove-DirectorySafe (Join-Path $ProjectRoot $relative)
    }
    if ($Deep) {
        foreach ($relative in @('.gradle\daemon','.gradle\workers','.gradle\kotlin')) {
            Remove-DirectorySafe (Join-Path $env:USERPROFILE $relative)
        }
    }
}

function Invoke-FlutterBuildWithRetry {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('debug','release','aab')][string]$Mode
    )
    Repair-KotlinBuildCache $ProjectRoot
    Invoke-NativeChecked 'flutter' @('clean') $ProjectRoot
    Invoke-NativeChecked 'flutter' @('pub','get') $ProjectRoot
    Invoke-NativeChecked 'flutter' @('analyze','--no-fatal-infos','--no-fatal-warnings') $ProjectRoot

    $args = switch ($Mode) {
        'debug' { @('build','apk','--debug','--no-pub') }
        'release' { @('build','apk','--release','--no-pub') }
        'aab' { @('build','appbundle','--release','--no-pub') }
    }

    try {
        Invoke-NativeChecked 'flutter' $args $ProjectRoot
    } catch {
        Write-Warning 'First build failed. Performing deep Kotlin/Gradle cache repair and retrying once.'
        Repair-KotlinBuildCache $ProjectRoot -Deep
        Invoke-NativeChecked 'flutter' @('pub','get') $ProjectRoot
        Invoke-NativeChecked 'flutter' $args $ProjectRoot
    }
}
