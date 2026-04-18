@echo off
title DLH-Frontend
cd /d "%~dp0frontend"

:: Install packages if needed
if not exist "node_modules" (
    echo Installing frontend packages (2-3 minutes first time)...
    call yarn install
    echo.
)

if not exist "node_modules\.bin\craco.cmd" (
    echo craco not found, reinstalling...
    call yarn install
    echo.
)

set HOST=0.0.0.0
set PORT=3000

echo Starting frontend on port 3000...
echo.
.\node_modules\.bin\craco.cmd start
