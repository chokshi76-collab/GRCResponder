# Install Bicep CLI for Windows
Write-Host "Installing Bicep CLI..." -ForegroundColor Green

# Create a temporary directory
$tempDir = "$env:TEMP\bicep-install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download the latest Bicep release
Write-Host "Downloading Bicep..." -ForegroundColor Cyan
$bicepUrl = "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe"
$bicepPath = "$tempDir\bicep.exe"

try {
    Invoke-WebRequest -Uri $bicepUrl -OutFile $bicepPath -UseBasicParsing
    Write-Host "Bicep downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Bicep: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create Bicep directory in user profile
$bicepInstallDir = "$env:USERPROFILE\.bicep"
New-Item -ItemType Directory -Force -Path $bicepInstallDir | Out-Null

# Copy bicep.exe to install directory
Copy-Item $bicepPath "$bicepInstallDir\bicep.exe" -Force
Write-Host "Bicep installed to: $bicepInstallDir" -ForegroundColor Green

# Add to PATH for current session
$env:PATH += ";$bicepInstallDir"

# Add to PATH permanently for user
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$bicepInstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$bicepInstallDir", "User")
    Write-Host "Bicep added to user PATH permanently" -ForegroundColor Green
} else {
    Write-Host "Bicep already in user PATH" -ForegroundColor Yellow
}

# Test Bicep installation
try {
    $bicepVersion = & "$bicepInstallDir\bicep.exe" --version
    Write-Host "Bicep installed successfully!" -ForegroundColor Green
    Write-Host "Version: $bicepVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to verify Bicep installation" -ForegroundColor Red
    exit 1
}

# Clean up temp files
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "You can now deploy your Bicep templates." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: If you get PATH errors, restart PowerShell or run:" -ForegroundColor Yellow
Write-Host "`$env:PATH += ';$bicepInstallDir'" -ForegroundColor White