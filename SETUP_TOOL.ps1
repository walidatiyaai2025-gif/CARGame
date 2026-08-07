[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:ToolName = "CARGame Setup Tool"
$Script:ToolVersion = "2.0.0"
$Script:OriginalLocation = Get-Location
$Script:ProjectPath = if ($ProjectPath) { $ProjectPath } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot ".git"))) { $PSScriptRoot } else { "D:\Apps\CARGame" }
$Script:LogDirectory = Join-Path $Script:ProjectPath "logs\setup_tool"
$Script:LogFile = $null
$Script:LastFailure = $null
$Script:LastDiagnostics = $null

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
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if (-not $Quiet) {
        foreach ($line in @($output)) { if ($null -ne $line) { Write-Host $line } }
    }
    try {
        foreach ($line in @($output)) { if ($null -ne $line) { Add-Content -Path $Script:LogFile -Value "    $line" -Encoding UTF8 } }
    } catch { }
    $duration = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    if ($exitCode -eq 0) {
        Write-Log "$Step completed in ${duration}s" "OK"
    } else {
        $Script:LastFailure = [pscustomobject]@{ Step = $Step; Command = $display; ExitCode = $exitCode; Output = (@($output) -join [Environment]::NewLine) }
        Write-Log "$Step failed with exit code $exitCode" "ERROR"
        if (-not $AllowFailure) { throw "$Step failed with exit code $exitCode." }
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output); TimedOut = $false }
}

function Invoke-TimedNative {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$Step = $FilePath,
        [int]$TimeoutSeconds = 30,
        [string]$WorkingDirectory = $Script:ProjectPath,
        [switch]$AllowFailure,
        [switch]$Quiet
    )
    $display = "$FilePath $($Arguments -join ' ')".Trim()
    Write-Log "$Step -> $display (timeout ${TimeoutSeconds}s)"
    $stdout = Join-Path $env:TEMP ("cargame_out_" + [guid]::NewGuid().ToString("N") + ".txt")
    $stderr = Join-Path $env:TEMP ("cargame_err_" + [guid]::NewGuid().ToString("N") + ".txt")
    $process = $null
    try {
        $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $finished = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $finished) {
            try { $process.Kill() } catch { }
            $output = @()
            if (Test-Path $stdout) { $output += @(Get-Content $stdout -ErrorAction SilentlyContinue) }
            if (Test-Path $stderr) { $output += @(Get-Content $stderr -ErrorAction SilentlyContinue) }
            Write-Log "$Step timed out after ${TimeoutSeconds}s" "ERROR"
            $Script:LastFailure = [pscustomobject]@{ Step = $Step; Command = $display; ExitCode = -1; Output = (@($output) -join [Environment]::NewLine) }
            if (-not $AllowFailure) { throw "$Step timed out after ${TimeoutSeconds}s." }
            return [pscustomobject]@{ ExitCode = -1; Output = @($output); TimedOut = $true }
        }
        $output = @()
        if (Test-Path $stdout) { $output += @(Get-Content $stdout -ErrorAction SilentlyContinue) }
        if (Test-Path $stderr) { $output += @(Get-Content $stderr -ErrorAction SilentlyContinue) }
        if (-not $Quiet) { @($output) | ForEach-Object { Write-Host $_ } }
        try { @($output) | ForEach-Object { Add-Content -Path $Script:LogFile -Value "    $_" -Encoding UTF8 } } catch { }
        if ($process.ExitCode -eq 0) {
            Write-Log "$Step completed" "OK"
        } else {
            Write-Log "$Step failed with exit code $($process.ExitCode)" "ERROR"
            $Script:LastFailure = [pscustomobject]@{ Step = $Step; Command = $display; ExitCode = $process.ExitCode; Output = (@($output) -join [Environment]::NewLine) }
            if (-not $AllowFailure) { throw "$Step failed with exit code $($process.ExitCode)." }
        }
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = @($output); TimedOut = $false }
    } finally {
        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
        if ($process) { $process.Dispose() }
    }
}

function Test-TcpPort {
    param([string]$HostName, [int]$Port = 443, [int]$TimeoutMs = 3000)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch { return $false } finally { $client.Close() }
}

function Test-RepositoryFolder { return (Test-Path (Join-Path $Script:ProjectPath ".git")) }

