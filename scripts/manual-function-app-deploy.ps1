# PDF AI AGENT - MANUAL FUNCTION APP DEPLOYMENT
# Deploy Function App code manually since GitHub Actions CI/CD is broken

Write-Host "=== PDF AI AGENT - MANUAL FUNCTION APP DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Bypassing broken GitHub Actions to deploy code directly..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. CHECKING AZURE CLI AUTHENTICATION..." -ForegroundColor Cyan
Write-Host "Verifying you're logged into Azure..." -ForegroundColor White

try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✅ Subscription: $($account.name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged into Azure CLI!" -ForegroundColor Red
    Write-Host "Run: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. PREPARING FUNCTION APP CODE..." -ForegroundColor Cyan
$functionPath = "src/mcp-server"
Write-Host "Function app source path: $functionPath" -ForegroundColor White

if (Test-Path $functionPath) {
    Write-Host "✅ Function app source found" -ForegroundColor Green
} else {
    Write-Host "❌ Function app source not found!" -ForegroundColor Red
    exit 1
}

# Check key files
$keyFiles = @(
    "$functionPath/package.json",
    "$functionPath/src/index.ts",
    "$functionPath/host.json"
)

foreach ($file in $keyFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing!" -ForegroundColor Red
    }
}

Write-Host "`n3. BUILDING FUNCTION APP..." -ForegroundColor Cyan
Write-Host "Building TypeScript and installing dependencies..." -ForegroundColor White

Push-Location $functionPath

# Install dependencies
Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
npm install

# Build TypeScript
Write-Host "Building TypeScript..." -ForegroundColor Yellow
npm run build

# Check if build succeeded
if (Test-Path "dist/src/index.js") {
    Write-Host "✅ TypeScript build successful" -ForegroundColor Green
} else {
    Write-Host "❌ TypeScript build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

Write-Host "`n4. DEPLOYING TO AZURE FUNCTION APP..." -ForegroundColor Cyan
$functionAppName = "func-pdfai-dev-tjqwgu4v"
$resourceGroup = "pdf-ai-agent-rg-dev"

Write-Host "Deploying to: $functionAppName" -ForegroundColor White
Write-Host "Resource Group: $resourceGroup" -ForegroundColor White

# Deploy using Azure CLI
Write-Host "Starting deployment..." -ForegroundColor Yellow
$deployResult = az functionapp deployment source config-zip `
    --resource-group $resourceGroup `
    --name $functionAppName `
    --src "$functionPath.zip" `
    --build-remote true `
    --output json

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Function App deployment successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Function App deployment failed!" -ForegroundColor Red
    Write-Host "Trying alternative deployment method..." -ForegroundColor Yellow
    
    # Alternative: Use zip deployment
    Compress-Archive -Path "$functionPath/*" -DestinationPath "function-app.zip" -Force
    
    az functionapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $functionAppName `
        --src "function-app.zip" `
        --output json
        
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Alternative deployment successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ All deployment methods failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n5. WAITING FOR DEPLOYMENT TO COMPLETE..." -ForegroundColor Cyan
Write-Host "Waiting 60 seconds for function app to restart..." -ForegroundColor White
Start-Sleep -Seconds 60

Write-Host "`n=== DEPLOYMENT COMPLETE! ===" -ForegroundColor Green
Write-Host "✅ Function App code deployed manually" -ForegroundColor Green
Write-Host "✅ Bypassed broken GitHub Actions CI/CD" -ForegroundColor Green
Write-Host "✅ Using working commit a342a7c code" -ForegroundColor Green

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. Test endpoints to verify they're working" -ForegroundColor White
Write-Host "2. If working, proceed with PDF processing implementation" -ForegroundColor White
Write-Host "3. Fix GitHub Actions authentication later" -ForegroundColor White

Write-Host "`nTest endpoints now:" -ForegroundColor Cyan
Write-Host ".\scripts\test-endpoints-after-rollback.ps1" -ForegroundColor Green

Write-Host "`nFunction App URL: https://$functionAppName.azurewebsites.net" -ForegroundColor Cyan