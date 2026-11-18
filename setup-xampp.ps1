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

# --- Write the start script ---
$dir = Join-Path $env:LOCALAPPDATA 'XamppAutoStart'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$script = Join-Path $dir 'start-xampp.ps1'

@'
$xampp = "__XAMPP__"

if (-not (Get-Process httpd -ErrorAction SilentlyContinue)) {
    Start-Process "$xampp\apache\bin\httpd.exe" `
        -WorkingDirectory "$xampp\apache\bin" -WindowStyle Hidden
}

if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    Start-Process "$xampp\mysql\bin\mysqld.exe" `
        -ArgumentList "--defaults-file=`"$xampp\mysql\bin\my.ini`"", "--standalone" `
        -WorkingDirectory "$xampp\mysql\bin" -WindowStyle Hidden
}
'@.Replace('__XAMPP__', $xampp) | Set-Content -Path $script -Encoding UTF8

# --- Register the scheduled task ---
try {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""

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