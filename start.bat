@echo off
title Dine Local Hub
color 0A
cd /d "%~dp0"

echo.
echo  ===========================================================
echo       DINE LOCAL HUB - Restaurant Management System
echo  ===========================================================
echo  Working folder: %cd%
echo.

:: ================================================================
:: STEP 1: PYTHON (Windows Store alias returns garbage, so check properly)
:: ================================================================
echo  [Step 1/7] Checking Python...

:: Disable Windows Store python alias detection
:: The real test: can python actually print its version?
set PYTHON_OK=0
python --version >nul 2>&1 && (
    python --version 2>&1 | findstr /i "Python 3" >nul && set PYTHON_OK=1
)

if "%PYTHON_OK%"=="0" (
    echo  [!!] Python not found or is Windows Store alias.
    echo  [!!] Downloading Python 3.11 installer...
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    
    echo      Please wait...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%~dp0installers\python-setup.exe' -ErrorAction Stop; Write-Host '      Download OK' } catch { Write-Host '      DOWNLOAD FAILED: ' $_.Exception.Message; exit 1 }"
    
    if not exist "%~dp0installers\python-setup.exe" (
        echo  [ERROR] Could not download Python.
        echo  Please install Python manually from https://www.python.org/downloads/
        echo  IMPORTANT: Check "Add Python to PATH" during install.
        echo  Then run start.bat again.
        goto :failed
    )
    
    echo  [!!] Installing Python (takes 1-2 minutes)...
    start /wait "" "%~dp0installers\python-setup.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
    echo  [!!] Python installer finished.
    
    :: Update PATH to find newly installed Python
    set "PATH=C:\Program Files\Python311;C:\Program Files\Python311\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;C:\Python311;C:\Python311\Scripts;%PATH%"
    
    :: Verify
    python --version >nul 2>&1
    if errorlevel 1 (
        echo  [ERROR] Python installed but PATH not updated.
        echo  Please CLOSE ALL command windows, then run start.bat again.
        echo  Windows needs to refresh PATH after installing Python.
        goto :failed
    )
    echo  [OK] Python installed!
    del "%~dp0installers\python-setup.exe" >nul 2>&1
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v
)

:: ================================================================
:: STEP 2: NODE.JS
:: ================================================================
echo  [Step 2/7] Checking Node.js...

set NODE_OK=0
node --version >nul 2>&1 && (
    node --version 2>&1 | findstr /r "v[0-9]" >nul && set NODE_OK=1
)

if "%NODE_OK%"=="0" (
    echo  [!!] Node.js not found. Downloading...
    if not exist "%~dp0installers" mkdir "%~dp0installers"
    
    echo      Please wait...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.18.1/node-v20.18.1-x64.msi' -OutFile '%~dp0installers\node-setup.msi' -ErrorAction Stop; Write-Host '      Download OK' } catch { Write-Host '      DOWNLOAD FAILED: ' $_.Exception.Message; exit 1 }"
    
    if not exist "%~dp0installers\node-setup.msi" (
        echo  [ERROR] Could not download Node.js.
        echo  Please install from https://nodejs.org/ then run start.bat again.
        goto :failed
    )
    
    echo  [!!] Installing Node.js (takes 1-2 minutes)...
    start /wait msiexec /i "%~dp0installers\node-setup.msi" /qn /norestart
    echo  [!!] Node.js installer finished.
    
    set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
    
    node --version >nul 2>&1
    if errorlevel 1 (
        echo  [ERROR] Node.js installed but PATH not updated.
        echo  Please CLOSE ALL command windows, then run start.bat again.
        goto :failed
    )
    echo  [OK] Node.js installed!
    del "%~dp0installers\node-setup.msi" >nul 2>&1
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo  [OK] Node.js %%v
)

:: ================================================================
:: STEP 3: YARN
:: ================================================================
echo  [Step 3/7] Checking Yarn...
where yarn >nul 2>&1
if errorlevel 1 (
    echo  [!!] Installing Yarn...
    call npm install -g yarn
)
echo  [OK] Yarn ready

:: ================================================================
:: STEP 4: MONGODB (portable)
:: ================================================================
echo  [Step 4/7] Checking MongoDB...

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

