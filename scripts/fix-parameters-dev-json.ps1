# PDF AI AGENT - FIX PARAMETERS FILE
# Add missing userObjectId parameter to fix infrastructure deployment

Write-Host "=== PDF AI AGENT - FIX PARAMETERS FILE ===" -ForegroundColor Green
Write-Host "Adding missing userObjectId parameter..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

$parametersFile = "environments/dev/parameters.dev.json"

Write-Host "`n1. CHECKING CURRENT PARAMETERS FILE..." -ForegroundColor Cyan
if (Test-Path $parametersFile) {
    Write-Host "✅ Parameters file exists: $parametersFile" -ForegroundColor Green
    
    # Show current content
    Write-Host "`nCurrent content:" -ForegroundColor White
    Get-Content $parametersFile | Write-Host -ForegroundColor Gray
    
} else {
    Write-Host "❌ Parameters file not found: $parametersFile" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. ADDING MISSING USEROBJECTID PARAMETER..." -ForegroundColor Cyan
Write-Host "Your user object ID from the prompt: 402ed151-67f7-4f36-bc74-ac2b9c9e1980" -ForegroundColor White

# Read current parameters
$parametersContent = Get-Content $parametersFile -Raw | ConvertFrom-Json

# Add the missing userObjectId parameter
if (-not $parametersContent.parameters.PSObject.Properties['userObjectId']) {
    $parametersContent.parameters | Add-Member -Type NoteProperty -Name 'userObjectId' -Value @{
        value = "402ed151-67f7-4f36-bc74-ac2b9c9e1980"
    }
    Write-Host "✅ Added userObjectId parameter" -ForegroundColor Green
} else {
    Write-Host "⚠️ userObjectId parameter already exists, updating value..." -ForegroundColor Yellow
    $parametersContent.parameters.userObjectId.value = "402ed151-67f7-4f36-bc74-ac2b9c9e1980"
}

# Save updated parameters
$parametersContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $parametersFile -Encoding UTF8

Write-Host "`n3. VERIFYING UPDATED PARAMETERS..." -ForegroundColor Cyan
Write-Host "Updated parameters file:" -ForegroundColor White
Get-Content $parametersFile | Write-Host -ForegroundColor Gray

Write-Host "`n4. COMMITTING PARAMETER FIX..." -ForegroundColor Cyan
git add $parametersFile
git commit -m "fix: Add missing userObjectId parameter to dev environment

- Add userObjectId: 402ed151-67f7-4f36-bc74-ac2b9c9e1980
- Resolves infrastructure deployment error
- Required for Bicep template deployment"

git push origin main

Write-Host "`n=== PARAMETER FIX COMPLETE! ===" -ForegroundColor Green
Write-Host "✅ Added missing userObjectId parameter" -ForegroundColor Green
Write-Host "✅ Committed and pushed to trigger new deployment" -ForegroundColor Green
Write-Host "✅ Infrastructure deployment should now succeed" -ForegroundColor Green

Write-Host "`n=== MONITORING NEW DEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "1. GitHub Actions: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan
Write-Host "2. Expected results:" -ForegroundColor White
Write-Host "   ✅ Azure authentication succeeds" -ForegroundColor Green
Write-Host "   ✅ Infrastructure deployment completes (no more userObjectId error)" -ForegroundColor Green
Write-Host "   ✅ Function app deployment succeeds" -ForegroundColor Green
Write-Host "   ✅ Endpoint verification passes" -ForegroundColor Green

Write-Host "`n3. After successful deployment:" -ForegroundColor Cyan
Write-Host "   Test endpoints:" -ForegroundColor White
Write-Host "   .\scripts\test-endpoints-after-rollback.ps1" -ForegroundColor Green

Write-Host "`nMonitoring link: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan