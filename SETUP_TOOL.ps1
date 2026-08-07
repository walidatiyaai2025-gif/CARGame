[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

# CARGame Setup Tool v2.3.0
# Windows PowerShell 5.1 compatible.
# Destructive Git operations require explicit confirmation and create a backup first.

$ErrorActionPreference = "Continue"
$ToolVersion = "2.3.0"
$OriginalLocation = Get-Location
$script:LastFailure = $null

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot ".git"))) {
        $ProjectPath = $PSScriptRoot
    } else {
        $ProjectPath = "D:\Apps\CARGame"
    }
}

$LogDirectory = Join-Path $ProjectPath "logs\setup_tool"
$BackupDirectory = Join-Path $LogDirectory "backups"
$script:LogFile = $null

function Initialize-Log {
    try {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    } catch {
        $script:LogDirectory = Join-Path $env:TEMP "CARGame_SetupTool_Logs"
        $script:BackupDirectory = Join-Path $script:LogDirectory "backups"
        New-Item -ItemType Directory -Path $script:BackupDirectory -Force | Out-Null
    }
    $script:LogFile = Join-Path $script:LogDirectory ("setup_tool_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    try { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] CARGame Setup Tool v$ToolVersion" | Set-Content $script:LogFile -Encoding UTF8 } catch { }
}

function Write-ToolLog {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch { }
    switch ($Level) {
        "OK"    { Write-Host $line -ForegroundColor Green }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Cyan }
    }
}

function Pause-Tool { Write-Host ""; [void](Read-Host "Press Enter to continue") }

function Show-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host " CARGame Setup Tool v$ToolVersion" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host "Project : $ProjectPath"
    Write-Host "Repo    : $RepositoryUrl"
    Write-Host "Branch  : $Branch"
    Write-Host "Log     : $script:LogFile"
    Write-Host ""
}

function Test-CommandExists { param([string]$Name); return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Test-Repo { return Test-Path (Join-Path $ProjectPath ".git") }
function Enter-Project { if (-not (Test-Path $ProjectPath)) { throw "Project folder does not exist: $ProjectPath" }; Set-Location $ProjectPath }

function Invoke-External {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$Step = "Command",
        [switch]$AllowFailure,
        [switch]$Quiet
    )

    if (-not (Test-CommandExists $FilePath)) {
        $msg = "Required command '$FilePath' was not found in PATH."
        Write-ToolLog $msg "ERROR"
        if (-not $AllowFailure) { throw $msg }
        return [pscustomobject]@{ ExitCode = 9009; Output = @($msg) }
    }

    $display = "$FilePath $($Arguments -join ' ')".Trim()
    Write-ToolLog "$Step -> $display"
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = @()
    $exitCode = -1
    try {
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
    } catch {
        $output = @($_.Exception.Message)
        $exitCode = 1
    } finally { $ErrorActionPreference = $old }

    if (-not $Quiet) { foreach ($line in $output) { if ($null -ne $line) { Write-Host $line } } }
    try { foreach ($line in $output) { if ($null -ne $line) { Add-Content $script:LogFile "    $line" -Encoding UTF8 } } } catch { }

    if ($exitCode -eq 0) { Write-ToolLog "$Step completed" "OK" }
    else {
        $script:LastFailure = [pscustomobject]@{ Step=$Step; Command=$display; ExitCode=$exitCode; Output=($output -join [Environment]::NewLine) }
        Write-ToolLog "$Step failed with exit code $exitCode" "ERROR"
        if (-not $AllowFailure) { throw "$Step failed with exit code $exitCode." }
    }
    return [pscustomobject]@{ ExitCode=$exitCode; Output=$output }
}

function Ensure-Origin {
    if (-not (Test-Repo)) { return }
    Enter-Project
    $r = Invoke-External "git" @("remote") "Read remotes" -AllowFailure -Quiet
    if ($r.Output -notcontains "origin") {
        Invoke-External "git" @("remote","add","origin",$RepositoryUrl) "Add origin" | Out-Null
        return
    }
    $current = Invoke-External "git" @("remote","get-url","origin") "Read origin" -AllowFailure -Quiet
    $url = $current.Output | Select-Object -First 1
    if ($url -ne $RepositoryUrl) {
        Write-ToolLog "Origin URL differs. Updating it." "WARN"
        Invoke-External "git" @("remote","set-url","origin",$RepositoryUrl) "Fix origin" | Out-Null
    }
}

