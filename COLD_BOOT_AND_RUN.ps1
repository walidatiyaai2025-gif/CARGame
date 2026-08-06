param(
    [string]$AvdName = "",
    [string]$ProjectPath = $PSScriptRoot,
    [string]$PackageId = "com.walka.cargosort"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Pause-Tool {
    Write-Host ""
    [void](Read-Host "Press Enter to continue")
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ""
    )

    if ($WorkingDirectory) { Push-Location $WorkingDirectory }
    try {
        Write-Host "> $Command $($Arguments -join ' ')" -ForegroundColor DarkGray
        & $Command @Arguments
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            throw "Command failed with exit code ${code}: $Command $($Arguments -join ' ')"
        }
    }
    finally {
        if ($WorkingDirectory) { Pop-Location }
    }
}

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

        [pscustomobject]@{
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

    $firstLine = $result.Text -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1
    if ($firstLine -match 'version\s+"(?<major>\d+)') {
        return [pscustomobject]@{ Major = [int]$Matches.major; FirstLine = $firstLine }
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

function Configure-FlutterJdk([string]$JdkPath) {
    $flutterBat = (Get-Command flutter.bat -ErrorAction SilentlyContinue).Source
    if (-not $flutterBat) {
        $flutterBat = (Get-Command flutter -ErrorAction Stop).Source
    }

    # cmd.exe preserves the quoted JDK path as one argument, including Program Files.
    $escapedFlutter = $flutterBat.Replace('"', '\"')
    $escapedJdk = $JdkPath.Replace('"', '\"')
    $commandLine = '"{0}" config --jdk-dir "{1}"' -f $escapedFlutter, $escapedJdk

    $result = Invoke-CapturedProcess `
        -FilePath $env:ComSpec `
        -Arguments @('/d', '/s', '/c', $commandLine)

    if ($result.Text) { Write-Host $result.Text }
    if ($result.ExitCode -ne 0) {
        throw "Flutter JDK configuration failed with exit code $($result.ExitCode)."
    }
}

function Ensure-Jdk17 {
    $jdk = Find-CompatibleJdk17
    if (-not $jdk) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "JDK 17 is required. Install Eclipse Temurin JDK 17 and run again."
        }

        Write-Host "Installing Eclipse Temurin JDK 17..." -ForegroundColor Yellow
        Invoke-Checked "winget" @(
            "install", "--id", "EclipseAdoptium.Temurin.17.JDK", "--exact", "--silent",
            "--accept-package-agreements", "--accept-source-agreements"
        )
        $jdk = Find-CompatibleJdk17
    }

    if (-not $jdk) { throw "JDK 17 could not be detected after installation." }
    $jdk = [System.IO.Path]::GetFullPath([string]$jdk)

    $env:JAVA_HOME = $jdk
    $jdkBin = Join-Path $jdk "bin"
    $filteredPath = $env:Path -split ';' | Where-Object {
        $_ -and $_ -notmatch '\\Java\\' -and $_ -notmatch '\\jdk-' -and $_ -notmatch 'Android Studio\\jbr'
    }
    $env:Path = "$jdkBin;" + ($filteredPath -join ';')
    Remove-Item Env:GRADLE_OPTS -ErrorAction SilentlyContinue
    Remove-Item Env:JAVA_TOOL_OPTIONS -ErrorAction SilentlyContinue

    $info = Get-JavaInfo $jdk
    Write-Host "Using JDK 17: $jdk" -ForegroundColor Green
    Write-Host $info.FirstLine -ForegroundColor Cyan

    Configure-FlutterJdk $jdk
    return ,$jdk
}

