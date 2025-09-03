# PDF AI AGENT - TROUBLESHOOT WORKFLOW TRIGGER
# Check why GitHub Actions workflow didn't start automatically

Write-Host "=== PDF AI AGENT - TROUBLESHOOT WORKFLOW TRIGGER ===" -ForegroundColor Yellow
Write-Host "Investigating why workflow didn't trigger after push..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. VERIFYING PUSH WAS SUCCESSFUL..." -ForegroundColor Cyan
Write-Host "Checking if commit reached GitHub:" -ForegroundColor White

# Check if local and remote are in sync
git fetch origin
$localCommit = git rev-parse HEAD
$remoteCommit = git rev-parse origin/main

Write-Host "Local HEAD:  $localCommit" -ForegroundColor White
Write-Host "Remote HEAD: $remoteCommit" -ForegroundColor White

if ($localCommit -eq $remoteCommit) {
    Write-Host "✅ Local and remote are in sync - push was successful" -ForegroundColor Green
} else {
    Write-Host "❌ Local and remote are out of sync - push may have failed" -ForegroundColor Red
    Write-Host "Try pushing again:" -ForegroundColor Yellow
    Write-Host "git push origin main" -ForegroundColor Green
    exit 1
}

Write-Host "`n2. CHECKING WORKFLOW FILE SYNTAX..." -ForegroundColor Cyan
$workflowPath = ".github/workflows/deploy-function-app.yml"

Write-Host "Validating YAML syntax..." -ForegroundColor White
try {
    # Basic YAML validation - check for common issues
    $content = Get-Content $workflowPath -Raw
    
    # Check for required sections
    if ($content -match "name:.*Deploy Function App") {
        Write-Host "✅ Workflow name found" -ForegroundColor Green
    } else {
        Write-Host "❌ Workflow name missing or incorrect" -ForegroundColor Red
    }
    
    if ($content -match "on:\s*push:") {
        Write-Host "✅ Push trigger found" -ForegroundColor Green
    } else {
        Write-Host "❌ Push trigger missing or incorrect" -ForegroundColor Red
    }
    
    if ($content -match "branches:.*main") {
        Write-Host "✅ Main branch trigger found" -ForegroundColor Green
    } else {
        Write-Host "❌ Main branch trigger missing" -ForegroundColor Red
    }
    
    # Check for authentication
    if ($content -match "client-id.*AZURE_CLIENT_ID") {
        Write-Host "✅ New authentication method found" -ForegroundColor Green
    } else {
        Write-Host "❌ New authentication method missing" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error reading workflow file: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. COMMON WORKFLOW TRIGGER ISSUES..." -ForegroundColor Cyan

Write-Host "`nPossible Issue 1: GitHub Actions disabled" -ForegroundColor Yellow
Write-Host "Solution: Check if Actions are enabled in repo settings" -ForegroundColor White
Write-Host "Go to: https://github.com/chokshi76-collab/GRCResponder/settings/actions" -ForegroundColor Cyan

Write-Host "`nPossible Issue 2: Workflow file path wrong" -ForegroundColor Yellow
Write-Host "Expected path: .github/workflows/deploy-function-app.yml" -ForegroundColor White
Write-Host "Current path exists: $(Test-Path $workflowPath)" -ForegroundColor White

Write-Host "`nPossible Issue 3: YAML syntax error" -ForegroundColor Yellow
Write-Host "Solution: GitHub may have rejected invalid YAML" -ForegroundColor White
Write-Host "Check: Repository Actions tab for error messages" -ForegroundColor White

Write-Host "`nPossible Issue 4: Workflow name conflict" -ForegroundColor Yellow
Write-Host "Solution: GitHub may have multiple workflows with same name" -ForegroundColor White
Write-Host "Check: Delete old workflow files" -ForegroundColor White

Write-Host "`n4. FORCE TRIGGER OPTIONS..." -ForegroundColor Green

Write-Host "`nOption 1: Manual trigger from GitHub web interface" -ForegroundColor Cyan
Write-Host "1. Go to: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor White
Write-Host "2. Click on 'Deploy Function App' workflow" -ForegroundColor White
Write-Host "3. Click 'Run workflow' button" -ForegroundColor White
Write-Host "4. Select 'main' branch and click 'Run workflow'" -ForegroundColor White

Write-Host "`nOption 2: Create empty commit to force trigger" -ForegroundColor Cyan
Write-Host "git commit --allow-empty -m 'trigger: Force workflow execution'" -ForegroundColor Green
Write-Host "git push origin main" -ForegroundColor Green

Write-Host "`nOption 3: Make small file change" -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "echo '# Trigger - $timestamp' >> .trigger" -ForegroundColor Green
Write-Host "git add .trigger" -ForegroundColor Green
Write-Host "git commit -m 'trigger: Force deployment $timestamp'" -ForegroundColor Green
Write-Host "git push origin main" -ForegroundColor Green

Write-Host "`n5. IMMEDIATE ACTION NEEDED..." -ForegroundColor Red
Write-Host "Try Option 1 first (manual trigger from GitHub web):" -ForegroundColor White
Write-Host "https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan

Write-Host "`nIf that doesn't work, run Option 2 (empty commit):" -ForegroundColor White
Write-Host "git commit --allow-empty -m 'trigger: Force workflow execution'" -ForegroundColor Green
Write-Host "git push origin main" -ForegroundColor Green

Write-Host "`nWhich option would you like to try first?" -ForegroundColor Yellow