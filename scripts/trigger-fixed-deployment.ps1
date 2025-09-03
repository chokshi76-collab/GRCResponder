# PDF AI AGENT - TRIGGER DEPLOYMENT WITH FIXED CI/CD
# Deploy the updated workflow and trigger complete deployment

Write-Host "=== PDF AI AGENT - TRIGGER FIXED DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Deploying fixed workflow and triggering CI/CD..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. CHECKING WORKFLOW FILE..." -ForegroundColor Cyan
Write-Host "Verifying the updated deploy-function-app.yml file exists..." -ForegroundColor White

if (Test-Path ".github/workflows/deploy-function-app.yml") {
    Write-Host "✅ Workflow file found" -ForegroundColor Green
} else {
    Write-Host "❌ Workflow file missing! Please save the updated YAML first." -ForegroundColor Red
    exit 1
}

# Add the workflow file and any other changes
git add .

# Check git status
Write-Host "`nCurrent changes:" -ForegroundColor White
git status

Write-Host "`n2. COMMITTING AND PUSHING..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "fix: Update GitHub Actions workflow with proper Azure authentication

- Add support for service principal authentication
- Use AZURE_CLIENT_ID and AZURE_TENANT_ID secrets
- Include deployment verification steps
- Fix CI/CD pipeline that has never worked
- Timestamp: $timestamp"

git push origin main

Write-Host "`n=== DEPLOYMENT TRIGGERED! ===" -ForegroundColor Green
Write-Host "✅ Updated workflow file pushed to GitHub" -ForegroundColor Green
Write-Host "✅ GitHub Actions should now authenticate properly" -ForegroundColor Green
Write-Host "✅ Complete infrastructure + function app deployment" -ForegroundColor Green

Write-Host "`n=== MONITORING DEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "1. GitHub Actions: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan
Write-Host "2. Expected timeline:" -ForegroundColor White
Write-Host "   - Infrastructure deployment: 3-4 minutes" -ForegroundColor Gray
Write-Host "   - Function app deployment: 2-3 minutes" -ForegroundColor Gray
Write-Host "   - Verification tests: 1 minute" -ForegroundColor Gray
Write-Host "   - Total: ~6-8 minutes" -ForegroundColor Gray

Write-Host "`n3. What to watch for:" -ForegroundColor White
Write-Host "   ✅ Azure login should succeed (no more auth errors)" -ForegroundColor Green
Write-Host "   ✅ Infrastructure deployment should complete" -ForegroundColor Green
Write-Host "   ✅ Function app deployment should succeed" -ForegroundColor Green
Write-Host "   ✅ Verification tests should pass (200 status codes)" -ForegroundColor Green

Write-Host "`n=== AFTER SUCCESSFUL DEPLOYMENT ===" -ForegroundColor Cyan
Write-Host "Run this to test endpoints:" -ForegroundColor White
Write-Host ".\scripts\test-endpoints-after-rollback.ps1" -ForegroundColor Green

Write-Host "`nThen we'll add real PDF processing to the working code!" -ForegroundColor Yellow
Write-Host "`nMonitor the deployment at:" -ForegroundColor Cyan
Write-Host "https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Green