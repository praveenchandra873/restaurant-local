@echo off
title Dine Local Hub - Setup
color 0B

echo.
echo  ================================================
echo       DINE LOCAL HUB - Setup
echo  ================================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!!] Administrator access is needed.
    echo  [!!] A permission popup will appear - click YES.
    echo.
    
    REM Re-launch THIS SAME bat file as admin, passing our folder path
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/k cd /d \"%~dp0\" && \"%~f0\" elevated' -Verb RunAs"
    exit /b
)

REM If we get here, we are admin. Make sure we are in the right folder.
cd /d "%~dp0"

echo  [OK] Running as Administrator
echo  [OK] Working folder: %cd%
echo.
echo  This will install everything needed to run the
echo  restaurant management system. Please wait...
echo.

REM Run the PowerShell setup script from the current folder
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"

echo.
echo  ================================================
echo  Setup script finished. Check above for results.
echo  ================================================
echo.
pause
