$ErrorActionPreference = 'Stop'

# --- Find XAMPP ---
$candidates = 'C:\xampp','D:\xampp','E:\xampp','C:\Program Files\xampp'
$xampp = $candidates | Where-Object { Test-Path "$_\apache\bin\httpd.exe" } | Select-Object -First 1

if (-not $xampp) {
    $xampp = (Read-Host "Couldn't find XAMPP. Type its folder (example: C:\xampp)").Trim('" ')
    if (-not (Test-Path "$xampp\apache\bin\httpd.exe")) {
        Write-Host "XAMPP not found at '$xampp'. Please install XAMPP first." -ForegroundColor Red
        return
    }
}
Write-Host "Found XAMPP at $xampp" -ForegroundColor Green

# --- Install folder ---
$dir = Join-Path $env:LOCALAPPDATA 'XamppAutoStart'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
Remove-Item (Join-Path $dir 'start-xampp.ps1') -Force -ErrorAction SilentlyContinue  # old version
$script = Join-Path $dir 'xampp.ps1'

# --- Write the xampp command script ---
@'
param(
    [Parameter(Position = 0)][string]$Action = 'help',
    [Parameter(Position = 1)][string]$Target = 'all'
)

$xampp  = "__XAMPP__"
$Action = $Action.ToLower()
$Target = $Target.ToLower()
$doApache = $Target -in 'all', 'apache'
$doMysql  = $Target -in 'all', 'mysql'

function Say([string]$msg, [string]$color = 'White') { Write-Host $msg -ForegroundColor $color }

function Get-ConfigPort($file, $pattern, $default) {
    try {
        $m = Select-String -Path $file -Pattern $pattern -ErrorAction Stop | Select-Object -First 1
        if ($m) { return [int]$m.Matches[0].Groups[1].Value }
    } catch {}
    return $default
}
$apachePort = Get-ConfigPort "$xampp\apache\conf\httpd.conf" '^\s*Listen\s+(?:\S*:)?(\d+)\s*$' 80
$mysqlPort  = Get-ConfigPort "$xampp\mysql\bin\my.ini" '^\s*port\s*=\s*(\d+)' 3306

