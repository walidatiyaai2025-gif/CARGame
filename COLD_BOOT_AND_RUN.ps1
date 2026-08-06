param(
    [string]$AvdName = "",
    [string]$ProjectPath = $PSScriptRoot,
    [string]$PackageId = "com.walka.cargosort"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

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

function Get-JavaMajor([string]$JdkPath) {
    $javaExe = Join-Path $JdkPath "bin\java.exe"
    if (-not (Test-Path $javaExe)) { return $null }
    $versionText = (& $javaExe -version 2>&1 | Select-Object -First 1).ToString()
    if ($versionText -match 'version\s+"(?<major>\d+)') {
        return [int]$Matches.major
    }
    return $null
}

function Find-CompatibleJdk {
    $candidates = @(
        $env:JAVA_HOME,
        "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot",
        "C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot",
        "C:\Program Files\Microsoft\jdk-17.0.16.8-hotspot",
        "C:\Program Files\Microsoft\jdk-17.0.15.6-hotspot"
    )

    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Java"
    )
    foreach ($root in $roots) {
        if (Test-Path $root) {
            $candidates += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'jdk-17|jdk17' } |
                ForEach-Object { $_.FullName }
        }
    }

    foreach ($candidate in $candidates | Where-Object { $_ } | Select-Object -Unique) {
        $major = Get-JavaMajor $candidate
        if ($major -eq 17) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Ensure-CompatibleJdk {
    $jdk = Find-CompatibleJdk
    if (-not $jdk) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw "JDK 17 is required but was not found. Install Eclipse Temurin JDK 17, then run this script again."
        }

        Write-Host "JDK 17 was not found. Installing Eclipse Temurin JDK 17..." -ForegroundColor Yellow
        & winget install --id EclipseAdoptium.Temurin.17.JDK --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Automatic JDK 17 installation failed with exit code $LASTEXITCODE."
        }
        $jdk = Find-CompatibleJdk
    }

    if (-not $jdk) {
        throw "JDK 17 installation completed but its folder could not be detected. Restart PowerShell and run again."
    }

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
    $env:GRADLE_OPTS = "-Dorg.gradle.java.home=$($jdk -replace '\\','/') --enable-native-access=ALL-UNNAMED"
    $env:JAVA_TOOL_OPTIONS = "--enable-native-access=ALL-UNNAMED"

    Write-Host "Using JDK 17: $jdk" -ForegroundColor Green
    & flutter config --jdk-dir $jdk
    if ($LASTEXITCODE -ne 0) { throw "Could not configure Flutter to use JDK 17." }

    $javaVersion = & (Join-Path $jdk "bin\java.exe") -version 2>&1
    $javaVersion | Select-Object -First 1 | Write-Host -ForegroundColor Cyan
    return $jdk
}

function Force-ProjectGradleJdk([string]$Root, [string]$JdkPath) {
    $propertiesPath = Join-Path $Root "android\gradle.properties"
    if (-not (Test-Path $propertiesPath)) {
        New-Item -ItemType File -Path $propertiesPath -Force | Out-Null
    }

    $content = Get-Content $propertiesPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = "" }

    $javaHomeValue = $JdkPath -replace '\\', '\\'
    $line = "org.gradle.java.home=$javaHomeValue"

    if ($content -match '(?m)^org\.gradle\.java\.home=.*$') {
        $content = [regex]::Replace(
            $content,
            '(?m)^org\.gradle\.java\.home=.*$',
            $line
        )
    }
    else {
        if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
            $content += "`r`n"
        }
        $content += "$line`r`n"
    }

    [System.IO.File]::WriteAllText(
        $propertiesPath,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host "Pinned Gradle JDK in: $propertiesPath" -ForegroundColor Green
}

function Stop-GradleDaemons([string]$Root) {
    $gradlew = Join-Path $Root "android\gradlew.bat"
    if (Test-Path $gradlew) {
        Write-Host "Stopping old Gradle daemons..." -ForegroundColor DarkGray
        Push-Location (Split-Path $gradlew -Parent)
        try { & $gradlew --stop 2>$null | Out-Null } catch { }
        finally { Pop-Location }
    }

    Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'GradleDaemon|gradle-launcher' } |
        ForEach-Object {
            try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch { }
        }
}

