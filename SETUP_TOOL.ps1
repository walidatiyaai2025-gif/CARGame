[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [string]$RepositoryUrl = "https://github.com/walidatiyaai2025-gif/CARGame.git",
    [string]$Branch = "main"
)

# CARGame Setup Tool v2.6.0
# Windows PowerShell 5.1 compatible.
# Safe by default: destructive sync creates a backup and requires YES.

$ErrorActionPreference = "Continue"
$ToolVersion = "2.6.0"
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

function Invoke-Git {
    param([string[]]$Arguments,[string]$Step="Git",[switch]$AllowFailure,[switch]$Quiet)
    return Invoke-External "git" (@("-C",$ProjectPath)+$Arguments) $Step -AllowFailure:$AllowFailure -Quiet:$Quiet
}

function Ensure-Origin {
    if (-not (Test-Repo)) { return }
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
        if($found){Write-Host ("[OK]   {0,-18} {1}" -f $cmd,$found.Source) -ForegroundColor Green}else{Write-Host ("[FAIL] {0,-18} NOT FOUND" -f $cmd) -ForegroundColor Red}
    }
    if(Test-Repo){Write-Host "[OK]   Git repository      .git found" -ForegroundColor Green;$s=Get-ChangeSummary;Write-Host "[INFO] Working tree        $($s.Source.Count) source / $($s.Generated.Count) generated"}
    else{Write-Host "[WARN] Git repository      not initialized" -ForegroundColor Yellow}
    $id=Get-AndroidDeviceId
    if($id){Write-Host "[OK]   Android device      $id" -ForegroundColor Green}else{Write-Host "[WARN] Android device      none online" -ForegroundColor Yellow}
    if(-not$NoPause){Pause-Tool}
}

function Repair-Basic {
    Write-ToolLog "Starting basic repair"
    Stop-ProjectLockingProcesses
    if(Test-Repo){Ensure-Origin;Invoke-Git @("fsck","--no-progress") "Git fsck" -AllowFailure|Out-Null;Invoke-Git @("fetch","--prune","origin") "Git fetch" -AllowFailure|Out-Null}
    Remove-SafeCaches
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null;Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
    Write-ToolLog "Basic repair completed" "OK"
}

function First-Download {
    if(-not(Test-CommandExists "git")){throw "Git is not installed or not in PATH."}
    if(Test-Repo){Update-Project;return}
    if(Test-Path $ProjectPath){$items=@(Get-ChildItem $ProjectPath -Force -ErrorAction SilentlyContinue);if($items.Count-gt0){Stop-ProjectLockingProcesses;Move-OutOfProjectFolder;$backup="$ProjectPath`_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')";Move-Item $ProjectPath $backup -Force}}
    if(-not(Test-Path $ProjectParent)){New-Item -ItemType Directory -Path $ProjectParent -Force|Out-Null}
    Invoke-External "git" @("clone","--branch",$Branch,"--single-branch",$RepositoryUrl,$ProjectPath) "Clone repository"|Out-Null
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
}

function Update-Project {
    if(-not(Test-Repo)){First-Download;return}
    Ensure-Origin
    $s=Get-ChangeSummary
    if($s.Source.Count-gt0){Show-ChangeSummary|Out-Null;Write-Host "1 - Backup + DISCARD local changes + apply GitHub" -ForegroundColor Yellow;Write-Host "2 - Keep local changes and cancel";Write-Host "3 - Upload local changes";$a=Read-Host "Choose [1/2/3]";if($a-eq"1"){[void](Sync-FromGitHub);return}elseif($a-eq"3"){Upload-Changes;return}else{return}}
    if($s.Generated.Count-gt0){Stop-ProjectLockingProcesses;Remove-SafeCaches;Invoke-Git @("clean","-fd","-e","logs/") "Clean generated files" -AllowFailure|Out-Null}
    Invoke-Git @("fetch","--prune","origin",$Branch) "Fetch origin/$Branch"|Out-Null
    $co=Invoke-Git @("checkout",$Branch) "Checkout $Branch" -AllowFailure
    if($co.ExitCode-ne0){Invoke-Git @("checkout","-b",$Branch,"origin/$Branch") "Create branch"|Out-Null}
    Invoke-Git @("pull","--ff-only","origin",$Branch) "Fast-forward update"|Out-Null
    if(Test-CommandExists "flutter"){Invoke-External "flutter" @("pub","get") "Flutter pub get" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null}
}

