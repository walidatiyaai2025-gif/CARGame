[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:ToolName = "CARGame Setup Tool"
$Script:ToolVersion = "1.0.0"
$Script:OriginalLocation = Get-Location
$Script:ProjectPath = if ($ProjectPath) { $ProjectPath } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot ".git"))) { $PSScriptRoot } else { "D:\Apps\CARGame" }
$Script:LogDirectory = Join-Path $Script:ProjectPath "logs\setup_tool"
$Script:LogFile = $null
$Script:LastFailure = $null

function Initialize-Logging {
    try {
        New-Item -ItemType Directory -Path $Script:LogDirectory -Force | Out-Null
    } catch {
        $fallback = Join-Path $env:TEMP "CARGame_SetupTool_Logs"
        New-Item -ItemType Directory -Path $fallback -Force | Out-Null
        $Script:LogDirectory = $fallback
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Script:LogFile = Join-Path $Script:LogDirectory "setup_tool_$stamp.log"
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $($Script:ToolName) v$($Script:ToolVersion) started" | Set-Content -Path $Script:LogFile -Encoding UTF8
}

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "OK", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    try { Add-Content -Path $Script:LogFile -Value $line -Encoding UTF8 } catch { }

    switch ($Level) {
        "OK"    { Write-Host $line -ForegroundColor Green }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Cyan }
    }
}

function Show-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host " $($Script:ToolName) v$($Script:ToolVersion)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host "Project : $($Script:ProjectPath)"
    Write-Host "Repo    : $RepositoryUrl"
    Write-Host "Branch  : $Branch"
    Write-Host "Log     : $($Script:LogFile)"
    Write-Host ""
}

function Pause-Tool {
    Write-Host ""
    [void](Read-Host "Press Enter to continue")
}

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$Step = $FilePath,
        [switch]$AllowFailure,
        [switch]$Quiet
    )

    $display = "$FilePath $($Arguments -join ' ')".Trim()
    Write-Log "$Step -> $display"
    $start = Get-Date

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if (-not $Quiet) {
        foreach ($line in @($output)) {
            if ($null -ne $line) { Write-Host $line }
        }
    }

    try {
        foreach ($line in @($output)) {
            if ($null -ne $line) { Add-Content -Path $Script:LogFile -Value "    $line" -Encoding UTF8 }
        }
    } catch { }

    $duration = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    if ($exitCode -eq 0) {
        Write-Log "$Step completed in ${duration}s" "OK"
    } else {
        $Script:LastFailure = [pscustomobject]@{
            Step = $Step
            Command = $display
            ExitCode = $exitCode
            Output = (@($output) -join [Environment]::NewLine)
        }
        Write-Log "$Step failed with exit code $exitCode" "ERROR"
        if (-not $AllowFailure) {
            throw "$Step failed with exit code $exitCode."
        }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output)
    }
}

