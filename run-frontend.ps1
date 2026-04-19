$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"

Write-Host ""
Write-Host "  Starting Dine Local Hub Frontend..." -ForegroundColor Cyan
Write-Host "  Folder: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Refresh PATH from system
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Go to frontend folder first (PowerShell handles special chars)
Set-Location $frontendDir

# Install packages if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "  Installing packages - first time, 2-3 minutes..." -ForegroundColor Yellow
    # Run npm from current directory (no path issues)
    cmd /c "npm install"
    Write-Host ""
}

# Check craco exists
if (-not (Test-Path "node_modules\@craco\craco\dist\bin\craco.js")) {
    Write-Host "  craco not found, reinstalling..." -ForegroundColor Yellow
    cmd /c "npm install"
    Write-Host ""
}

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

# Set env vars and run craco from current directory
$env:HOST = "0.0.0.0"
$env:PORT = "3000"
cmd /c "node node_modules\@craco\craco\dist\bin\craco.js start"
