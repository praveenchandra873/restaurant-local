@echo off
title Dine Local Hub - Setup
color 0B

echo.
echo  ================================================
echo       DINE LOCAL HUB - Setup Starting...
echo  ================================================
echo.
echo  This will install everything needed to run the
echo  restaurant management system on this computer.
echo.
echo  Please DO NOT close this window until setup
echo  is complete.
echo.
pause

REM Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!!] Administrator access required.
    echo  [!!] Restarting with admin rights...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Run the PowerShell setup script
powershell -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"

pause
