param(
    [string]$AvdName = "",
    [string]$ProjectPath = $PSScriptRoot,
    [string]$PackageId = "com.walka.cargosort"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ""
    )

    $token = [Guid]::NewGuid().ToString("N")
    $stdout = Join-Path $env:TEMP "$token.out"
    $stderr = Join-Path $env:TEMP "$token.err"

    try {
        $start = @{
            FilePath               = $FilePath
            ArgumentList           = $Arguments
            RedirectStandardOutput = $stdout
            RedirectStandardError  = $stderr
            NoNewWindow            = $true
            Wait                   = $true
            PassThru               = $true
        }
        if ($WorkingDirectory) { $start.WorkingDirectory = $WorkingDirectory }

        $process = Start-Process @start
        $parts = @()
        if (Test-Path $stdout) { $parts += Get-Content $stdout -Raw -ErrorAction SilentlyContinue }
        if (Test-Path $stderr) { $parts += Get-Content $stderr -Raw -ErrorAction SilentlyContinue }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Text = (($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join [Environment]::NewLine)
        }
    }
    finally {
        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

function Find-AndroidSdk {
    $candidates = @(
        $env:ANDROID_SDK_ROOT,
        $env:ANDROID_HOME,
        (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate "platform-tools\adb.exe")) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    throw "Android SDK was not found."
}

function Get-JavaInfo([string]$JdkPath) {
    $javaExe = Join-Path $JdkPath "bin\java.exe"
    if (-not (Test-Path $javaExe)) { return $null }

    $result = Invoke-CapturedProcess -FilePath $javaExe -Arguments @("-version")
    if ($result.ExitCode -ne 0) { return $null }

    $firstLine = $result.Text -split "`r?`n" |
        Where-Object { $_.Trim() } |
        Select-Object -First 1

    if ($firstLine -match 'version\s+"(?<major>\d+)') {
        return [pscustomobject]@{
            Major = [int]$Matches.major
            FirstLine = $firstLine
        }
    }
    return $null
}

function Find-CompatibleJdk17 {
    $candidates = @($env:JAVA_HOME)
    foreach ($root in @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Java"
    )) {
        if (Test-Path $root) {
            $candidates += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'jdk-17|jdk17' } |
                ForEach-Object { $_.FullName }
        }
    }

    foreach ($candidate in $candidates | Where-Object { $_ } | Select-Object -Unique) {
        $info = Get-JavaInfo $candidate
        if ($info -and $info.Major -eq 17) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Ensure-Jdk17 {
    $jdk = Find-CompatibleJdk17
    if (-not $jdk) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "JDK 17 is required. Install Eclipse Temurin JDK 17 and run again."
        }

        Write-Host "Installing Eclipse Temurin JDK 17..." -ForegroundColor Yellow
        & winget install --id EclipseAdoptium.Temurin.17.JDK --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "JDK 17 installation failed with exit code $LASTEXITCODE."
        }
        $jdk = Find-CompatibleJdk17
    }

    if (-not $jdk) { throw "JDK 17 could not be detected after installation." }

    $env:JAVA_HOME = $jdk
    $jdkBin = Join-Path $jdk "bin"
    $filteredPath = $env:Path -split ';' | Where-Object {
        $_ -and
        $_ -notmatch '\\Java\\' -and
        $_ -notmatch '\\jdk-' -and
        $_ -notmatch 'Android Studio\\jbr'
    }
    $env:Path = "$jdkBin;" + ($filteredPath -join ';')
    $env:GRADLE_JAVA_HOME = $jdk
    Remove-Item Env:GRADLE_OPTS -ErrorAction SilentlyContinue
    Remove-Item Env:JAVA_TOOL_OPTIONS -ErrorAction SilentlyContinue

    $info = Get-JavaInfo $jdk
    Write-Host "Using JDK 17: $jdk" -ForegroundColor Green
    Write-Host $info.FirstLine -ForegroundColor Cyan

    & flutter config --jdk-dir $jdk | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Flutter JDK configuration failed." }
    return $jdk
}

