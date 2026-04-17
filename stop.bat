@echo off
title Dine Local Hub - Stopping
color 0C

echo.
echo  ================================================
echo       DINE LOCAL HUB - Stopping Services
echo  ================================================
echo.

:: Kill by port (most reliable)
echo  [..] Stopping Backend (port 8001)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8001" ^| findstr "LISTENING" 2^>nul') do (
    taskkill /PID %%p /F >nul 2>&1
    echo  [OK] Killed process %%p
)

echo  [..] Stopping Frontend (port 3000)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do (
    taskkill /PID %%p /F >nul 2>&1
    echo  [OK] Killed process %%p
)

:: Kill by window title as backup
taskkill /FI "WINDOWTITLE eq DLH-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq DLH-Frontend*" /F >nul 2>&1

echo.
echo  [OK] All services stopped.
echo.
echo  Press any key to close...
pause >nul
