# PDF AI AGENT - UPDATE AND DEPLOY FIXED WORKFLOW
# Replace workflow file with corrected version and trigger deployment

Write-Host "=== PDF AI AGENT - UPDATE WORKFLOW AND DEPLOY ===" -ForegroundColor Green
Write-Host "Fixing workflow authentication and triggering deployment..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. UPDATING WORKFLOW FILE..." -ForegroundColor Cyan
Write-Host "Replacing .github/workflows/deploy-function-app.yml with fixed version..." -ForegroundColor White

# Note: You need to manually copy the fixed YAML content to the workflow file
Write-Host "✅ Copy the fixed YAML from the artifact above" -ForegroundColor Yellow
Write-Host "✅ Save it as .github/workflows/deploy-function-app.yml" -ForegroundColor Yellow
Write-Host "✅ This fixes the authentication and permissions issues" -ForegroundColor Yellow

Write-Host "`n2. KEY FIXES IN NEW WORKFLOW..." -ForegroundColor Cyan
Write-Host "✅ Added permissions: id-token: write, contents: read" -ForegroundColor Green
Write-Host "✅ Fixed auth: Uses AZURE_CREDENTIALS secret properly" -ForegroundColor Green
Write-Host "✅ Added workflow_dispatch for manual triggering" -ForegroundColor Green
Write-Host "✅ Improved endpoint verification with retry logic" -ForegroundColor Green

Write-Host "`n3. COMMITTING FIXED WORKFLOW..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Wait for user to confirm they've updated the file
Write-Host "`nHave you saved the fixed YAML to .github/workflows/deploy-function-app.yml? (y/n): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "✅ Proceeding with commit and push..." -ForegroundColor Green
    
    git add .github/workflows/deploy-function-app.yml
    git commit -m "fix: Update workflow with proper permissions and authentication

- Add id-token write permissions for Azure login
- Use AZURE_CREDENTIALS secret instead of individual tokens  
- Add workflow_dispatch for manual triggering
- Improve endpoint verification with retry logic
- Fix authentication errors preventing deployment
- Timestamp: $timestamp"
    
    git push origin main
    
    Write-Host "`n=== DEPLOYMENT TRIGGERED! ===" -ForegroundColor Green
    Write-Host "✅ Fixed workflow pushed to GitHub" -ForegroundColor Green
    Write-Host "✅ Should resolve authentication errors" -ForegroundColor Green
    Write-Host "✅ GitHub Actions will start automatically" -ForegroundColor Green
    
} else {
    Write-Host "❌ Please update the workflow file first, then run this script again" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== MONITORING DEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "1. GitHub Actions: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan
Write-Host "2. Expected to see:" -ForegroundColor White
Write-Host "   ✅ Azure login succeeds (no more token errors)" -ForegroundColor Green
Write-Host "   ✅ Infrastructure deployment completes" -ForegroundColor Green
Write-Host "   ✅ Function app deployment succeeds" -ForegroundColor Green
Write-Host "   ✅ Endpoint verification passes (200 status)" -ForegroundColor Green

Write-Host "`n3. If it still fails:" -ForegroundColor Yellow
Write-Host "   Try manual trigger from GitHub web interface:" -ForegroundColor White
Write-Host "   - Go to Actions tab" -ForegroundColor Gray
Write-Host "   - Click 'Deploy Function App'" -ForegroundColor Gray
Write-Host "   - Click 'Run workflow' button" -ForegroundColor Gray

Write-Host "`n4. After successful deployment:" -ForegroundColor Cyan
Write-Host "   Test endpoints:" -ForegroundColor White
Write-Host "   .\scripts\test-endpoints-after-rollback.ps1" -ForegroundColor Green

Write-Host "`nMonitoring link: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan