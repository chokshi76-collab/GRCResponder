# Deploy PDF AI Agent Infrastructure to Azure
# Run this from your project root directory

Write-Host "Deploying PDF AI Agent Infrastructure..." -ForegroundColor Green

# Check if logged in to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please login to Azure first..." -ForegroundColor Yellow
        Connect-AzAccount
    }
} catch {
    Write-Host "Installing Azure PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
    Connect-AzAccount
}

# Set subscription (replace with your subscription ID if needed)
# Get-AzSubscription | Select-Object Name, Id
# Set-AzContext -SubscriptionId "your-subscription-id"

# Deploy the Bicep template
Write-Host "Deploying Bicep template..." -ForegroundColor Cyan

$deploymentResult = New-AzResourceGroupDeployment `
    -ResourceGroupName "pdf-ai-agent-rg-dev" `
    -TemplateFile "infrastructure/bicep/main.bicep" `
    -TemplateParameterFile "infrastructure/bicep/parameters.dev.json" `
    -Verbose

# Check deployment status
if ($deploymentResult.ProvisioningState -eq "Succeeded") {
    Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
    
    # Show deployed resources
    Write-Host "`nDeployed resources:" -ForegroundColor Cyan
    Get-AzResource -ResourceGroupName "pdf-ai-agent-rg-dev" | Format-Table Name, ResourceType, Location
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host $deploymentResult
    exit 1
}

Write-Host "`nStep 1 complete! Ready for next step." -ForegroundColor Green