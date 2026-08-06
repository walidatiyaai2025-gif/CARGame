param(
    [string]$ProjectPath = $PSScriptRoot,
    [switch]$EnvironmentCheck
)

$ErrorActionPreference = 'Stop'
$ProjectPath = [IO.Path]::GetFullPath($ProjectPath)

$requiredScripts = @(
    'BUILD_COMMON.ps1',
    'COLD_BOOT_AND_RUN.ps1',
    'FIRST_TIME_SETUP_AND_RUN.ps1',
    'BUILD_RELEASE.ps1',
    'BUILD_RELEASE_V2.ps1'
)

$errors = [Collections.Generic.List[string]]::new()

foreach ($relative in $requiredScripts) {
    $path = Join-Path $ProjectPath $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("Missing required script: $relative")
        continue
    }

    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        $path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    foreach ($parseError in @($parseErrors)) {
        $errors.Add("PowerShell parser error in ${relative}: $($parseError.Message)")
    }
}

$scriptFiles = Get-ChildItem -LiteralPath $ProjectPath -Filter '*.ps1' -File
$forbiddenPatterns = [ordered]@{
    'fixed emulator transport ID' = '(?i)emulator-\d{4}'
    'fixed AVD/device model' = '(?i)(A51_API|Pixel_\d|Resizable_Experimental)'
    'local Java installation path' = '(?i)[A-Z]:\\Program Files\\(?:Java|Eclipse Adoptium|Microsoft)\\jdk'
    'PowerShell ISE host' = '(?i)powershell_ise\.exe'
}

foreach ($script in $scriptFiles) {
    $content = Get-Content -LiteralPath $script.FullName -Raw
    foreach ($entry in $forbiddenPatterns.GetEnumerator()) {
        if ($content -match $entry.Value) {
            $errors.Add("$($entry.Key) found in $($script.Name)")
        }
    }
}

$commonPath = Join-Path $ProjectPath 'BUILD_COMMON.ps1'
if (Test-Path $commonPath) {
    $common = Get-Content -LiteralPath $commonPath -Raw
    foreach ($functionName in @(
        'Resolve-Jdk17Home',
        'Initialize-AndroidBuildEnvironment',
        'Repair-KotlinBuildCache',
        'Invoke-FlutterBuildWithRetry'
    )) {
        if ($common -notmatch "(?m)^function\s+$([regex]::Escape($functionName))\b") {
            $errors.Add("BUILD_COMMON.ps1 is missing function: $functionName")
        }
    }
}

if ($EnvironmentCheck -and $errors.Count -eq 0) {
    . $commonPath
    $toolchain = Initialize-AndroidBuildEnvironment $ProjectPath
    if (-not (Test-Path $toolchain.AdbExe)) {
        $errors.Add("ADB was not found after initialization: $($toolchain.AdbExe)")
    }
    if ((Get-JavaMajorVersion $toolchain.JavaExe) -ne 17) {
        $errors.Add('Environment initialization did not resolve JDK 17.')
    }

    Push-Location (Join-Path $ProjectPath 'android')
    try {
        & $toolchain.GradleWrapper '--version' | Out-Host
        if ($LASTEXITCODE -ne 0) { $errors.Add('Gradle wrapper verification failed.') }
    }
    finally {
        Pop-Location
    }
}

if ($errors.Count -gt 0) {
    Write-Host 'ANDROID TOOLCHAIN SELF-TEST FAILED' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'ANDROID TOOLCHAIN SELF-TEST PASSED' -ForegroundColor Green
Write-Host "Scripts parsed: $($requiredScripts.Count)" -ForegroundColor Green
Write-Host "Repository PowerShell scripts audited: $($scriptFiles.Count)" -ForegroundColor Green
if (-not $EnvironmentCheck) {
    Write-Host 'Run with -EnvironmentCheck to validate local JDK, SDK, ADB, and Gradle.' -ForegroundColor Cyan
}
