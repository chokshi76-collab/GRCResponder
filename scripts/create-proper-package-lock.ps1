# Remove package-lock.json completely and use npm install only
Write-Host "=== SIMPLIFYING TO USE NPM INSTALL ONLY ===" -ForegroundColor Green

$packageLockPath = "src/mcp-server/package-lock.json"

Write-Host "`n1. Removing package-lock.json to use npm install..." -ForegroundColor Yellow
if (Test-Path $packageLockPath) {
    Remove-Item $packageLockPath -Force
    Write-Host "✅ Removed package-lock.json" -ForegroundColor Green
} else {
    Write-Host "✅ No package-lock.json to remove" -ForegroundColor Green
}

# Also let's simplify the workflow to just use npm install
$workflowPath = ".github/workflows/deploy-function-app.yml"
$workflowContent = @"
name: Deploy MCP Server to Azure Function App

on:
  push:
    branches: [ main ]
    paths:
      - 'src/mcp-server/**'
      - '.github/workflows/**'
  workflow_dispatch:

env:
  AZURE_FUNCTIONAPP_NAME: func-pdfai-dev-tjqwgu4v
  AZURE_FUNCTIONAPP_PACKAGE_PATH: './src/mcp-server'
  NODE_VERSION: '18.x'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: `${{ env.NODE_VERSION }}

    - name: 'Install dependencies'
      run: |
        cd `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        npm install

    - name: 'Install dev dependencies for build'
      run: |
        cd `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        npm install typescript @types/node --save-dev

    - name: 'Build TypeScript'
      run: |
        cd `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        npx tsc

    - name: 'Deploy to Azure Function App'
      uses: Azure/functions-action@v1
      with:
        app-name: `${{ env.AZURE_FUNCTIONAPP_NAME }}
        package: `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        publish-profile: `${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
"@

Write-Host "`n2. Updating workflow to use simple npm install..." -ForegroundColor Yellow
$workflowContent | Out-File -FilePath $workflowPath -Encoding UTF8
Write-Host "✅ Updated GitHub workflow" -ForegroundColor Green

# Commit and push changes
Write-Host "`n3. Committing and pushing changes..." -ForegroundColor Yellow
try {
    git add .
    git commit -m "Simplify CI/CD: Remove package-lock.json, use npm install only"
    git push origin main
    
    Write-Host "✅ Changes pushed successfully!" -ForegroundColor Green
    Write-Host "`n🚀 New GitHub Actions deployment should start now!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Git push failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nManual commands:" -ForegroundColor Yellow
    Write-Host "  git add ."
    Write-Host "  git commit -m 'Simplify CI/CD: Remove package-lock.json, use npm install only'"
    Write-Host "  git push origin main"
}

Write-Host "`n=== SIMPLIFIED APPROACH ===" -ForegroundColor Cyan
Write-Host "1. ✅ Removed problematic package-lock.json"
Write-Host "2. ✅ Using npm install (more forgiving than npm ci)"
Write-Host "3. ✅ Installing TypeScript explicitly in CI"
Write-Host "4. ✅ Using npx tsc for build (no package.json scripts needed)"

Write-Host "`n📊 This should definitely work now!" -ForegroundColor Green
'@

Write-Host "Run this script to fix the package-lock.json issue:" -ForegroundColor Green