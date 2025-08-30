# Deploy using Azure CLI (compiles Bicep in the cloud)
Write-Host "Deploying infrastructure using Azure CLI..." -ForegroundColor Green

# Check if Azure CLI is installed
try {
    $azVersion = az version --output tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI not found"
    }
    Write-Host "Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI is required. Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Red
    Write-Host "Or use Azure Cloud Shell: https://shell.azure.com" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
$accountInfo = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Azure CLI first:" -ForegroundColor Yellow
    Write-Host "az login" -ForegroundColor Cyan
    exit 1
}

Write-Host "Logged in to Azure CLI" -ForegroundColor Green

# Deploy using Azure CLI (Bicep compilation happens in Azure)
Write-Host "Deploying Bicep template via Azure CLI..." -ForegroundColor Cyan
Write-Host "Note: Bicep compilation happens in Azure - no local install needed!" -ForegroundColor Yellow

try {
    $deploymentResult = az deployment group create `
        --resource-group "pdf-ai-agent-rg-dev" `
        --template-file "infrastructure/bicep/main.bicep" `
        --parameters "@infrastructure/bicep/parameters.dev.json" `
        --output json | ConvertFrom-Json

    if ($deploymentResult.properties.provisioningState -eq "Succeeded") {
        Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
        
        # Show outputs
        Write-Host "`nDeployment outputs:" -ForegroundColor Cyan
        $deploymentResult.properties.outputs | ConvertTo-Json -Depth 3
        
        # List resources
        Write-Host "`nDeployed resources:" -ForegroundColor Cyan
        az resource list --resource-group "pdf-ai-agent-rg-dev" --output table
    } else {
        Write-Host "Deployment failed!" -ForegroundColor Red
        Write-Host $deploymentResult.properties.error -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Deployment failed with error:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}

Write-Host "`nDeployment complete! All resources created in Azure." -ForegroundColor Green