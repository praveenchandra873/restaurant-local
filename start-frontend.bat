@echo off
title DLH-Frontend
setlocal

:: Use quotes everywhere to handle parentheses in paths
cd /d "%~dp0frontend"

echo Starting Dine Local Hub Frontend...
echo.

if exist "node_modules" goto :has_modules
echo Installing packages - first time only, 2-3 minutes...
call yarn install
echo.

:has_modules
if exist "node_modules\.bin\craco.cmd" goto :has_craco
echo craco not found, reinstalling...
call yarn install
echo.

:has_craco
set HOST=0.0.0.0
set PORT=3000
echo Starting on port 3000...
echo.
"node_modules\.bin\craco.cmd" start

endlocal
