@echo off
title Dine Local Hub - Setup
color 0B

echo.
echo  ================================================
echo       DINE LOCAL HUB - SETUP
echo       Restaurant Management System
echo  ================================================
echo.

:: ---- ELEVATE TO ADMIN USING VBS (most reliable method) ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Need administrator access. Click YES on the popup...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\dlh_elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "%~dp0", "runas", 1 >> "%temp%\dlh_elevate.vbs"
    cscript //nologo "%temp%\dlh_elevate.vbs"
    del "%temp%\dlh_elevate.vbs" >nul 2>&1
    exit /b
)

:: ---- NOW RUNNING AS ADMIN ----
cd /d "%~dp0"
echo  [OK] Running as Administrator
echo  [OK] Folder: %cd%
echo.

:: ---- STEP 1: INSTALL CHOCOLATEY ----
echo  [Step 1/7] Checking Chocolatey...
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo  Installing Chocolatey package manager...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    set "PATH=%ALLUSERSPROFILE%\chocolatey\bin;%PATH%"
    call refreshenv >nul 2>&1
)
echo  [OK] Chocolatey ready
echo.

:: ---- STEP 2: INSTALL MONGODB ----
echo  [Step 2/7] Checking MongoDB...
where mongod >nul 2>&1
if %errorlevel% neq 0 (
    echo  Installing MongoDB (this takes a few minutes)...
    choco install mongodb -y --no-progress
    if not exist "C:\data\db" mkdir "C:\data\db"
)
echo  [OK] MongoDB ready
echo.

:: ---- STEP 3: INSTALL PYTHON ----
echo  [Step 3/7] Checking Python...
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo  Installing Python...
    choco install python311 -y --no-progress
    call refreshenv >nul 2>&1
)
echo  [OK] Python ready
echo.

:: ---- STEP 4: INSTALL NODE.JS + YARN ----
echo  [Step 4/7] Checking Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo  Installing Node.js...
    choco install nodejs-lts -y --no-progress
    call refreshenv >nul 2>&1
)
where yarn >nul 2>&1
if %errorlevel% neq 0 (
    echo  Installing Yarn...
    call npm install -g yarn
)
echo  [OK] Node.js + Yarn ready
echo.

:: ---- STEP 5: SETUP BACKEND ----
echo  [Step 5/7] Setting up Backend...
cd /d "%~dp0backend"

:: Create .env
(
echo MONGO_URL=mongodb://localhost:27017
echo DB_NAME=dine_local_hub
echo CORS_ORIGINS=*
) > ".env"

:: Create virtual environment and install
python -m venv venv
call venv\Scripts\activate.bat
pip install --upgrade pip -q
if exist "requirements-local.txt" (
    pip install -r requirements-local.txt -q
) else (
    pip install -r requirements.txt -q
)
echo  [OK] Backend packages installed

:: Seed database
echo  Seeding database with sample menu and tables...
python seed_db.py
echo  [OK] Database seeded
call deactivate
echo.

:: ---- STEP 6: SETUP FRONTEND ----
echo  [Step 6/7] Setting up Frontend...
cd /d "%~dp0frontend"

:: Get local IP
set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :got_ip
    )
)
:got_ip

:: Create .env with network binding
(
echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
echo HOST=0.0.0.0
echo PORT=3000
) > ".env"

call yarn install
echo  [OK] Frontend packages installed
echo.

:: ---- STEP 7: FIREWALL RULES ----
echo  [Step 7/7] Configuring firewall...
netsh advfirewall firewall delete rule name="DLH Backend" >nul 2>&1
netsh advfirewall firewall delete rule name="DLH Frontend" >nul 2>&1
netsh advfirewall firewall add rule name="DLH Backend" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH Frontend" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
echo  [OK] Firewall configured for ports 3000 and 8001
echo.

:: ---- DONE ----
cd /d "%~dp0"
echo.
echo  ================================================
echo.
echo       SETUP COMPLETE!
echo.
echo       Your Network IP: %LOCAL_IP%
echo.
echo       To start the system: double-click start.bat
echo       To stop the system:  double-click stop.bat
echo.
echo       Then open on any device on your WiFi:
echo.
echo       Captain:  http://%LOCAL_IP%:3000/captain
echo       Kitchen:  http://%LOCAL_IP%:3000/kitchen
echo       Billing:  http://%LOCAL_IP%:3000/billing
echo       Admin:    http://%LOCAL_IP%:3000/admin
echo.
echo  ================================================
echo.
echo  Press any key to close this window...
pause >nul
