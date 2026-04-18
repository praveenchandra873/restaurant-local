@echo off
title Dine Local Hub
color 0A
cd /d "%~dp0"

echo.
echo  ===========================================================
echo       DINE LOCAL HUB - Restaurant Management System
echo  ===========================================================
echo.

:: ================================================================
:: PYTHON
:: ================================================================
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Python not found. Downloading...
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading Python...'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%~dp0installers\python-setup.exe'"
    if exist "%~dp0installers\python-setup.exe" (
        echo  [!!] Installing Python... (please wait)
        "%~dp0installers\python-setup.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
        set "PATH=C:\Program Files\Python311;C:\Program Files\Python311\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
        del "%~dp0installers\python-setup.exe" >nul 2>&1
    )
    where python >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo  [ERROR] Python could not be installed automatically.
        echo  Please install it manually:
        echo    1. Go to https://www.python.org/downloads/
        echo    2. Download and install (CHECK "Add to PATH")
        echo    3. Then run start.bat again
        echo.
        pause
        exit /b
    )
    echo  [OK] Python installed
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v
)

:: ================================================================
:: NODE.JS
:: ================================================================
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Node.js not found. Downloading...
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading Node.js...'; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.18.1/node-v20.18.1-x64.msi' -OutFile '%~dp0installers\node-setup.msi'"
    if exist "%~dp0installers\node-setup.msi" (
        echo  [!!] Installing Node.js... (please wait)
        msiexec /i "%~dp0installers\node-setup.msi" /qn /norestart
        set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
        del "%~dp0installers\node-setup.msi" >nul 2>&1
    )
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo  [ERROR] Node.js could not be installed automatically.
        echo  Please install it manually:
        echo    1. Go to https://nodejs.org/
        echo    2. Download LTS and install
        echo    3. Then run start.bat again
        echo.
        pause
        exit /b
    )
    echo  [OK] Node.js installed
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo  [OK] Node.js %%v
)

:: ================================================================
:: YARN
:: ================================================================
where yarn >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Installing Yarn...
    call npm install -g yarn >nul 2>&1
)
echo  [OK] Yarn ready

:: ================================================================
:: MONGODB (portable - no install needed)
:: ================================================================
set "MONGO_CMD=mongod"
set "MONGO_PORTABLE=%~dp0mongodb\bin\mongod.exe"

where mongod >nul 2>&1
if %errorlevel% equ 0 (
    echo  [OK] MongoDB found
    goto :mongo_ready
)
if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB found (portable)
    goto :mongo_ready
)

echo  [!!] MongoDB not found. Downloading portable version...
if not exist "%~dp0mongodb\bin" mkdir "%~dp0mongodb\bin"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading MongoDB (~200MB, please wait)...'; try { Invoke-WebRequest -Uri 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip' -OutFile '%~dp0mongodb\mongo.zip'; Write-Host '      Extracting...'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%~dp0mongodb\mongo.zip','%~dp0mongodb\temp'); $d=Get-ChildItem '%~dp0mongodb\temp' -Directory|Select -First 1; Copy-Item (Join-Path $d.FullName 'bin\*') '%~dp0mongodb\bin\' -Force; Remove-Item '%~dp0mongodb\temp' -Recurse -Force; Remove-Item '%~dp0mongodb\mongo.zip' -Force; Write-Host '      Done!' } catch { Write-Host '      Failed: ' $_.Exception.Message }"

if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB ready
    goto :mongo_ready
)
echo.
echo  [ERROR] MongoDB download failed.
echo  Please download manually:
echo    https://www.mongodb.com/try/download/community
echo    (Windows / 7.0 / zip) then extract mongod.exe
echo    into the mongodb\bin\ folder and run start.bat again.
echo.
pause
exit /b

:mongo_ready

:: ================================================================
:: LOCAL IP
:: ================================================================
set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do set LOCAL_IP=%%b& goto :ip_done
)
:ip_done
echo  [OK] Network IP: %LOCAL_IP%
echo.

:: ================================================================
:: ENV FILES
:: ================================================================
cd /d "%~dp0backend"
>".env" (
    echo MONGO_URL=mongodb://localhost:27017
    echo DB_NAME=dine_local_hub
    echo CORS_ORIGINS=*
)
cd /d "%~dp0frontend"
>".env" (
    echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
    echo HOST=0.0.0.0
    echo PORT=3000
    echo ENABLE_HEALTH_CHECK=false
)
cd /d "%~dp0"

:: ================================================================
:: STOP OLD PROCESSES
:: ================================================================
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1
timeout /t 1 /nobreak >nul

:: Firewall (silent, ok if fails)
netsh advfirewall firewall add rule name="DLH-Back" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH-Front" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1

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
:: BACKEND
:: ================================================================
echo  [..] Backend setup...
cd /d "%~dp0backend"
if not exist "venv\Scripts\activate.bat" (
    echo      Creating virtual environment...
    python -m venv venv
)
call venv\Scripts\activate.bat
python -c "import uvicorn" >nul 2>&1
if errorlevel 1 (
    echo      Installing packages...
    if exist "requirements-local.txt" (
        pip install -r requirements-local.txt
    ) else (
        pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    )
)
:: Seed if empty
python -c "from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({}));print(n)" 2>nul | findstr /r "^0$" >nul && (
    echo      Seeding database...
    python seed_db.py
)
call deactivate

echo  [OK] Starting Backend...
start "DLH-Backend" /min cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn server:app --host 0.0.0.0 --port 8001"
timeout /t 5 /nobreak >nul

:: ================================================================
:: FRONTEND
:: ================================================================
cd /d "%~dp0frontend"
if not exist "node_modules" (
    echo  [!!] Installing frontend packages (2-3 min first time)...
    call yarn install
)
echo  [OK] Starting Frontend...
start "DLH-Frontend" /min cmd /k "cd /d "%~dp0frontend" && set HOST=0.0.0.0&& set PORT=3000&& .\node_modules\.bin\craco.cmd start"
echo  [..] Compiling (~30 seconds)...
timeout /t 30 /nobreak >nul

:: ================================================================
:: DONE
:: ================================================================
cd /d "%~dp0"
cls
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
echo       Owner password:    owner123
echo.
echo       DO NOT close the minimized DLH windows!
echo       To stop: double-click stop.bat
echo.
echo  ===========================================================
echo.
pause
