$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

# Refresh PATH first
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")

# Find folders
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"
Set-Location $frontendDir

Write-Host ""
Write-Host "  DLH Frontend" -ForegroundColor Cyan
Write-Host "  Dir: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Install packages if node_modules missing
$cracoJs = Join-Path $frontendDir "node_modules\@craco\craco\dist\bin\craco.js"
if (-not (Test-Path $cracoJs)) {
    Write-Host "  Installing packages (2-3 min first time)..." -ForegroundColor Yellow
    Write-Host ""
    & npm install
    Write-Host ""
}

# Verify craco exists after install
if (-not (Test-Path $cracoJs)) {
    Write-Host "  [ERROR] Package install failed. Retrying..." -ForegroundColor Red
    & npm install --force
    Write-Host ""
}

if (-not (Test-Path $cracoJs)) {
    Write-Host "  [ERROR] Could not install packages." -ForegroundColor Red
    Write-Host "  Try running this manually:" -ForegroundColor Red
    Write-Host "    cd $frontendDir" -ForegroundColor Yellow
    Write-Host "    npm install" -ForegroundColor Yellow
    Read-Host "  Press Enter"
    exit
}

$env:HOST = "0.0.0.0"
$env:PORT = "3000"

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

& node $cracoJs start