echo  [!!] Downloading portable MongoDB (~200MB, please wait)...
if not exist "%~dp0mongodb\bin" mkdir "%~dp0mongodb\bin"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip' -OutFile '%~dp0mongodb\mongo.zip' -ErrorAction Stop; Write-Host '      Download OK. Extracting...'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('%~dp0mongodb\mongo.zip','%~dp0mongodb\temp'); $d=Get-ChildItem '%~dp0mongodb\temp' -Directory|Select -First 1; Copy-Item (Join-Path $d.FullName 'bin\*') '%~dp0mongodb\bin\' -Force; Remove-Item '%~dp0mongodb\temp' -Recurse -Force; Remove-Item '%~dp0mongodb\mongo.zip' -Force; Write-Host '      Done!' } catch { Write-Host '      FAILED: ' $_.Exception.Message; exit 1 }"

if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB ready
    goto :mongo_ready
)
echo  [ERROR] MongoDB download failed.
echo  Download manually: https://www.mongodb.com/try/download/community
echo  (Windows / 7.0 / zip), extract mongod.exe into mongodb\bin\ folder.
goto :failed

:mongo_ready

:: ================================================================
:: STEP 5: GET IP + CREATE CONFIG
:: ================================================================
echo  [Step 5/7] Configuring network...

set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do set LOCAL_IP=%%b& goto :ip_done
)
:ip_done
echo  [OK] Network IP: %LOCAL_IP%

:: Backend .env
cd /d "%~dp0backend"
>".env" (
    echo MONGO_URL=mongodb://localhost:27017
    echo DB_NAME=dine_local_hub
    echo CORS_ORIGINS=*
)
:: Frontend .env
cd /d "%~dp0frontend"
>".env" (
    echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
    echo HOST=0.0.0.0
    echo PORT=3000
    echo ENABLE_HEALTH_CHECK=false
)
cd /d "%~dp0"

:: Kill old processes
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1

:: Firewall (silent)
netsh advfirewall firewall add rule name="DLH-Back" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH-Front" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1

:: ================================================================
:: STEP 6: START BACKEND
:: ================================================================
echo  [Step 6/7] Starting Backend...

:: Start MongoDB
tasklist /FI "IMAGENAME eq mongod.exe" 2>nul | find /I "mongod.exe" >nul
if errorlevel 1 (
    if not exist "%~dp0data\db" mkdir "%~dp0data\db"
    start "" /min "%MONGO_CMD%" --dbpath "%~dp0data\db"
    echo  [OK] MongoDB started
    timeout /t 3 /nobreak >nul
) else (
    echo  [OK] MongoDB already running
)

:: Setup venv
cd /d "%~dp0backend"
if not exist "venv\Scripts\activate.bat" (
    echo      Creating Python virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo  [ERROR] Failed to create virtual environment.
        goto :failed
    )
)

:: Install packages if needed
call venv\Scripts\activate.bat
python -c "import uvicorn" >nul 2>&1
if errorlevel 1 (
    echo      Installing backend packages...
    if exist "requirements-local.txt" (
        pip install -r requirements-local.txt
    ) else (
        pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    )
)

:: Seed database if empty
python -c "from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({}));print(n)" 2>nul | findstr /r "^0$" >nul && (
    echo      Seeding database with sample data...
    python seed_db.py
)
call deactivate

:: Launch backend
echo  [OK] Launching backend server...
start "DLH-Backend" /min cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn server:app --host 0.0.0.0 --port 8001"
timeout /t 5 /nobreak >nul

:: ================================================================
:: STEP 7: START FRONTEND
:: ================================================================
echo  [Step 7/7] Starting Frontend...
cd /d "%~dp0frontend"

if not exist "node_modules" (
    echo      Installing frontend packages (2-3 min first time)...
    call yarn install
    if errorlevel 1 (
        echo  [ERROR] yarn install failed.
        goto :failed
    )
)

echo  [OK] Launching frontend...
start "DLH-Frontend" /min cmd /k "cd /d "%~dp0frontend" && set HOST=0.0.0.0&& set PORT=3000&& .\node_modules\.bin\craco.cmd start"
echo      Compiling (~30 seconds)...
timeout /t 30 /nobreak >nul

:: ================================================================
:: SUCCESS
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
exit /b

:: ================================================================
:: ERROR HANDLER
:: ================================================================
:failed
color 0C
echo.
echo  ===========================================================
echo  Setup could not complete. See the error above.
echo  If you need help, take a screenshot of this window.
echo  ===========================================================
echo.
pause
exit /b 1