function Upload-Changes {
    if(-not(Test-Repo)){throw "Project is not a Git repository."}
    Ensure-Origin
    $s=Show-ChangeSummary
    if($s.All.Count-eq0){Write-ToolLog "No local changes to upload." "OK";return}
    $msg=Read-Host "Commit message [Update project]";if([string]::IsNullOrWhiteSpace($msg)){$msg="Update project"}
    Invoke-Git @("add","-A") "Stage changes"|Out-Null
    Invoke-Git @("commit","-m",$msg) "Commit changes"|Out-Null
    $push=Invoke-Git @("push","origin",$Branch) "Push changes" -AllowFailure
    if($push.ExitCode-ne0){throw "Push failed. Check authentication or remote changes in the log."}
}

function Build-Apk {
    param([ValidateSet("debug","release")][string]$Mode)
    if(-not(Test-CommandExists "flutter")){throw "Flutter is not installed or not in PATH."}

    Write-ToolLog "Build mode does not run dart format; source files will not be rewritten." "OK"

    if($Mode-eq"release"){
        Write-ToolLog "Preparing lock-safe Release build." "INFO"
        Stop-ProjectLockingProcesses
        Remove-SafeCaches
        Invoke-External "flutter" @("clean") "Flutter clean before Release" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null
    }

    Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null
    Invoke-External "flutter" @("analyze","--no-fatal-infos","--no-fatal-warnings") "Flutter analyze" -WorkingDirectory $ProjectPath|Out-Null

    $r=Invoke-External "flutter" @("build","apk","--$Mode","--no-pub") "Build $Mode APK" -AllowFailure -WorkingDirectory $ProjectPath
    if($r.ExitCode-eq0){return}

    if($Mode-ne"release"){
        throw "Flutter $Mode build failed. See log."
    }

    $failureText=($r.Output-join[Environment]::NewLine)
    $looksLikeLockFailure=$failureText-match'Unable to delete directory|Failed to delete some children|minifyReleaseWithR8|classes\.dex|file.*open|working directory set in the target directory'
    if($looksLikeLockFailure){
        Write-ToolLog "Release build hit a Windows/Gradle file lock. Running aggressive recovery and retrying once." "WARN"
    }else{
        Write-ToolLog "Release build failed. Running one clean recovery retry before returning the error." "WARN"
    }

    Stop-ProjectLockingProcesses -Aggressive
    Remove-SafeCaches
    Start-Sleep -Seconds 2
    Invoke-External "flutter" @("clean") "Flutter clean after Release failure" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null
    Invoke-External "flutter" @("pub","get") "Flutter pub get after recovery" -WorkingDirectory $ProjectPath|Out-Null
    $retry=Invoke-External "flutter" @("build","apk","--release","--no-pub") "Retry Release APK after lock recovery" -AllowFailure -WorkingDirectory $ProjectPath
    if($retry.ExitCode-ne0){throw "Flutter release build failed after automatic lock recovery. See log."}
    Write-ToolLog "Release APK succeeded after automatic lock recovery." "OK"
}

function Get-AndroidDeviceId {
    if(-not(Test-CommandExists "flutter")){return $null}
    $r=Invoke-External "flutter" @("devices","--machine") "Discover devices" -AllowFailure -Quiet -WorkingDirectory $ProjectPath
    if($r.ExitCode-ne0){return $null}
    try{$json=($r.Output-join"`n")|ConvertFrom-Json;$d=@($json|Where-Object{$_.targetPlatform-like"android*"-and$_.isSupported-ne$false})|Select-Object -First 1;if($d){return $d.id}}catch{}
    return $null
}

function Get-AdbPath {
    $cmd=Get-Command adb.exe -ErrorAction SilentlyContinue
    if($cmd){return $cmd.Source}
    foreach($root in @($env:ANDROID_SDK_ROOT,$env:ANDROID_HOME,(Join-Path $env:LOCALAPPDATA "Android\Sdk"))){if([string]::IsNullOrWhiteSpace([string]$root)){continue};$p=Join-Path $root "platform-tools\adb.exe";if(Test-Path $p){return $p}}
    return $null
}

function Repair-Adb {
    $adb=Get-AdbPath
    if(-not$adb){Write-ToolLog "adb.exe not found." "WARN";return $false}
    Write-ToolLog "Restarting ADB server" "WARN"
    try{& $adb kill-server 2>&1|ForEach-Object{Write-Host $_}}catch{}
    Start-Sleep -Milliseconds 700
    try{& $adb start-server 2>&1|ForEach-Object{Write-Host $_}}catch{}
    Start-Sleep -Seconds 1
    return $true
}

function Get-InstalledAndroidEmulators {
    if(-not(Test-CommandExists "flutter")){return @()}
    $r=Invoke-External "flutter" @("emulators") "Discover Android emulators" -AllowFailure -Quiet -WorkingDirectory $ProjectPath
    if($r.ExitCode-ne0){return @()}
    $ids=New-Object System.Collections.Generic.List[string]
    foreach($line in $r.Output){$text=[string]$line;if($text-match'^\s*([^\s•]+)\s+•.*•\s+android\s*$'){$ids.Add($Matches[1].Trim())}}
    return @($ids)
}

