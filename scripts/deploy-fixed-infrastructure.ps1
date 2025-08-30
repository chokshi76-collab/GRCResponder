# Deploy Fixed Infrastructure - PDF AI Agent MCP
# Run this script to deploy the corrected Bicep template

Write-Host "Deploying PDF AI Agent Infrastructure with FIXED Function App Identity..." -ForegroundColor Green

# Set variables
$resourceGroupName = "pdf-ai-agent-rg-dev"
$deploymentName = "pdf-ai-agent-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$location = "westus2"
$userObjectId = "402ed151-67f7-4f36-bc74-ac2b9c9e1980"

# Deploy the infrastructure
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host "Deployment name: $deploymentName" -ForegroundColor Cyan

$deployResult = az deployment group create `
  --resource-group $resourceGroupName `
  --template-file "infrastructure/bicep/main.bicep" `
  --parameters "infrastructure/bicep/parameters.dev.json" `
  --parameters userObjectId=$userObjectId `
  --name $deploymentName `
  --output json 2>&1

# Check if deployment succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Infrastructure deployment completed successfully!" -ForegroundColor Green
    
    # Get deployment outputs
    Write-Host "Getting deployment outputs..." -ForegroundColor Yellow
    $outputs = az deployment group show --resource-group $resourceGroupName --name $deploymentName --query properties.outputs --output json | ConvertFrom-Json
    
    Write-Host "Key Vault Name: $($outputs.keyVaultName.value)" -ForegroundColor Cyan
    Write-Host "Document Intelligence: $($outputs.documentIntelligenceName.value)" -ForegroundColor Cyan
    Write-Host "Search Service: $($outputs.searchServiceName.value)" -ForegroundColor Cyan
    Write-Host "SQL Server: $($outputs.sqlServerName.value)" -ForegroundColor Cyan
    Write-Host "Storage Account: $($outputs.storageAccountName.value)" -ForegroundColor Cyan
    Write-Host "Function App: $($outputs.functionAppName.value)" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "READY FOR NEXT STEP: Create MCP Server" -ForegroundColor Green
} else {
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    Write-Host "Full error output:" -ForegroundColor Yellow
    Write-Host $deployResult -ForegroundColor Red
    
    # Try to get deployment operation details
    Write-Host ""
    Write-Host "Getting deployment operation details..." -ForegroundColor Yellow
    az deployment operation group list --resource-group $resourceGroupName --name $deploymentName --query "[?properties.provisioningState=='Failed']" --output table
    
    exit 1
}