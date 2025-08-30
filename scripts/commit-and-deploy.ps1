# Commit and deploy MCP server via CI/CD
Write-Host "Committing MCP server files and triggering CI/CD deployment..." -ForegroundColor Green

Write-Host "1. Adding all new files to git..." -ForegroundColor Yellow
git add .

Write-Host "2. Committing changes..." -ForegroundColor Yellow  
git commit -m "Add MCP server with CI/CD pipeline

- Add basic MCP server with 5 tools (placeholders)
- Add GitHub Actions workflows for infrastructure and MCP deployment
- Add environment-specific configurations for dev/qa
- Configure Function App for MCP server deployment"

Write-Host "3. Pushing to trigger CI/CD pipeline..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "SUCCESS: Files committed and pushed!" -ForegroundColor Green
Write-Host "Check GitHub Actions tab to monitor deployment progress" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT: Once deployed, test MCP server connection from Claude Desktop" -ForegroundColor Yellow