# Deploy the working infrastructure
Write-Host "Deploying PDF AI Agent Infrastructure - FINAL VERSION..." -ForegroundColor Green

# Set variables
$resourceGroupName = "pdf-ai-agent-rg-dev"
$deploymentName = "pdf-ai-agent-final-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$userObjectId = "402ed151-67f7-4f36-bc74-ac2b9c9e1980"

Write-Host "Starting deployment: $deploymentName" -ForegroundColor Yellow
Write-Host "This will create 14 new resources..." -ForegroundColor Cyan

# Deploy the infrastructure
az deployment group create `
  --resource-group $resourceGroupName `
  --template-file "infrastructure/bicep/main.bicep" `
  --parameters userObjectId=$userObjectId `
  --name $deploymentName `
  --output table

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: Infrastructure deployment completed!" -ForegroundColor Green
    
    # Get deployment outputs
    Write-Host "Getting deployment outputs..." -ForegroundColor Yellow
    $outputs = az deployment group show --resource-group $resourceGroupName --name $deploymentName --query properties.outputs --output json | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "=== DEPLOYED RESOURCES ===" -ForegroundColor Green
    Write-Host "Key Vault: $($outputs.keyVaultName.value)" -ForegroundColor Cyan
    Write-Host "Document Intelligence: $($outputs.documentIntelligenceName.value)" -ForegroundColor Cyan
    Write-Host "Search Service: $($outputs.searchServiceName.value)" -ForegroundColor Cyan
    Write-Host "SQL Server: $($outputs.sqlServerName.value)" -ForegroundColor Cyan
    Write-Host "SQL Database: $($outputs.sqlDatabaseName.value)" -ForegroundColor Cyan
    Write-Host "Storage Account: $($outputs.storageAccountName.value)" -ForegroundColor Cyan
    Write-Host "Function App: $($outputs.functionAppName.value)" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "NEXT STEP: Create MCP Server TypeScript project" -ForegroundColor Green
    Write-Host "Key Vault URL for MCP server: https://$($outputs.keyVaultName.value).vault.azure.net/" -ForegroundColor Yellow
    
} else {
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    exit 1
}