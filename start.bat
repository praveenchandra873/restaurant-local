@echo off
title Dine Local Hub - Restaurant Management System
color 0A
cd /d "%~dp0"

echo.
echo  ===========================================================
echo       DINE LOCAL HUB - Restaurant Management System
echo  ===========================================================
echo.
echo  Checking requirements...
echo.

:: ================================================================
:: CHECK 1: PYTHON
:: ================================================================
where python >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo  [ERROR] Python is NOT installed on this computer.
    echo.
    echo  Please install Python first:
    echo.
    echo    1. Open this link in your browser:
    echo       https://www.python.org/downloads/
    echo.
    echo    2. Click the big "Download Python" button
    echo.
    echo    3. Run the installer
    echo       IMPORTANT: Check the box "Add Python to PATH"
    echo       Then click "Install Now"
    echo.
    echo    4. After installation, CLOSE this window and
    echo       double-click start.bat again.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v found

:: ================================================================
:: CHECK 2: NODE.JS
:: ================================================================
where node >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo  [ERROR] Node.js is NOT installed on this computer.
    echo.
    echo  Please install Node.js first:
    echo.
    echo    1. Open this link in your browser:
    echo       https://nodejs.org/
    echo.
    echo    2. Click the big green "Download" button (LTS version)
    echo.
    echo    3. Run the installer, click Next through everything
    echo.
    echo    4. After installation, CLOSE this window and
    echo       double-click start.bat again.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo  [OK] Node.js %%v found

:: ================================================================
:: CHECK 3: YARN
:: ================================================================
where yarn >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Yarn not found, installing...
    call npm install -g yarn >nul 2>&1
)
echo  [OK] Yarn ready

:: ================================================================
:: CHECK 4: MONGODB
:: ================================================================
set MONGO_CMD=mongod
set "MONGO_PORTABLE=%~dp0mongodb\bin\mongod.exe"

:: Check system mongod
where mongod >nul 2>&1
if %errorlevel% equ 0 (
    echo  [OK] MongoDB found
    set MONGO_CMD=mongod
    goto :mongo_ok
)

:: Check portable mongod
if exist "%MONGO_PORTABLE%" (
    echo  [OK] MongoDB found (portable)
    set "MONGO_CMD=%MONGO_PORTABLE%"
    goto :mongo_ok
)

:: MongoDB not found - try to download
echo  [!!] MongoDB not found. Downloading portable version...
echo      (One-time download, please wait...)
echo.

if not exist "%~dp0mongodb" mkdir "%~dp0mongodb"
if not exist "%~dp0mongodb\bin" mkdir "%~dp0mongodb\bin"

:: Download mongod using PowerShell (direct zip)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip' -OutFile '%~dp0mongodb\mongo.zip'; Write-Host '  Download complete!'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%~dp0mongodb\mongo.zip', '%~dp0mongodb\temp'); $src = Get-ChildItem '%~dp0mongodb\temp' -Directory | Select-Object -First 1; Copy-Item (Join-Path $src.FullName 'bin\*') '%~dp0mongodb\bin\' -Force; Remove-Item '%~dp0mongodb\temp' -Recurse -Force; Remove-Item '%~dp0mongodb\mongo.zip' -Force; Write-Host '  MongoDB extracted!' } catch { Write-Host '  Download failed: ' $_.Exception.Message }"

if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB portable installed
    goto :mongo_ok
)

:: Still not found
color 0C
echo.
echo  [ERROR] Could not download MongoDB automatically.
echo.
echo  Please install MongoDB manually:
echo.
echo    1. Open: https://www.mongodb.com/try/download/community
echo    2. Select Windows, version 7.0, zip package
echo    3. Download and extract
echo    4. Copy mongod.exe to: %~dp0mongodb\bin\
echo.
echo  Then double-click start.bat again.
echo.
pause
exit /b 1

:mongo_ok

:: ================================================================
:: GET LOCAL IP
:: ================================================================
set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :got_ip
    )
)
:got_ip
echo.
echo  [OK] Your Network IP: %LOCAL_IP%
echo.

:: ================================================================
:: CREATE ENV FILES
:: ================================================================
echo  [..] Configuring...

