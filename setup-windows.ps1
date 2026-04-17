# ============================================
#  DINE LOCAL HUB - One-Click Setup Script
#  For Windows (PowerShell)
# ============================================

$ErrorActionPreference = "Stop"

function Write-Banner {
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host "                                                  " -ForegroundColor Cyan
    Write-Host "       DINE LOCAL HUB                             " -ForegroundColor White
    Write-Host "       Restaurant Management System               " -ForegroundColor Cyan
    Write-Host "       One-Click Setup for Windows                " -ForegroundColor Cyan
    Write-Host "                                                  " -ForegroundColor Cyan
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$StepNum, [string]$Message)
    Write-Host ""
    Write-Host "  ------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  Step ${StepNum}: $Message" -ForegroundColor White
    Write-Host "  ------------------------------------------------" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!!] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [ERROR] $Message" -ForegroundColor Red
}

function Get-LocalIP {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -ne "127.0.0.1"
    } | Select-Object -First 1).IPAddress
    if (-not $ip) { $ip = "127.0.0.1" }
    return $ip
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Install-Chocolatey {
    if (-not (Test-Command "choco")) {
        Write-Warn "Chocolatey not found. Installing (needed to install other tools)..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path = "$env:ALLUSERSPROFILE\chocolatey\bin;$env:Path"
        Write-Ok "Chocolatey installed"
    } else {
        Write-Ok "Chocolatey is already installed"
    }
}

function Install-MongoDB {
    if (Test-Command "mongod") {
        Write-Ok "MongoDB is already installed"
        return
    }

    Write-Warn "MongoDB not found. Installing..."
    choco install mongodb -y --no-progress
    # Add MongoDB to PATH
    $mongoPath = "C:\Program Files\MongoDB\Server\7.0\bin"
    if (Test-Path $mongoPath) {
        $env:Path = "$mongoPath;$env:Path"
    }

    # Create data directory
    if (-not (Test-Path "C:\data\db")) {
        New-Item -ItemType Directory -Path "C:\data\db" -Force | Out-Null
    }

    # Start MongoDB as a service
    try {
        Start-Service MongoDB -ErrorAction SilentlyContinue
    } catch {
        Write-Warn "Starting MongoDB manually..."
        Start-Process -FilePath "mongod" -ArgumentList "--dbpath C:\data\db" -WindowStyle Hidden
    }

    Write-Ok "MongoDB installed and started"
}

function Install-Python {
    if (Test-Command "python") {
        $ver = python --version 2>&1
        Write-Ok "Python is already installed ($ver)"
        return
    }

    Write-Warn "Python not found. Installing..."
    choco install python311 -y --no-progress
    $env:Path = "$env:LOCALAPPDATA\Programs\Python\Python311;$env:LOCALAPPDATA\Programs\Python\Python311\Scripts;$env:Path"
    Write-Ok "Python installed"
}

function Install-NodeJS {
    if (Test-Command "node") {
        $ver = node --version 2>&1
        Write-Ok "Node.js is already installed ($ver)"
        return
    }

    Write-Warn "Node.js not found. Installing..."
    choco install nodejs-lts -y --no-progress
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Ok "Node.js installed"
}

function Install-Yarn {
    if (Test-Command "yarn") {
        Write-Ok "Yarn is already installed"
        return
    }

    Write-Warn "Yarn not found. Installing..."
    npm install -g yarn
    Write-Ok "Yarn installed"
}

function Setup-Backend {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) { $scriptDir = Get-Location }
    $backendDir = Join-Path $scriptDir "backend"
    Set-Location $backendDir

    # Create virtual environment
    python -m venv venv
    & "$backendDir\venv\Scripts\Activate.ps1"

    # Install dependencies
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create .env file
    @"
MONGO_URL=mongodb://localhost:27017
DB_NAME=dine_local_hub
CORS_ORIGINS=*
"@ | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline

    Write-Ok "Backend setup complete"

    # Seed the database
    python seed_db.py
    Write-Ok "Database seeded with sample data"

    deactivate
}

function Setup-Frontend {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) { $scriptDir = Get-Location }
    $frontendDir = Join-Path $scriptDir "frontend"
    $localIP = Get-LocalIP
    Set-Location $frontendDir

    # Install dependencies
    yarn install

    # Create .env file
    @"
REACT_APP_BACKEND_URL=http://${localIP}:8001
"@ | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline

    Write-Ok "Frontend setup complete"
}

