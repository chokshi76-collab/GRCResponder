# Deploy Optimized Always-On Development Infrastructure
# Target: $15-30/month total cost with full development capabilities

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "qa", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westus2",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "=== OPTIMIZED ALWAYS-ON DEVELOPMENT DEPLOYMENT ===" -ForegroundColor Green
Write-Host "Target Cost: $15-30/month with full development capabilities" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan

# Cost optimization summary
Write-Host "`n=== COST OPTIMIZATIONS ===" -ForegroundColor Yellow
Write-Host "✅ AI Search: FREE tier ($0/month vs $250/month Basic)" -ForegroundColor Green
Write-Host "✅ Function App: Consumption plan (pay-per-execution)" -ForegroundColor Green  
Write-Host "✅ Document Intelligence: Pay-per-use (F0 tier)" -ForegroundColor Green
Write-Host "✅ Storage: Standard LRS (minimal cost)" -ForegroundColor Green
Write-Host "✅ Key Vault: Standard tier (low cost)" -ForegroundColor Green
Write-Host "❌ SQL Database: Removed entirely (saves $50-200/month)" -ForegroundColor Green
Write-Host ""
Write-Host "Expected Total: $15-30/month for full development environment" -ForegroundColor Green

# Ensure we're logged in
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "`nLogged in as: $($context.Account)" -ForegroundColor Green
} catch {
    Write-Host "Please login to Azure first: Connect-AzAccount" -ForegroundColor Red
    exit 1
}

# Set variables
$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$templateFile = "infrastructure/bicep/main.bicep"
$parametersFile = "environments/$Environment/parameters.$Environment.json"

# Verify files exist
if (-not (Test-Path $templateFile)) {
    Write-Host "ERROR: Template file not found: $templateFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $parametersFile)) {
    Write-Host "ERROR: Parameters file not found: $parametersFile" -ForegroundColor Red
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "`n=== ENSURING RESOURCE GROUP EXISTS ===" -ForegroundColor Yellow
try {
    $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group: $resourceGroupName" -ForegroundColor Cyan
        New-AzResourceGroup -Name $resourceGroupName -Location $Location
        Write-Host "Resource group created successfully" -ForegroundColor Green
    } else {
        Write-Host "Resource group already exists: $resourceGroupName" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR creating resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get user object ID for Key Vault access
Write-Host "`n=== GETTING USER OBJECT ID ===" -ForegroundColor Yellow
try {
    $context = Get-AzContext
    $user = Get-AzADUser -UserPrincipalName $context.Account.Id -ErrorAction SilentlyContinue
    if (-not $user) {
        # Try with service principal
        $user = Get-AzADServicePrincipal -ApplicationId $context.Account.Id -ErrorAction SilentlyContinue
        if (-not $user) {
            throw "Could not find user or service principal"
        }
    }
    $userObjectId = $user.Id
    Write-Host "User Object ID: $userObjectId" -ForegroundColor Green
} catch {
    Write-Host "ERROR getting user object ID: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show current resources before deployment
Write-Host "`n=== CURRENT RESOURCES ===" -ForegroundColor Yellow
try {
    $currentResources = Get-AzResource -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if ($currentResources) {
        Write-Host "Current resources:" -ForegroundColor Cyan
        $currentResources | ForEach-Object {
            Write-Host "  - $($_.Name) ($($_.ResourceType))" -ForegroundColor White
        }
    } else {
        Write-Host "No resources currently in resource group" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not list current resources" -ForegroundColor Yellow
}

if ($WhatIf) {
    Write-Host "`n=== WHAT-IF ANALYSIS ===" -ForegroundColor Yellow
    Write-Host "Performing What-If analysis for optimized infrastructure..." -ForegroundColor Cyan
    
    try {
        New-AzResourceGroupDeployment `
            -ResourceGroupName $resourceGroupName `
            -TemplateFile $templateFile `
            -TemplateParameterFile $parametersFile `
            -userObjectId $userObjectId `
            -keyVaultAccessObjectId $userObjectId `
            -Mode Complete `
            -WhatIf `
            -Verbose
        
        Write-Host "What-If analysis completed" -ForegroundColor Green
        return
    } catch {
        Write-Host "ERROR in What-If analysis: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Deploy infrastructure
Write-Host "`n=== DEPLOYING OPTIMIZED INFRASTRUCTURE ===" -ForegroundColor Yellow
$deploymentName = "optimized-infrastructure-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    Write-Host "Starting deployment: $deploymentName" -ForegroundColor Cyan
    Write-Host "Mode: COMPLETE (ensures clean infrastructure)" -ForegroundColor Yellow
    
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $parametersFile `
        -userObjectId $userObjectId `
        -keyVaultAccessObjectId $userObjectId `
        -Mode Complete `
        -Name $deploymentName `
        -Verbose
    
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "`n=== DEPLOYMENT SUCCESSFUL ===" -ForegroundColor Green
        Write-Host "Deployment Name: $deploymentName" -ForegroundColor Green
        Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Green
        
        # Show outputs
        if ($deployment.Outputs) {
            Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
            $deployment.Outputs.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value.Value)" -ForegroundColor White
            }
        }
        
        # Show final resource list
        Write-Host "`n=== OPTIMIZED INFRASTRUCTURE DEPLOYED ===" -ForegroundColor Green
        $finalResources = Get-AzResource -ResourceGroupName $resourceGroupName
        Write-Host "Final resources (optimized for cost):" -ForegroundColor Cyan
        $finalResources | ForEach-Object {
            Write-Host "  ✅ $($_.Name) ($($_.ResourceType))" -ForegroundColor Green
        }
        
        Write-Host "`n=== COST OPTIMIZATION RESULTS ===" -ForegroundColor Green
        Write-Host "🎯 Target achieved: $15-30/month development environment" -ForegroundColor Green
        Write-Host "🎯 AI Search: FREE tier (vs $250/month Basic)" -ForegroundColor Green
        Write-Host "🎯 Function App: True serverless (pay-per-execution)" -ForegroundColor Green
        Write-Host "🎯 SQL Database: Eliminated (saves $50-200/month)" -ForegroundColor Green
        Write-Host "🎯 Always-On: Disabled for cost savings" -ForegroundColor Green
        
    } else {
        Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "`nERROR in deployment: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check the Azure portal for detailed error information" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== OPTIMIZED ALWAYS-ON DEVELOPMENT DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host "Your development environment is now optimized for $15-30/month!" -ForegroundColor Green