[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

# CARGame Setup Tool v2.6.1
# Windows PowerShell 5.1 compatible.
# Safe by default: destructive sync creates a backup and requires YES.

$ErrorActionPreference = "Continue"
$ToolVersion = "2.6.1"
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
    param([string]$Message,[string]$Level="INFO")
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
function Test-CommandExists { param([string]$Name); return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Test-Repo { return Test-Path (Join-Path $ProjectPath ".git") }

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

function Move-OutOfProjectFolder {
    try {
        $current = (Get-Location).Path
        if ($current -and $current.StartsWith($ProjectPath,[System.StringComparison]::OrdinalIgnoreCase)) {
            Set-Location $ProjectParent
            Write-ToolLog "Moved PowerShell working directory outside project: $ProjectParent" "OK"
        }
    } catch { try { Set-Location $env:TEMP } catch { } }
}

function Restore-SafeLocation {
    try {
        if ($OriginalLocation -and -not $OriginalLocation.StartsWith($ProjectPath,[System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path $OriginalLocation)) { Set-Location $OriginalLocation }
        else { Set-Location $ProjectParent }
    } catch { try { Set-Location $env:TEMP } catch { } }
}

function Invoke-External {
    param(
        [string]$FilePath,
        [string[]]$Arguments=@(),
        [string]$Step="Command",
        [switch]$AllowFailure,
        [switch]$Quiet,
        [string]$WorkingDirectory=""
    )

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
        $output = @($_.Exception.Message)
        $exitCode = 1
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

function Get-GitSafeDirectoryValue {
    return $ProjectPath.Replace('\','/')
}

function Ensure-GitSafeDirectory {
    if (-not (Test-CommandExists "git")) { return $false }
    if (-not (Test-Path $ProjectPath)) { return $false }

    $safePath = Get-GitSafeDirectoryValue
    try {
        $existing = @(& git config --global --get-all safe.directory 2>$null)
        if ($LASTEXITCODE -eq 0 -and $existing -contains $safePath) { return $true }
    } catch { }

    Write-ToolLog "Repairing Git safe.directory for repository ownership mismatch: $safePath" "WARN"
    $result = Invoke-External "git" @("config","--global","--add","safe.directory",$safePath) "Repair Git safe.directory" -AllowFailure -Quiet
    if ($result.ExitCode -eq 0) {
        Write-ToolLog "Git safe.directory repaired: $safePath" "OK"
        return $true
    }
    return $false
}

function Test-DubiousOwnershipOutput {
    param([object[]]$Output)
    $text = ($Output -join [Environment]::NewLine)
    return $text -match "dubious ownership" -or $text -match "safe\.directory"
}

function Invoke-Git {
    param([string[]]$Arguments,[string]$Step="Git",[switch]$AllowFailure,[switch]$Quiet)

    if (Test-Path $ProjectPath) { [void](Ensure-GitSafeDirectory) }

    $result = Invoke-External "git" (@("-C",$ProjectPath)+$Arguments) $Step -AllowFailure -Quiet:$Quiet
    if ($result.ExitCode -ne 0 -and (Test-DubiousOwnershipOutput $result.Output)) {
        Write-ToolLog "Git reported dubious ownership; repairing safe.directory and retrying once." "WARN"
        if (Ensure-GitSafeDirectory) {
            $result = Invoke-External "git" (@("-C",$ProjectPath)+$Arguments) "$Step (retry)" -AllowFailure -Quiet:$Quiet
        }
    }
    if ($result.ExitCode -ne 0 -and -not $AllowFailure) { throw "$Step failed with exit code $($result.ExitCode)." }
    return $result
}

function Ensure-Origin {
    if (-not (Test-Repo)) { return }
    [void](Ensure-GitSafeDirectory)
    $r = Invoke-Git @("remote") "Read remotes" -AllowFailure -Quiet
    if ($r.Output -notcontains "origin") { Invoke-Git @("remote","add","origin",$RepositoryUrl) "Add origin" | Out-Null; return }
    $current = Invoke-Git @("remote","get-url","origin") "Read origin" -AllowFailure -Quiet
    $url = $current.Output | Select-Object -First 1
    if ($url -ne $RepositoryUrl) { Invoke-Git @("remote","set-url","origin",$RepositoryUrl) "Fix origin" | Out-Null }
}

function Close-ProjectExplorerWindows {
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($window in @($shell.Windows())) {
            try {
                $url = [string]$window.LocationURL
                if ([string]::IsNullOrWhiteSpace($url) -or -not $url.StartsWith("file:",[System.StringComparison]::OrdinalIgnoreCase)) { continue }
                $path = [uri]::UnescapeDataString(([uri]$url).LocalPath).TrimEnd('\')
                if ($path.StartsWith($ProjectPath,[System.StringComparison]::OrdinalIgnoreCase)) {
                    Write-ToolLog "Closing Explorer window: $path" "WARN"
                    $window.Quit()
                }
            } catch { }
        }
    } catch { Write-ToolLog "Explorer window detection unavailable." "WARN" }
}

function Stop-ProjectLockingProcesses {
    param([switch]$Aggressive)
    Write-Host ""
    Write-Host "RELEASING PROJECT FILE/FOLDER LOCKS" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"
    Move-OutOfProjectFolder

    $gradlew = Join-Path $ProjectPath "android\gradlew.bat"
    if (Test-Path $gradlew) {
        try { & $gradlew --stop 2>&1 | ForEach-Object { Write-Host $_ } } catch { }
    }
    Close-ProjectExplorerWindows
    Start-Sleep -Milliseconds 500

    $currentPid = $PID
    $projectRegex = [regex]::Escape($ProjectPath)
    $projectName = Split-Path $ProjectPath -Leaf
    $known = @("java.exe","javaw.exe","dart.exe","node.exe","gradle.exe","code.exe","studio64.exe","idea64.exe","devenv.exe","msbuild.exe","cmd.exe")

    try {
        foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
            try {
                if (-not $proc.ProcessId -or $proc.ProcessId -eq $currentPid) { continue }
                $name = ([string]$proc.Name).ToLowerInvariant()
                if ($known -notcontains $name) { continue }
                $matches = ([string]$proc.CommandLine) -match $projectRegex
                if (-not $matches) {
                    $gp = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue
                    if ($gp -and $gp.MainWindowTitle -like "*$projectName*") { $matches = $true }
                }
                if ($matches) {
                    Write-ToolLog "Stopping project process: $name PID=$($proc.ProcessId)" "WARN"
                    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
                }
            } catch { }
        }
    } catch { }
    Start-Sleep -Seconds 1
    Write-ToolLog "Project lock release pass completed." "OK"
}

function Get-LocalChanges {
    if (-not (Test-Repo)) { return @() }
    $r = Invoke-Git @("status","--porcelain") "Check local changes" -AllowFailure -Quiet
    return @($r.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

function Test-GeneratedPath {
    param([string]$StatusLine)
    $text=[string]$StatusLine
    $path=$text.Substring([Math]::Min(3,$text.Length)).Trim().Replace('"','')
    foreach($p in @('^build/','^\.dart_tool/','^android/\.gradle/','^android/gradle/','^android/gradlew(?:\.bat)?$','^\.gradle-user-home-','^node_modules/','^logs/','^\.metadata$','^android/app/src/debug/','^android/app/src/profile/')) { if($path-match$p){return $true} }
    return $false
}

function Get-ChangeSummary {
    $all=@(Get-LocalChanges)
    $generated=@($all|Where-Object{Test-GeneratedPath $_})
    $source=@($all|Where-Object{-not(Test-GeneratedPath $_)})
    return [pscustomobject]@{All=$all;Generated=$generated;Source=$source}
}

function Show-ChangeSummary {
    $s=Get-ChangeSummary
    Write-Host "";Write-Host "LOCAL CHANGE SUMMARY" -ForegroundColor Yellow
    Write-Host "  Source changes    : $($s.Source.Count)"
    Write-Host "  Generated changes : $($s.Generated.Count)"
    if($s.Source.Count-gt0){Write-Host "";Write-Host "Source changes:" -ForegroundColor Yellow;$s.Source|ForEach-Object{Write-Host "  $_"}}
    if($s.Generated.Count-gt0){Write-Host "";Write-Host "Generated/cache changes:" -ForegroundColor DarkYellow;$s.Generated|Select-Object -First 25|ForEach-Object{Write-Host "  $_"}}
    return $s
}

function Remove-SafeCaches {
    Move-OutOfProjectFolder
    foreach($relative in @("build",".dart_tool","android\.gradle","node_modules")) {
        $p=Join-Path $ProjectPath $relative
        if(Test-Path $p){Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue}
    }
    if(Test-Path $ProjectPath){Get-ChildItem $ProjectPath -Directory -Force -ErrorAction SilentlyContinue|Where-Object{$_.Name-like".gradle-user-home-*"}|ForEach-Object{Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue}}
}

function Backup-LocalChanges {
    if(-not(Test-Repo)){return $null}
    $s=Get-ChangeSummary
    if($s.All.Count-eq0){return $null}
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss"
    $root=Join-Path $BackupDirectory "local_changes_$stamp"
    New-Item -ItemType Directory -Path $root -Force|Out-Null
    $s.All|Set-Content (Join-Path $root "git_status.txt") -Encoding UTF8
    (Invoke-Git @("diff","--binary") "Backup tracked diff" -AllowFailure -Quiet).Output|Set-Content (Join-Path $root "tracked_changes.patch") -Encoding UTF8
    (Invoke-Git @("diff","--cached","--binary") "Backup staged diff" -AllowFailure -Quiet).Output|Set-Content (Join-Path $root "staged_changes.patch") -Encoding UTF8
    $zip="$root.zip"
    try{Compress-Archive -Path (Join-Path $root "*") -DestinationPath $zip -Force;Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue;Write-ToolLog "Local backup created: $zip" "OK";return $zip}catch{return $root}
}

function Sync-FromGitHub {
    if(-not(Test-Repo)){throw "Project is not a Git repository. Use First Download."}
    Ensure-Origin
    $s=Show-ChangeSummary
    Write-Host "";Write-Host "This will replace local files with origin/$Branch." -ForegroundColor Red
    Write-Host "A backup of local changes is created first." -ForegroundColor Yellow
    $confirm=Read-Host "Type YES to continue"
    if($confirm-cne"YES"){Write-ToolLog "Sync cancelled." "WARN";return $false}
    $backup=Backup-LocalChanges
    if($backup){Write-Host "Backup: $backup" -ForegroundColor Green}
    Stop-ProjectLockingProcesses
    Move-OutOfProjectFolder
    Invoke-Git @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch"|Out-Null
    Invoke-Git @("reset","--hard","origin/$Branch") "Reset tracked files"|Out-Null
    Invoke-Git @("clean","-fd","-e","logs/") "Remove untracked files"|Out-Null
    $co=Invoke-Git @("checkout",$Branch) "Checkout $Branch" -AllowFailure
    if($co.ExitCode-ne0){Invoke-Git @("checkout","-B",$Branch,"origin/$Branch") "Recreate branch"|Out-Null}
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
    Write-ToolLog "GitHub version applied successfully." "OK"
    return $true
}

function Run-Diagnostics {
    param([switch]$NoPause)
    Write-Host "";Write-Host "SYSTEM + PROJECT DIAGNOSTICS" -ForegroundColor Yellow;Write-Host "------------------------------------------------------------"
    foreach($cmd in @("git","flutter","dart","java")){
        $found=Get-Command $cmd -ErrorAction SilentlyContinue
        if($found){Write-Host ("[OK]   {0,-18} {1}" -f $cmd,$found.Source) -ForegroundColor Green}else{Write-Host ("[FAIL] {0,-18} Not found" -f $cmd) -ForegroundColor Red}
    }
    if(Test-Repo){
        $safe=Ensure-GitSafeDirectory
        if($safe){Write-Host "[OK]   Git safe.directory $(Get-GitSafeDirectoryValue)" -ForegroundColor Green}else{Write-Host "[WARN] Git safe.directory repair failed" -ForegroundColor Yellow}
        Ensure-Origin
        $branchResult=Invoke-Git @("branch","--show-current") "Read current branch" -AllowFailure -Quiet
        $branchName=($branchResult.Output|Select-Object -First 1)
        Write-Host "[OK]   Git repository     $ProjectPath" -ForegroundColor Green
        if($branchName){Write-Host "[INFO] Current branch     $branchName" -ForegroundColor Cyan}
    }else{Write-Host "[WARN] Git repository     Not initialized" -ForegroundColor Yellow}
    if(Test-CommandExists "flutter"){
        $d=Invoke-External "flutter" @("devices") "Flutter devices" -AllowFailure -Quiet
        $online=@($d.Output|Where-Object{$_ -match "android" -and $_ -notmatch "offline"})
        if($online.Count-gt0){Write-Host "[OK]   Android device     $($online[0])" -ForegroundColor Green}else{Write-Host "[WARN] Android device     None online" -ForegroundColor Yellow}
    }
    if(-not$NoPause){Pause-Tool}
}

function First-Download {
    if(Test-Path $ProjectPath){
        Write-Host "Project folder already exists: $ProjectPath" -ForegroundColor Yellow
        Write-Host "Use Update/Undo or choose a different -ProjectPath." -ForegroundColor Yellow
        return
    }
    if(-not(Test-CommandExists "git")){throw "Git is required."}
    New-Item -ItemType Directory -Path $ProjectParent -Force|Out-Null
    Invoke-External "git" @("clone","--branch",$Branch,"$RepositoryUrl","$ProjectPath") "Clone repository"|Out-Null
    [void](Ensure-GitSafeDirectory)
    Ensure-Origin
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
}

function Update-Project {
    if(-not(Test-Repo)){First-Download;return}
    Ensure-Origin
    $s=Show-ChangeSummary
    if($s.Source.Count-gt0){
        Write-Host "";Write-Host "Local source changes detected." -ForegroundColor Yellow
        Write-Host "1 - Backup + DISCARD local changes + apply GitHub"
        Write-Host "2 - Keep local changes and cancel update"
        Write-Host "3 - Upload local changes to GitHub"
        $choice=Read-Host "Choose"
        switch($choice){"1"{[void](Sync-FromGitHub)}"3"{Upload-Changes}default{Write-ToolLog "Update cancelled to protect local source changes." "WARN"}}
        return
    }
    if($s.Generated.Count-gt0){Write-ToolLog "Only generated/cache changes found; cleaning them before update." "WARN";Stop-ProjectLockingProcesses;Remove-SafeCaches}
    Move-OutOfProjectFolder
    Invoke-Git @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch"|Out-Null
    Invoke-Git @("checkout",$Branch) "Checkout branch" -AllowFailure|Out-Null
    Invoke-Git @("pull","--ff-only","origin",$Branch) "Fast-forward update"|Out-Null
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
}

function Upload-Changes {
    if(-not(Test-Repo)){throw "Project is not a Git repository."}
    Ensure-Origin
    $s=Show-ChangeSummary
    if($s.Source.Count-eq0){Write-ToolLog "No source changes to upload." "WARN";return}
    Invoke-Git @("add","-A") "Stage changes"|Out-Null
    $message=Read-Host "Commit message"
    if([string]::IsNullOrWhiteSpace($message)){$message="Update CARGame"}
    $c=Invoke-Git @("commit","-m",$message) "Commit changes" -AllowFailure
    if($c.ExitCode-ne0 -and (($c.Output-join" ")-notmatch"nothing to commit")){throw "Git commit failed."}
    Invoke-Git @("push","origin",$Branch) "Push $Branch"|Out-Null
}

function Run-FlutterRepairBuild {
    if(-not(Test-CommandExists "flutter")){throw "Flutter is not available in PATH."}
    Stop-ProjectLockingProcesses
    Remove-SafeCaches
    Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null
    Invoke-External "flutter" @("analyze","--no-fatal-infos","--no-fatal-warnings") "Flutter analyze" -WorkingDirectory $ProjectPath|Out-Null
    Invoke-External "flutter" @("test") "Flutter test" -WorkingDirectory $ProjectPath|Out-Null
    Invoke-External "flutter" @("build","apk","--release","--no-pub") "Build release APK" -WorkingDirectory $ProjectPath|Out-Null
}

function Start-SmartAndroidDevice {
    if(-not(Test-CommandExists "flutter")){throw "Flutter is not available in PATH."}
    $devices=Invoke-External "flutter" @("devices") "Detect Flutter devices" -AllowFailure -Quiet
    if(@($devices.Output|Where-Object{$_ -match "android" -and $_ -notmatch "offline"}).Count-gt0){Write-ToolLog "Android device already online." "OK";return}
    if(Test-CommandExists "adb"){
        Invoke-External "adb" @("kill-server") "Restart ADB (stop)" -AllowFailure -Quiet|Out-Null
        Invoke-External "adb" @("start-server") "Restart ADB (start)" -AllowFailure -Quiet|Out-Null
    }
    $emu=Invoke-External "flutter" @("emulators") "List Flutter emulators" -AllowFailure -Quiet
    $ids=@()
    foreach($line in $emu.Output){if([string]$line -match '^\s*([^\s]+)\s+•'){$ids+=$Matches[1]}}
    if($ids.Count-eq0){throw "No Android emulator is configured. Create an AVD in Android Studio Device Manager or connect a device."}
    $id=$ids[0]
    Write-ToolLog "Launching emulator: $id"
    Invoke-External "flutter" @("emulators","--launch",$id) "Launch emulator" -AllowFailure|Out-Null
    for($i=0;$i-lt60;$i++){
        Start-Sleep -Seconds 3
        $check=Invoke-External "flutter" @("devices") "Wait for Android device" -AllowFailure -Quiet
        $online=@($check.Output|Where-Object{$_ -match "android" -and $_ -notmatch "offline"})
        if($online.Count-gt0){Write-ToolLog "Android device ready: $($online[0])" "OK";return}
        if($i-eq20 -and (Test-CommandExists "adb")){Invoke-External "adb" @("kill-server") "ADB repair stop" -AllowFailure -Quiet|Out-Null;Invoke-External "adb" @("start-server") "ADB repair start" -AllowFailure -Quiet|Out-Null}
    }
    throw "Android emulator did not become ready within 180 seconds."
}

function Run-Game {
    Start-SmartAndroidDevice
    Invoke-External "flutter" @("run") "Run game" -WorkingDirectory $ProjectPath|Out-Null
}

function Show-LastFailure {
    Write-Host "";Write-Host "LAST FAILURE" -ForegroundColor Yellow
    if($null-eq$script:LastFailure){Write-Host "No operation failure has been recorded in this session."}else{$script:LastFailure|Format-List|Out-Host}
    Write-Host "Log: $script:LogFile" -ForegroundColor Cyan
}

function Invoke-MenuAction {
    param([scriptblock]$Action)
    try{&$Action;Write-Host "";Write-ToolLog "Operation finished." "OK"}
    catch{
        $message=$_.Exception.Message
        Write-Host "";Write-Host "============================================================" -ForegroundColor Red
        Write-Host " OPERATION FAILED" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host $message -ForegroundColor Red
        if($script:LastFailure){Write-Host "Step      : $($script:LastFailure.Step)";Write-Host "Command   : $($script:LastFailure.Command)";Write-Host "Exit Code : $($script:LastFailure.ExitCode)"}
        Write-Host "Log       : $script:LogFile" -ForegroundColor Cyan
        Write-Host "The tool will remain open." -ForegroundColor Yellow
        Write-ToolLog "Operation failed: $message" "ERROR"
    }
    Pause-Tool
}

Initialize-Log

try {
    Run-Diagnostics -NoPause
    while($true){
        Show-Header
        Write-Host "1  - Diagnostics"
        Write-Host "2  - Update from GitHub"
        Write-Host "3  - First Download / Clone"
        Write-Host "4  - Repair + Analyze + Test + Release APK"
        Write-Host "5  - Upload local source changes to GitHub"
        Write-Host "6  - Flutter pub get"
        Write-Host "7  - Flutter analyze"
        Write-Host "8  - Flutter test"
        Write-Host "9  - Build release APK"
        Write-Host "10 - Flutter doctor"
        Write-Host "11 - Show git status"
        Write-Host "12 - Run game (auto-start Android device)"
        Write-Host "13 - Show last error / log"
        Write-Host "14 - Backup + UNDO local changes + apply GitHub version"
        Write-Host "15 - Show local source/generated change summary"
        Write-Host "16 - Close/Kill processes locking project files"
        Write-Host "17 - Smart Android Device Manager"
        Write-Host "0  - Exit"
        Write-Host ""
        $choice=Read-Host "Choose an option"
        switch($choice){
            "1"{Invoke-MenuAction{Run-Diagnostics -NoPause}}
            "2"{Invoke-MenuAction{Update-Project}}
            "3"{Invoke-MenuAction{First-Download}}
            "4"{Invoke-MenuAction{Run-FlutterRepairBuild}}
            "5"{Invoke-MenuAction{Upload-Changes}}
            "6"{Invoke-MenuAction{Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null}}
            "7"{Invoke-MenuAction{Invoke-External "flutter" @("analyze","--no-fatal-infos","--no-fatal-warnings") "Flutter analyze" -WorkingDirectory $ProjectPath|Out-Null}}
            "8"{Invoke-MenuAction{Invoke-External "flutter" @("test") "Flutter test" -WorkingDirectory $ProjectPath|Out-Null}}
            "9"{Invoke-MenuAction{Invoke-External "flutter" @("build","apk","--release","--no-pub") "Build release APK" -WorkingDirectory $ProjectPath|Out-Null}}
            "10"{Invoke-MenuAction{Invoke-External "flutter" @("doctor","-v") "Flutter doctor" -AllowFailure|Out-Null}}
            "11"{Invoke-MenuAction{(Show-ChangeSummary)|Out-Null}}
            "12"{Invoke-MenuAction{Run-Game}}
            "13"{Invoke-MenuAction{Show-LastFailure}}
            "14"{Invoke-MenuAction{[void](Sync-FromGitHub)}}
            "15"{Invoke-MenuAction{(Show-ChangeSummary)|Out-Null}}
            "16"{Invoke-MenuAction{Stop-ProjectLockingProcesses -Aggressive}}
            "17"{Invoke-MenuAction{Start-SmartAndroidDevice}}
            "0"{Restore-SafeLocation;Write-ToolLog "Setup Tool closed." "OK";break}
            default{Write-Host "Invalid option." -ForegroundColor Yellow;Start-Sleep -Seconds 1}
        }
        if($choice-eq"0"){break}
    }
}
catch{
    Write-Host "";Write-Host "============================================================" -ForegroundColor Red
    Write-Host " FATAL STARTUP ERROR" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Log: $script:LogFile" -ForegroundColor Cyan
    try{Write-ToolLog "Fatal startup error: $($_.Exception.Message)" "ERROR"}catch{}
    Pause-Tool
}
finally{Restore-SafeLocation}
