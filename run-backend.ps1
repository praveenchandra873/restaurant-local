$Host.UI.RawUI.WindowTitle = "DLH-Backend"

# Refresh PATH first
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")

# Find folders
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir "backend"
Set-Location $backendDir

Write-Host ""
Write-Host "  DLH Backend" -ForegroundColor Cyan
Write-Host "  Dir: $backendDir" -ForegroundColor Gray
Write-Host ""

# Create .env using full path
$envFile = Join-Path $backendDir ".env"
"MONGO_URL=mongodb://localhost:27017`nDB_NAME=dine_local_hub`nCORS_ORIGINS=*" | Out-File -FilePath $envFile -Encoding ascii -NoNewline
Write-Host "  [OK] .env created" -ForegroundColor Green

# Create venv if needed
$venvActivate = Join-Path $backendDir "venv\Scripts\Activate.ps1"
if (-not (Test-Path $venvActivate)) {
    Write-Host "  Creating virtual environment..." -ForegroundColor Yellow
    & python -m venv (Join-Path $backendDir "venv")
}

# Activate venv in PowerShell
. $venvActivate

# Install packages if needed
try { & python -c "import uvicorn" 2>$null } catch {}
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Installing packages..." -ForegroundColor Yellow
    $reqFile = Join-Path $backendDir "requirements-local.txt"
    if (Test-Path $reqFile) {
        & pip install -r $reqFile
    } else {
        & pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    }
}

# Seed if database is empty OR has outdated menu (less than 90 items)
Write-Host "  Checking database..." -ForegroundColor Gray
$seedScript = Join-Path $backendDir "seed_db.py"
try {
    $menuCount = & python -c "from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.menu_items.count_documents({}));print(n)" 2>&1
    $menuNum = [int]("$menuCount".Trim())
    if ($menuNum -lt 90) {
        Write-Host "  Menu has $menuNum items, re-seeding with full 90-item menu..." -ForegroundColor Yellow
        & python $seedScript
    } else {
        Write-Host "  [OK] Database has $menuNum menu items" -ForegroundColor Green
    }
} catch {
    Write-Host "  Seeding database..." -ForegroundColor Yellow
    & python $seedScript
}

Write-Host ""
Write-Host "  Starting backend on port 8001..." -ForegroundColor Green
Write-Host ""

& python -m uvicorn server:app --host 0.0.0.0 --port 8001