function Wait-ForAndroidDevice {
    param([int]$TimeoutSeconds=150)
    $started=Get-Date;$adbRestarted=$false;$lastState="waiting"
    Write-Host "";Write-Host "Waiting for Android device to become ready..." -ForegroundColor Yellow
    while(((Get-Date)-$started).TotalSeconds-lt$TimeoutSeconds){
        $id=Get-AndroidDeviceId
        if($id){Write-Host "";Write-ToolLog "Android device ready: $id" "OK";return $id}
        $adb=Get-AdbPath
        if($adb){try{$states=@(& $adb devices 2>$null);$txt=$states-join' ';if($txt-match'\boffline\b'){$lastState="offline";if(-not$adbRestarted){[void](Repair-Adb);$adbRestarted=$true}}elseif($txt-match'\tdevice\b'){$lastState="booting"}else{$lastState="waiting"}}catch{}}
        $elapsed=[int]((Get-Date)-$started).TotalSeconds
        Write-Host -NoNewline ("`r  {0,3}s / {1}s   state: {2}          " -f $elapsed,$TimeoutSeconds,$lastState)
        Start-Sleep -Seconds 3
    }
    Write-Host ""
    return $null
}

function Start-SmartAndroidDevice {
    Write-Host "";Write-Host "SMART ANDROID DEVICE MANAGER" -ForegroundColor Yellow;Write-Host "------------------------------------------------------------"
    $existing=Get-AndroidDeviceId
    if($existing){Write-ToolLog "Using online Android device: $existing" "OK";return $existing}

    [void](Repair-Adb)
    $existing=Wait-ForAndroidDevice -TimeoutSeconds 12
    if($existing){return $existing}

    $emulators=@(Get-InstalledAndroidEmulators)
    if($emulators.Count-eq0){throw "No Android device is online and no Android emulator is installed. Create an AVD in Android Studio Device Manager, then retry."}

    Write-Host "Installed Android emulators:" -ForegroundColor Cyan
    for($i=0;$i-lt$emulators.Count;$i++){Write-Host ("  {0}. {1}" -f ($i+1),$emulators[$i])}
    $selected=$emulators[0]
    Write-ToolLog "Launching emulator automatically: $selected" "WARN"
    $launch=Invoke-External "flutter" @("emulators","--launch",$selected) "Launch Android emulator $selected" -AllowFailure -WorkingDirectory $ProjectPath
    if($launch.ExitCode-ne0){[void](Repair-Adb);$launch=Invoke-External "flutter" @("emulators","--launch",$selected) "Retry emulator launch" -AllowFailure -WorkingDirectory $ProjectPath;if($launch.ExitCode-ne0){throw "Android emulator '$selected' could not be launched."}}

    $deviceId=Wait-ForAndroidDevice -TimeoutSeconds 180
    if(-not$deviceId){[void](Repair-Adb);$deviceId=Wait-ForAndroidDevice -TimeoutSeconds 45}
    if(-not$deviceId){throw "Android emulator started but never became Flutter-supported/online. Check virtualization, emulator logs, and ADB state."}
    return $deviceId
}

function Run-App {
    $id=Start-SmartAndroidDevice
    if(-not$id){throw "Smart Device Manager could not provide an Android device."}
    Write-ToolLog "Launching CARGame on $id" "OK"
    Invoke-External "flutter" @("run","-d",$id) "Run application" -WorkingDirectory $ProjectPath|Out-Null
}

function Collect-Diagnostics {
    $stamp=Get-Date -Format "yyyyMMdd_HHmmss";$dir=Join-Path $env:TEMP "CARGame_Diagnostics_$stamp";New-Item -ItemType Directory -Path $dir -Force|Out-Null
    try{Copy-Item $script:LogFile (Join-Path $dir "setup_tool.log") -Force -ErrorAction SilentlyContinue;@("Generated: $(Get-Date)","Project: $ProjectPath","Repository: $RepositoryUrl","Branch: $Branch","Windows: $([Environment]::OSVersion.VersionString)","PowerShell: $($PSVersionTable.PSVersion)","JAVA_HOME: $env:JAVA_HOME","ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT","ANDROID_HOME: $env:ANDROID_HOME")|Set-Content (Join-Path $dir "environment.txt") -Encoding UTF8;if(Test-Repo){(Invoke-Git @("status","--branch","--short") "Diagnostic git status" -AllowFailure -Quiet).Output|Set-Content (Join-Path $dir "git_status.txt") -Encoding UTF8};if(Test-CommandExists "flutter"){(Invoke-External "flutter" @("devices","--machine") "Diagnostic devices" -AllowFailure -Quiet -WorkingDirectory $ProjectPath).Output|Set-Content (Join-Path $dir "flutter_devices.json") -Encoding UTF8};$adb=Get-AdbPath;if($adb){@(& $adb devices -l 2>&1)|Set-Content (Join-Path $dir "adb_devices.txt") -Encoding UTF8};$zip=Join-Path $LogDirectory "CARGame_Diagnostics_$stamp.zip";Compress-Archive -Path (Join-Path $dir "*") -DestinationPath $zip -Force;Write-ToolLog "Diagnostics ZIP created: $zip" "OK"}finally{Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue}
}

