$Host.UI.RawUI.WindowTitle = "Dine Local Hub"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Refresh PATH
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

Write-Host ""
Write-Host "  ===========================================================" -ForegroundColor Cyan
Write-Host "       DINE LOCAL HUB - Restaurant Management System" -ForegroundColor White
Write-Host "  ===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Folder: $scriptDir" -ForegroundColor Gray
Write-Host ""

# ---- STEP 1: PYTHON ----
Write-Host "  [Step 1/7] Checking Python..." -ForegroundColor White
$pyVer = cmd /c "python --version 2>&1"
if ($pyVer -match "Python 3") {
    Write-Host "  [OK] $pyVer" -ForegroundColor Green
} else {
    Write-Host "  [!!] Python not found. Downloading..." -ForegroundColor Yellow
    $installDir = Join-Path $scriptDir "installers"
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
    $pyInstaller = Join-Path $installDir "python-setup.exe"
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" -OutFile $pyInstaller
        Write-Host "  [!!] Installing Python..." -ForegroundColor Yellow
        Start-Process -FilePath $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_pip=1" -Wait
        # Refresh PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        Remove-Item $pyInstaller -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Python installed!" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Install Python manually: https://www.python.org/downloads/" -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit
    }
}

# ---- STEP 2: NODE.JS ----
Write-Host "  [Step 2/7] Checking Node.js..." -ForegroundColor White
$nodeVer = cmd /c "node --version 2>&1"
if ($nodeVer -match "v\d") {
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
} else {
    Write-Host "  [!!] Node.js not found. Downloading..." -ForegroundColor Yellow
    $installDir = Join-Path $scriptDir "installers"
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
    $nodeInstaller = Join-Path $installDir "node-setup.msi"
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.18.1/node-v20.18.1-x64.msi" -OutFile $nodeInstaller
        Write-Host "  [!!] Installing Node.js..." -ForegroundColor Yellow
        Start-Process msiexec -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Node.js installed!" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Install Node.js manually: https://nodejs.org/" -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit
    }
}

# ---- STEP 3: YARN ----
Write-Host "  [Step 3/7] Checking Yarn..." -ForegroundColor White
$yarnCheck = cmd /c "yarn --version 2>&1"
if (-not ($yarnCheck -match "\d+\.\d+")) {
    Write-Host "  [!!] Installing Yarn..." -ForegroundColor Yellow
    cmd /c "npm install -g yarn"
}
Write-Host "  [OK] Yarn ready" -ForegroundColor Green

# ---- STEP 4: MONGODB ----
Write-Host "  [Step 4/7] Checking MongoDB..." -ForegroundColor White
$mongoDir = Join-Path $scriptDir "mongodb\bin"
$mongoExe = Join-Path $mongoDir "mongod.exe"

$systemMongo = cmd /c "where mongod 2>&1"
if ($systemMongo -match "mongod") {
    $mongoCmd = "mongod"
    Write-Host "  [OK] MongoDB found" -ForegroundColor Green
} elseif (Test-Path $mongoExe) {
    $mongoCmd = $mongoExe
    Write-Host "  [OK] MongoDB found" -ForegroundColor Green
} else {
    Write-Host "  [!!] Downloading portable MongoDB ~200MB..." -ForegroundColor Yellow
    if (-not (Test-Path $mongoDir)) { New-Item -ItemType Directory -Path $mongoDir -Force | Out-Null }
    $mongoZip = Join-Path $scriptDir "mongodb\mongo.zip"
    $mongoTemp = Join-Path $scriptDir "mongodb\temp"
    $ProgressPreference = 'SilentlyContinue'
    try {
        Write-Host "       Downloading..." -ForegroundColor Gray
        Invoke-WebRequest -Uri "https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.20.zip" -OutFile $mongoZip
        Write-Host "       Extracting..." -ForegroundColor Gray
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($mongoZip, $mongoTemp)
        $extracted = Get-ChildItem $mongoTemp -Directory | Select-Object -First 1
        Copy-Item (Join-Path $extracted.FullName "bin\*") $mongoDir -Force
        Remove-Item $mongoTemp -Recurse -Force
        Remove-Item $mongoZip -Force
        $mongoCmd = $mongoExe
        Write-Host "  [OK] MongoDB ready" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] MongoDB download failed: $_" -ForegroundColor Red
        Write-Host "  Install manually: https://www.mongodb.com/try/download/community" -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit
    }
}

