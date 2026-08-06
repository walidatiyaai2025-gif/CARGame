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
        if ($code -ne 0) {
            throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-AndroidSdkRoot {
    $candidates = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Android\Sdk' })
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        $full = [IO.Path]::GetFullPath($candidate)
        if (Test-Path (Join-Path $full 'platform-tools\adb.exe')) {
            return $full
        }
    }

    throw 'Android SDK was not found. Set ANDROID_SDK_ROOT or install it through Android Studio.'
}

function Get-JavaMajorVersion {
    param([Parameter(Mandatory)][string]$JavaExe)

    $output = (& $JavaExe -version 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { return $null }

    $match = [regex]::Match($output, 'version\s+"(?<major>\d+)(?:\.|\")')
    if (-not $match.Success) {
        $match = [regex]::Match($output, 'openjdk\s+(?<major>\d+)(?:\.|\s)')
    }
    if (-not $match.Success) { return $null }
    return [int]$match.Groups['major'].Value
}

function Test-JdkHome {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try { $full = [IO.Path]::GetFullPath($Path) } catch { return $false }
    $java = Join-Path $full 'bin\java.exe'
    $javac = Join-Path $full 'bin\javac.exe'
    if (-not (Test-Path $java) -or -not (Test-Path $javac)) { return $false }
    return (Get-JavaMajorVersion $java) -eq 17
}

function Resolve-Jdk17Home {
    $candidates = [Collections.Generic.List[string]]::new()

    foreach ($value in @($env:JAVA_HOME, $env:JDK_HOME)) {
        if (-not [string]::IsNullOrWhiteSpace($value)) { $candidates.Add($value) }
    }

    $javaCommand = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaCommand) {
        $candidates.Add((Split-Path (Split-Path $javaCommand.Source -Parent) -Parent))
    }

    foreach ($root in @(
        (Join-Path $env:ProgramFiles 'Eclipse Adoptium'),
        (Join-Path $env:ProgramFiles 'Java'),
        (Join-Path $env:ProgramFiles 'Microsoft'),
        $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Eclipse Adoptium' })
    ) | Where-Object { $_ -and (Test-Path $_) }) {
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { $candidates.Add($_.FullName) }
    }

    $flutterConfig = (& flutter config --list 2>$null | Out-String)
    $jdkMatch = [regex]::Match($flutterConfig, '(?m)^jdk-dir:\s*(?<path>.+?)\s*$')
    if ($jdkMatch.Success) { $candidates.Add($jdkMatch.Groups['path'].Value.Trim('"')) }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-JdkHome $candidate) { return [IO.Path]::GetFullPath($candidate) }
    }

    throw 'A complete JDK 17 installation was not found. Install Temurin 17 or set JAVA_HOME to a JDK 17 directory.'
}

function Set-GradleProperty {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $content = if (Test-Path $Path) { Get-Content $Path -Raw } else { '' }
    $line = "$Name=$Value"
    $pattern = "(?m)^$([regex]::Escape($Name))=.*$"
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, [Text.RegularExpressions.MatchEvaluator]{ param($m) $line })
    }
    else {
        $content = $content.TrimEnd() + "`r`n$line`r`n"
    }
    [IO.File]::WriteAllText($Path, $content.Trim() + "`r`n", [Text.UTF8Encoding]::new($false))
}

function Set-StableGradleProperties {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string]$JdkHome
    )

    $path = Join-Path $ProjectRoot 'android\gradle.properties'
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
        Set-GradleProperty $path $key $settings[$key]
    }

    if (-not [string]::IsNullOrWhiteSpace($JdkHome)) {
        Set-GradleProperty $path 'org.gradle.java.home' ($JdkHome -replace '\\', '/')
    }
}

function Initialize-AndroidBuildEnvironment {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    foreach ($command in @('flutter', 'git')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "$command was not found in PATH."
        }
    }

    $sdk = Get-AndroidSdkRoot
    $jdk = Resolve-Jdk17Home
    $java = Join-Path $jdk 'bin\java.exe'

    $env:ANDROID_SDK_ROOT = $sdk
    $env:ANDROID_HOME = $sdk
    $env:JAVA_HOME = $jdk
    $env:JDK_HOME = $jdk
    $env:Path = "$(Join-Path $jdk 'bin');$env:Path"

    Set-StableGradleProperties $ProjectRoot $jdk

    Write-Host "Android SDK: $sdk" -ForegroundColor Green
    Write-Host "JDK 17: $jdk" -ForegroundColor Green
    & $java -version
    if ($LASTEXITCODE -ne 0 -or (Get-JavaMajorVersion $java) -ne 17) {
        throw 'Resolved Java runtime failed JDK 17 validation.'
    }

    $gradlew = Join-Path $ProjectRoot 'android\gradlew.bat'
    if (-not (Test-Path $gradlew)) { throw "Gradle wrapper was not found: $gradlew" }

    return [pscustomobject]@{
        AndroidSdk = $sdk
        JdkHome = $jdk
        JavaExe = $java
        AdbExe = Join-Path $sdk 'platform-tools\adb.exe'
        EmulatorExe = Join-Path $sdk 'emulator\emulator.exe'
        GradleWrapper = $gradlew
    }
}

function Remove-DirectorySafe {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return }
    $full = [IO.Path]::GetFullPath($Path)
    Write-Host "Removing: $full" -ForegroundColor DarkYellow
    & cmd.exe /d /c "rd /s /q `"\\?\$full`"" 2>$null
    if (Test-Path $full) {
        Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Stop-AndroidBuildProcesses {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $gradlew = Join-Path $ProjectRoot 'android\gradlew.bat'
    if (Test-Path $gradlew) {
        try { Invoke-NativeChecked $gradlew @('--stop') (Join-Path $ProjectRoot 'android') } catch {}
    }
    Get-Process java,javaw,gradle,kotlinc -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Repair-KotlinBuildCache {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$Deep
    )

    $toolchain = Initialize-AndroidBuildEnvironment $ProjectRoot
    Stop-AndroidBuildProcesses $ProjectRoot
    Set-StableGradleProperties $ProjectRoot $toolchain.JdkHome

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

    [void](Initialize-AndroidBuildEnvironment $ProjectRoot)
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
    }
    catch {
        Write-Warning 'First build failed. Performing deep Kotlin/Gradle cache repair and retrying once.'
        Repair-KotlinBuildCache $ProjectRoot -Deep
        Invoke-NativeChecked 'flutter' @('pub','get') $ProjectRoot
        Invoke-NativeChecked 'flutter' $args $ProjectRoot
    }
}