function Test-Internet {
    try {
        $result = Test-NetConnection -ComputerName github.com -Port 443 -WarningAction SilentlyContinue
        if (-not $result.TcpTestSucceeded) { throw "github.com:443 is not reachable." }
        Write-Log "GitHub connectivity OK" "OK"
        return $true
    } catch {
        Write-Log "Internet/GitHub connectivity check failed: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Test-RepositoryFolder {
    return (Test-Path (Join-Path $Script:ProjectPath ".git"))
}

function Enter-Project {
    if (-not (Test-Path $Script:ProjectPath)) {
        throw "Project folder does not exist: $($Script:ProjectPath)"
    }
    Set-Location $Script:ProjectPath
}

function Ensure-GitRemote {
    Enter-Project
    $remotes = Invoke-Native "git" @("remote") "Read Git remotes" -Quiet
    if ($remotes.Output -notcontains "origin") {
        Invoke-Native "git" @("remote", "add", "origin", $RepositoryUrl) "Add origin remote" | Out-Null
        return
    }

    $current = (Invoke-Native "git" @("remote", "get-url", "origin") "Read origin URL" -Quiet).Output | Select-Object -First 1
    if ($current -ne $RepositoryUrl) {
        Write-Log "Origin URL differs. Updating origin to configured repository." "WARN"
        Invoke-Native "git" @("remote", "set-url", "origin", $RepositoryUrl) "Update origin remote" | Out-Null
    }
}

function Remove-StaleGitLocks {
    if (-not (Test-RepositoryFolder)) { return }
    $locks = @(
        (Join-Path $Script:ProjectPath ".git\index.lock"),
        (Join-Path $Script:ProjectPath ".git\shallow.lock")
    )
    foreach ($lock in $locks) {
        if (Test-Path $lock) {
            Write-Log "Removing stale Git lock: $lock" "WARN"
            Remove-Item $lock -Force -ErrorAction SilentlyContinue
        }
    }
}

function Stop-GradleDaemons {
    $gradlew = Join-Path $Script:ProjectPath "android\gradlew.bat"
    if (Test-Path $gradlew) {
        Push-Location (Join-Path $Script:ProjectPath "android")
        try { Invoke-Native ".\gradlew.bat" @("--stop") "Stop Gradle daemons" -AllowFailure | Out-Null } finally { Pop-Location }
    }
}

function Repair-FlutterCaches {
    Enter-Project
    Write-Log "Starting Flutter/Gradle cache recovery"
    Stop-GradleDaemons

    $targets = @(
        (Join-Path $Script:ProjectPath "build"),
        (Join-Path $Script:ProjectPath ".dart_tool"),
        (Join-Path $Script:ProjectPath "android\.gradle")
    )

    foreach ($target in $targets) {
        if (Test-Path $target) {
            Write-Log "Removing cache: $target"
            Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Invoke-Native "flutter" @("clean") "Flutter clean" -AllowFailure | Out-Null
    Invoke-Native "flutter" @("pub", "get") "Flutter pub get" | Out-Null
}

function Repair-Git {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) {
        Write-Log "No Git repository found. Git repair skipped." "WARN"
        return
    }

    Remove-StaleGitLocks
    Ensure-GitRemote
    Enter-Project
    Invoke-Native "git" @("fsck", "--no-progress") "Git repository check" -AllowFailure | Out-Null
    Invoke-Native "git" @("fetch", "--prune", "origin") "Git fetch/prune" -AllowFailure | Out-Null
}

function First-Download {
    Assert-Command "git"
    [void](Test-Internet)

    if (Test-RepositoryFolder) {
        Write-Log "Repository already exists. Running safe update instead." "WARN"
        Update-Project
        return
    }

    if (Test-Path $Script:ProjectPath) {
        $items = @(Get-ChildItem $Script:ProjectPath -Force -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            $backup = "$($Script:ProjectPath)_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Log "Target folder is not empty. Moving it to: $backup" "WARN"
            Move-Item $Script:ProjectPath $backup -Force
        }
    }

    $parent = Split-Path $Script:ProjectPath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    Invoke-Native "git" @("clone", "--branch", $Branch, "--single-branch", $RepositoryUrl, $Script:ProjectPath) "Clone repository" | Out-Null
    Enter-Project

    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Invoke-Native "flutter" @("pub", "get") "Restore Flutter packages" -AllowFailure | Out-Null
    }

    Write-Log "First download completed" "OK"
}

function Get-GitDirtyState {
    Enter-Project
    $result = Invoke-Native "git" @("status", "--porcelain") "Check local changes" -Quiet
    return @($result.Output).Count -gt 0
}

function Update-Project {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) {
        First-Download
        return
    }

    Repair-Git
    Enter-Project

    $stashed = $false
    if (Get-GitDirtyState) {
        Write-Log "Local changes detected. Stashing them before update." "WARN"
        $stash = Invoke-Native "git" @("stash", "push", "-u", "-m", "SETUP_TOOL_AUTO_STASH_$(Get-Date -Format 'yyyyMMdd_HHmmss')") "Stash local changes" -AllowFailure
        $stashed = ($stash.ExitCode -eq 0)
        if (-not $stashed) { throw "Unable to protect local changes before update." }
    }

    Invoke-Native "git" @("fetch", "origin", $Branch) "Fetch origin/$Branch" | Out-Null
    $checkout = Invoke-Native "git" @("checkout", $Branch) "Checkout $Branch" -AllowFailure
    if ($checkout.ExitCode -ne 0) {
        Invoke-Native "git" @("checkout", "-b", $Branch, "origin/$Branch") "Create local $Branch" | Out-Null
    }

    $pull = Invoke-Native "git" @("pull", "--rebase", "origin", $Branch) "Update project" -AllowFailure
    if ($pull.ExitCode -ne 0) {
        Write-Log "Rebase update failed. Aborting rebase and trying fast-forward-safe recovery." "WARN"
        Invoke-Native "git" @("rebase", "--abort") "Abort failed rebase" -AllowFailure | Out-Null
        Invoke-Native "git" @("fetch", "origin", $Branch) "Refresh origin" | Out-Null
        throw "Automatic update could not be completed safely. Local work was preserved. Review the log before merging manually."
    }

    if ($stashed) {
        $pop = Invoke-Native "git" @("stash", "pop") "Restore local changes" -AllowFailure
        if ($pop.ExitCode -ne 0) {
            Write-Log "Update succeeded, but local changes have conflicts. Your stash was not discarded." "WARN"
        }
    }

    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Invoke-Native "flutter" @("pub", "get") "Restore Flutter packages" -AllowFailure | Out-Null
    }

    Write-Log "Project update completed" "OK"
}

