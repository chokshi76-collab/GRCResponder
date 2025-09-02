# PDF AI AGENT - REDEPLOY INFRASTRUCTURE AFTER ROLLBACK
# The rollback affected Bicep templates, need to redeploy infrastructure

Write-Host "=== PDF AI AGENT - INFRASTRUCTURE REDEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "Triggering infrastructure deployment after code rollback..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. CHECKING CURRENT INFRASTRUCTURE FILES..." -ForegroundColor Cyan
Write-Host "Verifying Bicep templates exist:" -ForegroundColor White

$infraFiles = @(
    "infrastructure/bicep/main.bicep",
    "environments/dev/parameters.dev.json",
    ".github/workflows/deploy-function-app.yml"
)

foreach ($file in $infraFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing!" -ForegroundColor Red
    }
}

Write-Host "`n2. CHECKING GITHUB ACTIONS STATUS..." -ForegroundColor Cyan
Write-Host "Current commit that should trigger deployment:" -ForegroundColor White
git log --oneline -1

Write-Host "`n3. TRIGGERING INFRASTRUCTURE REDEPLOYMENT..." -ForegroundColor Cyan
Write-Host "Making a small change to trigger GitHub Actions..." -ForegroundColor White

# Create a small change to trigger deployment
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$triggerMessage = "# Infrastructure redeployment trigger - $timestamp"

# Add a comment to README or create a trigger file
if (Test-Path "README.md") {
    Add-Content -Path "README.md" -Value "`n$triggerMessage"
    Write-Host "✅ Added trigger comment to README.md" -ForegroundColor Green
} else {
    # Create a deployment trigger file
    $triggerMessage | Out-File -FilePath "deployment-trigger.txt" -Encoding UTF8
    Write-Host "✅ Created deployment-trigger.txt" -ForegroundColor Green
}

Write-Host "`n4. COMMITTING AND PUSHING TRIGGER..." -ForegroundColor Cyan
git add .
git commit -m "trigger: Force infrastructure redeployment after rollback - $timestamp"
git push origin main

Write-Host "`n=== REDEPLOYMENT TRIGGERED! ===" -ForegroundColor Green
Write-Host "✅ GitHub Actions should now redeploy infrastructure and function app" -ForegroundColor Green
Write-Host "✅ This will provision/update all Azure resources" -ForegroundColor Green
Write-Host "✅ Then deploy the function app code from commit a342a7c" -ForegroundColor Green

Write-Host "`n=== MONITORING DEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "1. Check GitHub Actions: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan
Write-Host "2. Deployment typically takes 6-8 minutes total:" -ForegroundColor White
Write-Host "   - Infrastructure provisioning: 3-4 minutes" -ForegroundColor Gray
Write-Host "   - Function app deployment: 2-3 minutes" -ForegroundColor Gray
Write-Host "   - Total: ~6-8 minutes" -ForegroundColor Gray

Write-Host "`n3. Test endpoints after deployment completes:" -ForegroundColor White
Write-Host "   .\scripts\test-endpoints-after-rollback.ps1" -ForegroundColor Green

Write-Host "`n=== WHAT TO EXPECT ===" -ForegroundColor Cyan
Write-Host "After successful deployment:" -ForegroundColor White
Write-Host "✅ /api/health should return health status" -ForegroundColor Green
Write-Host "✅ /api/tools should return 5 tools" -ForegroundColor Green
Write-Host "✅ /api/tools/process_pdf should work with placeholder response" -ForegroundColor Green
Write-Host "✅ All Azure resources should be properly configured" -ForegroundColor Green

Write-Host "`nThen we'll add real PDF processing to the working code!" -ForegroundColor Yellow