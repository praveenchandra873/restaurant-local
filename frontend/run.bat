@echo off
title DLH-Frontend
cd /d "%~dp0"

echo Starting Dine Local Hub Frontend...
echo.

:: Install packages if needed
if not exist "node_modules" (
    echo Installing packages (first time, 2-3 minutes)...
    call yarn install
    echo.
)

:: Check craco exists
if not exist "node_modules\.bin\craco.cmd" (
    echo [ERROR] craco not found. Reinstalling...
    call yarn install
)

set HOST=0.0.0.0
set PORT=3000

echo Starting on port 3000...
echo.

.\node_modules\.bin\craco.cmd start
