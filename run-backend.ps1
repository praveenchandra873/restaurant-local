$Host.UI.RawUI.WindowTitle = "DLH-Backend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir "backend"
Set-Location $backendDir

Write-Host ""
Write-Host "  Starting Dine Local Hub Backend..." -ForegroundColor Cyan
Write-Host "  Folder: $backendDir" -ForegroundColor Gray
Write-Host ""

# Create .env
@"
MONGO_URL=mongodb://localhost:27017
DB_NAME=dine_local_hub
CORS_ORIGINS=*
"@ | Set-Content -Path ".env" -Encoding UTF8

# Create venv if needed
if (-not (Test-Path "venv\Scripts\activate.bat")) {
    Write-Host "  Creating virtual environment..." -ForegroundColor Yellow
    & python -m venv venv
}

# Activate venv
& "venv\Scripts\Activate.ps1"

# Install packages if needed
$uvicornCheck = python -c "import uvicorn" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Installing backend packages..." -ForegroundColor Yellow
    if (Test-Path "requirements-local.txt") {
        & pip install -r requirements-local.txt
    } else {
        & pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    }
}

# Seed if empty
$count = python -c "from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({}));print(n)" 2>&1
if ($count -match "^0$") {
    Write-Host "  Seeding database..." -ForegroundColor Yellow
    & python seed_db.py
}

Write-Host ""
Write-Host "  Starting backend on port 8001..." -ForegroundColor Green
Write-Host ""

& python -m uvicorn server:app --host 0.0.0.0 --port 8001
