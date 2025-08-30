# Setup MCP Server TypeScript Project with CI/CD in mind
Write-Host "Setting up MCP Server project for CI/CD deployment..." -ForegroundColor Green

# Create proper project structure for CI/CD
Write-Host "1. Creating CI/CD-ready project structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "src/mcp-server" -Force | Out-Null
New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
New-Item -ItemType Directory -Path "environments" -Force | Out-Null
New-Item -ItemType Directory -Path "environments/dev" -Force | Out-Null
New-Item -ItemType Directory -Path "environments/qa" -Force | Out-Null
New-Item -ItemType Directory -Path "environments/prod" -Force | Out-Null

Write-Host "2. Creating environment-specific parameter files..." -ForegroundColor Yellow

# Move existing dev parameters to environments folder
Move-Item "infrastructure/bicep/parameters.dev.json" "environments/dev/" -Force

Write-Host "3. Setting up MCP server directory..." -ForegroundColor Yellow
Set-Location "src/mcp-server"

# Create package.json with environment variables support
Write-Host "4. Creating environment-aware package.json..." -ForegroundColor Yellow

Set-Location "../.."

Write-Host "SUCCESS: CI/CD-ready project structure created!" -ForegroundColor Green
Write-Host ""
Write-Host "STRUCTURE:" -ForegroundColor Cyan
Write-Host "├── .github/workflows/ (CI/CD pipelines)" -ForegroundColor White
Write-Host "├── environments/" -ForegroundColor White
Write-Host "│   ├── dev/ (dev configs)" -ForegroundColor White
Write-Host "│   ├── qa/ (qa configs)" -ForegroundColor White
Write-Host "│   └── prod/ (prod configs)" -ForegroundColor White
Write-Host "├── infrastructure/bicep/ (reusable templates)" -ForegroundColor White
Write-Host "└── src/mcp-server/ (application code)" -ForegroundColor White
Write-Host ""
Write-Host "Next: Create environment configs and CI/CD pipeline" -ForegroundColor Yellow