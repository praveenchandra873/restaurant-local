@echo off
:: This launcher opens start-app.bat in a cmd window that STAYS OPEN even on errors
:: Right-click THIS file -> Run as administrator

:: Find where this file lives
set "MYDIR=%~dp0"

:: Open a new cmd window that stays open (/k) and runs the actual script
cmd /k "cd /d "%MYDIR%" && "%MYDIR%start-app.bat""