function Get-LocalChanges {
    if (-not (Test-Repo)) { return @() }
    Enter-Project
    $r = Invoke-External "git" @("status","--porcelain") "Check local changes" -AllowFailure -Quiet
    return @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

function Test-GeneratedPath {
    param([string]$StatusLine)
    $path = ([string]$StatusLine).Substring([Math]::Min(3, ([string]$StatusLine).Length)).Trim().Replace('"','')
    $patterns = @(
        '^build/', '^\.dart_tool/', '^android/\.gradle/', '^\.gradle-user-home-', '^node_modules/',
        '^logs/', '^\.metadata$', '^android/app/src/debug/', '^android/app/src/profile/'
    )
    foreach ($p in $patterns) { if ($path -match $p) { return $true } }
    return $false
}

function Get-ChangeSummary {
    $all = @(Get-LocalChanges)
    $generated = @($all | Where-Object { Test-GeneratedPath $_ })
    $source = @($all | Where-Object { -not (Test-GeneratedPath $_) })
    return [pscustomobject]@{ All=$all; Generated=$generated; Source=$source }
}

function Show-ChangeSummary {
    $s = Get-ChangeSummary
    Write-Host ""
    Write-Host "LOCAL CHANGE SUMMARY" -ForegroundColor Yellow
    Write-Host "  Source changes    : $($s.Source.Count)"
    Write-Host "  Generated changes : $($s.Generated.Count)"
    if ($s.Source.Count -gt 0) {
        Write-Host ""
        Write-Host "Source changes:" -ForegroundColor Yellow
        $s.Source | ForEach-Object { Write-Host "  $_" }
    }
    if ($s.Generated.Count -gt 0) {
        Write-Host ""
        Write-Host "Generated/cache changes:" -ForegroundColor DarkYellow
        $s.Generated | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }
        if ($s.Generated.Count -gt 25) { Write-Host "  ... $($s.Generated.Count - 25) more" }
    }
    return $s
}