function Enter-Project {
    if (-not (Test-Path $Script:ProjectPath)) { throw "Project folder does not exist: $($Script:ProjectPath)" }
    Set-Location $Script:ProjectPath
}

function Get-FreeDiskGB {
    try {
        $root = [System.IO.Path]::GetPathRoot($Script:ProjectPath)
        $drive = New-Object System.IO.DriveInfo($root)
        return [math]::Round($drive.AvailableFreeSpace / 1GB, 1)
    } catch { return -1 }
}

function Get-CommandVersionText {
    param([string]$Command, [string[]]$Arguments, [int]$TimeoutSeconds = 15)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) { return "NOT FOUND" }
    $r = Invoke-TimedNative $Command $Arguments "Detect $Command" $TimeoutSeconds $Script:ProjectPath -AllowFailure -Quiet
    if ($r.TimedOut) { return "TIMEOUT" }
    $line = @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) | Select-Object -First 1
    if ($line) { return ([string]$line).Trim() }
    return "Detected"
}

function Run-Diagnostics {
    param([switch]$Silent)
    $issues = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $checks = New-Object System.Collections.Generic.List[object]

    function Add-Check([string]$Name, [bool]$Ok, [string]$Detail, [string]$Severity = "ERROR") {
        $checks.Add([pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail; Severity = $Severity })
        if (-not $Ok) {
            if ($Severity -eq "WARN") { $warnings.Add("$Name: $Detail") } else { $issues.Add("$Name: $Detail") }
        }
    }

    if (-not $Silent) {
        Show-Header
        Write-Host "SYSTEM + PROJECT DIAGNOSTICS" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------"
    }

    Add-Check "Windows" $true ([Environment]::OSVersion.VersionString)
    Add-Check "PowerShell" ($PSVersionTable.PSVersion.Major -ge 5) ($PSVersionTable.PSVersion.ToString())

    $git = Get-Command git -ErrorAction SilentlyContinue
    Add-Check "Git" ($null -ne $git) $(if ($git) { Get-CommandVersionText "git" @("--version") 10 } else { "Git is not installed or not in PATH" })

    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    Add-Check "Flutter" ($null -ne $flutter) $(if ($flutter) { Get-CommandVersionText "flutter" @("--version") 25 } else { "Flutter is not installed or not in PATH" })

    $dart = Get-Command dart -ErrorAction SilentlyContinue
    Add-Check "Dart" ($null -ne $dart) $(if ($dart) { Get-CommandVersionText "dart" @("--version") 10 } else { "Dart is not available" }) "WARN"

    $java = Get-Command java -ErrorAction SilentlyContinue
    $javaText = if ($java) { Get-CommandVersionText "java" @("-version") 10 } else { "Java is not installed or not in PATH" }
    $javaOk = ($null -ne $java) -and ($javaText -match '17\.|version "17|openjdk 17')
    Add-Check "Java 17" $javaOk $javaText

    $androidSdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
    Add-Check "Android SDK" (Test-Path $androidSdk) $androidSdk

    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb -and (Test-Path (Join-Path $androidSdk "platform-tools\adb.exe"))) { $adb = Get-Item (Join-Path $androidSdk "platform-tools\adb.exe") }
    Add-Check "ADB" ($null -ne $adb) $(if ($adb) { $adb.FullName } else { "adb.exe was not found" }) "WARN"

    $githubOk = Test-TcpPort "github.com" 443 3500
    Add-Check "GitHub HTTPS" $githubOk $(if ($githubOk) { "github.com:443 reachable" } else { "github.com:443 is not reachable" })

    $freeGB = Get-FreeDiskGB
    Add-Check "Disk space" ($freeGB -ge 8 -or $freeGB -lt 0) $(if ($freeGB -ge 0) { "$freeGB GB free" } else { "Unable to read free space" }) $(if ($freeGB -ge 0 -and $freeGB -lt 8) { "ERROR" } else { "WARN" })

    $folderExists = Test-Path $Script:ProjectPath
    Add-Check "Project folder" $folderExists $(if ($folderExists) { $Script:ProjectPath } else { "Not installed yet; First Download is available" }) "WARN"

    $repoOk = Test-RepositoryFolder
    Add-Check "Git repository" $repoOk $(if ($repoOk) { ".git found" } elseif ($folderExists) { "Folder exists but .git is missing" } else { "Project not downloaded yet" }) $(if ($folderExists -and -not $repoOk) { "ERROR" } else { "WARN" })

    if ($repoOk -and $git) {
        $remote = Invoke-TimedNative "git" @("remote", "get-url", "origin") "Diagnose origin" 10 $Script:ProjectPath -AllowFailure -Quiet
        $remoteText = (@($remote.Output) | Select-Object -First 1)
        Add-Check "Origin" ($remote.ExitCode -eq 0) $(if ($remoteText) { [string]$remoteText } else { "origin remote missing" })

        $branchResult = Invoke-TimedNative "git" @("branch", "--show-current") "Diagnose branch" 10 $Script:ProjectPath -AllowFailure -Quiet
        $currentBranch = (@($branchResult.Output) | Select-Object -First 1)
        Add-Check "Branch" (($branchResult.ExitCode -eq 0) -and ($currentBranch -eq $Branch)) $(if ($currentBranch) { "Current: $currentBranch; expected: $Branch" } else { "Unable to determine branch" }) "WARN"

        $status = Invoke-TimedNative "git" @("status", "--porcelain") "Diagnose working tree" 15 $Script:ProjectPath -AllowFailure -Quiet
        $dirtyCount = @($status.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count
        Add-Check "Working tree" ($dirtyCount -eq 0) $(if ($dirtyCount -eq 0) { "Clean" } else { "$dirtyCount local change(s) detected" }) "WARN"

        $locks = @((Join-Path $Script:ProjectPath ".git\index.lock"), (Join-Path $Script:ProjectPath ".git\shallow.lock")) | Where-Object { Test-Path $_ }
        Add-Check "Git locks" (@($locks).Count -eq 0) $(if (@($locks).Count -eq 0) { "No stale lock files" } else { (@($locks) -join ", ") })

        $merge = Test-Path (Join-Path $Script:ProjectPath ".git\MERGE_HEAD")
        $rebase = (Test-Path (Join-Path $Script:ProjectPath ".git\rebase-merge")) -or (Test-Path (Join-Path $Script:ProjectPath ".git\rebase-apply"))
        Add-Check "Git operation" (-not ($merge -or $rebase)) $(if ($merge) { "Merge is in progress" } elseif ($rebase) { "Rebase is in progress" } else { "No interrupted merge/rebase" })
    }

    if ($folderExists) {
        $gradlew = Join-Path $Script:ProjectPath "android\gradlew.bat"
        Add-Check "Gradle wrapper" (Test-Path $gradlew) $(if (Test-Path $gradlew) { $gradlew } else { "android\gradlew.bat missing" })
        $pubspec = Join-Path $Script:ProjectPath "pubspec.yaml"
        Add-Check "Flutter project" (Test-Path $pubspec) $(if (Test-Path $pubspec) { "pubspec.yaml found" } else { "pubspec.yaml missing" })
    }

    if ($adb) {
        try {
            $adbPath = if ($adb.PSObject.Properties.Name -contains "Source") { $adb.Source } else { $adb.FullName }
            $devices = Invoke-TimedNative $adbPath @("devices") "Diagnose Android devices" 10 $Script:ProjectPath -AllowFailure -Quiet
            $online = @($devices.Output | Where-Object { ([string]$_) -match '\tdevice$' }).Count
            $offline = @($devices.Output | Where-Object { ([string]$_) -match '\toffline$' }).Count
            Add-Check "Android device" ($online -gt 0) $(if ($online -gt 0) { "$online online device(s)" } elseif ($offline -gt 0) { "$offline device(s) offline" } else { "No Android device online; build is still available" }) "WARN"
        } catch { Add-Check "Android device" $false $_.Exception.Message "WARN" }
    }

    $interesting = @("java", "adb", "emulator", "studio64", "gradle", "dart", "flutter")
    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $interesting -contains $_.ProcessName.ToLowerInvariant() } | Select-Object -ExpandProperty ProcessName -Unique)
    Add-Check "Tool processes" $true $(if ($running.Count -gt 0) { "Running: $($running -join ', ')" } else { "No related tool processes detected" })

    $okCount = @($checks | Where-Object { $_.Ok }).Count
    $total = [math]::Max(1, $checks.Count)
    $score = [math]::Round(($okCount / $total) * 100)
    $Script:LastDiagnostics = [pscustomobject]@{ Checks = $checks; Issues = $issues; Warnings = $warnings; Score = $score }

    if (-not $Silent) {
        foreach ($check in $checks) {
            $tag = if ($check.Ok) { "OK" } elseif ($check.Severity -eq "WARN") { "WARN" } else { "FAIL" }
            $color = if ($check.Ok) { "Green" } elseif ($check.Severity -eq "WARN") { "Yellow" } else { "Red" }
            Write-Host ("[{0,-4}] {1,-18} {2}" -f $tag, $check.Name, $check.Detail) -ForegroundColor $color
        }
        Write-Host "------------------------------------------------------------"
        $scoreColor = if ($score -ge 90) { "Green" } elseif ($score -ge 70) { "Yellow" } else { "Red" }
        Write-Host "Health Score: $score%" -ForegroundColor $scoreColor
        Write-Host "Problems    : $($issues.Count)" -ForegroundColor $(if ($issues.Count -eq 0) { "Green" } else { "Red" })
        Write-Host "Warnings    : $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { "Green" } else { "Yellow" })
        Write-Host ""
        if ($issues.Count -gt 0) {
            Write-Host "Detected problems:" -ForegroundColor Red
            $i = 1
            foreach ($issue in $issues) { Write-Host " $i. $issue" -ForegroundColor Red; $i++ }
        }
        Write-Log "Diagnostics completed: health $score%, $($issues.Count) problem(s), $($warnings.Count) warning(s)" $(if ($issues.Count -eq 0) { "OK" } else { "WARN" })
    }
    return $Script:LastDiagnostics
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
    $locks = @((Join-Path $Script:ProjectPath ".git\index.lock"), (Join-Path $Script:ProjectPath ".git\shallow.lock"))
    foreach ($lock in $locks) {
        if (Test-Path $lock) { Write-Log "Removing stale Git lock: $lock" "WARN"; Remove-Item $lock -Force -ErrorAction SilentlyContinue }
    }
}