function Upload-Changes {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) { throw "Project is not a Git repository." }
    Repair-Git
    Enter-Project

    $status = Invoke-Native "git" @("status", "--porcelain") "Check upload changes" -Quiet
    if (@($status.Output).Count -eq 0) {
        Write-Log "No local changes to upload." "OK"
        return
    }

    Write-Host ""
    Write-Host "Changed files:" -ForegroundColor Yellow
    @($status.Output) | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    $message = Read-Host "Commit message [Update project]"
    if ([string]::IsNullOrWhiteSpace($message)) { $message = "Update project" }

    Invoke-Native "git" @("add", "-A") "Stage changes" | Out-Null
    Invoke-Native "git" @("commit", "-m", $message) "Commit changes" | Out-Null

    $push = Invoke-Native "git" @("push", "origin", $Branch) "Push changes" -AllowFailure
    if ($push.ExitCode -ne 0) {
        Write-Log "Push failed. Trying safe fetch/rebase once before retry." "WARN"
        Invoke-Native "git" @("fetch", "origin", $Branch) "Refresh before push retry" | Out-Null
        $rebase = Invoke-Native "git" @("rebase", "origin/$Branch") "Rebase before push retry" -AllowFailure
        if ($rebase.ExitCode -ne 0) {
            Invoke-Native "git" @("rebase", "--abort") "Abort push rebase" -AllowFailure | Out-Null
            throw "Push cannot be repaired automatically because a merge conflict or permission problem exists."
        }
        Invoke-Native "git" @("push", "origin", $Branch) "Push retry" | Out-Null
    }

    Write-Log "Upload completed" "OK"
}

function Get-SupportedAndroidDeviceId {
    Assert-Command "flutter"
    $result = Invoke-Native "flutter" @("devices", "--machine") "Discover Flutter devices" -Quiet -AllowFailure
    if ($result.ExitCode -ne 0) { return $null }

    try {
        $json = (@($result.Output) -join [Environment]::NewLine) | ConvertFrom-Json
        $android = @($json | Where-Object { $_.targetPlatform -like "android*" -and $_.isSupported -ne $false })
        if ($android.Count -gt 0) { return $android[0].id }
    } catch {
        Write-Log "Could not parse flutter devices --machine output." "WARN"
    }
    return $null
}

function Start-AnyAndroidEmulator {
    Assert-Command "flutter"
    $result = Invoke-Native "flutter" @("emulators") "List emulators" -Quiet -AllowFailure
    if ($result.ExitCode -ne 0) { return $false }

    $id = $null
    foreach ($line in @($result.Output)) {
        $text = [string]$line
        if ($text -match '^\s*([^\s•]+)\s+•.*•\s+android\s*$') {
            $id = $Matches[1].Trim()
            break
        }
    }

    if (-not $id) {
        Write-Log "No Android emulator was found." "WARN"
        return $false
    }

    Invoke-Native "flutter" @("emulators", "--launch", $id) "Launch Android emulator" -AllowFailure | Out-Null
    Start-Sleep -Seconds 8
    return $true
}

function Run-App {
    Assert-Command "flutter"
    Enter-Project
    $deviceId = Get-SupportedAndroidDeviceId
    if (-not $deviceId) {
        Write-Log "No supported Android device is online. Trying the first available Android emulator." "WARN"
        [void](Start-AnyAndroidEmulator)
        for ($i = 0; $i -lt 12 -and -not $deviceId; $i++) {
            Start-Sleep -Seconds 5
            $deviceId = Get-SupportedAndroidDeviceId
        }
    }

    if ($deviceId) {
        Invoke-Native "flutter" @("run", "-d", $deviceId) "Run application" | Out-Null
    } else {
        throw "No supported Android device became available. Open an Android emulator or connect a supported device, then retry."
    }
}

