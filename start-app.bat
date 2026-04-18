@echo off
title Dine Local Hub
color 0A

echo.
echo  ===========================================================
echo       DINE LOCAL HUB - Restaurant Management System
echo  ===========================================================
echo.

cd /d "%~dp0"
echo  Folder: %cd%
echo.

:: ================================================================
:: STEP 1: PYTHON
:: ================================================================
echo  [Step 1/7] Checking Python...

set PYTHON_OK=0
python --version >"%temp%\dlh_pyver.txt" 2>&1
findstr /i "Python 3" "%temp%\dlh_pyver.txt" >nul 2>&1
if %errorlevel% equ 0 set PYTHON_OK=1
del "%temp%\dlh_pyver.txt" >nul 2>&1

if "%PYTHON_OK%"=="1" (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v
    goto :python_done
)

echo  [!!] Python not found. Downloading...
if not exist "installers" mkdir "installers"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '      Downloading Python 3.11...'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile 'installers\python-setup.exe'"

if not exist "installers\python-setup.exe" (
    echo  [ERROR] Download failed. Install manually: https://www.python.org/downloads/
    goto :the_end
)

echo  [!!] Installing Python...
start /wait "" "installers\python-setup.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
set "PATH=C:\Program Files\Python311;C:\Program Files\Python311\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
del "installers\python-setup.exe" >nul 2>&1

python --version >"%temp%\dlh_pyver2.txt" 2>&1
findstr /i "Python 3" "%temp%\dlh_pyver2.txt" >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Python installed. CLOSE this window and run start.bat again.
    goto :the_end
)
del "%temp%\dlh_pyver2.txt" >nul 2>&1
echo  [OK] Python installed!

:python_done

:: ================================================================
:: STEP 2: NODE.JS
:: ================================================================
echo  [Step 2/7] Checking Node.js...

set NODE_OK=0
node --version >"%temp%\dlh_nodever.txt" 2>&1
findstr /r "v[0-9]" "%temp%\dlh_nodever.txt" >nul 2>&1
if %errorlevel% equ 0 set NODE_OK=1
del "%temp%\dlh_nodever.txt" >nul 2>&1

if "%NODE_OK%"=="1" (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo  [OK] Node.js %%v
    goto :node_done
)

echo  [!!] Node.js not found. Downloading...
if not exist "installers" mkdir "installers"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '      Downloading Node.js 20...'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.18.1/node-v20.18.1-x64.msi' -OutFile 'installers\node-setup.msi'"

if not exist "installers\node-setup.msi" (
    echo  [ERROR] Download failed. Install manually: https://nodejs.org/
    goto :the_end
)

echo  [!!] Installing Node.js...
start /wait msiexec /i "installers\node-setup.msi" /qn /norestart
set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
del "installers\node-setup.msi" >nul 2>&1

node --version >nul 2>&1
if errorlevel 1 (
    echo  [!!] Node.js installed. CLOSE this window and run start.bat again.
    goto :the_end
)
echo  [OK] Node.js installed!

:node_done

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
:: STEP 4: MONGODB
:: ================================================================
echo  [Step 4/7] Checking MongoDB...

set "MONGO_CMD=mongod"
set "MONGO_PORTABLE=%cd%\mongodb\bin\mongod.exe"

where mongod >nul 2>&1
if %errorlevel% equ 0 (
    echo  [OK] MongoDB found
    goto :mongo_done
)
if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB found (portable)
    goto :mongo_done
)

echo  [!!] Downloading portable MongoDB (~200MB)...
if not exist "mongodb\bin" mkdir "mongodb\bin"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Write-Host '      Downloading...'; Invoke-WebRequest -Uri 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip' -OutFile 'mongodb\mongo.zip'; Write-Host '      Extracting...'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory('mongodb\mongo.zip','mongodb\temp'); $d=Get-ChildItem 'mongodb\temp' -Directory|Select -First 1; Copy-Item (Join-Path $d.FullName 'bin\*') 'mongodb\bin\' -Force; Remove-Item 'mongodb\temp' -Recurse -Force; Remove-Item 'mongodb\mongo.zip' -Force; Write-Host '      Done!'"

if exist "%MONGO_PORTABLE%" (
    set "MONGO_CMD=%MONGO_PORTABLE%"
    echo  [OK] MongoDB ready
    goto :mongo_done
)
echo  [ERROR] MongoDB download failed.
goto :the_end

:mongo_done

:: ================================================================
:: STEP 5: NETWORK + CONFIG
:: ================================================================
echo  [Step 5/7] Configuring...

set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do set LOCAL_IP=%%b& goto :ip_set
)
:ip_set
echo  [OK] Network IP: %LOCAL_IP%

cd /d "%~dp0"
>backend\.env (
    echo MONGO_URL=mongodb://localhost:27017
    echo DB_NAME=dine_local_hub
    echo CORS_ORIGINS=*
)
>frontend\.env (
    echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
    echo HOST=0.0.0.0
    echo PORT=3000
    echo ENABLE_HEALTH_CHECK=false
)

for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do taskkill /PID %%p /F >nul 2>&1

netsh advfirewall firewall add rule name="DLH-Back" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH-Front" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1

:: ================================================================
:: STEP 6: START MONGODB + BACKEND
:: ================================================================
echo  [Step 6/7] Starting Backend...

tasklist /FI "IMAGENAME eq mongod.exe" 2>nul | find /I "mongod.exe" >nul
if errorlevel 1 (
    if not exist "data\db" mkdir "data\db"
    start "" /min "%MONGO_CMD%" --dbpath "%cd%\data\db"
    timeout /t 3 /nobreak >nul
    echo  [OK] MongoDB started
) else (
    echo  [OK] MongoDB already running
)

echo  [OK] Launching backend...
cd /d "%~dp0"
start "" /min start-backend.bat
timeout /t 5 /nobreak >nul

:: ================================================================
:: STEP 7: START FRONTEND
:: ================================================================
echo  [Step 7/7] Starting Frontend...

cd /d "%~dp0"
echo  [OK] Launching frontend...
start "" /min start-frontend.bat
echo      Compiling (~30 seconds)...
timeout /t 30 /nobreak >nul

:: ================================================================
:: ALL DONE
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

:the_end
echo.
echo  Type EXIT to close this window.
echo.
