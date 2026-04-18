@echo off
title DLH-Backend
cd /d "%~dp0backend"

:: Ensure .env exists
if not exist ".env" (
    echo MONGO_URL=mongodb://localhost:27017> ".env"
    echo DB_NAME=dine_local_hub>> ".env"
    echo CORS_ORIGINS=*>> ".env"
)

:: Create venv if needed
if not exist "venv\Scripts\activate.bat" (
    echo Creating virtual environment...
    python -m venv venv
)

call venv\Scripts\activate.bat

:: Install packages if needed
python -c "import uvicorn" >nul 2>&1
if errorlevel 1 (
    echo Installing backend packages...
    if exist "requirements-local.txt" (
        pip install -r requirements-local.txt
    ) else (
        pip install fastapi uvicorn python-dotenv pymongo pydantic motor
    )
)

:: Seed if empty
python -c "from motor.motor_asyncio import AsyncIOMotorClient;import asyncio,os;from dotenv import load_dotenv;from pathlib import Path;load_dotenv(Path('.env'));c=AsyncIOMotorClient(os.environ['MONGO_URL']);db=c[os.environ['DB_NAME']];n=asyncio.get_event_loop().run_until_complete(db.tables.count_documents({}));print(n)" 2>nul | findstr /r "^0$" >nul && (
    echo Seeding database...
    python seed_db.py
)

echo.
echo Starting backend on port 8001...
python -m uvicorn server:app --host 0.0.0.0 --port 8001
