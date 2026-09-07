[CmdletBinding()]
param(
    [string]$UnityExe = $env:UNITY_EXE,
    [string]$OutputApk = "",
    [switch]$ValidateOnly,
    [switch]$VerifyApkOnly,
    [string]$EvidenceJson = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpectedVersion = "2022.3.75f1"
$ExpectedPackageId = "com.walka.cargov2"
$ProjectVersionFile = Join-Path (Join-Path $ProjectRoot "ProjectSettings") "ProjectVersion.txt"

if (-not (Test-Path -LiteralPath $ProjectVersionFile -PathType Leaf)) {
    throw "CARGO V2 Unity project scaffold is missing ProjectSettings/ProjectVersion.txt."
}

$VersionText = Get-Content -LiteralPath $ProjectVersionFile -Raw
if ($VersionText -notmatch [regex]::Escape("m_EditorVersion: $ExpectedVersion")) {
    throw "CARGO V2 requires Unity $ExpectedVersion."
}

$LogDir = Join-Path (Join-Path $ProjectRoot "BuildLogs") "CargoV2"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$ValidateLog = Join-Path $LogDir "unity-validate.log"
$BuildLog = Join-Path $LogDir "unity-android-build.log"

function Resolve-CargoV2ProjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $PathValue))
}

function Test-CargoV2ApkArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$ApkPath
    )

    if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
        throw "CARGO V2 APK artifact does not exist: $ApkPath"
    }

    $Apk = Get-Item -LiteralPath $ApkPath
    if ($Apk.Length -le 0) {
        throw "CARGO V2 APK artifact is empty: $ApkPath"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $Archive = [System.IO.Compression.ZipFile]::OpenRead($Apk.FullName)
    try {
        $Entries = @(
            $Archive.Entries |
                ForEach-Object { $_.FullName.Replace("\", "/") }
        )

        $RequiredEntries = @(
            "AndroidManifest.xml",
            "classes.dex",
            "assets/bin/Data/globalgamemanagers",
            "lib/arm64-v8a/libmain.so",
            "lib/arm64-v8a/libunity.so",
            "lib/arm64-v8a/libil2cpp.so"
        )

        foreach ($RequiredEntry in $RequiredEntries) {
            if ($Entries -cnotcontains $RequiredEntry) {
                throw "CARGO V2 APK contract missing required Unity entry: $RequiredEntry"
            }
        }

        $NativeArchitectures = @(
            @(
                foreach ($Entry in $Entries) {
                    if ($Entry -match '^lib/([^/]+)/[^/]+\.so$') {
                        $Matches[1]
                    }
                }
            ) | Sort-Object -Unique
        )

        if ($NativeArchitectures.Count -ne 1 -or $NativeArchitectures[0] -cne "arm64-v8a") {
            $Observed = if ($NativeArchitectures.Count -gt 0) {
                $NativeArchitectures -join ", "
            } else {
                "<none>"
            }
            throw "CARGO V2 APK native architecture contract requires only arm64-v8a; observed: $Observed"
        }
    } finally {
        $Archive.Dispose()
    }

    $Hash = Get-FileHash -LiteralPath $Apk.FullName -Algorithm SHA256
    $SourceSha = if ([string]::IsNullOrWhiteSpace($env:GITHUB_SHA)) {
        $null
    } else {
        $env:GITHUB_SHA
    }

    return [ordered]@{
        schemaVersion = 1
        artifactKind = "CARGO V2 Unity Android APK"
        verificationMode = "apk-archive-contract"
        unityVersion = $ExpectedVersion
        expectedPackageId = $ExpectedPackageId
        apkPath = $Apk.FullName
        sizeBytes = [int64]$Apk.Length
        sha256 = $Hash.Hash.ToLowerInvariant()
        requiredEntries = $RequiredEntries
        nativeArchitectures = @($NativeArchitectures)
        sourceSha = $SourceSha
        verifiedUtc = [DateTimeOffset]::UtcNow.ToString("o")
        runtimeInstallExecuted = $false
        runtimeLaunchExecuted = $false
        limitation = "Archive verification does not prove install, launch, Play Mode, FPS, device behavior, or signing identity."
    }
}

function Write-CargoV2BuildEvidence {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [string]$RequestedPath = ""
    )

    if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
        $RequestedPath = Join-Path $LogDir "CARGO-V2-build-evidence.json"
    } else {
        $RequestedPath = Resolve-CargoV2ProjectPath -PathValue $RequestedPath
    }

    $EvidenceDirectory = Split-Path -Parent $RequestedPath
    if (-not [string]::IsNullOrWhiteSpace($EvidenceDirectory)) {
        New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
    }

    $Evidence | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $RequestedPath -Encoding UTF8
    return [System.IO.Path]::GetFullPath($RequestedPath)
}

if ($VerifyApkOnly) {
    if ([string]::IsNullOrWhiteSpace($OutputApk)) {
        throw "-VerifyApkOnly requires -OutputApk."
    }

    $OutputApk = Resolve-CargoV2ProjectPath -PathValue $OutputApk
    $Evidence = Test-CargoV2ApkArtifact -ApkPath $OutputApk
    $EvidencePath = Write-CargoV2BuildEvidence -Evidence $Evidence -RequestedPath $EvidenceJson

    Write-Host "[CARGO V2] APK ARCHIVE CONTRACT PASS (no install/launch claim)."
    Write-Host "APK: $($Evidence.apkPath)"
    Write-Host "Size: $($Evidence.sizeBytes) bytes"
    Write-Host "SHA256: $($Evidence.sha256)"
    Write-Host "Native architectures: $($Evidence.nativeArchitectures -join ', ')"
    Write-Host "Evidence JSON: $EvidencePath"
    return
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
    return
}

if ([string]::IsNullOrWhiteSpace($OutputApk)) {
    $OutputApk = Join-Path (Join-Path (Join-Path $ProjectRoot "Builds") "CargoV2") "CARGO-V2.apk"
} else {
    $OutputApk = Resolve-CargoV2ProjectPath -PathValue $OutputApk
}

$OutputApk = [System.IO.Path]::GetFullPath($OutputApk)
$OutputDir = Split-Path -Parent $OutputApk
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$env:CARGO_V2_ANDROID_OUTPUT = $OutputApk

Invoke-UnityBatch -Method "CargoV2.EditorTools.SCR_CargoV2Build.BuildAndroidBatch" -LogFile $BuildLog -ExtraArgs @("-buildTarget", "Android")

$Evidence = Test-CargoV2ApkArtifact -ApkPath $OutputApk
$EvidencePath = Write-CargoV2BuildEvidence -Evidence $Evidence -RequestedPath $EvidenceJson

Write-Host "[CARGO V2] ANDROID BUILD + APK CONTRACT PASS"
Write-Host "APK: $($Evidence.apkPath)"
Write-Host "Size: $($Evidence.sizeBytes) bytes"
Write-Host "SHA256: $($Evidence.sha256)"
Write-Host "Native architectures: $($Evidence.nativeArchitectures -join ', ')"
Write-Host "Evidence JSON: $EvidencePath"
Write-Host "Validation log: $ValidateLog"
Write-Host "Build log: $BuildLog"