function Pin-GradleJdk([string]$Root, [string]$JdkPath) {
    $propertiesPath = Join-Path $Root "android\gradle.properties"
    $content = if (Test-Path $propertiesPath) { Get-Content $propertiesPath -Raw } else { "" }
    $escaped = $JdkPath -replace '\\', '\\'
    $line = "org.gradle.java.home=$escaped"

    if ($content -match '(?m)^org\.gradle\.java\.home=.*$') {
        $content = [regex]::Replace($content, '(?m)^org\.gradle\.java\.home=.*$', $line)
    }
    else {
        if ($content -and -not $content.EndsWith("`n")) { $content += "`r`n" }
        $content += "$line`r`n"
    }

    [System.IO.File]::WriteAllText(
        $propertiesPath,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host "Pinned Gradle JDK: $propertiesPath" -ForegroundColor Green
}

function Stop-GradleDaemons([string]$Root) {
    $androidDir = Join-Path $Root "android"
    $gradlew = Join-Path $androidDir "gradlew.bat"
    if (Test-Path $gradlew) {
        $null = Invoke-CapturedProcess -FilePath $gradlew -Arguments @("--stop") -WorkingDirectory $androidDir
    }

    Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'GradleDaemon|gradle-launcher' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Verify-GradleJdk17([string]$Root) {
    $androidDir = Join-Path $Root "android"
    $gradlew = Join-Path $androidDir "gradlew.bat"
    if (-not (Test-Path $gradlew)) { throw "Gradle wrapper not found." }

    $result = Invoke-CapturedProcess -FilePath $gradlew -Arguments @("--version", "--no-daemon") -WorkingDirectory $androidDir
    Write-Host $result.Text

    if ($result.ExitCode -ne 0) {
        throw "Gradle verification failed with exit code $($result.ExitCode)."
    }

    $launcherIs17 = $result.Text -match '(?im)^Launcher JVM:\s+17(?:\.|\s)'
    $legacyIs17 = $result.Text -match '(?im)^JVM:\s+17(?:\.|\s)'
    $daemonUsesPinnedJdk = $result.Text -match '(?im)^Daemon JVM:.*\(from org\.gradle\.java\.home\)'

    if (-not ($launcherIs17 -or $legacyIs17)) {
        throw "Gradle launcher is not using JDK 17."
    }
    if (-not $daemonUsesPinnedJdk) {
        Write-Warning "Gradle launcher is JDK 17, but the daemon JDK source could not be confirmed."
    }

    Write-Host "Gradle confirmed on JDK 17." -ForegroundColor Green
}

function Get-OnlineDevice([string]$Adb) {
    foreach ($line in (& $Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') {
            return $Matches[1]
        }
    }
    return $null
}

function Save-CrashLog([string]$Adb, [string]$Device, [string]$Destination) {
    Write-Host "Collecting Android crash log..." -ForegroundColor Yellow
    & $Adb -s $Device logcat -d -v time "AndroidRuntime:E" "flutter:E" "ActivityManager:E" "*:S" 2>&1 |
        Out-File -FilePath $Destination -Encoding utf8
    Write-Host "Crash log: $Destination" -ForegroundColor Cyan
}

try {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " CARGO SORT - COLD BOOT AND RUN" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan

    $ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    Set-Location $ProjectPath

    $jdk = Ensure-Jdk17
    Pin-GradleJdk $ProjectPath $jdk
    Stop-GradleDaemons $ProjectPath
    Verify-GradleJdk17 $ProjectPath

    $sdk = Find-AndroidSdk
    $adb = Join-Path $sdk "platform-tools\adb.exe"
    $emulator = Join-Path $sdk "emulator\emulator.exe"
    if (-not (Test-Path $emulator)) { throw "Android Emulator was not found." }

    & $adb start-server | Out-Null
    $device = Get-OnlineDevice $adb

    if (-not $device) {
        $avds = @(& $emulator -list-avds | Where-Object { $_.Trim() })
        if ($avds.Count -eq 0) { throw "No Android Virtual Device exists." }

        $selectedAvd = if ($AvdName) { $AvdName } else { $avds[0] }
        if ($avds -notcontains $selectedAvd) { throw "AVD not found: $selectedAvd" }

        $snapshotFolder = Join-Path $env:USERPROFILE ".android\avd\$selectedAvd.avd\snapshots"
        Remove-Item $snapshotFolder -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Starting $selectedAvd with clean cold boot..." -ForegroundColor Yellow
        Start-Process -FilePath $emulator -ArgumentList @(
            "-avd", $selectedAvd,
            "-no-snapshot-load",
            "-no-snapshot-save",
            "-no-boot-anim"
        ) | Out-Null

        $deadline = (Get-Date).AddMinutes(8)
        do {
            Start-Sleep -Seconds 3
            $device = Get-OnlineDevice $adb
            if ((Get-Date) -gt $deadline) { throw "Timed out waiting for emulator." }
        } until ($device)

        & $adb -s $device wait-for-device | Out-Null
        do {
            Start-Sleep -Seconds 3
            $boot = (& $adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
            if ((Get-Date) -gt $deadline) { throw "Timed out waiting for Android boot." }
        } until ($boot -eq "1")
    }

    Write-Host "Device ready: $device" -ForegroundColor Green
    & $adb -s $device logcat -c

    Write-Host "Restoring packages..." -ForegroundColor Cyan
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed with exit code $LASTEXITCODE" }

    Write-Host "Running application with JDK 17..." -ForegroundColor Cyan
    & flutter run --no-pub -d $device
    $runExitCode = $LASTEXITCODE

    if ($runExitCode -ne 0) {
        Save-CrashLog $adb $device (Join-Path $ProjectPath "android_crash_log.txt")
        throw "flutter run failed with exit code $runExitCode"
    }
}
catch {
    Write-Host ""
    Write-Host "COLD BOOT RUN FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed }

    try {
        if ($adb -and $device) {
            Save-CrashLog $adb $device (Join-Path $ProjectPath "android_crash_log.txt")
        }
    }
    catch { }
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close")
}
