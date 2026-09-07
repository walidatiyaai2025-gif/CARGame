[CmdletBinding()]
param(
    [string]$ApkPath = "Builds/CargoV2/CARGO-V2.apk",
    [string]$PackageId = "com.walka.cargov2",
    [string]$AdbPath = "",
    [string]$Serial = "",
    [ValidateRange(0, 60)][int]$LaunchWaitSeconds = 5,
    [string]$EvidenceJson = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ArchiveVerifier = Join-Path $ProjectRoot "BUILD_CARGO_V2_UNITY.ps1"
$LogDir = Join-Path (Join-Path $ProjectRoot "BuildLogs") "CargoV2"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Resolve-CargoV2Path {
    param([Parameter(Mandatory = $true)][string]$PathValue)
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $PathValue))
}

function Write-SmokeEvidence {
    param([Parameter(Mandatory = $true)]$Record)

    $target = $EvidenceJson
    if ([string]::IsNullOrWhiteSpace($target)) {
        $target = Join-Path $LogDir "CARGO-V2-android-smoke-evidence.json"
    } else {
        $target = Resolve-CargoV2Path -PathValue $target
    }

    $parent = Split-Path -Parent $target
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $target -Encoding UTF8
    return [System.IO.Path]::GetFullPath($target)
}

function Resolve-AdbExecutable {
    if (-not [string]::IsNullOrWhiteSpace($AdbPath)) {
        $resolved = Resolve-CargoV2Path -PathValue $AdbPath
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "ADB executable was not found: $resolved"
        }
        return $resolved
    }

    $command = Get-Command adb -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        throw "ADB was not found on PATH. Install Android platform-tools or pass -AdbPath."
    }
    return $command.Source
}

$script:ResolvedAdb = ""
function Invoke-CargoV2Adb {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $output = @(& $script:ResolvedAdb @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "ADB command failed ($exitCode): adb $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
        Text = ($output -join [Environment]::NewLine)
    }
}

function Get-ConnectedDevices {
    $result = Invoke-CargoV2Adb -Arguments @("devices", "-l")
    $devices = @()
    foreach ($line in $result.Output) {
        if ($line -match '^([^\s]+)\s+device(?:\s|$)') {
            $devices += $Matches[1]
        }
    }
    return @($devices | Sort-Object -Unique)
}

function Read-DeviceProperty {
    param([Parameter(Mandatory = $true)][string]$Name)
    $result = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "getprop", $Name) -AllowFailure
    if ($result.ExitCode -ne 0) { return "" }
    return $result.Text.Trim()
}

function Get-CrashMarkers {
    param(
        [Parameter(Mandatory = $true)][string[]]$LogLines,
        [Parameter(Mandatory = $true)][string[]]$ObservedProcessIds
    )

    $packagePattern = [regex]::Escape($PackageId)
    $crashPattern = '(?i)(FATAL EXCEPTION|ANR in|Fatal signal|Process .* has died)'
    $markers = @()

    foreach ($line in $LogLines) {
        $correlated = $line -match $packagePattern
        if (-not $correlated) {
            foreach ($observedProcessId in $ObservedProcessIds) {
                # `adb logcat -v brief` prefixes records like E/AndroidRuntime( 4242): ...
                $pidPattern = "\(\s*$([regex]::Escape($observedProcessId))\s*\):"
                if ($line -match $pidPattern) {
                    $correlated = $true
                    break
                }
            }
        }

        if ($correlated -and $line -match $crashPattern) {
            $markers += $line
        }
    }

    return @($markers)
}

$resolvedApk = Resolve-CargoV2Path -PathValue $ApkPath
$sourceSha = if ([string]::IsNullOrWhiteSpace($env:GITHUB_SHA)) { $null } else { $env:GITHUB_SHA }
$record = [ordered]@{
    schemaVersion = 1
    verificationMode = "adb-install-launch-smoke"
    sourceSha = $sourceSha
    packageId = $PackageId
    apkPath = $resolvedApk
    apkSha256 = $null
    adbPath = $null
    deviceSerial = $null
    manufacturer = $null
    model = $null
    sdk = $null
    abi = $null
    archiveContractPassed = $false
    installExecuted = $false
    installPassed = $false
    launchExecuted = $false
    launchPassed = $false
    processObserved = $false
    processIds = @()
    foregroundObserved = $false
    crashMarkersObserved = $null
    crashMarkerCount = 0
    logcatPath = $null
    smokePassed = $false
    observedUtc = [DateTimeOffset]::UtcNow.ToString("o")
    error = $null
    limitation = "ADB install/launch smoke does not prove gameplay completion, controls, visual quality, sustained FPS, thermal behavior, or production signing."
}