function Show-Failure {
    param($Err)
    Write-Host "";Write-Host "============================================================" -ForegroundColor Red;Write-Host " OPERATION FAILED" -ForegroundColor Red;Write-Host "============================================================" -ForegroundColor Red;Write-Host $Err.Exception.Message -ForegroundColor Red
    if($script:LastFailure){Write-Host "Step      : $($script:LastFailure.Step)";Write-Host "Command   : $($script:LastFailure.Command)";Write-Host "Exit Code : $($script:LastFailure.ExitCode)"}
    Write-Host "Log       : $script:LogFile" -ForegroundColor Yellow;Write-Host "The tool will remain open." -ForegroundColor Yellow
}

function Invoke-SafeAction { param([scriptblock]$Action);try{& $Action}catch{Show-Failure $_}finally{Restore-SafeLocation;Pause-Tool} }

try {
    Initialize-Log
    Show-Header
    Write-Host "Startup safety check..." -ForegroundColor Yellow
    try{Run-Diagnostics -NoPause}catch{Write-Host "Diagnostics could not finish, but the tool will continue." -ForegroundColor Yellow}

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
        Write-Host "11 - Build Release APK (lock-safe retry)"
        Write-Host "12 - Run app (auto detect/repair/launch Android)"
        Write-Host "13 - Full repair + Build Release APK"
        Write-Host "14 - Backup + UNDO local changes + apply GitHub version"
        Write-Host "15 - Show local source/generated change summary"
        Write-Host "16 - Close/Kill processes locking project files"
        Write-Host "17 - Smart Android Device Manager (detect/repair/launch)"
        Write-Host "0  - Exit"
        Write-Host ""
        $choice=Read-Host "Choose an option"
        if($choice-eq"0"){break}
        switch($choice){
            "1"{Invoke-SafeAction{First-Download}}
            "2"{Invoke-SafeAction{Update-Project}}
            "3"{Invoke-SafeAction{Upload-Changes}}
            "4"{Invoke-SafeAction{Update-Project;Repair-Basic;Run-App}}
            "5"{Invoke-SafeAction{Repair-Basic}}
            "6"{Invoke-SafeAction{Run-Diagnostics -NoPause}}
            "7"{Invoke-SafeAction{Collect-Diagnostics}}
            "8"{Invoke-SafeAction{Invoke-External "flutter" @("doctor","-v") "Flutter doctor" -WorkingDirectory $ProjectPath|Out-Null}}
            "9"{Invoke-SafeAction{Stop-ProjectLockingProcesses;Remove-SafeCaches;Invoke-External "flutter" @("clean") "Flutter clean" -AllowFailure -WorkingDirectory $ProjectPath|Out-Null;Invoke-External "flutter" @("pub","get") "Flutter pub get" -WorkingDirectory $ProjectPath|Out-Null}}
            "10"{Invoke-SafeAction{Build-Apk "debug"}}
            "11"{Invoke-SafeAction{Build-Apk "release"}}
            "12"{Invoke-SafeAction{Run-App}}
            "13"{Invoke-SafeAction{Repair-Basic;Build-Apk "release"}}
            "14"{Invoke-SafeAction{[void](Sync-FromGitHub)}}
            "15"{Invoke-SafeAction{Show-ChangeSummary|Out-Null}}
            "16"{Invoke-SafeAction{Stop-ProjectLockingProcesses -Aggressive}}
            "17"{Invoke-SafeAction{$id=Start-SmartAndroidDevice;Write-Host "Ready Android device: $id" -ForegroundColor Green}}
            default{Write-Host "Invalid option." -ForegroundColor Yellow;Start-Sleep -Seconds 1}
        }
    }
    Write-ToolLog "Setup Tool closed" "OK"
} catch {
    try{Show-Failure $_}catch{Write-Host "FATAL STARTUP ERROR" -ForegroundColor Red;Write-Host $_.Exception.Message -ForegroundColor Red}
    Write-Host "";Write-Host "The window will NOT close automatically." -ForegroundColor Yellow;[void](Read-Host "Press Enter to close")
} finally { Restore-SafeLocation }
