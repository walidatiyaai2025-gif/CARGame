[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

# CARGame Setup Tool v2.4.0
# Windows PowerShell 5.1 compatible.
# Safe by default. Destructive sync creates a backup and requires YES.

$ErrorActionPreference = "Continue"
$ToolVersion = "2.4.0"
$OriginalLocation = (Get-Location).Path
$script:LastFailure = $null

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot ".git"))) { $ProjectPath = $PSScriptRoot }
    else { $ProjectPath = "D:\Apps\CARGame" }
}

$ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath).TrimEnd('\')
$ProjectParent = Split-Path $ProjectPath -Parent
if (-not $ProjectParent) { $ProjectParent = $env:TEMP }
$LogDirectory = Join-Path $ProjectPath "logs\setup_tool"
$BackupDirectory = Join-Path $LogDirectory "backups"
$script:LogFile = $null

function Initialize-Log {
    try {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
        $script:LogFile = Join-Path $LogDirectory ("setup_tool_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    } catch {
        $script:LogDirectory = Join-Path $env:TEMP "CARGame_SetupTool_Logs"
        $script:BackupDirectory = Join-Path $script:LogDirectory "backups"
        New-Item -ItemType Directory -Path $script:BackupDirectory -Force | Out-Null
        $script:LogFile = Join-Path $script:LogDirectory ("setup_tool_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    }
    try { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] CARGame Setup Tool v$ToolVersion" | Set-Content $script:LogFile -Encoding UTF8 } catch { }
}

function Write-ToolLog {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch { }
    switch ($Level) {
        "OK" { Write-Host $line -ForegroundColor Green }
        "WARN" { Write-Host $line -ForegroundColor Yellow }
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

function Move-OutOfProjectFolder {
    try {
        $current = (Get-Location).Path
        if ($current -and $current.StartsWith($ProjectPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            Set-Location $ProjectParent
            Write-ToolLog "Moved PowerShell working directory outside project: $ProjectParent" "OK"
        }
    } catch { try { Set-Location $env:TEMP } catch { } }
}

function Restore-SafeLocation {
    try {
        if ($OriginalLocation -and -not $OriginalLocation.StartsWith($ProjectPath, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path $OriginalLocation)) { Set-Location $OriginalLocation }
        else { Set-Location $ProjectParent }
    } catch { try { Set-Location $env:TEMP } catch { } }
}

function Invoke-External {
    param([string]$FilePath,[string[]]$Arguments=@(),[string]$Step="Command",[switch]$AllowFailure,[switch]$Quiet,[string]$WorkingDirectory="")
    if (-not (Test-CommandExists $FilePath)) {
        $msg = "Required command '$FilePath' was not found in PATH."
        Write-ToolLog $msg "ERROR"
        if (-not $AllowFailure) { throw $msg }
        return [pscustomobject]@{ ExitCode=9009; Output=@($msg) }
    }
    $display = "$FilePath $($Arguments -join ' ')".Trim()
    Write-ToolLog "$Step -> $display"
    $oldPref = $ErrorActionPreference
    $oldLocation = (Get-Location).Path
    $ErrorActionPreference = "Continue"
    $output = @(); $exitCode = -1
    try {
        if ($WorkingDirectory) { Set-Location $WorkingDirectory }
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
    } catch {
        $output = @($_.Exception.Message); $exitCode = 1
    } finally {
        $ErrorActionPreference = $oldPref
        try { if ($oldLocation -and (Test-Path $oldLocation)) { Set-Location $oldLocation } } catch { }
    }
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

function Invoke-Git {
    param([string[]]$Arguments,[string]$Step="Git",[switch]$AllowFailure,[switch]$Quiet)
    $args = @("-C",$ProjectPath) + $Arguments
    return Invoke-External "git" $args $Step -AllowFailure:$AllowFailure -Quiet:$Quiet
}

function Ensure-Origin {
    if (-not (Test-Repo)) { return }
    $r = Invoke-Git @("remote") "Read remotes" -AllowFailure -Quiet
    if ($r.Output -notcontains "origin") { Invoke-Git @("remote","add","origin",$RepositoryUrl) "Add origin" | Out-Null; return }
    $current = Invoke-Git @("remote","get-url","origin") "Read origin" -AllowFailure -Quiet
    $url = $current.Output | Select-Object -First 1
    if ($url -ne $RepositoryUrl) { Write-ToolLog "Origin URL differs. Updating it." "WARN"; Invoke-Git @("remote","set-url","origin",$RepositoryUrl) "Fix origin" | Out-Null }
}

function Close-ProjectExplorerWindows {
    $closed = 0
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($window in @($shell.Windows())) {
            try {
                $url = [string]$window.LocationURL
                if ([string]::IsNullOrWhiteSpace($url) -or -not $url.StartsWith("file:",[System.StringComparison]::OrdinalIgnoreCase)) { continue }
                $path = [uri]::UnescapeDataString(([uri]$url).LocalPath).TrimEnd('\')
                if ($path.StartsWith($ProjectPath,[System.StringComparison]::OrdinalIgnoreCase)) {
                    Write-ToolLog "Closing Explorer window: $path" "WARN"
                    $window.Quit(); $closed++
                }
            } catch { }
        }
    } catch { Write-ToolLog "Explorer window detection unavailable: $($_.Exception.Message)" "WARN" }
    return $closed
}

function Stop-ProjectLockingProcesses {
    param([switch]$Aggressive)
    Write-Host ""
    Write-Host "RELEASING PROJECT FILE/FOLDER LOCKS" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"
    Move-OutOfProjectFolder
    $stopped = New-Object System.Collections.Generic.List[string]
    $currentPid = $PID
    $projectRegex = [regex]::Escape($ProjectPath)
    $projectName = Split-Path $ProjectPath -Leaf

    $gradlew = Join-Path $ProjectPath "android\gradlew.bat"
    if (Test-Path $gradlew) {
        try { Write-ToolLog "Stopping Gradle daemons"; & $gradlew --stop 2>&1 | ForEach-Object { Write-Host $_ } }
        catch { Write-ToolLog "Gradle daemon stop failed; continuing with forced cleanup." "WARN" }
    }

    [void](Close-ProjectExplorerWindows)
    Start-Sleep -Milliseconds 600

    $known = @("java.exe","javaw.exe","dart.exe","adb.exe","node.exe","gradle.exe","code.exe","studio64.exe","idea64.exe","devenv.exe","msbuild.exe","cmd.exe")
    try {
        foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
            try {
                if (-not $proc.ProcessId -or $proc.ProcessId -eq $currentPid) { continue }
                $name = ([string]$proc.Name).ToLowerInvariant()
                if ($known -notcontains $name) { continue }
                $matches = ([string]$proc.CommandLine) -match $projectRegex
                if (-not $matches) {
                    $gp = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue
                    if ($gp -and $gp.MainWindowTitle -and $gp.MainWindowTitle -like "*$projectName*") { $matches = $true }
                }
                if ($matches) {
                    Write-ToolLog "Stopping project process: $name PID=$($proc.ProcessId)" "WARN"
                    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
                    $stopped.Add("$name ($($proc.ProcessId))")
                }
            } catch { }
        }
    } catch { Write-ToolLog "Process detection failed: $($_.Exception.Message)" "WARN" }

    $handle = Get-Command handle.exe -ErrorAction SilentlyContinue
    if ($handle) {
        try {
            Write-ToolLog "Sysinternals handle.exe detected; scanning exact handles." "INFO"
            $pids = New-Object System.Collections.Generic.HashSet[int]
            foreach ($line in @(& $handle.Source -accepteula -nobanner $ProjectPath 2>&1)) {
                if ([string]$line -match 'pid:\s*(\d+)') { [void]$pids.Add([int]$Matches[1]) }
            }
            foreach ($id in $pids) {
                if ($id -eq $currentPid) { continue }
                $gp = Get-Process -Id $id -ErrorAction SilentlyContinue
                if (-not $gp) { continue }
                if (-not $Aggressive -and $gp.ProcessName -in @("explorer","powershell","pwsh")) { continue }
                Write-ToolLog "Stopping exact handle owner: $($gp.ProcessName) PID=$id" "WARN"
                Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
                $stopped.Add("$($gp.ProcessName) ($id)")
            }
        } catch { Write-ToolLog "handle.exe scan failed: $($_.Exception.Message)" "WARN" }
    }

    Start-Sleep -Seconds 1
    if ($stopped.Count -eq 0) { Write-ToolLog "No project-specific locking processes required termination." "OK" }
    else { Write-ToolLog "Stopped $($stopped.Count) locking process(es): $($stopped -join ', ')" "OK" }
    return $stopped.Count
}

function Get-LocalChanges {
    if (-not (Test-Repo)) { return @() }
    $r = Invoke-Git @("status","--porcelain") "Check local changes" -AllowFailure -Quiet
    return @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

function Test-GeneratedPath {
    param([string]$StatusLine)
    $text = [string]$StatusLine
    $path = $text.Substring([Math]::Min(3,$text.Length)).Trim().Replace('"','')
    foreach ($p in @('^build/','^\.dart_tool/','^android/\.gradle/','^\.gradle-user-home-','^node_modules/','^logs/','^\.metadata$','^android/app/src/debug/','^android/app/src/profile/')) { if ($path -match $p) { return $true } }
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
    Write-Host ""; Write-Host "LOCAL CHANGE SUMMARY" -ForegroundColor Yellow
    Write-Host "  Source changes    : $($s.Source.Count)"
    Write-Host "  Generated changes : $($s.Generated.Count)"
    if ($s.Source.Count -gt 0) { Write-Host ""; Write-Host "Source changes:" -ForegroundColor Yellow; $s.Source | ForEach-Object { Write-Host "  $_" } }
    if ($s.Generated.Count -gt 0) { Write-Host ""; Write-Host "Generated/cache changes:" -ForegroundColor DarkYellow; $s.Generated | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }; if ($s.Generated.Count -gt 25) { Write-Host "  ... $($s.Generated.Count-25) more" } }
    return $s
}

function Remove-SafeCaches {
    Move-OutOfProjectFolder
    foreach ($relative in @("build",".dart_tool","android\.gradle","node_modules")) {
        $p = Join-Path $ProjectPath $relative
        if (Test-Path $p) { Write-ToolLog "Removing generated cache: $p" "WARN"; Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path $ProjectPath) {
        Get-ChildItem $ProjectPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like ".gradle-user-home-*" } | ForEach-Object { Write-ToolLog "Removing generated cache: $($_.FullName)" "WARN"; Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Backup-LocalChanges {
    if (-not (Test-Repo)) { return $null }
    $s = Get-ChangeSummary
    if ($s.All.Count -eq 0) { return $null }
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $root = Join-Path $script:BackupDirectory "local_changes_$stamp"
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $s.All | Set-Content (Join-Path $root "git_status.txt") -Encoding UTF8
    $diff = Invoke-Git @("diff","--binary") "Backup tracked diff" -AllowFailure -Quiet
    $diff.Output | Set-Content (Join-Path $root "tracked_changes.patch") -Encoding UTF8
    $staged = Invoke-Git @("diff","--cached","--binary") "Backup staged diff" -AllowFailure -Quiet
    $staged.Output | Set-Content (Join-Path $root "staged_changes.patch") -Encoding UTF8
    $untracked = (Invoke-Git @("ls-files","--others","--exclude-standard") "List untracked files" -AllowFailure -Quiet).Output
    foreach ($rel in $untracked) {
        if ([string]::IsNullOrWhiteSpace([string]$rel) -or (Test-GeneratedPath "?? $rel")) { continue }
        $src = Join-Path $ProjectPath ([string]$rel)
        if (Test-Path $src -PathType Leaf) {
            $dst = Join-Path (Join-Path $root "untracked_source") ([string]$rel)
            New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
            Copy-Item $src $dst -Force -ErrorAction SilentlyContinue
        }
    }
    $zip = "$root.zip"
    try { Compress-Archive -Path (Join-Path $root "*") -DestinationPath $zip -Force; Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue; Write-ToolLog "Local backup created: $zip" "OK"; return $zip }
    catch { Write-ToolLog "Backup folder created: $root" "WARN"; return $root }
}

function Sync-FromGitHub {
    if (-not (Test-Repo)) { throw "Project is not a Git repository. Use First Download." }
    Ensure-Origin
    $s = Show-ChangeSummary
    Write-Host ""; Write-Host "This will replace local files with origin/$Branch." -ForegroundColor Red
    Write-Host "A backup of source changes is created first." -ForegroundColor Yellow
    $confirm = Read-Host "Type YES to continue"
    if ($confirm -cne "YES") { Write-ToolLog "Sync cancelled." "WARN"; return $false }
    $backup = Backup-LocalChanges
    if ($backup) { Write-Host "Backup: $backup" -ForegroundColor Green }
    [void](Stop-ProjectLockingProcesses)
    Move-OutOfProjectFolder
    Invoke-Git @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch" | Out-Null
    Invoke-Git @("reset","--hard","origin/$Branch") "Reset tracked files" | Out-Null
    Invoke-Git @("clean","-fd","-e","logs/") "Remove untracked files" | Out-Null
    $checkout = Invoke-Git @("checkout",$Branch) "Checkout $Branch" -AllowFailure
    if ($checkout.ExitCode -ne 0) { Invoke-Git @("checkout","-B",$Branch,"origin/$Branch") "Recreate branch" | Out-Null }
    if (Test-CommandExists "flutter") { Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath | Out-Null }
    Write-ToolLog "GitHub version applied successfully." "OK"
    return $true
}

function Add-DiagnosticResult { param([string]$Name,[bool]$Ok,[string]$Details,[bool]$WarningOnly=$false); if ($Ok) { Write-Host ("[OK]   {0,-20} {1}" -f $Name,$Details) -ForegroundColor Green } elseif ($WarningOnly) { Write-Host ("[WARN] {0,-20} {1}" -f $Name,$Details) -ForegroundColor Yellow } else { Write-Host ("[FAIL] {0,-20} {1}" -f $Name,$Details) -ForegroundColor Red } }

function Run-Diagnostics {
    param([switch]$NoPause)
    Write-Host ""; Write-Host "SYSTEM + PROJECT DIAGNOSTICS" -ForegroundColor Yellow; Write-Host "------------------------------------------------------------"
    $score=100; $problems=0; $warnings=0
    try { Add-DiagnosticResult "Windows" $true ([Environment]::OSVersion.VersionString) } catch { $problems++; $score-=8; Add-DiagnosticResult "Windows" $false "Check failed" }
    try { Add-DiagnosticResult "PowerShell" $true $PSVersionTable.PSVersion.ToString() } catch { $warnings++; $score-=2; Add-DiagnosticResult "PowerShell" $false "Unavailable" $true }
    foreach ($cmd in @("git","flutter","dart","java")) { $found=Get-Command $cmd -ErrorAction SilentlyContinue; if ($found) { Add-DiagnosticResult $cmd $true $found.Source } else { $problems++; $score-=8; Add-DiagnosticResult $cmd $false "NOT FOUND" } }
    try { if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) { Add-DiagnosticResult "JAVA_HOME" $true $env:JAVA_HOME } else { $warnings++; $score-=3; Add-DiagnosticResult "JAVA_HOME" $false "Missing or invalid" $true } } catch { }
    try { $sdk=$env:ANDROID_SDK_ROOT; if(-not $sdk){$sdk=$env:ANDROID_HOME}; if($sdk -and (Test-Path $sdk)){Add-DiagnosticResult "Android SDK" $true $sdk}else{$warnings++;$score-=3;Add-DiagnosticResult "Android SDK" $false "Environment variable not set" $true} } catch { }
    try { $tcp=Test-NetConnection github.com -Port 443 -WarningAction SilentlyContinue; if($tcp.TcpTestSucceeded){Add-DiagnosticResult "GitHub HTTPS" $true "github.com:443 reachable"}else{$problems++;$score-=10;Add-DiagnosticResult "GitHub HTTPS" $false "Unreachable"} } catch { $warnings++;$score-=3;Add-DiagnosticResult "GitHub HTTPS" $false "Check unavailable" $true }
    if(Test-Repo){ try { Add-DiagnosticResult "Git repository" $true ".git found"; Ensure-Origin; $br=Invoke-Git @("branch","--show-current") "Read branch" -AllowFailure -Quiet; Add-DiagnosticResult "Branch" $true (($br.Output|Select-Object -First 1)); $s=Get-ChangeSummary; if($s.All.Count-eq0){Add-DiagnosticResult "Working tree" $true "Clean"}else{$warnings++;$score-=3;Add-DiagnosticResult "Working tree" $false "$($s.Source.Count) source / $($s.Generated.Count) generated" $true} } catch { $warnings++;$score-=4;Add-DiagnosticResult "Repository checks" $false $_.Exception.Message $true } } else { $warnings++;$score-=4;Add-DiagnosticResult "Git repository" $false "Not initialized/downloaded" $true }
    try { $drive=Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($ProjectPath).Substring(0,1)) -ErrorAction SilentlyContinue; if($drive){$free=[math]::Round($drive.Free/1GB,1);$ok=$free-ge5;if(-not$ok){$warnings++;$score-=4};Add-DiagnosticResult "Free disk" $ok "$free GB" (-not$ok)} } catch { }
    try { if(Test-CommandExists "flutter"){$dev=Invoke-External "flutter" @("devices","--machine") "Discover devices" -AllowFailure -Quiet -WorkingDirectory $ProjectPath;$txt=$dev.Output-join"`n";if($dev.ExitCode-eq0-and$txt-match'"targetPlatform"\s*:\s*"android'){Add-DiagnosticResult "Android device" $true "Detected"}else{$warnings++;$score-=2;Add-DiagnosticResult "Android device" $false "No supported Android device online" $true}} } catch { }
    if($score-lt0){$score=0}; Write-Host "------------------------------------------------------------"; Write-Host "Health Score : $score%" -ForegroundColor Cyan; Write-Host "Problems     : $problems"; Write-Host "Warnings     : $warnings"; Write-ToolLog "Diagnostics completed. Health=$score%, Problems=$problems, Warnings=$warnings" "OK"
    if(-not$NoPause){Pause-Tool}
}

function Repair-Basic {
    Write-ToolLog "Starting basic repair"
    [void](Stop-ProjectLockingProcesses)
    if(Test-Repo){ foreach($lock in @(".git\index.lock",".git\shallow.lock")){ $p=Join-Path $ProjectPath $lock; if(Test-Path $p){Remove-Item $p -Force -ErrorAction SilentlyContinue;Write-ToolLog "Removed $lock" "OK"} }; Ensure-Origin; Invoke-Git @("fsck","--no-progress") "Git fsck" -AllowFailure | Out-Null; Invoke-Git @("fetch","--prune","origin") "Git fetch" -AllowFailure | Out-Null }
    Remove-SafeCaches
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure -WorkingDirectory $ProjectPath | Out-Null;Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath | Out-Null}
    Write-ToolLog "Basic repair completed" "OK"
}

function First-Download {
    if(-not(Test-CommandExists "git")){throw "Git is not installed or not in PATH."}
    if(Test-Repo){Write-ToolLog "Repository already exists; switching to update." "WARN";Update-Project;return}
    if(Test-Path $ProjectPath){$items=@(Get-ChildItem $ProjectPath -Force -ErrorAction SilentlyContinue);if($items.Count-gt0){[void](Stop-ProjectLockingProcesses);Move-OutOfProjectFolder;$backup="$ProjectPath`_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')";Write-ToolLog "Moving existing folder to $backup" "WARN";Move-Item $ProjectPath $backup -Force}}
    if(-not(Test-Path $ProjectParent)){New-Item -ItemType Directory -Path $ProjectParent -Force|Out-Null}
    Invoke-External "git" @("clone","--branch",$Branch,"--single-branch",$RepositoryUrl,$ProjectPath) "Clone repository" | Out-Null
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
}

function Update-Project {
    if(-not(Test-Repo)){First-Download;return};Ensure-Origin
    $s=Get-ChangeSummary
    if($s.Source.Count-gt0){Show-ChangeSummary|Out-Null;Write-Host "";Write-Host "1 - Backup + DISCARD local changes + apply GitHub" -ForegroundColor Yellow;Write-Host "2 - Keep local changes and cancel update";Write-Host "3 - Upload local changes to GitHub";$a=Read-Host "Choose [1/2/3]";if($a-eq"1"){[void](Sync-FromGitHub);return}elseif($a-eq"3"){Upload-Changes;return}else{Write-ToolLog "Update cancelled to protect local source changes." "WARN";return}}
    if($s.Generated.Count-gt0){[void](Stop-ProjectLockingProcesses);Remove-SafeCaches;Invoke-Git @("clean","-fd","-e","logs/") "Clean generated files" -AllowFailure|Out-Null}
    Invoke-Git @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch"|Out-Null
    $co=Invoke-Git @("checkout",$Branch) "Checkout $Branch" -AllowFailure;if($co.ExitCode-ne0){Invoke-Git @("checkout","-b",$Branch,"origin/$Branch") "Create branch"|Out-Null}
    Invoke-Git @("pull","--ff-only","origin",$Branch) "Fast-forward update"|Out-Null
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null};Write-ToolLog "Project update completed" "OK"
}

function Upload-Changes {
    if(-not(Test-Repo)){throw "Project is not a Git repository."};Ensure-Origin;$s=Show-ChangeSummary;if($s.All.Count-eq0){Write-ToolLog "No local changes to upload." "OK";return};$msg=Read-Host "Commit message [Update project]";if([string]::IsNullOrWhiteSpace($msg)){$msg="Update project"};Invoke-Git @("add","-A") "Stage changes"|Out-Null;Invoke-Git @("commit","-m",$msg) "Commit changes"|Out-Null;$push=Invoke-Git @("push","origin",$Branch) "Push changes" -AllowFailure;if($push.ExitCode-ne0){throw "Push failed. Check authentication or remote changes in the log."}
}

function Build-Apk {
    param([ValidateSet("debug","release")][string]$Mode)
    if(-not(Test-CommandExists "flutter")){throw "Flutter is not installed or not in PATH."};Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null;if(Test-CommandExists "dart"){Invoke-External "dart" @("format","lib","test") "Dart format" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null};Invoke-External "flutter" @("analyze","--no-fatal-infos","--no-fatal-warnings") "Flutter analyze" -WorkingDirectory $ProjectPath|Out-Null;$r=Invoke-External "flutter" @("build","apk","--$Mode","--no-pub") "Build $Mode APK" -AllowFailure -WorkingDirectory $ProjectPath;if($r.ExitCode-ne0){$txt=$r.Output-join"`n";if($txt-match"incremental caches|Could not close incremental caches|compile.*Kotlin"){Repair-Basic;Invoke-External "flutter" @("build","apk","--$Mode","--no-pub") "Build $Mode APK after repair" -WorkingDirectory $ProjectPath|Out-Null}else{throw "Flutter $Mode build failed. See log."}}
}

function Get-AndroidDeviceId { if(-not(Test-CommandExists "flutter")){return $null};$r=Invoke-External "flutter" @("devices","--machine") "Discover devices" -AllowFailure -Quiet -WorkingDirectory $ProjectPath;if($r.ExitCode-ne0){return $null};try{$json=($r.Output-join"`n")|ConvertFrom-Json;$d=@($json|Where-Object{$_.targetPlatform-like"android*"-and$_.isSupported-ne$false})|Select-Object -First 1;if($d){return $d.id}}catch{};return $null }
function Run-App { $id=Get-AndroidDeviceId;if(-not$id){throw "No supported Android device is online."};Invoke-External "flutter" @("run","-d",$id) "Run application" -WorkingDirectory $ProjectPath|Out-Null }

function Collect-Diagnostics {
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss";$dir=Join-Path $env:TEMP "CARGame_Diagnostics_$stamp";New-Item -ItemType Directory -Path $dir -Force|Out-Null
    try{Copy-Item $script:LogFile (Join-Path $dir "setup_tool.log") -Force -ErrorAction SilentlyContinue;@("Generated: $(Get-Date)","Project: $ProjectPath","Repository: $RepositoryUrl","Branch: $Branch","Windows: $([Environment]::OSVersion.VersionString)","PowerShell: $($PSVersionTable.PSVersion)","JAVA_HOME: $env:JAVA_HOME","ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT","ANDROID_HOME: $env:ANDROID_HOME")|Set-Content (Join-Path $dir "environment.txt") -Encoding UTF8;if(Test-Repo){$r=Invoke-Git @("status","--branch","--short") "Diagnostic git status" -AllowFailure -Quiet;$r.Output|Set-Content (Join-Path $dir "git_status.txt") -Encoding UTF8};Get-Process|Select-Object ProcessName,Id,Path -ErrorAction SilentlyContinue|Out-File (Join-Path $dir "processes.txt") -Encoding UTF8;$zip=Join-Path $script:LogDirectory "CARGame_Diagnostics_$stamp.zip";Compress-Archive -Path (Join-Path $dir "*") -DestinationPath $zip -Force;Write-ToolLog "Diagnostics ZIP created: $zip" "OK"}finally{Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue}
}

function Show-Failure { param($Err);Write-Host "";Write-Host "============================================================" -ForegroundColor Red;Write-Host " OPERATION FAILED" -ForegroundColor Red;Write-Host "============================================================" -ForegroundColor Red;Write-Host $Err.Exception.Message -ForegroundColor Red;if($script:LastFailure){Write-Host "Step      : $($script:LastFailure.Step)";Write-Host "Command   : $($script:LastFailure.Command)";Write-Host "Exit Code : $($script:LastFailure.ExitCode)"};Write-Host "Log       : $script:LogFile" -ForegroundColor Yellow;Write-Host "The tool will remain open." -ForegroundColor Yellow;try{Write-ToolLog "Operation failed: $($Err.Exception.Message)" "ERROR"}catch{} }
function Invoke-SafeAction { param([scriptblock]$Action);try{& $Action}catch{Show-Failure $_}finally{Restore-SafeLocation;Pause-Tool} }

try {
    Initialize-Log;Show-Header;Write-Host "Startup safety check..." -ForegroundColor Yellow
    try{Run-Diagnostics -NoPause}catch{Write-Host "Diagnostics could not finish, but the tool will continue." -ForegroundColor Yellow;Write-Host $_.Exception.Message -ForegroundColor Red}
    while($true){
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
        Write-Host "16 - Close/Kill processes locking project files"
        Write-Host "0  - Exit"
        Write-Host ""
        $choice=Read-Host "Choose an option";if($choice-eq"0"){break}
        switch($choice){
            "1"{Invoke-SafeAction{First-Download}}
            "2"{Invoke-SafeAction{Update-Project}}
            "3"{Invoke-SafeAction{Upload-Changes}}
            "4"{Invoke-SafeAction{Update-Project;Repair-Basic;Run-App}}
            "5"{Invoke-SafeAction{Repair-Basic}}
            "6"{Invoke-SafeAction{Run-Diagnostics -NoPause}}
            "7"{Invoke-SafeAction{Collect-Diagnostics}}
            "8"{Invoke-SafeAction{Invoke-External "flutter" @("doctor","-v") "Flutter doctor" -WorkingDirectory $ProjectPath|Out-Null}}
            "9"{Invoke-SafeAction{[void](Stop-ProjectLockingProcesses);Remove-SafeCaches;Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null;Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null}}
            "10"{Invoke-SafeAction{Build-Apk "debug"}}
            "11"{Invoke-SafeAction{Build-Apk "release"}}
            "12"{Invoke-SafeAction{Run-App}}
            "13"{Invoke-SafeAction{Repair-Basic;Build-Apk "release"}}
            "14"{Invoke-SafeAction{[void](Sync-FromGitHub)}}
            "15"{Invoke-SafeAction{Show-ChangeSummary|Out-Null}}
            "16"{Invoke-SafeAction{[void](Stop-ProjectLockingProcesses -Aggressive)}}
            default{Write-Host "Invalid option." -ForegroundColor Yellow;Start-Sleep -Seconds 1}
        }
    }
    Write-ToolLog "Setup Tool closed" "OK"
} catch { try{Show-Failure $_}catch{Write-Host "FATAL STARTUP ERROR" -ForegroundColor Red;Write-Host $_.Exception.Message -ForegroundColor Red};Write-Host "";Write-Host "The window will NOT close automatically." -ForegroundColor Yellow;[void](Read-Host "Press Enter to close") }
finally { Restore-SafeLocation }