function Test-Port($port) {
    [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

function Get-PortOwner($port) {
    $c = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { return Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue }
    return $null
}

function Wait-Port($port, $secs = 15) {
    for ($i = 0; $i -lt $secs; $i++) {
        if (Test-Port $port) { return $true }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Start-Apache {
    if (Get-Process httpd -ErrorAction SilentlyContinue) { Say "Apache is already running." Yellow; return }
    $owner = Get-PortOwner $apachePort
    if ($owner) { Say "Apache can't start: port $apachePort is used by '$($owner.ProcessName)'. Try: xampp fix" Red; return }
    Start-Process "$xampp\apache\bin\httpd.exe" -WorkingDirectory "$xampp\apache\bin" -WindowStyle Hidden
    if (Wait-Port $apachePort) { Say "Apache started." Green } else { Say "Apache did not start. Try: xampp fix" Red }
}

function Start-Mysql {
    if (Get-Process mysqld -ErrorAction SilentlyContinue) { Say "MySQL is already running." Yellow; return }
    $owner = Get-PortOwner $mysqlPort
    if ($owner) { Say "MySQL can't start: port $mysqlPort is used by '$($owner.ProcessName)'. Try: xampp fix" Red; return }
    Start-Process "$xampp\mysql\bin\mysqld.exe" `
        -ArgumentList "--defaults-file=`"$xampp\mysql\bin\my.ini`"", "--standalone" `
        -WorkingDirectory "$xampp\mysql\bin" -WindowStyle Hidden
    if (Wait-Port $mysqlPort 20) { Say "MySQL started." Green } else { Say "MySQL did not start. Try: xampp fix" Red }
}

function Stop-Apache {
    $p = Get-Process httpd -ErrorAction SilentlyContinue
    if (-not $p) { Say "Apache is not running." Yellow; return }
    $p | Stop-Process -Force -ErrorAction SilentlyContinue
    Say "Apache stopped." Green
}

function Stop-Mysql {
    if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) { Say "MySQL is not running." Yellow; return }
    # Try a clean shutdown first (protects your databases), then force if needed
    & "$xampp\mysql\bin\mysqladmin.exe" -u root --connect-timeout=5 shutdown 2>&1 | Out-Null
    for ($i = 0; $i -lt 10; $i++) {
        if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Seconds 1
    }
    Get-Process mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Say "MySQL stopped." Green
}

function Show-Status {
    Say ""
    foreach ($s in @(@('Apache', 'httpd', $apachePort), @('MySQL', 'mysqld', $mysqlPort))) {
        $name = $s[0]; $proc = $s[1]; $port = $s[2]
        if (Get-Process $proc -ErrorAction SilentlyContinue) {
            Say ("  {0,-8} RUNNING  (port {1})" -f $name, $port) Green
        } else {
            $owner = Get-PortOwner $port
            if ($owner) { Say ("  {0,-8} STOPPED  (port {1} is blocked by '{2}')" -f $name, $port, $owner.ProcessName) Red }
            else        { Say ("  {0,-8} STOPPED" -f $name) Yellow }
        }
    }
    Say ""
}

function Repair-Xampp {
    Say "Fixing XAMPP..." Cyan

    # 1. Kill leftover or frozen processes
    Get-Process httpd, mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # 2. Remove stale MySQL lock files left by a crash
    Get-ChildItem "$xampp\mysql\data" -Filter *.pid -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Say "Cleared leftover processes and lock files." Green

    # 3. Look for other programs blocking the ports
    foreach ($s in @(@('Apache', $apachePort), @('MySQL', $mysqlPort))) {
        $name = $s[0]; $port = $s[1]
        $owner = Get-PortOwner $port
        if (-not $owner) { continue }
        Say "Port $port (needed by $name) is being used by '$($owner.ProcessName)'." Yellow
        if ($owner.ProcessName -eq 'System') {
            Say "  This is usually Windows' built-in web server (IIS)." Yellow
            Say "  Open PowerShell as administrator and type: net stop w3svc" Yellow
        } else {
            $ans = Read-Host "  Close '$($owner.ProcessName)'? (y/n)"
            if ($ans -match '^[yY]') {
                Stop-Process -Id $owner.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
    }

    # 4. Start again
    Start-Apache
    Start-Mysql

    if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
        Say ""
        Say "MySQL still won't start. Its error log may say why:" Yellow
        Say "  $xampp\mysql\data\mysql_error.log" Yellow
    }
}

function Uninstall-Xampp {
    Unregister-ScheduledTask -TaskName 'Start XAMPP' -Confirm:$false -ErrorAction SilentlyContinue
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $new  = (($user -split ';') | Where-Object { $_ -and $_ -ne $PSScriptRoot }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $new, 'User')
    Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command',
        "Start-Sleep 3; Remove-Item -LiteralPath '$PSScriptRoot' -Recurse -Force"
    Say "XAMPP auto-start and the 'xampp' command were removed. Your XAMPP files are untouched." Green
}

function Show-Help {
    Say ""
    Say "  xampp start      Start Apache and MySQL"
    Say "  xampp stop       Stop Apache and MySQL"
    Say "  xampp restart    Stop, then start both again"
    Say "  xampp status     Show what is running"
    Say "  xampp fix        Repair common problems, then restart"
    Say "  xampp uninstall  Remove auto-start and this command"
    Say ""
    Say "  Add 'apache' or 'mysql' to act on just one, for example:  xampp restart mysql"
    Say ""
}

if ($Target -notin 'all', 'apache', 'mysql') {
    Say "Unknown target '$Target'. Use: apache, mysql, or leave it out for both." Red
    return
}

switch ($Action) {
    'start'     { if ($doApache) { Start-Apache }; if ($doMysql) { Start-Mysql } }
    'stop'      { if ($doApache) { Stop-Apache };  if ($doMysql) { Stop-Mysql } }
    'restart'   {
        if ($doApache) { Stop-Apache }; if ($doMysql) { Stop-Mysql }
        Start-Sleep -Seconds 2
        if ($doApache) { Start-Apache }; if ($doMysql) { Start-Mysql }
    }
    'status'    { Show-Status }
    'fix'       { Repair-Xampp; Show-Status }
    'uninstall' { Uninstall-Xampp }
    default     { Show-Help }
}
'@.Replace('__XAMPP__', $xampp) | Set-Content -Path $script -Encoding UTF8

# --- Write the 'xampp' launcher so it works as a plain command ---
@('@echo off',
  'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0xampp.ps1" %*') |
    Set-Content -Path (Join-Path $dir 'xampp.cmd') -Encoding ASCII

# --- Add the folder to the user's PATH (no admin needed) ---
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $dir) {
    [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ';' + $dir).TrimStart(';')), 'User')
}
if (($env:Path -split ';') -notcontains $dir) { $env:Path += ";$dir" }

# --- Register the scheduled task (runs "xampp start" at sign-in and unlock) ---
try {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" start"

    $logon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    $cls = Get-CimClass -Namespace ROOT\Microsoft\Windows\TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger
    $unlock = New-CimInstance -CimClass $cls -ClientOnly -Property @{
        StateChange = 8
        UserId      = "$env:USERDOMAIN\$env:USERNAME"
    }

    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -StartWhenAvailable

    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName 'Start XAMPP' -Action $action `
        -Trigger @($logon, $unlock) -Settings $settings -Principal $principal -Force | Out-Null
}
catch {
    Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try again by right-clicking PowerShell and choosing 'Run as administrator'." -ForegroundColor Yellow
    return
}

# --- Start it now ---
Start-ScheduledTask -TaskName 'Start XAMPP'

Write-Host ""
Write-Host "Done! Apache and MySQL will now start automatically when you sign in or unlock your laptop." -ForegroundColor Green
Write-Host ""
Write-Host "You can also control them by typing these in PowerShell:" -ForegroundColor Cyan
Write-Host "  xampp start | stop | restart | status | fix"
Write-Host ""
Write-Host "(If 'xampp' isn't recognized, close this window and open a new one.)" -ForegroundColor DarkGray