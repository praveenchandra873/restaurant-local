$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"
Set-Location $frontendDir

Write-Host ""
Write-Host "  Starting Dine Local Hub Frontend..." -ForegroundColor Cyan
Write-Host "  Folder: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Install packages if needed (use cmd /c for yarn/npm since they may not be in PS path)
$nodeModules = Join-Path $frontendDir "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "  Installing packages - first time, 2-3 minutes..." -ForegroundColor Yellow
    cmd /c "cd /d `"$frontendDir`" && npm install" 2>&1
    Write-Host ""
}

# Check craco exists
$cracoJs = Join-Path $frontendDir "node_modules\@craco\craco\dist\bin\craco.js"
if (-not (Test-Path $cracoJs)) {
    Write-Host "  craco not found, reinstalling..." -ForegroundColor Yellow
    cmd /c "cd /d `"$frontendDir`" && npm install" 2>&1
    Write-Host ""
}

# Set environment variables
$env:HOST = "0.0.0.0"
$env:PORT = "3000"

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

# Run craco directly via node (bypasses all .cmd and PATH issues)
& node $cracoJs start