# ---- STEP 5: NETWORK CONFIG ----
Write-Host "  [Step 5/7] Configuring..." -ForegroundColor White

$localIP = "127.0.0.1"
$ipOutput = ipconfig | Select-String "IPv4 Address"
if ($ipOutput) {
    $match = $ipOutput[0] -match ":\s*(\d+\.\d+\.\d+\.\d+)"
    if ($match) { $localIP = $Matches[1] }
}
Write-Host "  [OK] Network IP: $localIP" -ForegroundColor Green

# Create .env files
$backendEnv = Join-Path $scriptDir "backend\.env"
@"
MONGO_URL=mongodb://localhost:27017
DB_NAME=dine_local_hub
CORS_ORIGINS=*
"@ | Set-Content $backendEnv -Encoding UTF8

$frontendEnv = Join-Path $scriptDir "frontend\.env"
@"
REACT_APP_BACKEND_URL=http://${localIP}:8001
HOST=0.0.0.0
PORT=3000
ENABLE_HEALTH_CHECK=false
"@ | Set-Content $frontendEnv -Encoding UTF8

# Kill old processes
Get-NetTCPConnection -LocalPort 8001 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

# Firewall
netsh advfirewall firewall add rule name="DLH-Back" dir=in action=allow protocol=TCP localport=8001 2>$null | Out-Null
netsh advfirewall firewall add rule name="DLH-Front" dir=in action=allow protocol=TCP localport=3000 2>$null | Out-Null

# ---- STEP 6: START MONGODB + BACKEND ----
Write-Host "  [Step 6/7] Starting Backend..." -ForegroundColor White

$mongoRunning = Get-Process mongod -ErrorAction SilentlyContinue
if (-not $mongoRunning) {
    $dataDir = Join-Path $scriptDir "data\db"
    if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
    Start-Process -FilePath $mongoCmd -ArgumentList "--dbpath `"$dataDir`"" -WindowStyle Minimized
    Start-Sleep -Seconds 3
}
Write-Host "  [OK] MongoDB running" -ForegroundColor Green

Write-Host "  [OK] Launching backend..." -ForegroundColor Green
$backendBat = Join-Path $scriptDir "start-backend.bat"
Start-Process -FilePath $backendBat -WindowStyle Minimized
Start-Sleep -Seconds 5

# ---- STEP 7: START FRONTEND ----
Write-Host "  [Step 7/7] Starting Frontend..." -ForegroundColor White
$frontendBat = Join-Path $scriptDir "start-frontend.bat"
Start-Process -FilePath $frontendBat -WindowStyle Minimized
Write-Host "       Compiling ~30 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# ---- DONE ----
Clear-Host
Write-Host ""
Write-Host "  ===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "       DINE LOCAL HUB IS RUNNING!" -ForegroundColor White
Write-Host ""
Write-Host "       Your Network IP: $localIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "       Open on ANY device on your WiFi:" -ForegroundColor Green
Write-Host ""
Write-Host "       Captain:  http://${localIP}:3000/captain" -ForegroundColor Cyan
Write-Host "       Kitchen:  http://${localIP}:3000/kitchen" -ForegroundColor Cyan
Write-Host "       Billing:  http://${localIP}:3000/billing" -ForegroundColor Cyan
Write-Host "       Admin:    http://${localIP}:3000/admin" -ForegroundColor Cyan
Write-Host "       Owner:    http://${localIP}:3000/owner" -ForegroundColor Cyan
Write-Host ""
Write-Host "       On THIS computer:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "       Owner password:    owner123" -ForegroundColor Yellow
Write-Host ""
Write-Host "       DO NOT close the minimized windows!" -ForegroundColor Yellow
Write-Host "       To stop: double-click stop.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "  ===========================================================" -ForegroundColor Green
Write-Host ""
Read-Host "  Press Enter to close this window"
