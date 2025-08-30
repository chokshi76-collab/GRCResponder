# Create proper GitHub Actions workflow for Function App deployment
Write-Host "=== CREATING GITHUB ACTIONS DEPLOYMENT WORKFLOW ===" -ForegroundColor Green

# Create .github/workflows directory if it doesn't exist
$workflowDir = ".github/workflows"
if (!(Test-Path $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir -Force
    Write-Host "✅ Created $workflowDir directory" -ForegroundColor Green
} else {
    Write-Host "✅ $workflowDir directory already exists" -ForegroundColor Green
}

# Create the workflow file
$workflowFile = "$workflowDir/deploy-function-app.yml"
$workflowContent = @"
name: Deploy MCP Server to Azure Function App

on:
  push:
    branches: [ main ]
    paths:
      - 'src/mcp-server/**'
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
        cache: 'npm'
        cache-dependency-path: `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}/package.json

    - name: 'Install dependencies'
      run: |
        cd `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        npm ci

    - name: 'Build TypeScript'
      run: |
        cd `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        npm run build

    - name: 'Deploy to Azure Function App'
      uses: Azure/functions-action@v1
      with:
        app-name: `${{ env.AZURE_FUNCTIONAPP_NAME }}
        package: `${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        publish-profile: `${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
"@

# Write the workflow file
$workflowContent | Out-File -FilePath $workflowFile -Encoding UTF8
Write-Host "✅ Created workflow file: $workflowFile" -ForegroundColor Green

# Add build script to package.json if missing
$packageJsonPath = "src/mcp-server/package.json"
if (Test-Path $packageJsonPath) {
    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    
    if (-not $packageJson.scripts.build) {
        Write-Host "`nAdding build script to package.json..." -ForegroundColor Yellow
        
        if (-not $packageJson.scripts) {
            $packageJson | Add-Member -MemberType NoteProperty -Name "scripts" -Value @{}
        }
        
        $packageJson.scripts | Add-Member -MemberType NoteProperty -Name "build" -Value "tsc" -Force
        $packageJson.scripts | Add-Member -MemberType NoteProperty -Name "start" -Value "node dist/index.js" -Force
        
        $packageJson | ConvertTo-Json -Depth 10 | Out-File $packageJsonPath -Encoding UTF8
        Write-Host "✅ Added build and start scripts to package.json" -ForegroundColor Green
    } else {
        Write-Host "✅ Build script already exists in package.json" -ForegroundColor Green
    }
} else {
    Write-Host "❌ package.json not found at $packageJsonPath" -ForegroundColor Red
}

# Commit and push the changes
Write-Host "`n=== COMMITTING AND PUSHING CHANGES ===" -ForegroundColor Cyan
try {
    git add .
    git commit -m "Add Azure Function App deployment workflow"
    git push origin main
    
    Write-Host "✅ Changes pushed to GitHub!" -ForegroundColor Green
    Write-Host "`n🚀 GitHub Actions will now automatically deploy your MCP server!" -ForegroundColor Green
    Write-Host "`nCheck the Actions tab in GitHub to see the deployment progress."
    
} catch {
    Write-Host "❌ Error pushing to GitHub: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run these commands manually:" -ForegroundColor Yellow
    Write-Host "  git add ."
    Write-Host "  git commit -m 'Add Azure Function App deployment workflow'"
    Write-Host "  git push origin main"
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Go to GitHub Actions tab to watch the deployment"
Write-Host "2. Once deployed, test the Function App endpoint"
Write-Host "3. Implement actual MCP tool logic"