# XAMPP Auto-Start

Automatically starts **Apache** and **MySQL** from XAMPP every time you sign in to or unlock your laptop. No more opening the XAMPP Control Panel and clicking "Start" each time.

---

## Before you begin

- **Windows 10 or 11**
- **XAMPP already installed** (usually in `C:\xampp`)

You do **not** need administrator rights.

---

## Install (takes about 1 minute)

**1. Open PowerShell**

Click the **Start** button, type `PowerShell`, and press **Enter**.

**2. Copy this line, paste it into the PowerShell window, and press Enter**

```powershell
iwr -useb https://raw.githubusercontent.com/YOUR-USER/YOUR-REPO/main/setup-xampp.ps1 | iex
```

> To paste in PowerShell, **right-click** inside the window.

**3. Wait for the green message**

```
Done! Apache and MySQL will now start automatically when you sign in or unlock your laptop.
```

That's it. Apache and MySQL are already running, and they will start by themselves from now on.

---

## Check that it works

Open your browser and go to:

**http://localhost**

If you see the XAMPP welcome page, Apache is running.

To open phpMyAdmin (MySQL): **http://localhost/phpmyadmin**

---

## What does the installer do?

1. Finds your XAMPP folder (or asks you to type it if it can't find it).
2. Saves a small start script in `%LOCALAPPDATA%\XamppAutoStart`.
3. Creates a Windows Scheduled Task called **Start XAMPP** that runs the script when you:
   - sign in to Windows, or
   - unlock your laptop.
4. Starts Apache and MySQL right away.

The script skips any service that is already running, so nothing gets started twice.

---

## Uninstall

Open PowerShell, paste this, and press Enter:

```powershell
Unregister-ScheduledTask -TaskName 'Start XAMPP' -Confirm:$false; Remove-Item "$env:LOCALAPPDATA\XamppAutoStart" -Recurse -Force
```

Apache and MySQL will no longer start automatically. Your XAMPP files and databases are not touched.

---

## Troubleshooting

| Problem | What to do |
|---|---|
| **"Couldn't find XAMPP"** | Type the folder where XAMPP is installed, for example `C:\xampp`, when asked. |
| **"Setup failed"** | Right-click PowerShell, choose **Run as administrator**, and paste the command again. |
| **Red error about scripts being disabled** | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, answer **Y**, then try again. |
| **http://localhost doesn't open** | Another program may be using port 80 (such as IIS, Skype, or another web server). Close it, or change Apache's port in XAMPP's `httpd.conf`. |
| **MySQL won't start** | Another MySQL may be using port 3306. Stop it, or change the port in XAMPP's `my.ini`. |
| **Apache or MySQL still stopped after sign-in** | Open **Task Scheduler**, find **Start XAMPP**, right-click it and choose **Run**. Check the "Last Run Result" column. |

---

## Security note

The install command downloads and runs a script from the link above. Only run it if you trust the source. You can read the script yourself before running it by opening the link in your browser.

---

## FAQ

**Does it stop Apache and MySQL when I close the lid or lock the laptop?**
No. It only starts them. Closing the lid or locking the screen does not stop them.

**Can I still use the XAMPP Control Panel?**
Yes. If you stop a service from the Control Panel, it stays stopped until your next sign-in or unlock.

**I installed Apache and MySQL as Windows services in XAMPP. Do I still need this?**
No. In that case, set those services to start automatically in Windows Services instead.