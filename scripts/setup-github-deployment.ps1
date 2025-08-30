# Setup GitHub Actions deployment to Azure Function App
$functionAppName = "func-pdfai-dev-tjqwgu4v"
$resourceGroup = "pdf-ai-agent-rg-dev"
$repoUrl = "https://github.com/chokshi76-collab/GRCResponder"

Write-Host "=== SETTING UP GITHUB ACTIONS DEPLOYMENT ===" -ForegroundColor Green

# Step 1: Get Function App publish profile for GitHub secrets
Write-Host "`n1. Getting Function App publish profile..." -ForegroundColor Yellow
$publishProfile = az functionapp deployment list-publishing-profiles --name $functionAppName --resource-group $resourceGroup --xml

if ($publishProfile) {
    Write-Host "✅ Publish profile retrieved" -ForegroundColor Green
    Write-Host "`nPublish Profile (first 200 chars):"
    Write-Host $publishProfile.Substring(0, [Math]::Min(200, $publishProfile.Length))
    Write-Host "..."
    
    Write-Host "`n📋 COPY THIS ENTIRE PUBLISH PROFILE:" -ForegroundColor Cyan
    Write-Host "You need to add this as a GitHub Secret named 'AZURE_FUNCTIONAPP_PUBLISH_PROFILE'"
    Write-Host "`nFull Publish Profile:" -ForegroundColor White
    Write-Host $publishProfile
} else {
    Write-Host "❌ Failed to get publish profile" -ForegroundColor Red
}

Write-Host "`n=== MANUAL STEPS TO COMPLETE DEPLOYMENT SETUP ===" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub repository: $repoUrl"
Write-Host "2. Click 'Settings' > 'Secrets and variables' > 'Actions'"
Write-Host "3. Click 'New repository secret'"
Write-Host "4. Name: AZURE_FUNCTIONAPP_PUBLISH_PROFILE"
Write-Host "5. Value: Paste the entire publish profile from above"
Write-Host "6. Save the secret"

Write-Host "`n=== THEN RUN THIS SCRIPT TO TRIGGER DEPLOYMENT ===" -ForegroundColor Green
Write-Host "After adding the GitHub secret, we'll create a proper workflow file and trigger deployment."