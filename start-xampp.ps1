$xampp = "C:\xampp"

# Start Apache (skip if already running)
if (-not (Get-Process httpd -ErrorAction SilentlyContinue)) {
    Start-Process "$xampp\apache\bin\httpd.exe" `
        -WorkingDirectory "$xampp\apache\bin" `
        -WindowStyle Hidden
}

# Start MySQL (skip if already running)
if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    Start-Process "$xampp\mysql\bin\mysqld.exe" `
        -ArgumentList "--defaults-file=`"$xampp\mysql\bin\my.ini`"", "--standalone" `
        -WorkingDirectory "$xampp\mysql\bin" `
        -WindowStyle Hidden
}