function Stop-GradleDaemons {
    $gradlew = Join-Path $Script:ProjectPath "android\gradlew.bat"
    if (Test-Path $gradlew) {
        Push-Location (Join-Path $Script:ProjectPath "android")
        try { Invoke-TimedNative ".\gradlew.bat" @("--stop") "Stop Gradle daemons" 30 (Get-Location).Path -AllowFailure | Out-Null } finally { Pop-Location }
    }
}

function Repair-FlutterCaches {
    if (-not (Test-Path $Script:ProjectPath)) { return }
    Enter-Project
    Write-Log "Starting Flutter/Gradle cache recovery"
    Stop-GradleDaemons
    foreach ($target in @((Join-Path $Script:ProjectPath "build"), (Join-Path $Script:ProjectPath ".dart_tool"), (Join-Path $Script:ProjectPath "android\.gradle"))) {
        if (Test-Path $target) { Write-Log "Removing cache: $target"; Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Invoke-Native "flutter" @("clean") "Flutter clean" -AllowFailure | Out-Null
        Invoke-Native "flutter" @("pub", "get") "Flutter pub get" | Out-Null
    }
}

function Repair-Git {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) { Write-Log "No Git repository found. Git repair skipped." "WARN"; return }
    Remove-StaleGitLocks
    Enter-Project
    if (Test-Path ".git\rebase-merge" -or Test-Path ".git\rebase-apply") { Invoke-Native "git" @("rebase", "--abort") "Abort interrupted rebase" -AllowFailure | Out-Null }
    if (Test-Path ".git\MERGE_HEAD") { Invoke-Native "git" @("merge", "--abort") "Abort interrupted merge" -AllowFailure | Out-Null }
    Ensure-GitRemote
    Invoke-Native "git" @("fsck", "--no-progress") "Git repository check" -AllowFailure | Out-Null
    Invoke-Native "git" @("fetch", "--prune", "origin") "Git fetch/prune" -AllowFailure | Out-Null
}

