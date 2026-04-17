@echo off
title Dine Local Hub - Running
color 0A

echo.
echo  ================================================
echo       DINE LOCAL HUB - Starting Services
echo  ================================================
echo.

cd /d "%~dp0"

:: ---- GET LOCAL IP ----
set LOCAL_IP=127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :got_ip
    )
)
:got_ip
echo  [OK] Your Network IP: %LOCAL_IP%

:: ---- UPDATE FRONTEND ENV WITH CURRENT IP ----
cd /d "%~dp0frontend"
(
echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001
echo HOST=0.0.0.0
echo PORT=3000
) > ".env"
cd /d "%~dp0"

:: ---- ADD FIREWALL RULES (silently, needs admin) ----
netsh advfirewall firewall add rule name="DLH Backend" dir=in action=allow protocol=TCP localport=8001 >nul 2>&1
netsh advfirewall firewall add rule name="DLH Frontend" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1

:: ---- KILL OLD INSTANCES ----
echo  [..] Cleaning up old processes...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do (taskkill /PID %%p /F >nul 2>&1)
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do (taskkill /PID %%p /F >nul 2>&1)
timeout /t 2 /nobreak >nul

:: ---- START MONGODB ----
echo  [..] Starting MongoDB...
tasklist /FI "IMAGENAME eq mongod.exe" 2>nul | find /I "mongod.exe" >nul
if errorlevel 1 (
    if not exist "C:\data\db" mkdir "C:\data\db"
    start "" /min mongod --dbpath C:\data\db
    timeout /t 3 /nobreak >nul
)
echo  [OK] MongoDB running

:: ---- START BACKEND ----
echo  [..] Starting Backend (port 8001)...
cd /d "%~dp0backend"
start "DLH-Backend" /min cmd /k "call venv\Scripts\activate.bat && uvicorn server:app --host 0.0.0.0 --port 8001"
timeout /t 5 /nobreak >nul
echo  [OK] Backend started

:: ---- START FRONTEND ----
echo  [..] Starting Frontend (port 3000)...
cd /d "%~dp0frontend"
start "DLH-Frontend" /min cmd /k "set HOST=0.0.0.0&& set PORT=3000&& yarn start"
echo  [..] Waiting for frontend to compile (about 30 seconds)...
timeout /t 30 /nobreak >nul
echo  [OK] Frontend started

:: ---- SHOW URLS ----
cd /d "%~dp0"
echo.
echo  ================================================
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
echo.
echo       On THIS computer also try:
echo       http://localhost:3000
echo.
echo       DO NOT close the minimized DLH windows!
echo       To stop all services: double-click stop.bat
echo.
echo  ================================================
echo.
echo  Press any key to close ONLY this info window...
echo  (The services will keep running in background)
pause >nul