function Verify-GradleJdk([string]$Root) {
    $gradlew = Join-Path $Root "android\gradlew.bat"
    if (-not (Test-Path $gradlew)) { throw "Gradle wrapper was not found: $gradlew" }

    Push-Location (Split-Path $gradlew -Parent)
    try {
        $output = & $gradlew --version --no-daemon 2>&1
        $exitCode = $LASTEXITCODE
        $output | ForEach-Object { Write-Host $_ }
        if ($exitCode -ne 0) {
            throw "Gradle JDK verification failed with exit code $exitCode."
        }

        $text = ($output | Out-String)
        if ($text -notmatch '(?im)^JVM:\s+17(?:\.|\s)') {
            throw "Gradle is still not using JDK 17. Check android\gradle.properties and Flutter JDK configuration."
        }
        Write-Host "Gradle confirmed on JDK 17." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
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
    & $Adb -s $Device logcat -d -v time `
        "AndroidRuntime:E" `
        "flutter:E" `
        "ActivityManager:E" `
        "*:S" 2>&1 | Out-File -FilePath $Destination -Encoding utf8
    Write-Host "Crash log: $Destination" -ForegroundColor Cyan
}

try {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " CARGO SORT - COLD BOOT AND RUN" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan

    $ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    Set-Location $ProjectPath

    $jdk = Ensure-CompatibleJdk
    Force-ProjectGradleJdk $ProjectPath $jdk
    Stop-GradleDaemons $ProjectPath
    Verify-GradleJdk $ProjectPath

    $sdk = Find-AndroidSdk
    $adb = Join-Path $sdk "platform-tools\adb.exe"
    $emulator = Join-Path $sdk "emulator\emulator.exe"

    if (-not (Test-Path $emulator)) {
        throw "Android Emulator was not found: $emulator"
    }

    & $adb start-server | Out-Null
    $device = Get-OnlineDevice $adb

    if (-not $device) {
        $avds = @(& $emulator -list-avds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($avds.Count -eq 0) {
            throw "No Android Virtual Device exists. Create one in Android Studio Device Manager."
        }

        $selectedAvd = if ($AvdName) { $AvdName } else { $avds[0] }
        if ($avds -notcontains $selectedAvd) {
            throw "AVD '$selectedAvd' was not found. Available: $($avds -join ', ')"
        }

        $snapshotFolder = Join-Path $env:USERPROFILE ".android\avd\$selectedAvd.avd\snapshots"
        if (Test-Path $snapshotFolder) {
            Write-Host "Removing incompatible snapshots: $snapshotFolder" -ForegroundColor Yellow
            Remove-Item $snapshotFolder -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Starting $selectedAvd with a clean cold boot..." -ForegroundColor Yellow
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
            if ((Get-Date) -gt $deadline) {
                throw "Timed out waiting for the emulator device."
            }
        } until ($device)

        & $adb -s $device wait-for-device | Out-Null
        do {
            Start-Sleep -Seconds 3
            $bootCompleted = (& $adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
            if ((Get-Date) -gt $deadline) {
                throw "Timed out waiting for Android to finish booting."
            }
        } until ($bootCompleted -eq "1")
    }

    Write-Host "Device ready: $device" -ForegroundColor Green
    & $adb -s $device logcat -c

    Write-Host "Restoring packages..." -ForegroundColor Cyan
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed with exit code $LASTEXITCODE" }

    Write-Host "Running application with forced JDK 17..." -ForegroundColor Cyan
    & flutter run --no-pub -d $device
    $runExitCode = $LASTEXITCODE

    if ($runExitCode -ne 0) {
        $logPath = Join-Path $ProjectPath "android_crash_log.txt"
        Save-CrashLog $adb $device $logPath
        throw "flutter run failed with exit code $runExitCode"
    }
}
catch {
    Write-Host ""
    Write-Host "COLD BOOT RUN FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    try {
        if ($adb -and $device) {
            $fallbackLog = Join-Path $ProjectPath "android_crash_log.txt"
            Save-CrashLog $adb $device $fallbackLog
        }
    } catch {
        Write-Warning "Could not collect Logcat: $($_.Exception.Message)"
    }
}
finally {
    Write-Host ""
    [void](Read-Host "Press Enter to close")
}