function Build-Flutter {
    param([ValidateSet("debug", "release")][string]$Mode)
    Assert-Command "flutter"
    Enter-Project

    Invoke-Native "flutter" @("pub", "get") "Restore packages" | Out-Null
    Invoke-Native "dart" @("format", "lib", "test") "Format Dart sources" -AllowFailure | Out-Null
    Invoke-Native "flutter" @("analyze", "--no-fatal-infos", "--no-fatal-warnings") "Flutter analyze" | Out-Null

    $build = Invoke-Native "flutter" @("build", "apk", "--$Mode", "--no-pub") "Build $Mode APK" -AllowFailure
    if ($build.ExitCode -ne 0 -and $build.Output -match "incremental caches|Could not close incremental caches|compile.*Kotlin") {
        Write-Log "Kotlin/Gradle cache failure detected. Applying automatic cache repair and retrying once." "WARN"
        Repair-FlutterCaches
        Invoke-Native "flutter" @("build", "apk", "--$Mode", "--no-pub") "Build $Mode APK after repair" | Out-Null
    } elseif ($build.ExitCode -ne 0) {
        throw "Flutter $Mode build failed. See the log for the compiler output."
    }

    $apk = Join-Path $Script:ProjectPath "build\app\outputs\flutter-apk\app-$Mode.apk"
    if (Test-Path $apk) { Write-Log "APK ready: $apk" "OK" }
}

function Show-Status {
    Show-Header
    Write-Host "Environment" -ForegroundColor Yellow
    foreach ($cmd in @("git", "flutter", "dart", "java")) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        Write-Host ("{0,-10}: {1}" -f $cmd, $(if ($found) { $found.Source } else { "NOT FOUND" }))
    }

    Write-Host ""
    Write-Host "Repository" -ForegroundColor Yellow
    if (-not (Test-RepositoryFolder)) {
        Write-Host "Git repo   : NOT INITIALIZED" -ForegroundColor Yellow
        return
    }

    Enter-Project
    Invoke-Native "git" @("status", "--short", "--branch") "Git status" -AllowFailure | Out-Null
    Invoke-Native "git" @("remote", "-v") "Git remotes" -AllowFailure | Out-Null
    Invoke-Native "git" @("log", "-1", "--oneline") "Latest commit" -AllowFailure | Out-Null
}

function Collect-Diagnostics {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $diagRoot = Join-Path $env:TEMP "CARGame_Diagnostics_$stamp"
    New-Item -ItemType Directory -Path $diagRoot -Force | Out-Null

    try {
        Copy-Item $Script:LogFile (Join-Path $diagRoot "setup_tool.log") -Force -ErrorAction SilentlyContinue

        $summary = New-Object System.Collections.Generic.List[string]
        $summary.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $summary.Add("Project: $($Script:ProjectPath)")
        $summary.Add("Repository: $RepositoryUrl")
        $summary.Add("Branch: $Branch")
        $summary.Add("Windows: $([Environment]::OSVersion.VersionString)")
        $summary.Add("PowerShell: $($PSVersionTable.PSVersion)")
        $summary.Add("PATH: $env:PATH")
        $summary | Set-Content (Join-Path $diagRoot "environment.txt") -Encoding UTF8

        foreach ($cmd in @("git", "flutter", "dart", "java")) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                $args = switch ($cmd) {
                    "git" { @("--version") }
                    "flutter" { @("doctor", "-v") }
                    "dart" { @("--version") }
                    "java" { @("-version") }
                }
                $r = Invoke-Native $cmd $args "Diagnostics $cmd" -AllowFailure -Quiet
                @($r.Output) | Set-Content (Join-Path $diagRoot "$cmd.txt") -Encoding UTF8
            }
        }

        if (Test-RepositoryFolder) {
            Enter-Project
            foreach ($entry in @(
                @{ Name = "git_status.txt"; Args = @("status", "--branch", "--short") },
                @{ Name = "git_remote.txt"; Args = @("remote", "-v") },
                @{ Name = "git_log.txt"; Args = @("log", "-20", "--oneline", "--decorate") }
            )) {
                $r = Invoke-Native "git" $entry.Args "Diagnostics $($entry.Name)" -AllowFailure -Quiet
                @($r.Output) | Set-Content (Join-Path $diagRoot $entry.Name) -Encoding UTF8
            }
        }

        Get-Process | Sort-Object ProcessName | Select-Object ProcessName, Id, Path -ErrorAction SilentlyContinue | Out-File (Join-Path $diagRoot "processes.txt") -Encoding UTF8

        $zip = Join-Path $Script:LogDirectory "CARGame_Diagnostics_$stamp.zip"
        Compress-Archive -Path (Join-Path $diagRoot "*") -DestinationPath $zip -Force
        Write-Log "Diagnostics package created: $zip" "OK"
    } finally {
        Remove-Item $diagRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Repair-All {
    Write-Log "Starting automatic repair" "INFO"
    Assert-Command "git"
    [void](Test-Internet)
    if (Test-RepositoryFolder) { Repair-Git }

    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Repair-FlutterCaches
        Enter-Project
        Invoke-Native "flutter" @("doctor", "-v") "Flutter doctor" -AllowFailure | Out-Null
    } else {
        Write-Log "Flutter is not available in PATH. Git repair completed, Flutter repair skipped." "WARN"
    }

    Write-Log "Automatic repair completed" "OK"
}