function Remove-SafeCaches {
    foreach ($relative in @("build", ".dart_tool", "android\.gradle", "node_modules")) {
        $p = Join-Path $ProjectPath $relative
        if (Test-Path $p) {
            Write-ToolLog "Removing generated cache: $p" "WARN"
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Get-ChildItem $ProjectPath -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like ".gradle-user-home-*" } |
        ForEach-Object { Write-ToolLog "Removing generated cache: $($_.FullName)" "WARN"; Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
}

function Backup-LocalChanges {
    if (-not (Test-Repo)) { return $null }
    Enter-Project
    $summary = Get-ChangeSummary
    if ($summary.All.Count -eq 0) { return $null }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $root = Join-Path $script:BackupDirectory "local_changes_$stamp"
    New-Item -ItemType Directory -Path $root -Force | Out-Null

    $statusFile = Join-Path $root "git_status.txt"
    $summary.All | Set-Content $statusFile -Encoding UTF8

    $trackedPatch = Join-Path $root "tracked_changes.patch"
    $stagedPatch = Join-Path $root "staged_changes.patch"
    cmd /c "git diff --binary > `"$trackedPatch`"" | Out-Null
    cmd /c "git diff --cached --binary > `"$stagedPatch`"" | Out-Null

    $untracked = @(Invoke-External "git" @("ls-files","--others","--exclude-standard") "List untracked files" -AllowFailure -Quiet).Output
    $copyRoot = Join-Path $root "untracked_source"
    foreach ($rel in $untracked) {
        if ([string]::IsNullOrWhiteSpace([string]$rel)) { continue }
        $fake = "?? $rel"
        if (Test-GeneratedPath $fake) { continue }
        $src = Join-Path $ProjectPath ([string]$rel)
        if (Test-Path $src -PathType Leaf) {
            $dst = Join-Path $copyRoot ([string]$rel)
            $parent = Split-Path $dst -Parent
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Copy-Item $src $dst -Force -ErrorAction SilentlyContinue
        }
    }

    $zip = "$root.zip"
    try {
        Compress-Archive -Path (Join-Path $root "*") -DestinationPath $zip -Force
        Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
        Write-ToolLog "Local changes backup created: $zip" "OK"
        return $zip
    } catch {
        Write-ToolLog "Backup folder created but ZIP compression failed: $root" "WARN"
        return $root
    }
}

function Sync-FromGitHub {
    param([switch]$SkipConfirmation)
    if (-not (Test-Repo)) { throw "Project is not a Git repository. Use First Download instead." }
    Ensure-Origin
    Enter-Project

    $summary = Show-ChangeSummary
    if (-not $SkipConfirmation) {
        Write-Host ""
        Write-Host "This operation will replace the local working tree with origin/$Branch." -ForegroundColor Red
        Write-Host "A backup of source changes will be created first." -ForegroundColor Yellow
        $confirm = Read-Host "Type YES to continue"
        if ($confirm -cne "YES") { Write-ToolLog "Sync cancelled by user." "WARN"; return $false }
    }

    $backup = Backup-LocalChanges
    if ($backup) { Write-Host "Backup: $backup" -ForegroundColor Green }

    Remove-SafeCaches
    Invoke-External "git" @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch" | Out-Null
    Invoke-External "git" @("reset","--hard","origin/$Branch") "Reset tracked files to GitHub" | Out-Null
    Invoke-External "git" @("clean","-fd","-e","logs/") "Remove untracked files" | Out-Null
    $checkout = Invoke-External "git" @("checkout",$Branch) "Checkout $Branch" -AllowFailure
    if ($checkout.ExitCode -ne 0) { Invoke-External "git" @("checkout","-B",$Branch,"origin/$Branch") "Recreate local branch" | Out-Null }
    if (Test-CommandExists "flutter") { Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure | Out-Null }
    Write-ToolLog "GitHub version applied successfully." "OK"
    return $true
}

function Add-DiagnosticResult {
    param([string]$Name, [bool]$Ok, [string]$Details, [bool]$WarningOnly = $false)
    if ($Ok) { Write-Host ("[OK]   {0,-20} {1}" -f $Name,$Details) -ForegroundColor Green }
    elseif ($WarningOnly) { Write-Host ("[WARN] {0,-20} {1}" -f $Name,$Details) -ForegroundColor Yellow }
    else { Write-Host ("[FAIL] {0,-20} {1}" -f $Name,$Details) -ForegroundColor Red }
}

function Run-Diagnostics {
    param([switch]$NoPause)
    Write-Host ""
    Write-Host "SYSTEM + PROJECT DIAGNOSTICS" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"
    $score = 100; $problems = 0; $warnings = 0

    try { Add-DiagnosticResult "Windows" $true ([Environment]::OSVersion.VersionString) } catch { $problems++; $score -= 8; Add-DiagnosticResult "Windows" $false "Check failed" }
    try { Add-DiagnosticResult "PowerShell" $true $PSVersionTable.PSVersion.ToString() } catch { $warnings++; $score -= 2; Add-DiagnosticResult "PowerShell" $false "Version unavailable" $true }

    foreach ($cmd in @("git","flutter","dart","java")) {
        try {
            $found = Get-Command $cmd -ErrorAction SilentlyContinue
            if ($found) { Add-DiagnosticResult $cmd $true $found.Source }
            else { $problems++; $score -= 8; Add-DiagnosticResult $cmd $false "NOT FOUND" }
        } catch { $warnings++; $score -= 2; Add-DiagnosticResult $cmd $false "Check failed" $true }
    }

    try {
        if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) { Add-DiagnosticResult "JAVA_HOME" $true $env:JAVA_HOME }
        else { $warnings++; $score -= 3; Add-DiagnosticResult "JAVA_HOME" $false "Missing or invalid" $true }
    } catch { $warnings++; $score -= 2; Add-DiagnosticResult "JAVA_HOME" $false "Check failed" $true }

    try {
        $sdk = $env:ANDROID_SDK_ROOT; if (-not $sdk) { $sdk = $env:ANDROID_HOME }
        if ($sdk -and (Test-Path $sdk)) { Add-DiagnosticResult "Android SDK" $true $sdk }
        else { $warnings++; $score -= 3; Add-DiagnosticResult "Android SDK" $false "Environment variable not set" $true }
    } catch { $warnings++; $score -= 2; Add-DiagnosticResult "Android SDK" $false "Check failed" $true }

    try {
        $tcp = Test-NetConnection github.com -Port 443 -WarningAction SilentlyContinue
        if ($tcp.TcpTestSucceeded) { Add-DiagnosticResult "GitHub HTTPS" $true "github.com:443 reachable" }
        else { $problems++; $score -= 10; Add-DiagnosticResult "GitHub HTTPS" $false "github.com:443 unreachable" }
    } catch { $warnings++; $score -= 3; Add-DiagnosticResult "GitHub HTTPS" $false "Connectivity check unavailable" $true }

    if (Test-Repo) {
        try {
            Add-DiagnosticResult "Git repository" $true ".git found"
            Ensure-Origin; Enter-Project
            $branchResult = Invoke-External "git" @("branch","--show-current") "Read branch" -AllowFailure -Quiet
            $branchText = $branchResult.Output | Select-Object -First 1
            if ($branchText) { Add-DiagnosticResult "Branch" $true $branchText } else { $warnings++; $score -= 2; Add-DiagnosticResult "Branch" $false "Unable to determine" $true }
            $s = Get-ChangeSummary
            if ($s.All.Count -eq 0) { Add-DiagnosticResult "Working tree" $true "Clean" }
            else { $warnings++; $score -= 3; Add-DiagnosticResult "Working tree" $false "$($s.Source.Count) source / $($s.Generated.Count) generated" $true }
            $locks = @(".git\index.lock", ".git\shallow.lock") | Where-Object { Test-Path (Join-Path $ProjectPath $_) }
            if (@($locks).Count -eq 0) { Add-DiagnosticResult "Git locks" $true "None" } else { $warnings++; $score -= 4; Add-DiagnosticResult "Git locks" $false ($locks -join ", ") $true }
        } catch { $warnings++; $score -= 4; Add-DiagnosticResult "Repository checks" $false $_.Exception.Message $true }
    } else { $warnings++; $score -= 4; Add-DiagnosticResult "Git repository" $false "Not initialized/downloaded" $true }

    try {
        $root = [System.IO.Path]::GetPathRoot($ProjectPath); $drive = Get-PSDrive -Name $root.Substring(0,1) -ErrorAction SilentlyContinue
        if ($drive) { $freeGb = [math]::Round($drive.Free / 1GB,1); $ok = $freeGb -ge 5; if (-not $ok) { $warnings++; $score -= 4 }; Add-DiagnosticResult "Free disk" $ok "$freeGb GB" (-not $ok) }
    } catch { $warnings++; $score -= 2; Add-DiagnosticResult "Free disk" $false "Check failed" $true }

    try {
        if (Test-CommandExists "flutter") {
            $dev = Invoke-External "flutter" @("devices","--machine") "Discover devices" -AllowFailure -Quiet; $text = $dev.Output -join "`n"
            if ($dev.ExitCode -eq 0 -and $text -match '"targetPlatform"\s*:\s*"android') { Add-DiagnosticResult "Android device" $true "Detected by Flutter" }
            else { $warnings++; $score -= 2; Add-DiagnosticResult "Android device" $false "No supported Android device online" $true }
        }
    } catch { $warnings++; $score -= 1; Add-DiagnosticResult "Android device" $false "Check failed" $true }

    if ($score -lt 0) { $score = 0 }
    Write-Host "------------------------------------------------------------"
    Write-Host "Health Score : $score%" -ForegroundColor Cyan
    Write-Host "Problems     : $problems"
    Write-Host "Warnings     : $warnings"
    Write-ToolLog "Diagnostics completed. Health=$score%, Problems=$problems, Warnings=$warnings" "OK"
    try { Set-Location $OriginalLocation } catch { }
    if (-not $NoPause) { Pause-Tool }
}

function Repair-Basic {
    Write-ToolLog "Starting basic repair"
    if (Test-Repo) {
        foreach ($lock in @(".git\index.lock", ".git\shallow.lock")) { $p=Join-Path $ProjectPath $lock; if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue; Write-ToolLog "Removed $lock" "OK" } }
        Ensure-Origin; Enter-Project
        Invoke-External "git" @("fsck","--no-progress") "Git fsck" -AllowFailure | Out-Null
        Invoke-External "git" @("fetch","--prune","origin") "Git fetch" -AllowFailure | Out-Null
    }
    if (Test-CommandExists "flutter") { Remove-SafeCaches; Enter-Project; Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure | Out-Null; Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure | Out-Null }
    Write-ToolLog "Basic repair completed" "OK"
}

