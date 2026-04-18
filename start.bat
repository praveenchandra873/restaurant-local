@echo off
title Dine Local Hub - Restaurant Management System
color 0A
cd /d "%~dp0"

:: ================================================================
:: AUTO-ELEVATE TO ADMIN (needed to install Python/Node/Firewall)
:: ================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator access...
    echo  (Click YES on the popup)
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\dlh_elevate.vbs"
    echo UAC.ShellExecute "cmd.exe", "/k cd /d ""%~dp0"" && ""%~f0"" elevated", "", "runas", 1 >> "%temp%\dlh_elevate.vbs"
    cscript //nologo "%temp%\dlh_elevate.vbs"
    del "%temp%\dlh_elevate.vbs" >nul 2>&1
    exit /b
)

:: We are now admin. Make sure we are in the right folder.
cd /d "%~dp0"

echo.
echo  ===========================================================
echo       DINE LOCAL HUB - Restaurant Management System
echo  ===========================================================
echo.
echo  Checking and installing requirements...
echo  (First run may take 5-10 minutes)
echo.

:: ================================================================
:: CHECK + AUTO-INSTALL PYTHON
:: ================================================================
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Python not found. Downloading installer...
    
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading Python (about 25MB)...'; try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%~dp0installers\python-installer.exe'; Write-Host '      Download complete!' } catch { Write-Host '      Download failed!' }"
    
    if not exist "%~dp0installers\python-installer.exe" (
        color 0C
        echo.
        echo  [ERROR] Could not download Python.
        echo  Please download manually from: https://www.python.org/downloads/
        echo  IMPORTANT: Check "Add Python to PATH" during install.
        echo  Then run start.bat again.
        pause
        exit /b 1
    )
    
    echo  [!!] Installing Python (this takes a minute)...
    echo      A Python installer window may appear - just wait...
    "%~dp0installers\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
    
    :: Refresh PATH so we can find python immediately
    set "PATH=C:\Program Files\Python311;C:\Program Files\Python311\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
    
    where python >nul 2>&1
    if %errorlevel% neq 0 (
        color 0C
        echo.
        echo  [ERROR] Python installed but not found in PATH.
        echo  Please CLOSE this window and double-click start.bat again.
        echo  (Windows needs to refresh after installation)
        pause
        exit /b 1
    )
    
    echo  [OK] Python installed successfully!
    del "%~dp0installers\python-installer.exe" >nul 2>&1
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v found
)

:: ================================================================
:: CHECK + AUTO-INSTALL NODE.JS
:: ================================================================
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Node.js not found. Downloading installer...
    
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading Node.js (about 30MB)...'; try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.18.1/node-v20.18.1-x64.msi' -OutFile '%~dp0installers\node-installer.msi'; Write-Host '      Download complete!' } catch { Write-Host '      Download failed!' }"
    
    if not exist "%~dp0installers\node-installer.msi" (
        color 0C
        echo.
        echo  [ERROR] Could not download Node.js.
        echo  Please download manually from: https://nodejs.org/
        echo  Then run start.bat again.
        pause
        exit /b 1
    )
    
    echo  [!!] Installing Node.js (this takes a minute)...
    msiexec /i "%~dp0installers\node-installer.msi" /qn /norestart
    
    :: Refresh PATH
    set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
    
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        color 0C
        echo.
        echo  [ERROR] Node.js installed but not found in PATH.
        echo  Please CLOSE this window and double-click start.bat again.
        echo  (Windows needs to refresh after installation)
        pause
        exit /b 1
    )
    
    echo  [OK] Node.js installed successfully!
    del "%~dp0installers\node-installer.msi" >nul 2>&1
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo  [OK] Node.js %%v found
)

:: ================================================================
:: CHECK + INSTALL YARN
:: ================================================================
where yarn >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Installing Yarn...
    call npm install -g yarn >nul 2>&1
)
echo  [OK] Yarn ready

:: ================================================================
:: CHECK + AUTO-INSTALL MONGODB (portable)
:: ================================================================
set MONGO_CMD=mongod
set "MONGO_PORTABLE=%~dp0mongodb\bin\mongod.exe"

where mongod >nul 2>&1
if %errorlevel% equ 0 (
    echo  [OK] MongoDB found
    set MONGO_CMD=mongod
    goto :mongo_ok
)

if exist "%MONGO_PORTABLE%" (
    echo  [OK] MongoDB found (portable)
    set "MONGO_CMD=%MONGO_PORTABLE%"
    goto :mongo_ok
)

echo  [!!] MongoDB not found. Downloading portable version...
echo      (One-time download, please wait...)

if not exist "%~dp0mongodb" mkdir "%~dp0mongodb"
if not exist "%~dp0mongodb\bin" mkdir "%~dp0mongodb\bin"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading MongoDB (about 200MB, please wait)...'; try { Invoke-WebRequest -Uri 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip' -OutFile '%~dp0mongodb\mongo.zip'; Write-Host '      Download complete! Extracting...'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%~dp0mongodb\mongo.zip', '%~dp0mongodb\temp'); $src = Get-ChildItem '%~dp0mongodb\temp' -Directory | Select-Object -First 1; Copy-Item (Join-Path $src.FullName 'bin\*') '%~dp0mongodb\bin\' -Force; Remove-Item '%~dp0mongodb\temp' -Recurse -Force; Remove-Item '%~dp0mongodb\mongo.zip' -Force; Write-Host '      MongoDB ready!' } catch { Write-Host '      Error: ' $_.Exception.Message }"

if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB installed
    goto :mongo_ok
)

color 0C
echo.
echo  [ERROR] Could not download MongoDB automatically.
echo  Please download manually:
echo    https://www.mongodb.com/try/download/community
echo    Select: Windows / 7.0 / zip
echo    Extract and copy mongod.exe to: %~dp0mongodb\bin\
echo  Then run start.bat again.
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
echo  [OK] Network IP: %LOCAL_IP%
echo.

:: ================================================================
:: CREATE ENV FILES
:: ================================================================
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

:: Firewall rules (ok if fails without admin)
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
    echo  [!!] Creating virtual environment...
    python -m venv venv
)

call venv\Scripts\activate.bat
python -c "import uvicorn" >nul 2>&1
if errorlevel 1 (
    echo  [!!] Installing backend packages...
    if exist "requirements-local.txt" (
        pip install -r requirements-local.txt
    ) else (
        pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    )
)

:: Seed if database is empty
python -c "from motor.motor_asyncio import AsyncIOMotorClient; import asyncio,os; from dotenv import load_dotenv; from pathlib import Path; load_dotenv(Path('.env')); c=AsyncIOMotorClient(os.environ['MONGO_URL']); db=c[os.environ['DB_NAME']]; n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({})); print(n)" 2>nul | findstr /r "^0$" >nul
if %errorlevel% equ 0 (
    echo  [!!] First run - seeding database...
    python seed_db.py
)
call deactivate

echo  [OK] Starting Backend...
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

echo  [OK] Starting Frontend...
start "DLH-Frontend" /min cmd /k "cd /d "%~dp0frontend" && set HOST=0.0.0.0&& set PORT=3000&& .\node_modules\.bin\craco.cmd start"
echo  [..] Compiling (about 30 seconds)...
timeout /t 30 /nobreak >nul

:: ================================================================
:: DONE
:: ================================================================
cd /d "%~dp0"
color 0A
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