function Create-StartScript {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) { $scriptDir = Get-Location }

    # Create start.bat
    @"
@echo off
title Dine Local Hub - Restaurant Management System
color 0B

echo.
echo  ================================================
echo       DINE LOCAL HUB - Starting...
echo  ================================================
echo.

REM Get Local IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
    goto :found_ip
)
:found_ip
set LOCAL_IP=%LOCAL_IP: =%

REM Update frontend .env
echo REACT_APP_BACKEND_URL=http://%LOCAL_IP%:8001> "%~dp0frontend\.env"

REM Start MongoDB (if not running)
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I "mongod.exe" >NUL
if errorlevel 1 (
    echo [!!] Starting MongoDB...
    start /B mongod --dbpath C:\data\db
    timeout /t 3 >NUL
)
echo [OK] MongoDB running

REM Start Backend
echo [OK] Starting Backend...
cd /d "%~dp0backend"
start "DLH-Backend" cmd /c "venv\Scripts\activate && uvicorn server:app --host 0.0.0.0 --port 8001"
timeout /t 3 >NUL

REM Start Frontend
echo [OK] Starting Frontend...
cd /d "%~dp0frontend"
start "DLH-Frontend" cmd /c "set PORT=3000 && set HOST=0.0.0.0 && yarn start"
timeout /t 8 >NUL

echo.
echo  ================================================
echo.
echo       DINE LOCAL HUB IS RUNNING!
echo.
echo       Your Network IP: %LOCAL_IP%
echo.
echo       Open on any device connected to WiFi:
echo.
echo       Captain (Phone):   http://%LOCAL_IP%:3000/captain
echo       Kitchen (Tablet):  http://%LOCAL_IP%:3000/kitchen
echo       Billing (Desktop): http://%LOCAL_IP%:3000/billing
echo       Admin Panel:       http://%LOCAL_IP%:3000/admin
echo.
echo       Close this window to keep running.
echo       To stop: run stop.bat
echo.
echo  ================================================
echo.
pause
"@ | Out-File -FilePath (Join-Path $scriptDir "start.bat") -Encoding ASCII

    # Create stop.bat
    @"
@echo off
echo Stopping Dine Local Hub...
taskkill /FI "WINDOWTITLE eq DLH-Backend*" /F 2>NUL
taskkill /FI "WINDOWTITLE eq DLH-Frontend*" /F 2>NUL
echo All services stopped.
pause
"@ | Out-File -FilePath (Join-Path $scriptDir "stop.bat") -Encoding ASCII

    Write-Ok "Start/Stop scripts created (start.bat / stop.bat)"
}

function Write-Success {
    $localIP = Get-LocalIP
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Green
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       SETUP COMPLETE!                            " -ForegroundColor White
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       Your Network IP: $localIP               " -ForegroundColor Cyan
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       To start the system, double-click:         " -ForegroundColor Green
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "         start.bat                                " -ForegroundColor White
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       Then open on any device on your WiFi:      " -ForegroundColor Green
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       Captain:  http://${localIP}:3000/captain " -ForegroundColor Cyan
    Write-Host "       Kitchen:  http://${localIP}:3000/kitchen " -ForegroundColor Cyan
    Write-Host "       Billing:  http://${localIP}:3000/billing " -ForegroundColor Cyan
    Write-Host "       Admin:    http://${localIP}:3000/admin   " -ForegroundColor Cyan
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "       To stop: double-click stop.bat             " -ForegroundColor Green
    Write-Host "                                                  " -ForegroundColor Green
    Write-Host "  ================================================" -ForegroundColor Green
    Write-Host ""
}

# ==================== MAIN ====================

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "Please run this script as Administrator!"
    Write-Err "Right-click PowerShell -> 'Run as Administrator' -> then run this script again"
    pause
    exit 1
}

Write-Banner

Write-Step "1" "Installing package manager (Chocolatey)"
Install-Chocolatey

Write-Step "2" "Installing MongoDB (Database)"
Install-MongoDB

Write-Step "3" "Installing Python (Backend Server)"
Install-Python

Write-Step "4" "Installing Node.js & Yarn (Frontend)"
Install-NodeJS
Install-Yarn

Write-Step "5" "Setting up Backend"
Setup-Backend

Write-Step "6" "Setting up Frontend"
Setup-Frontend

Write-Step "7" "Creating startup scripts"
Create-StartScript

Write-Success
pause