try {
    if (-not (Test-Path -LiteralPath $ArchiveVerifier -PathType Leaf)) {
        throw "CARGO V2 archive verifier is missing: $ArchiveVerifier"
    }
    if (-not (Test-Path -LiteralPath $resolvedApk -PathType Leaf)) {
        throw "CARGO V2 APK does not exist: $resolvedApk"
    }

    $archiveEvidence = Join-Path $LogDir "CARGO-V2-android-smoke-archive-evidence.json"
    & pwsh -NoProfile -File $ArchiveVerifier -VerifyApkOnly -OutputApk $resolvedApk -EvidenceJson $archiveEvidence
    if ($LASTEXITCODE -ne 0) {
        throw "CARGO V2 APK failed the archive/ABI contract before device smoke (exit $LASTEXITCODE)."
    }
    $record.archiveContractPassed = $true
    $record.apkSha256 = (Get-FileHash -LiteralPath $resolvedApk -Algorithm SHA256).Hash.ToLowerInvariant()

    $script:ResolvedAdb = Resolve-AdbExecutable
    $record.adbPath = $script:ResolvedAdb

    $devices = @(Get-ConnectedDevices)
    if ($devices.Count -eq 0) {
        throw "No authorized Android device/emulator is connected to ADB."
    }

    if (-not [string]::IsNullOrWhiteSpace($Serial)) {
        if ($devices -notcontains $Serial) {
            throw "Requested ADB serial '$Serial' is not an authorized connected device. Connected: $($devices -join ', ')"
        }
        $script:SelectedSerial = $Serial
    } elseif ($devices.Count -eq 1) {
        $script:SelectedSerial = $devices[0]
    } else {
        throw "Multiple authorized Android devices are connected. Pass -Serial explicitly. Connected: $($devices -join ', ')"
    }

    $record.deviceSerial = $script:SelectedSerial
    $record.manufacturer = Read-DeviceProperty -Name "ro.product.manufacturer"
    $record.model = Read-DeviceProperty -Name "ro.product.model"
    $record.sdk = Read-DeviceProperty -Name "ro.build.version.sdk"
    $record.abi = Read-DeviceProperty -Name "ro.product.cpu.abi"

    $install = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "install", "-r", $resolvedApk) -AllowFailure
    $record.installExecuted = $true
    if ($install.ExitCode -ne 0 -or $install.Text -notmatch '(?im)^Success\s*$') {
        throw "ADB install -r failed for CARGO V2.`n$($install.Text)"
    }

    $packagePath = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "pm", "path", $PackageId) -AllowFailure
    if ($packagePath.ExitCode -ne 0 -or $packagePath.Text -notmatch '(?im)^package:') {
        throw "Expected installed package '$PackageId' was not found after installation."
    }
    $record.installPassed = $true

    [void](Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "logcat", "-c") -AllowFailure)
    [void](Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "am", "force-stop", $PackageId) -AllowFailure)

    $launch = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "monkey", "-p", $PackageId, "-c", "android.intent.category.LAUNCHER", "1") -AllowFailure
    $record.launchExecuted = $true
    if ($launch.ExitCode -ne 0 -or $launch.Text -match '(?i)(No activities found|monkey aborted|error:)') {
        throw "CARGO V2 launcher intent failed.`n$($launch.Text)"
    }

    if ($LaunchWaitSeconds -gt 0) {
        Start-Sleep -Seconds $LaunchWaitSeconds
    }

    $processIdResult = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "pidof", $PackageId) -AllowFailure
    $observedProcessIds = @()
    if ($processIdResult.ExitCode -eq 0) {
        $observedProcessIds = @($processIdResult.Text -split '\s+' | Where-Object { $_ -match '^\d+$' } | Sort-Object -Unique)
    }
    $record.processIds = @($observedProcessIds)
    $record.processObserved = $observedProcessIds.Count -gt 0

    $activities = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "shell", "dumpsys", "activity", "activities") -AllowFailure
    $record.foregroundObserved = ($activities.ExitCode -eq 0 -and $activities.Text -match [regex]::Escape($PackageId))

    $logcat = Invoke-CargoV2Adb -Arguments @("-s", $script:SelectedSerial, "logcat", "-d", "-v", "brief") -AllowFailure
    $logPath = Join-Path $LogDir "CARGO-V2-android-smoke-logcat.txt"
    $logcat.Output | Set-Content -LiteralPath $logPath -Encoding UTF8
    $record.logcatPath = [System.IO.Path]::GetFullPath($logPath)
    $crashMarkers = @(Get-CrashMarkers -LogLines $logcat.Output -ObservedProcessIds $observedProcessIds)
    $record.crashMarkerCount = $crashMarkers.Count
    $record.crashMarkersObserved = $crashMarkers.Count -gt 0

    if (-not $record.processObserved) {
        throw "CARGO V2 process '$PackageId' was not observed after launch."
    }
    if (-not $record.foregroundObserved) {
        throw "CARGO V2 package was running but not observed in the resumed activity state."
    }
    if ($record.crashMarkersObserved) {
        throw "CARGO V2 crash/ANR marker was observed in package/PID-correlated logcat after launch."
    }

    $record.launchPassed = $true
    $record.smokePassed = $true
    $record.observedUtc = [DateTimeOffset]::UtcNow.ToString("o")
    $path = Write-SmokeEvidence -Record $record

    Write-Host "[CARGO V2] ANDROID ADB INSTALL/LAUNCH SMOKE PASS"
    Write-Host "Device: $($record.manufacturer) $($record.model) serial=$($record.deviceSerial) sdk=$($record.sdk) abi=$($record.abi)"
    Write-Host "APK SHA256: $($record.apkSha256)"
    Write-Host "Evidence JSON: $path"
    Write-Host "Boundary: install/launch smoke only; gameplay, visual quality and FPS are not claimed."
} catch {
    $record.error = $_.Exception.Message
    $record.observedUtc = [DateTimeOffset]::UtcNow.ToString("o")
    $path = Write-SmokeEvidence -Record $record
    Write-Error "$($_.Exception.Message) Evidence JSON: $path"
    exit 1
}
