[CmdletBinding()]
param(
    [string]$UnityExe = $env:UNITY_EXE,
    [string]$OutputApk = "",
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpectedVersion = "2022.3.75f1"
$ProjectVersionFile = Join-Path $ProjectRoot "ProjectSettings\ProjectVersion.txt"

if (-not (Test-Path -LiteralPath $ProjectVersionFile -PathType Leaf)) {
    throw "CARGO V2 Unity project scaffold is missing ProjectSettings\ProjectVersion.txt."
}

$VersionText = Get-Content -LiteralPath $ProjectVersionFile -Raw
if ($VersionText -notmatch [regex]::Escape("m_EditorVersion: $ExpectedVersion")) {
    throw "CARGO V2 requires Unity $ExpectedVersion."
}

if ([string]::IsNullOrWhiteSpace($UnityExe)) {
    $Candidates = @()
    if ($env:ProgramFiles) {
        $Candidates += Join-Path $env:ProgramFiles "Unity\Hub\Editor\$ExpectedVersion\Editor\Unity.exe"
    }
    if (${env:ProgramFiles(x86)}) {
        $Candidates += Join-Path ${env:ProgramFiles(x86)} "Unity\Hub\Editor\$ExpectedVersion\Editor\Unity.exe"
    }

    $UnityExe = $Candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($UnityExe) -or -not (Test-Path -LiteralPath $UnityExe -PathType Leaf)) {
    throw "Unity $ExpectedVersion was not found. Install that editor with Android Build Support, or set UNITY_EXE to Unity.exe."
}

$LogDir = Join-Path $ProjectRoot "BuildLogs\CargoV2"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$ValidateLog = Join-Path $LogDir "unity-validate.log"
$BuildLog = Join-Path $LogDir "unity-android-build.log"

function Invoke-UnityBatch {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$LogFile,
        [string[]]$ExtraArgs = @()
    )

    if (Test-Path -LiteralPath $LogFile) {
        Remove-Item -LiteralPath $LogFile -Force
    }

    $Arguments = @(
        "-batchmode",
        "-nographics",
        "-quit",
        "-projectPath", $ProjectRoot,
        "-executeMethod", $Method,
        "-logFile", $LogFile
    ) + $ExtraArgs

    Write-Host "[CARGO V2] Unity method: $Method"
    & $UnityExe @Arguments
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -ne 0) {
        if (Test-Path -LiteralPath $LogFile) {
            Get-Content -LiteralPath $LogFile -Tail 160 | Write-Host
        }
        throw "Unity batch method '$Method' failed with exit code $ExitCode. Full log: $LogFile"
    }

    if (Test-Path -LiteralPath $LogFile) {
        $Errors = Select-String -LiteralPath $LogFile -Pattern "error CS\d+|Compilation failed|BuildFailedException|CARGO V2.*FAIL" -CaseSensitive:$false
        if ($Errors) {
            $Errors | Select-Object -Last 40 | ForEach-Object { Write-Host $_.Line }
            throw "Unity reported compile/validation errors. Full log: $LogFile"
        }
    }
}

Invoke-UnityBatch -Method "CargoV2.EditorTools.SCR_CargoV2Build.ValidateBatch" -LogFile $ValidateLog
Write-Host "[CARGO V2] Unity compile/import/structural validation PASS."

if ($ValidateOnly) {
    exit 0
}

if ([string]::IsNullOrWhiteSpace($OutputApk)) {
    $OutputApk = Join-Path $ProjectRoot "Builds\CargoV2\CARGO-V2.apk"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputApk)) {
    $OutputApk = Join-Path $ProjectRoot $OutputApk
}

$OutputApk = [System.IO.Path]::GetFullPath($OutputApk)
$OutputDir = Split-Path -Parent $OutputApk
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$env:CARGO_V2_ANDROID_OUTPUT = $OutputApk

Invoke-UnityBatch -Method "CargoV2.EditorTools.SCR_CargoV2Build.BuildAndroidBatch" -LogFile $BuildLog -ExtraArgs @("-buildTarget", "Android")

if (-not (Test-Path -LiteralPath $OutputApk -PathType Leaf)) {
    throw "Unity returned success but the APK was not created: $OutputApk"
}

$Apk = Get-Item -LiteralPath $OutputApk
if ($Apk.Length -le 0) {
    throw "Unity created an empty APK: $OutputApk"
}

$Hash = Get-FileHash -LiteralPath $OutputApk -Algorithm SHA256
Write-Host "[CARGO V2] ANDROID BUILD PASS"
Write-Host "APK: $($Apk.FullName)"
Write-Host "Size: $($Apk.Length) bytes"
Write-Host "SHA256: $($Hash.Hash)"
Write-Host "Validation log: $ValidateLog"
Write-Host "Build log: $BuildLog"