function Pin-GradleJdk([string]$Root, [string]$JdkPath) {
    $cleanJdkPath = ([string]$JdkPath).Trim()
    if (-not (Test-Path (Join-Path $cleanJdkPath "bin\java.exe"))) {
        throw "Invalid JDK path received by Gradle configuration: $cleanJdkPath"
    }

    $propertiesPath = Join-Path $Root "android\gradle.properties"
    $content = if (Test-Path $propertiesPath) { Get-Content $propertiesPath -Raw } else { "" }
    $escaped = $cleanJdkPath -replace '\\', '\\'
    $line = "org.gradle.java.home=$escaped"

    if ($content -match '(?m)^org\.gradle\.java\.home=.*$') {
        $content = [regex]::Replace($content, '(?m)^org\.gradle\.java\.home=.*$', $line)
    }
    else {
        if ($content -and -not $content.EndsWith("`n")) { $content += "`r`n" }
        $content += "$line`r`n"
    }

    [System.IO.File]::WriteAllText($propertiesPath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Pinned Gradle JDK: $cleanJdkPath" -ForegroundColor Green
}

function Verify-GradleJdk17([string]$Root) {
    $androidDir = Join-Path $Root "android"
    $gradlew = Join-Path $androidDir "gradlew.bat"
    $result = Invoke-CapturedProcess -FilePath $gradlew -Arguments @("--version", "--no-daemon") -WorkingDirectory $androidDir
    if ($result.Text) { Write-Host $result.Text }
    if ($result.ExitCode -ne 0) { throw "Gradle verification failed.`n$($result.Text)" }
    if ($result.Text -notmatch '(?im)^(Launcher JVM|JVM):\s+17(?:\.|\s)') {
        throw "Gradle launcher is not using JDK 17.`n$($result.Text)"
    }
    Write-Host "Gradle confirmed on JDK 17." -ForegroundColor Green
}

function Initialize-Environment {
    $script:ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
    Set-Location $script:ProjectPath

    $jdk = Ensure-Jdk17
    Pin-GradleJdk $script:ProjectPath ([string]$jdk)
    Verify-GradleJdk17 $script:ProjectPath

    $script:Sdk = Find-AndroidSdk
    $script:Adb = Join-Path $script:Sdk "platform-tools\adb.exe"
    $script:Emulator = Join-Path $script:Sdk "emulator\emulator.exe"
    if (-not (Test-Path $script:Emulator)) { throw "Android Emulator was not found." }
}

function Get-OnlineDevice {
    foreach ($line in (& $script:Adb devices)) {
        if ($line -match '^([^\s]+)\s+device$' -and $Matches[1] -ne 'List') { return $Matches[1] }
    }
    return $null
}

function Start-AndroidDevice([bool]$ColdBoot) {
    & $script:Adb start-server | Out-Null
    $device = Get-OnlineDevice
    if ($device) { return $device }

    $avds = @(& $script:Emulator -list-avds | Where-Object { $_.Trim() })
    if ($avds.Count -eq 0) { throw "No Android Virtual Device exists." }
    $selected = if ($AvdName) { $AvdName } else { $avds[0] }
    if ($avds -notcontains $selected) { throw "AVD not found: $selected" }

    $args = @("-avd", $selected, "-no-boot-anim")
    if ($ColdBoot) {
        Remove-Item (Join-Path $env:USERPROFILE ".android\avd\$selected.avd\snapshots") -Recurse -Force -ErrorAction SilentlyContinue
        $args += @("-no-snapshot-load", "-no-snapshot-save")
    }

    Write-Host "Starting emulator: $selected" -ForegroundColor Yellow
    Start-Process -FilePath $script:Emulator -ArgumentList $args | Out-Null

    $deadline = (Get-Date).AddMinutes(8)
    do {
        Start-Sleep -Seconds 3
        $device = Get-OnlineDevice
        if ((Get-Date) -gt $deadline) { throw "Timed out waiting for emulator." }
    } until ($device)

    & $script:Adb -s $device wait-for-device | Out-Null
    do {
        Start-Sleep -Seconds 3
        $boot = (& $script:Adb -s $device shell getprop sys.boot_completed 2>$null).Trim()
        if ((Get-Date) -gt $deadline) { throw "Timed out waiting for Android boot." }
    } until ($boot -eq "1")
    return $device
}

function Restore-Packages {
    Invoke-Checked "flutter" @("pub", "get") $script:ProjectPath
}

function Build-Debug {
    Restore-Packages
    Invoke-Checked "flutter" @("build", "apk", "--debug", "--no-pub") $script:ProjectPath
    Write-Host "Debug APK: $(Join-Path $script:ProjectPath 'build\app\outputs\flutter-apk\app-debug.apk')" -ForegroundColor Green
}

function Build-Release {
    Restore-Packages
    Invoke-Checked "flutter" @("build", "apk", "--release", "--no-pub") $script:ProjectPath
    Write-Host "Release APK: $(Join-Path $script:ProjectPath 'build\app\outputs\flutter-apk\app-release.apk')" -ForegroundColor Green
}

function Build-AppBundle {
    Restore-Packages
    Invoke-Checked "flutter" @("build", "appbundle", "--release", "--no-pub") $script:ProjectPath
    Write-Host "AAB: $(Join-Path $script:ProjectPath 'build\app\outputs\bundle\release\app-release.aab')" -ForegroundColor Green
}

function Install-Apk([string]$ApkPath) {
    if (-not (Test-Path $ApkPath)) { throw "APK not found: $ApkPath" }
    $device = Start-AndroidDevice $false
    Invoke-Checked $script:Adb @("-s", $device, "install", "-r", $ApkPath)
    Invoke-Checked $script:Adb @("-s", $device, "shell", "am", "start", "-n", "$PackageId/.MainActivity")
}

function Update-FromGitHub {
    Invoke-Checked "git" @("fetch", "origin") $script:ProjectPath
    Invoke-Checked "git" @("reset", "--hard", "origin/main") $script:ProjectPath
}

function Diagnose {
    $report = Join-Path $script:ProjectPath "diagnostics_report.txt"
    $lines = @("Generated: $(Get-Date -Format s)", "Project: $script:ProjectPath", "")

    foreach ($command in @(
        @{ File = "flutter"; Args = @("--version") },
        @{ File = "flutter"; Args = @("doctor", "-v") },
        @{ File = "git"; Args = @("status", "--short", "--branch") },
        @{ File = (Join-Path $script:ProjectPath "android\gradlew.bat"); Args = @("--version", "--no-daemon"); Dir = (Join-Path $script:ProjectPath "android") }
    )) {
        $result = Invoke-CapturedProcess -FilePath $command.File -Arguments $command.Args -WorkingDirectory $command.Dir
        $lines += "> $($command.File) $($command.Args -join ' ')"
        $lines += $result.Text
        $lines += ""
    }

    $lines += "> adb devices"
    $lines += (& $script:Adb devices | Out-String)
    [System.IO.File]::WriteAllLines($report, $lines, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Diagnostics report: $report" -ForegroundColor Green
}

function Show-Menu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "       CARGO SORT DEVELOPMENT TOOL" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Project: $script:ProjectPath"
    Write-Host ""
    Write-Host " 1  - Run Debug on device/emulator"
    Write-Host " 2  - Build Debug APK"
    Write-Host " 3  - Build Release APK"
    Write-Host " 4  - Build Release App Bundle (AAB)"
    Write-Host " 5  - Build + Install Debug APK"
    Write-Host " 6  - Build + Install Release APK"
    Write-Host " 7  - Flutter clean + pub get"
    Write-Host " 8  - Flutter analyze"
    Write-Host " 9  - Start emulator only"
    Write-Host "10  - Cold boot emulator only"
    Write-Host "11  - Update project from GitHub"
    Write-Host "12  - Update + clean + run Debug"
    Write-Host "99  - Diagnose environment"
    Write-Host " 0  - Exit"
    Write-Host ""
}

try {
    Initialize-Environment

    while ($true) {
        Show-Menu
        $choice = Read-Host "Choose an option"
        try {
            switch ($choice) {
                "1" {
                    $device = Start-AndroidDevice $false
                    Restore-Packages
                    Invoke-Checked "flutter" @("run", "--no-pub", "-d", $device) $script:ProjectPath
                }
                "2" { Build-Debug }
                "3" { Build-Release }
                "4" { Build-AppBundle }
                "5" {
                    Build-Debug
                    Install-Apk (Join-Path $script:ProjectPath "build\app\outputs\flutter-apk\app-debug.apk")
                }
                "6" {
                    Build-Release
                    Install-Apk (Join-Path $script:ProjectPath "build\app\outputs\flutter-apk\app-release.apk")
                }
                "7" {
                    Invoke-Checked "flutter" @("clean") $script:ProjectPath
                    Restore-Packages
                }
                "8" { Invoke-Checked "flutter" @("analyze", "--no-fatal-infos") $script:ProjectPath }
                "9" { [void](Start-AndroidDevice $false); Write-Host "Emulator is ready." -ForegroundColor Green }
                "10" { [void](Start-AndroidDevice $true); Write-Host "Cold-boot emulator is ready." -ForegroundColor Green }
                "11" { Update-FromGitHub; Write-Host "Project updated." -ForegroundColor Green }
                "12" {
                    Update-FromGitHub
                    Invoke-Checked "flutter" @("clean") $script:ProjectPath
                    $device = Start-AndroidDevice $true
                    Restore-Packages
                    Invoke-Checked "flutter" @("run", "--no-pub", "-d", $device) $script:ProjectPath
                }
                "99" { Diagnose }
                "0" { break }
                default { Write-Warning "Invalid option." }
            }
        }
        catch {
            Write-Host ""
            Write-Host "OPERATION FAILED" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed }
        }

        if ($choice -eq "0") { break }
        Pause-Tool
    }
}
catch {
    Write-Host ""
    Write-Host "CARGO SORT TOOL FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed }
    Pause-Tool
}