cd /d "%~dp0backend"
(
echo MONGO_URL=mongodb://localhost:27017
echo DB_NAME=dine_local_hub
echo CORS_ORIGINS=*
) > ".env"

cd /d "%~dp0frontend"
(
echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
echo HOST=0.0.0.0
echo PORT=3000
echo ENABLE_HEALTH_CHECK=false
) > ".env"

cd /d "%~dp0"

:: ================================================================
:: KILL OLD INSTANCES
:: ================================================================
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do (taskkill /PID %%p /F >nul 2>&1)
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do (taskkill /PID %%p /F >nul 2>&1)
timeout /t 1 /nobreak >nul

:: ================================================================
:: FIREWALL (silently, ok if fails without admin)
:: ================================================================
netsh advfirewall firewall add rule name="DLH Backend" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH Frontend" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1

:: ================================================================
:: START MONGODB
:: ================================================================
echo  [..] Starting MongoDB...
tasklist /FI "IMAGENAME eq mongod.exe" 2>nul | find /I "mongod.exe" >nul
if errorlevel 1 (
    if not exist "%~dp0data\db" mkdir "%~dp0data\db"
    start "" /min "%MONGO_CMD%" --dbpath "%~dp0data\db"
    timeout /t 3 /nobreak >nul
)
echo  [OK] MongoDB running

:: ================================================================
:: SETUP + START BACKEND
:: ================================================================
echo  [..] Setting up Backend...
cd /d "%~dp0backend"

if not exist "venv\Scripts\activate.bat" (
    echo  [!!] Creating virtual environment (first time)...
    python -m venv venv
)

call venv\Scripts\activate.bat
python -c "import uvicorn" >nul 2>&1
if errorlevel 1 (
    echo  [!!] Installing backend packages (first time)...
    if exist "requirements-local.txt" (
        pip install -r requirements-local.txt
    ) else (
        pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    )
)

:: Seed database if empty
python -c "from motor.motor_asyncio import AsyncIOMotorClient; import asyncio, os; from dotenv import load_dotenv; from pathlib import Path; load_dotenv(Path('.env')); c=AsyncIOMotorClient(os.environ['MONGO_URL']); db=c[os.environ['DB_NAME']]; n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({})); print(n)" 2>nul | findstr /r "^0$" >nul
if %errorlevel% equ 0 (
    echo  [!!] Seeding database with sample data...
    python seed_db.py
)
call deactivate

echo  [OK] Starting Backend on port 8001...
start "DLH-Backend" /min cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn server:app --host 0.0.0.0 --port 8001"
timeout /t 5 /nobreak >nul

:: ================================================================
:: SETUP + START FRONTEND
:: ================================================================
cd /d "%~dp0frontend"

if not exist "node_modules" (
    echo  [!!] Installing frontend packages (first time, 2-3 min)...
    call yarn install
)

echo  [OK] Starting Frontend on port 3000...
start "DLH-Frontend" /min cmd /k "cd /d "%~dp0frontend" && set HOST=0.0.0.0&& set PORT=3000&& .\node_modules\.bin\craco.cmd start"
echo  [..] Compiling frontend (about 30 seconds)...
timeout /t 30 /nobreak >nul

:: ================================================================
:: DONE
:: ================================================================
cd /d "%~dp0"
echo.
echo  ===========================================================
echo.
echo       DINE LOCAL HUB IS RUNNING!
echo.
echo       Your Network IP: %LOCAL_IP%
echo.
echo       Open on ANY device on your WiFi:
echo.
echo       Captain (Phone):   http://%LOCAL_IP%:3000/captain
echo       Kitchen (Tablet):  http://%LOCAL_IP%:3000/kitchen
echo       Billing (Desktop): http://%LOCAL_IP%:3000/billing
echo       Admin Panel:       http://%LOCAL_IP%:3000/admin
echo       Owner Panel:       http://%LOCAL_IP%:3000/owner
echo.
echo       On THIS computer:  http://localhost:3000
echo.
echo       Owner password:    owner123
echo.
echo       DO NOT close the minimized DLH windows!
echo       To stop: double-click stop.bat
echo.
echo  ===========================================================
echo.
pause