function First-Download {
    if (-not (Test-CommandExists "git")) { throw "Git is not installed or not in PATH." }
    if (Test-Repo) { Write-ToolLog "Repository already exists; switching to update." "WARN"; Update-Project; return }
    if (Test-Path $ProjectPath) {
        $items = @(Get-ChildItem $ProjectPath -Force -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) { $backup = "$ProjectPath`_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"; Write-ToolLog "Existing non-Git folder moved to $backup" "WARN"; Move-Item $ProjectPath $backup -Force }
    }
    $parent = Split-Path $ProjectPath -Parent; if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Invoke-External "git" @("clone","--branch",$Branch,"--single-branch",$RepositoryUrl,$ProjectPath) "Clone repository" | Out-Null
    if (Test-CommandExists "flutter") { Enter-Project; Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure | Out-Null }
}

function Update-Project {
    if (-not (Test-Repo)) { First-Download; return }
    Ensure-Origin; Enter-Project; Remove-SafeCaches
    $s = Get-ChangeSummary
    if ($s.Source.Count -gt 0) {
        Show-ChangeSummary | Out-Null
        Write-Host ""
        Write-Host "1 - Backup + DISCARD local changes + apply GitHub" -ForegroundColor Yellow
        Write-Host "2 - Keep local changes and cancel update"
        Write-Host "3 - Upload local changes to GitHub"
        $action = Read-Host "Choose [1/2/3]"
        if ($action -eq "1") { if (Sync-FromGitHub) { return } }
        elseif ($action -eq "3") { Upload-Changes; return }
        Write-ToolLog "Update cancelled to protect local source changes." "WARN"; return
    }
    if ($s.Generated.Count -gt 0) { Write-ToolLog "Only generated changes remain; cleaning them automatically." "WARN"; Invoke-External "git" @("clean","-fd","-e","logs/") "Clean generated/untracked files" -AllowFailure | Out-Null }
    Invoke-External "git" @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch" | Out-Null
    $checkout = Invoke-External "git" @("checkout",$Branch) "Checkout $Branch" -AllowFailure
    if ($checkout.ExitCode -ne 0) { Invoke-External "git" @("checkout","-b",$Branch,"origin/$Branch") "Create branch" | Out-Null }
    Invoke-External "git" @("pull","--ff-only","origin",$Branch) "Fast-forward update" | Out-Null
    if (Test-CommandExists "flutter") { Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure | Out-Null }
    Write-ToolLog "Project update completed" "OK"
}

