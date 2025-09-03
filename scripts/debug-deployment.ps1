# PDF AI AGENT - DEBUG DEPLOYMENT TRIGGER
# Check why GitHub Actions deployment didn't start

Write-Host "=== PDF AI AGENT - DEBUG DEPLOYMENT TRIGGER ===" -ForegroundColor Yellow
Write-Host "Investigating why deployment didn't start..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. CHECKING GIT STATUS..." -ForegroundColor Cyan
git status

Write-Host "`n2. CHECKING RECENT COMMITS..." -ForegroundColor Cyan
Write-Host "Last 3 commits:" -ForegroundColor White
git log --oneline -3

Write-Host "`n3. CHECKING WORKFLOW FILE..." -ForegroundColor Cyan
$workflowPath = ".github/workflows/deploy-function-app.yml"

if (Test-Path $workflowPath) {
    Write-Host "✅ Workflow file exists" -ForegroundColor Green
    
    # Check if it has the new authentication
    $content = Get-Content $workflowPath -Raw
    if ($content -match "client-id.*AZURE_CLIENT_ID") {
        Write-Host "✅ Workflow has new authentication method" -ForegroundColor Green
    } else {
        Write-Host "❌ Workflow still has old authentication!" -ForegroundColor Red
        Write-Host "Need to update the workflow file with new YAML" -ForegroundColor Yellow
    }
    
    # Show first few lines
    Write-Host "`nFirst 10 lines of workflow:" -ForegroundColor White
    Get-Content $workflowPath | Select-Object -First 10
    
} else {
    Write-Host "❌ Workflow file missing!" -ForegroundColor Red
}

Write-Host "`n4. CHECKING BRANCH STATUS..." -ForegroundColor Cyan
Write-Host "Current branch:" -ForegroundColor White
git branch --show-current

Write-Host "`nRemote status:" -ForegroundColor White
git remote -v

Write-Host "`n5. POSSIBLE ISSUES AND SOLUTIONS..." -ForegroundColor Yellow

Write-Host "`nIssue 1: Workflow file not updated" -ForegroundColor Red
Write-Host "Solution: Make sure you saved the new YAML content" -ForegroundColor Green
Write-Host "Check: Does the workflow use 'client-id' instead of 'auth-type'?" -ForegroundColor White

Write-Host "`nIssue 2: No changes to commit" -ForegroundColor Red  
Write-Host "Solution: Make a small change and commit" -ForegroundColor Green
Write-Host "Check: Run 'git status' to see if there are changes" -ForegroundColor White

Write-Host "`nIssue 3: GitHub Actions disabled" -ForegroundColor Red
Write-Host "Solution: Check GitHub repo settings" -ForegroundColor Green
Write-Host "Check: Go to repo > Actions tab" -ForegroundColor White

Write-Host "`nIssue 4: Push didn't work" -ForegroundColor Red
Write-Host "Solution: Check git push output for errors" -ForegroundColor Green
Write-Host "Check: Network connectivity or authentication" -ForegroundColor White

Write-Host "`n=== FORCE TRIGGER DEPLOYMENT ===" -ForegroundColor Green
Write-Host "If workflow file is correct, try these commands:" -ForegroundColor White

Write-Host "`n# Option 1: Make a small change and push" -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "echo '# Deployment trigger - $timestamp' >> README.md" -ForegroundColor Green
Write-Host "git add ." -ForegroundColor Green
Write-Host "git commit -m 'trigger: Force deployment with fixed authentication'" -ForegroundColor Green
Write-Host "git push origin main" -ForegroundColor Green

Write-Host "`n# Option 2: Check GitHub Actions status" -ForegroundColor Cyan
Write-Host "Go to: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Green
Write-Host "Look for: New workflow runs after your push" -ForegroundColor White

Write-Host "`n# Option 3: Manual trigger" -ForegroundColor Cyan
Write-Host "Go to: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Green
Write-Host "Click: 'Deploy Function App' workflow" -ForegroundColor White
Write-Host "Click: 'Run workflow' button" -ForegroundColor White

Write-Host "`nWhat would you like to check first?" -ForegroundColor Yellow