function Update-Repair-Run {
    Update-Project
    Repair-All
    Run-App
}

function Full-Repair-Release {
    Repair-All
    Build-Flutter "release"
}

function Show-Failure {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host " OPERATION FAILED" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $ErrorRecord.Exception.Message -ForegroundColor Red

    if ($Script:LastFailure) {
        Write-Host ""
        Write-Host "Step      : $($Script:LastFailure.Step)"
        Write-Host "Command   : $($Script:LastFailure.Command)"
        Write-Host "Exit Code : $($Script:LastFailure.ExitCode)"
    }

    Write-Host ""
    Write-Host "Full log: $($Script:LogFile)" -ForegroundColor Yellow
    Write-Host "Use menu option 7 to create a diagnostics ZIP." -ForegroundColor Yellow
    Write-Log "Operation failed: $($ErrorRecord.Exception.Message)" "ERROR"
}

function Invoke-MenuAction {
    param([scriptblock]$Action)
    try {
        & $Action
    } catch {
        Show-Failure $_
    } finally {
        try { Set-Location $Script:OriginalLocation } catch { }
        Pause-Tool
    }
}

Initialize-Logging

while ($true) {
    Show-Header
    Write-Host "1  - First download / install project"
    Write-Host "2  - Update project from GitHub"
    Write-Host "3  - Upload local changes to GitHub"
    Write-Host "4  - Update + repair + run"
    Write-Host "5  - Repair Git + Flutter + Gradle"
    Write-Host "6  - Show project status"
    Write-Host "7  - Collect diagnostics ZIP"
    Write-Host "8  - Flutter doctor"
    Write-Host "9  - Flutter cache repair"
    Write-Host "10 - Build Debug APK"
    Write-Host "11 - Build Release APK"
    Write-Host "12 - Run app on supported Android device"
    Write-Host "13 - Full repair + Build Release APK"
    Write-Host "0  - Exit"
    Write-Host ""

    $choice = Read-Host "Choose an option"
    switch ($choice) {
        "1"  { Invoke-MenuAction { First-Download } }
        "2"  { Invoke-MenuAction { Update-Project } }
        "3"  { Invoke-MenuAction { Upload-Changes } }
        "4"  { Invoke-MenuAction { Update-Repair-Run } }
        "5"  { Invoke-MenuAction { Repair-All } }
        "6"  { Invoke-MenuAction { Show-Status } }
        "7"  { Invoke-MenuAction { Collect-Diagnostics } }
        "8"  { Invoke-MenuAction { Assert-Command "flutter"; Invoke-Native "flutter" @("doctor", "-v") "Flutter doctor" | Out-Null } }
        "9"  { Invoke-MenuAction { Assert-Command "flutter"; Repair-FlutterCaches } }
        "10" { Invoke-MenuAction { Build-Flutter "debug" } }
        "11" { Invoke-MenuAction { Build-Flutter "release" } }
        "12" { Invoke-MenuAction { Run-App } }
        "13" { Invoke-MenuAction { Full-Repair-Release } }
        "0"  { Write-Log "Setup Tool closed" "OK"; break }
        default { Write-Host "Invalid option." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }

    if ($choice -eq "0") { break }
}
