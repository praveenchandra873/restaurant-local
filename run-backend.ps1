$Host.UI.RawUI.WindowTitle = "DLH-Backend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir "backend"

# GO TO BACKEND FOLDER
Set-Location $backendDir

Write-Host ""
Write-Host "  Starting Dine Local Hub Backend..." -ForegroundColor Cyan
Write-Host "  Folder: $backendDir" -ForegroundColor Gray
Write-Host ""

# Refresh PATH from system
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Create .env
@"
MONGO_URL=mongodb://localhost:27017
DB_NAME=dine_local_hub
CORS_ORIGINS=*
"@ | Set-Content -Path ".\.env" -Encoding UTF8

# Create venv if needed
if (-not (Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "  Creating virtual environment..." -ForegroundColor Yellow
    cmd /c "python -m venv venv"
}

# Activate venv and install packages via cmd (reliable PATH)
cmd /c "call venv\Scripts\activate.bat && python -c ""import uvicorn"" 2>nul || pip install -r requirements-local.txt"

# Seed only if database is empty
Write-Host "  Checking database..." -ForegroundColor Gray
$seedCheck = cmd /c "call venv\Scripts\activate.bat && python -c ""from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({}));print(n)"" 2>&1"
if ($seedCheck -match "^0$") {
    Write-Host "  Seeding database with sample data..." -ForegroundColor Yellow
    cmd /c "call venv\Scripts\activate.bat && python seed_db.py"
}

Write-Host ""
Write-Host "  Starting backend on port 8001..." -ForegroundColor Green
Write-Host ""

# Run uvicorn via cmd (handles venv activation properly)
cmd /c "call venv\Scripts\activate.bat && python -m uvicorn server:app --host 0.0.0.0 --port 8001"