function Upload-Changes {
    if (-not (Test-Repo)) { throw "Project is not a Git repository." }
    Ensure-Origin; Enter-Project; $s=Show-ChangeSummary
    if ($s.All.Count -eq 0) { Write-ToolLog "No local changes to upload." "OK"; return }
    $msg=Read-Host "Commit message [Update project]"; if ([string]::IsNullOrWhiteSpace($msg)) { $msg="Update project" }
    Invoke-External "git" @("add","-A") "Stage changes" | Out-Null
    Invoke-External "git" @("commit","-m",$msg) "Commit changes" | Out-Null
    $push=Invoke-External "git" @("push","origin",$Branch) "Push changes" -AllowFailure; if ($push.ExitCode -ne 0) { throw "Push failed. Check authentication, branch protection, or remote changes in the log." }
}

function Build-Apk {
    param([ValidateSet("debug","release")][string]$Mode)
    if (-not (Test-CommandExists "flutter")) { throw "Flutter is not installed or not in PATH." }
    Enter-Project; Invoke-External "flutter" @("pub","get") "Flutter pub get" | Out-Null
    if (Test-CommandExists "dart") { Invoke-External "dart" @("format","lib","test") "Dart format" -AllowFailure | Out-Null }
    Invoke-External "flutter" @("analyze","--no-fatal-infos","--no-fatal-warnings") "Flutter analyze" | Out-Null
    $result=Invoke-External "flutter" @("build","apk","--$Mode","--no-pub") "Build $Mode APK" -AllowFailure
    if ($result.ExitCode -ne 0) {
        $txt=$result.Output -join "`n"
        if ($txt -match "incremental caches|Could not close incremental caches|compile.*Kotlin") { Write-ToolLog "Kotlin cache problem detected. Repairing and retrying once." "WARN"; Repair-Basic; Enter-Project; Invoke-External "flutter" @("build","apk","--$Mode","--no-pub") "Build $Mode APK after repair" | Out-Null }
        else { throw "Flutter $Mode build failed. See log." }
    }
}

