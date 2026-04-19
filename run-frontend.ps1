$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

# Go to the frontend folder (handles paths with spaces and parentheses)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"
Set-Location $frontendDir

Write-Host ""
Write-Host "  Starting Dine Local Hub Frontend..." -ForegroundColor Cyan
Write-Host "  Folder: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Install packages if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "  Installing packages (first time, 2-3 minutes)..." -ForegroundColor Yellow
    & yarn install
    Write-Host ""
}

# Check craco exists
$cracoPath = Join-Path $frontendDir "node_modules\.bin\craco.cmd"
if (-not (Test-Path $cracoPath)) {
    Write-Host "  craco not found, reinstalling..." -ForegroundColor Yellow
    & yarn install
    Write-Host ""
}

# Set environment variables
$env:HOST = "0.0.0.0"
$env:PORT = "3000"

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

# Run craco via cmd (PowerShell can't execute .cmd files directly)
cmd /c "$cracoPath start"
