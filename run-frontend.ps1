$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"

Write-Host ""
Write-Host "  Starting Dine Local Hub Frontend..." -ForegroundColor Cyan
Write-Host "  Folder: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Refresh PATH from system (picks up newly installed programs)
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Install packages if needed
$nodeModules = Join-Path $frontendDir "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "  Installing packages - first time, 2-3 minutes..." -ForegroundColor Yellow
    cmd /c "cd /d `"$frontendDir`" && npm install"
    Write-Host ""
}

# Check craco exists
$cracoJs = Join-Path $frontendDir "node_modules\@craco\craco\dist\bin\craco.js"
if (-not (Test-Path $cracoJs)) {
    Write-Host "  craco not found, reinstalling..." -ForegroundColor Yellow
    cmd /c "cd /d `"$frontendDir`" && npm install"
    Write-Host ""
}

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

# Run everything through cmd which has the correct PATH
cmd /c "cd /d `"$frontendDir`" && set HOST=0.0.0.0 && set PORT=3000 && node `"$cracoJs`" start"
