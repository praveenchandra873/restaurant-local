$Host.UI.RawUI.WindowTitle = "DLH-Frontend"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir "frontend"

# GO TO FRONTEND FOLDER
Set-Location $frontendDir

Write-Host ""
Write-Host "  Starting Dine Local Hub Frontend..." -ForegroundColor Cyan
Write-Host "  Folder: $frontendDir" -ForegroundColor Gray
Write-Host ""

# Refresh PATH from system
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Install packages if needed
if (-not (Test-Path "node_modules\@craco")) {
    Write-Host "  Installing packages - first time, 2-3 minutes..." -ForegroundColor Yellow
    Write-Host ""
    cmd /c "npm install"
    Write-Host ""
}

# Verify craco exists
if (-not (Test-Path "node_modules\@craco\craco\dist\bin\craco.js")) {
    Write-Host "  [!!] Packages missing. Running npm install..." -ForegroundColor Yellow
    cmd /c "npm install"
    Write-Host ""
}

$env:HOST = "0.0.0.0"
$env:PORT = "3000"

Write-Host "  Starting on port 3000..." -ForegroundColor Green
Write-Host ""

# Run craco from current directory via cmd
cmd /c "node node_modules\@craco\craco\dist\bin\craco.js start"
