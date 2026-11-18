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
iwr -useb https://raw.githubusercontent.com/the-kimbe/xscript/main/setup-xampp.ps1 | iex
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

## Control XAMPP with simple commands

After installing, open PowerShell (or Command Prompt) and type one of these:

| Type this | What it does |
|---|---|
| `xampp start` | Starts Apache and MySQL |
| `xampp stop` | Stops Apache and MySQL |
| `xampp restart` | Stops, then starts both again |
| `xampp status` | Shows what is running and what is not |
| `xampp fix` | Repairs common problems, then restarts everything |
| `xampp uninstall` | Removes auto-start and the `xampp` command |

To act on just one service, add `apache` or `mysql`:

```powershell
xampp restart mysql
xampp stop apache
```

### What does `xampp fix` do?

1. Closes any frozen or leftover Apache and MySQL processes.
2. Deletes the stale lock files MySQL leaves behind after a crash.
3. Checks whether another program is blocking Apache's or MySQL's port. If it finds one, it tells you which program and asks if you want to close it.
4. Starts Apache and MySQL again and shows the result.

> If `xampp` is not recognized right after installing, close PowerShell and open a new window.

---

## What does the installer do?

1. Finds your XAMPP folder (or asks you to type it if it can't find it).
2. Saves the `xampp` command in `%LOCALAPPDATA%\XamppAutoStart` and adds that folder to your PATH, so you can type `xampp` anywhere.
3. Creates a Windows Scheduled Task called **Start XAMPP** that runs `xampp start` when you:
   - sign in to Windows, or
   - unlock your laptop.
4. Starts Apache and MySQL right away.

The script skips any service that is already running, so nothing gets started twice.

---

## Uninstall

Open PowerShell, type this, and press Enter:

```powershell
xampp uninstall
```

Apache and MySQL will no longer start automatically, and the `xampp` command is removed. Your XAMPP files and databases are not touched.

---

## Troubleshooting

| Problem | What to do |
|---|---|
| **"Couldn't find XAMPP"** | Type the folder where XAMPP is installed, for example `C:\xampp`, when asked. |
| **"Setup failed"** | Right-click PowerShell, choose **Run as administrator**, and paste the command again. |
| **Red error about scripts being disabled** | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, answer **Y**, then try again. |
| **http://localhost doesn't open** | Another program may be using port 80 (such as IIS, Skype, or another web server). Close it, or change Apache's port in XAMPP's `httpd.conf`. |
| **MySQL won't start** | Another MySQL may be using port 3306. Stop it, or change the port in XAMPP's `my.ini`. |
| **Apache or MySQL stopped after sign-in** | Type `xampp fix`. It cleans up leftovers, finds anything blocking the ports, and restarts both. |
| **Not sure what's running** | Type `xampp status`. |
| **`xampp` is not recognized** | Close PowerShell and open a new window. If it still fails, run the install command again. |
| **MySQL still won't start after `xampp fix`** | Check the log at `C:\xampp\mysql\data\mysql_error.log` (adjust the path if XAMPP is elsewhere). |

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