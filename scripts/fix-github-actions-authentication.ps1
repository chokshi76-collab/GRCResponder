# PDF AI AGENT - FIX GITHUB ACTIONS AUTHENTICATION
# Create service principal and configure GitHub Secrets for CI/CD

Write-Host "=== PDF AI AGENT - FIX GITHUB ACTIONS CI/CD ===" -ForegroundColor Green
Write-Host "Setting up proper Azure authentication for GitHub Actions..." -ForegroundColor White

# Navigate to project directory
Set-Location "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "`n1. CHECKING AZURE CLI AUTHENTICATION..." -ForegroundColor Cyan
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✅ Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged into Azure CLI!" -ForegroundColor Red
    Write-Host "Run: az login" -ForegroundColor Yellow
    exit 1
}

# Set variables
$subscriptionId = "d4d5edc0-d0d0-491c-8d55-4bf5481b5b49"
$resourceGroup = "pdf-ai-agent-rg-dev"
$servicePrincipalName = "sp-pdf-ai-agent-github"

Write-Host "`n2. CREATING SERVICE PRINCIPAL FOR GITHUB ACTIONS..." -ForegroundColor Cyan
Write-Host "Service Principal Name: $servicePrincipalName" -ForegroundColor White

# Create service principal with contributor role on resource group
Write-Host "Creating service principal with Contributor role..." -ForegroundColor Yellow

$spCreation = az ad sp create-for-rbac `
    --name $servicePrincipalName `
    --role "Contributor" `
    --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
    --sdk-auth `
    --output json

if ($LASTEXITCODE -eq 0) {
    $spCredentials = $spCreation | ConvertFrom-Json
    Write-Host "✅ Service Principal created successfully!" -ForegroundColor Green
    
    Write-Host "`nService Principal Details:" -ForegroundColor White
    Write-Host "Client ID: $($spCredentials.clientId)" -ForegroundColor Gray
    Write-Host "Tenant ID: $($spCredentials.tenantId)" -ForegroundColor Gray
    Write-Host "Subscription ID: $($spCredentials.subscriptionId)" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to create service principal!" -ForegroundColor Red
    Write-Host "Checking if it already exists..." -ForegroundColor Yellow
    
    # Try to get existing service principal
    $existingSp = az ad sp list --display-name $servicePrincipalName --output json | ConvertFrom-Json
    if ($existingSp.Count -gt 0) {
        Write-Host "✅ Service Principal already exists!" -ForegroundColor Green
        Write-Host "Client ID: $($existingSp[0].appId)" -ForegroundColor Gray
        
        # Reset credentials
        Write-Host "Resetting credentials..." -ForegroundColor Yellow
        $spCreation = az ad sp credential reset `
            --id $existingSp[0].appId `
            --sdk-auth `
            --output json
            
        $spCredentials = $spCreation | ConvertFrom-Json
    } else {
        Write-Host "❌ Cannot create or find service principal!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n3. GITHUB SECRETS CONFIGURATION..." -ForegroundColor Cyan
Write-Host "You need to add these secrets to your GitHub repository:" -ForegroundColor White
Write-Host "Repository: https://github.com/chokshi76-collab/GRCResponder" -ForegroundColor Cyan
Write-Host "Go to: Settings > Secrets and variables > Actions" -ForegroundColor Cyan

Write-Host "`n=== REQUIRED GITHUB SECRETS ===" -ForegroundColor Yellow

# Azure credentials for OIDC authentication
Write-Host "`n1. AZURE_CLIENT_ID" -ForegroundColor Green
Write-Host "   Value: $($spCredentials.clientId)" -ForegroundColor White

Write-Host "`n2. AZURE_TENANT_ID" -ForegroundColor Green  
Write-Host "   Value: $($spCredentials.tenantId)" -ForegroundColor White

Write-Host "`n3. AZURE_SUBSCRIPTION_ID" -ForegroundColor Green
Write-Host "   Value: $($spCredentials.subscriptionId)" -ForegroundColor White

Write-Host "`n4. AZURE_CREDENTIALS (for backup compatibility)" -ForegroundColor Green
Write-Host "   Value: $spCreation" -ForegroundColor White

# Function App publish profile (if not already set)
Write-Host "`n5. AZURE_FUNCTIONAPP_PUBLISH_PROFILE" -ForegroundColor Green
Write-Host "   Getting publish profile..." -ForegroundColor Yellow

$publishProfile = az functionapp deployment list-publishing-profiles `
    --name "func-pdfai-dev-tjqwgu4v" `
    --resource-group $resourceGroup `
    --xml

if ($LASTEXITCODE -eq 0) {
    Write-Host "   Value: [PUBLISH PROFILE XML - see below]" -ForegroundColor White
    Write-Host "`n--- PUBLISH PROFILE START ---" -ForegroundColor Gray
    Write-Host $publishProfile -ForegroundColor Gray
    Write-Host "--- PUBLISH PROFILE END ---" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to get publish profile!" -ForegroundColor Red
}

Write-Host "`n=== MANUAL STEPS TO COMPLETE ===" -ForegroundColor Red
Write-Host "1. Go to: https://github.com/chokshi76-collab/GRCResponder/settings/secrets/actions" -ForegroundColor White
Write-Host "2. Add each secret listed above" -ForegroundColor White
Write-Host "3. Make sure secret names match exactly (case-sensitive)" -ForegroundColor White
Write-Host "4. After adding secrets, trigger a new deployment" -ForegroundColor White

Write-Host "`n=== WORKFLOW FILE UPDATE NEEDED ===" -ForegroundColor Yellow
Write-Host "The GitHub workflow needs to be updated to use the new authentication method." -ForegroundColor White
Write-Host "Current workflow: .github/workflows/deploy-function-app.yml" -ForegroundColor Cyan

Write-Host "`nWould you like me to create an updated workflow file? (This will fix the auth issues)" -ForegroundColor Green