function Get-AndroidDeviceId {
    if (-not (Test-CommandExists "flutter")) { return $null }
    $r=Invoke-External "flutter" @("devices","--machine") "Discover devices" -AllowFailure -Quiet; if ($r.ExitCode -ne 0) { return $null }
    try { $json=($r.Output -join "`n") | ConvertFrom-Json; $dev=@($json | Where-Object { $_.targetPlatform -like "android*" -and $_.isSupported -ne $false }) | Select-Object -First 1; if ($dev) { return $dev.id } } catch { }
    return $null
}

function Run-App { $id=Get-AndroidDeviceId; if (-not $id) { throw "No supported Android device is online. Start an emulator or connect a device, then retry." }; Enter-Project; Invoke-External "flutter" @("run","-d",$id) "Run application" | Out-Null }

function Collect-Diagnostics {
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss"; $dir=Join-Path $env:TEMP "CARGame_Diagnostics_$stamp"; New-Item -ItemType Directory -Path $dir -Force | Out-Null
    try {
        Copy-Item $script:LogFile (Join-Path $dir "setup_tool.log") -Force -ErrorAction SilentlyContinue
        @("Generated: $(Get-Date)","Project: $ProjectPath","Repository: $RepositoryUrl","Branch: $Branch","Windows: $([Environment]::OSVersion.VersionString)","PowerShell: $($PSVersionTable.PSVersion)","JAVA_HOME: $env:JAVA_HOME","ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT","ANDROID_HOME: $env:ANDROID_HOME") | Set-Content (Join-Path $dir "environment.txt") -Encoding UTF8
        if (Test-Repo) { Enter-Project; $r=Invoke-External "git" @("status","--branch","--short") "Diagnostic git status" -AllowFailure -Quiet; $r.Output | Set-Content (Join-Path $dir "git_status.txt") -Encoding UTF8; $r=Invoke-External "git" @("remote","-v") "Diagnostic git remote" -AllowFailure -Quiet; $r.Output | Set-Content (Join-Path $dir "git_remote.txt") -Encoding UTF8 }
        if (Test-CommandExists "flutter") { $r=Invoke-External "flutter" @("doctor","-v") "Diagnostic flutter doctor" -AllowFailure -Quiet; $r.Output | Set-Content (Join-Path $dir "flutter_doctor.txt") -Encoding UTF8 }
        Get-Process | Select-Object ProcessName,Id,Path -ErrorAction SilentlyContinue | Out-File (Join-Path $dir "processes.txt") -Encoding UTF8
        $zip=Join-Path $script:LogDirectory "CARGame_Diagnostics_$stamp.zip"; Compress-Archive -Path (Join-Path $dir "*") -DestinationPath $zip -Force; Write-ToolLog "Diagnostics ZIP created: $zip" "OK"
    } finally { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

function Show-Failure {
    param($Err)
    Write-Host ""; Write-Host "============================================================" -ForegroundColor Red; Write-Host " OPERATION FAILED" -ForegroundColor Red; Write-Host "============================================================" -ForegroundColor Red; Write-Host $Err.Exception.Message -ForegroundColor Red
    if ($script:LastFailure) { Write-Host "Step      : $($script:LastFailure.Step)"; Write-Host "Command   : $($script:LastFailure.Command)"; Write-Host "Exit Code : $($script:LastFailure.ExitCode)" }
    Write-Host "Log       : $script:LogFile" -ForegroundColor Yellow; Write-Host "The tool will remain open." -ForegroundColor Yellow; try { Write-ToolLog "Operation failed: $($Err.Exception.Message)" "ERROR" } catch { }
}

function Invoke-SafeAction { param([scriptblock]$Action); try { & $Action } catch { Show-Failure $_ } finally { try { Set-Location $OriginalLocation } catch { }; Pause-Tool } }

try {
    Initialize-Log; Show-Header; Write-Host "Startup safety check..." -ForegroundColor Yellow
    try { Run-Diagnostics -NoPause } catch { Write-Host "Diagnostics could not finish, but the Setup Tool will continue." -ForegroundColor Yellow; Write-Host $_.Exception.Message -ForegroundColor Red }

    while ($true) {
        Show-Header
        Write-Host "1  - First download / install project"
        Write-Host "2  - Update project from GitHub"
        Write-Host "3  - Upload local changes to GitHub"
        Write-Host "4  - Update + repair + run"
        Write-Host "5  - Repair Git + Flutter + Gradle"
        Write-Host "6  - Run diagnostics now"
        Write-Host "7  - Collect diagnostics ZIP"
        Write-Host "8  - Flutter doctor"
        Write-Host "9  - Flutter cache repair"
        Write-Host "10 - Build Debug APK"
        Write-Host "11 - Build Release APK"
        Write-Host "12 - Run app on supported Android device"
        Write-Host "13 - Full repair + Build Release APK"
        Write-Host "14 - Backup + UNDO local changes + apply GitHub version"
        Write-Host "15 - Show local source/generated change summary"
        Write-Host "0  - Exit"
        Write-Host ""
        $choice=Read-Host "Choose an option"
        if ($choice -eq "0") { break }
        switch ($choice) {
            "1"  { Invoke-SafeAction { First-Download } }
            "2"  { Invoke-SafeAction { Update-Project } }
            "3"  { Invoke-SafeAction { Upload-Changes } }
            "4"  { Invoke-SafeAction { Update-Project; Repair-Basic; Run-App } }
            "5"  { Invoke-SafeAction { Repair-Basic } }
            "6"  { Invoke-SafeAction { Run-Diagnostics -NoPause } }
            "7"  { Invoke-SafeAction { Collect-Diagnostics } }
            "8"  { Invoke-SafeAction { Invoke-External "flutter" @("doctor","-v") "Flutter doctor" | Out-Null } }
            "9"  { Invoke-SafeAction { Remove-SafeCaches; Enter-Project; Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure | Out-Null; Invoke-External "flutter" @("pub","get") "Flutter pub get" | Out-Null } }
            "10" { Invoke-SafeAction { Build-Apk "debug" } }
            "11" { Invoke-SafeAction { Build-Apk "release" } }
            "12" { Invoke-SafeAction { Run-App } }
            "13" { Invoke-SafeAction { Repair-Basic; Build-Apk "release" } }
            "14" { Invoke-SafeAction { Sync-FromGitHub } }
            "15" { Invoke-SafeAction { Show-ChangeSummary | Out-Null } }
            default { Write-Host "Invalid option." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    }
    Write-ToolLog "Setup Tool closed" "OK"
} catch {
    try { Show-Failure $_ } catch { Write-Host "FATAL STARTUP ERROR" -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red }
    Write-Host ""; Write-Host "The window will NOT close automatically." -ForegroundColor Yellow; [void](Read-Host "Press Enter to close")
} finally { try { Set-Location $OriginalLocation } catch { } }