function Repair-All {
    Write-Log "Starting automatic repair"
    if (Get-Command git -ErrorAction SilentlyContinue) { if (Test-RepositoryFolder) { Repair-Git } } else { Write-Log "Git missing; automatic repository repair unavailable." "WARN" }
    if (Test-Path $Script:ProjectPath -and (Get-Command flutter -ErrorAction SilentlyContinue)) { Repair-FlutterCaches }
    Write-Log "Automatic repair completed" "OK"
    [void](Run-Diagnostics)
}

function First-Download {
    Assert-Command "git"
    if (-not (Test-TcpPort "github.com" 443 3500)) { throw "GitHub is not reachable on port 443." }
    if (Test-RepositoryFolder) { Write-Log "Repository already exists. Running safe update instead." "WARN"; Update-Project; return }
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
    if (Get-Command flutter -ErrorAction SilentlyContinue) { Invoke-Native "flutter" @("pub", "get") "Restore Flutter packages" -AllowFailure | Out-Null }
    Write-Log "First download completed" "OK"
}

function Get-GitStatusLines {
    Enter-Project
    $r = Invoke-TimedNative "git" @("status", "--porcelain") "Check local changes" 20 $Script:ProjectPath -AllowFailure -Quiet
    if ($r.TimedOut) { throw "git status timed out. Close tools locking the project and retry." }
    return @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

function Save-LocalChangesSafely {
    $changes = @(Get-GitStatusLines)
    if ($changes.Count -eq 0) { return $false }
    Write-Log "$($changes.Count) local change(s) detected. Protecting them before update." "WARN"
    Write-Host "Local changes:" -ForegroundColor Yellow
    @($changes | Select-Object -First 30) | ForEach-Object { Write-Host "  $_" }
    if ($changes.Count -gt 30) { Write-Host "  ... and $($changes.Count - 30) more" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Saving local changes with a 120 second timeout..." -ForegroundColor Cyan
    $name = "SETUP_TOOL_AUTO_STASH_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $stash = Invoke-TimedNative "git" @("stash", "push", "-u", "-m", $name) "Stash local changes" 120 $Script:ProjectPath -AllowFailure
    if ($stash.TimedOut) {
        throw "Git stash timed out after 120 seconds. Local files were NOT discarded. Close Android Studio/emulator if they are locking files, use option 7 for diagnostics, then retry."
    }
    if ($stash.ExitCode -ne 0) { throw "Unable to protect local changes. Nothing was discarded. See the log for git stash output." }
    return $true
}

function Update-Project {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) { First-Download; return }
    Repair-Git
    Enter-Project
    $stashed = Save-LocalChangesSafely
    Invoke-Native "git" @("fetch", "origin", $Branch) "Fetch origin/$Branch" | Out-Null
    $checkout = Invoke-Native "git" @("checkout", $Branch) "Checkout $Branch" -AllowFailure
    if ($checkout.ExitCode -ne 0) { Invoke-Native "git" @("checkout", "-b", $Branch, "origin/$Branch") "Create local $Branch" | Out-Null }
    $pull = Invoke-Native "git" @("pull", "--rebase", "origin", $Branch) "Update project" -AllowFailure
    if ($pull.ExitCode -ne 0) {
        Invoke-Native "git" @("rebase", "--abort") "Abort failed rebase" -AllowFailure | Out-Null
        throw "Automatic update could not be completed safely. Local work is preserved. Review the log."
    }
    if ($stashed) {
        $pop = Invoke-TimedNative "git" @("stash", "pop") "Restore local changes" 120 $Script:ProjectPath -AllowFailure
        if ($pop.TimedOut -or $pop.ExitCode -ne 0) { Write-Log "Update succeeded but stash restore needs attention. The stash remains recoverable; run git stash list." "WARN" }
    }
    if (Get-Command flutter -ErrorAction SilentlyContinue) { Invoke-Native "flutter" @("pub", "get") "Restore Flutter packages" -AllowFailure | Out-Null }
    Write-Log "Project update completed" "OK"
}

function Upload-Changes {
    Assert-Command "git"
    if (-not (Test-RepositoryFolder)) { throw "Project is not a Git repository." }
    Repair-Git
    Enter-Project
    $status = @(Get-GitStatusLines)
    if ($status.Count -eq 0) { Write-Log "No local changes to upload." "OK"; return }
    Write-Host "Changed files:" -ForegroundColor Yellow
    $status | ForEach-Object { Write-Host "  $_" }
    $message = Read-Host "Commit message [Update project]"
    if ([string]::IsNullOrWhiteSpace($message)) { $message = "Update project" }
    Invoke-Native "git" @("add", "-A") "Stage changes" | Out-Null
    Invoke-Native "git" @("commit", "-m", $message) "Commit changes" | Out-Null
    $push = Invoke-Native "git" @("push", "origin", $Branch) "Push changes" -AllowFailure
    if ($push.ExitCode -ne 0) {
        Write-Log "Push failed. Trying one safe fetch/rebase and retry." "WARN"
        Invoke-Native "git" @("fetch", "origin", $Branch) "Refresh before push retry" | Out-Null
        $rebase = Invoke-Native "git" @("rebase", "origin/$Branch") "Rebase before push retry" -AllowFailure
        if ($rebase.ExitCode -ne 0) { Invoke-Native "git" @("rebase", "--abort") "Abort push rebase" -AllowFailure | Out-Null; throw "Push cannot be repaired automatically because of a conflict or permission problem." }
        Invoke-Native "git" @("push", "origin", $Branch) "Push retry" | Out-Null
    }
    Write-Log "Upload completed" "OK"
}

function Get-SupportedAndroidDeviceId {
    Assert-Command "flutter"
    $result = Invoke-TimedNative "flutter" @("devices", "--machine") "Discover Flutter devices" 25 $Script:ProjectPath -AllowFailure -Quiet
    if ($result.ExitCode -ne 0 -or $result.TimedOut) { return $null }
    try {
        $json = (@($result.Output) -join [Environment]::NewLine) | ConvertFrom-Json
        $android = @($json | Where-Object { $_.targetPlatform -like "android*" -and $_.isSupported -ne $false })
        if ($android.Count -gt 0) { return $android[0].id }
    } catch { Write-Log "Could not parse flutter devices --machine output." "WARN" }
    return $null
}

function Start-AnyAndroidEmulator {
    Assert-Command "flutter"
    $result = Invoke-TimedNative "flutter" @("emulators") "List emulators" 20 $Script:ProjectPath -AllowFailure -Quiet
    if ($result.ExitCode -ne 0) { return $false }
    $id = $null
    foreach ($line in @($result.Output)) {
        $text = [string]$line
        if ($text -match '^\s*([^\s•]+)\s+•.*•\s+android\s*$') { $id = $Matches[1].Trim(); break }
    }
    if (-not $id) { Write-Log "No Android emulator was found." "WARN"; return $false }
    Invoke-Native "flutter" @("emulators", "--launch", $id) "Launch Android emulator" -AllowFailure | Out-Null
    Start-Sleep -Seconds 8
    return $true
}

function Run-App {
    Assert-Command "flutter"
    Enter-Project
    $deviceId = Get-SupportedAndroidDeviceId
    if (-not $deviceId) {
        Write-Log "No supported Android device online. Trying an available emulator." "WARN"
        [void](Start-AnyAndroidEmulator)
        for ($i = 0; $i -lt 12 -and -not $deviceId; $i++) { Start-Sleep -Seconds 5; $deviceId = Get-SupportedAndroidDeviceId }
    }
    if ($deviceId) { Invoke-Native "flutter" @("run", "-d", $deviceId) "Run application" | Out-Null }
    else { throw "No supported Android device became available." }
}

function Build-Flutter {
    param([ValidateSet("debug", "release")][string]$Mode)
    Assert-Command "flutter"
    Enter-Project
    Invoke-Native "flutter" @("pub", "get") "Restore packages" | Out-Null
    if (Get-Command dart -ErrorAction SilentlyContinue) { Invoke-Native "dart" @("format", "lib", "test") "Format Dart sources" -AllowFailure | Out-Null }
    Invoke-Native "flutter" @("analyze", "--no-fatal-infos", "--no-fatal-warnings") "Flutter analyze" | Out-Null
    $build = Invoke-Native "flutter" @("build", "apk", "--$Mode", "--no-pub") "Build $Mode APK" -AllowFailure
    $joined = @($build.Output) -join "`n"
    if ($build.ExitCode -ne 0 -and $joined -match "incremental caches|Could not close incremental caches|compile.*Kotlin") {
        Write-Log "Kotlin/Gradle cache failure detected. Repairing and retrying once." "WARN"
        Repair-FlutterCaches
        Invoke-Native "flutter" @("build", "apk", "--$Mode", "--no-pub") "Build $Mode APK after repair" | Out-Null
    } elseif ($build.ExitCode -ne 0) { throw "Flutter $Mode build failed. See the log for compiler output." }
    $apk = Join-Path $Script:ProjectPath "build\app\outputs\flutter-apk\app-$Mode.apk"
    if (Test-Path $apk) { Write-Log "APK ready: $apk" "OK" }
}

function Show-Status { [void](Run-Diagnostics) }

function Collect-Diagnostics {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $diagRoot = Join-Path $env:TEMP "CARGame_Diagnostics_$stamp"
    New-Item -ItemType Directory -Path $diagRoot -Force | Out-Null
    try {
        Copy-Item $Script:LogFile (Join-Path $diagRoot "setup_tool.log") -Force -ErrorAction SilentlyContinue
        [void](Run-Diagnostics -Silent)
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $lines.Add("Project: $($Script:ProjectPath)")
        $lines.Add("Repository: $RepositoryUrl")
        $lines.Add("Branch: $Branch")
        $lines.Add("Health score: $($Script:LastDiagnostics.Score)%")
        $lines.Add("")
        foreach ($check in $Script:LastDiagnostics.Checks) { $lines.Add("[$(if ($check.Ok) { 'OK' } else { $check.Severity })] $($check.Name): $($check.Detail)") }
        $lines | Set-Content (Join-Path $diagRoot "diagnostics.txt") -Encoding UTF8
        if (Test-RepositoryFolder -and (Get-Command git -ErrorAction SilentlyContinue)) {
            foreach ($entry in @(@{ Name = "git_status.txt"; Args = @("status", "--branch", "--short") }, @{ Name = "git_remote.txt"; Args = @("remote", "-v") }, @{ Name = "git_log.txt"; Args = @("log", "-20", "--oneline", "--decorate") })) {
                $r = Invoke-TimedNative "git" $entry.Args "Diagnostics $($entry.Name)" 20 $Script:ProjectPath -AllowFailure -Quiet
                @($r.Output) | Set-Content (Join-Path $diagRoot $entry.Name) -Encoding UTF8
            }
        }
        Get-Process | Sort-Object ProcessName | Select-Object ProcessName, Id, Path -ErrorAction SilentlyContinue | Out-File (Join-Path $diagRoot "processes.txt") -Encoding UTF8
        $zip = Join-Path $Script:LogDirectory "CARGame_Diagnostics_$stamp.zip"
        Compress-Archive -Path (Join-Path $diagRoot "*") -DestinationPath $zip -Force
        Write-Log "Diagnostics package created: $zip" "OK"
    } finally { Remove-Item $diagRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

function Update-Repair-Run { Update-Project; Repair-All; Run-App }
function Full-Repair-Release { Repair-All; Build-Flutter "release" }

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
    Write-Host "Use option 7 to create a diagnostics ZIP." -ForegroundColor Yellow
    Write-Log "Operation failed: $($ErrorRecord.Exception.Message)" "ERROR"
}

function Invoke-MenuAction {
    param([scriptblock]$Action)
    try { & $Action } catch { Show-Failure $_ } finally { try { Set-Location $Script:OriginalLocation } catch { }; Pause-Tool }
}

Initialize-Logging

try {
    [void](Run-Diagnostics)
    if ($Script:LastDiagnostics.Issues.Count -gt 0) {
        Write-Host ""
        $repair = Read-Host "Problems detected. Run automatic repair now? [Y/N]"
        if ($repair -match '^[Yy]') {
            try { Repair-All } catch { Show-Failure $_ }
        }
    }
    Pause-Tool
} catch {
    Show-Failure $_
    Pause-Tool
}

while ($true) {
    Show-Header
    $health = if ($Script:LastDiagnostics) { "$($Script:LastDiagnostics.Score)%" } else { "Not checked" }
    Write-Host "Last Health Score: $health" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1  - First download / install project"
    Write-Host "2  - Smart update project from GitHub"
    Write-Host "3  - Upload local changes to GitHub"
    Write-Host "4  - Update + repair + run"
    Write-Host "5  - Repair Git + Flutter + Gradle"
    Write-Host "6  - Run full system/project diagnostics"
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
        "6"  { Invoke-MenuAction { [void](Run-Diagnostics) } }
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
