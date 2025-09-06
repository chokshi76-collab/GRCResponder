# Clean Infrastructure Deployment Script
# Uses COMPLETE mode to ensure infrastructure matches Bicep template exactly
# Deletes any resources NOT defined in Bicep template

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

Write-Host "=== CLEAN INFRASTRUCTURE DEPLOYMENT ===" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "Mode: COMPLETE (will delete resources not in Bicep template)" -ForegroundColor Red

# Ensure we're logged in
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "Logged in as: $($context.Account)" -ForegroundColor Green
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
    Write-Host "Please provide userObjectId manually or check your login" -ForegroundColor Red
    exit 1
}

# Show current resources before deployment
Write-Host "`n=== CURRENT RESOURCES IN RESOURCE GROUP ===" -ForegroundColor Yellow
try {
    $currentResources = Get-AzResource -ResourceGroupName $resourceGroupName
    if ($currentResources) {
        Write-Host "Resources that will be evaluated for deletion:" -ForegroundColor Red
        $currentResources | ForEach-Object {
            Write-Host "  - $($_.Name) ($($_.ResourceType))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No resources currently in resource group" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not list current resources" -ForegroundColor Yellow
}

# WARNING about Complete mode
Write-Host "`n=== WARNING: COMPLETE DEPLOYMENT MODE ===" -ForegroundColor Red
Write-Host "This deployment uses COMPLETE mode which will:" -ForegroundColor Red
Write-Host "  ✅ Create resources defined in Bicep template" -ForegroundColor Green
Write-Host "  ✅ Update existing resources to match template" -ForegroundColor Green
Write-Host "  ❌ DELETE resources NOT defined in template" -ForegroundColor Red
Write-Host ""

if ($WhatIf) {
    Write-Host "=== WHAT-IF DEPLOYMENT ===" -ForegroundColor Yellow
    Write-Host "Performing What-If analysis..." -ForegroundColor Cyan
    
    try {
        $whatIfResult = New-AzResourceGroupDeployment `
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

# Confirm deployment
$confirm = Read-Host "Do you want to proceed with COMPLETE deployment? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Deploy infrastructure
Write-Host "`n=== DEPLOYING INFRASTRUCTURE ===" -ForegroundColor Yellow
$deploymentName = "infrastructure-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    Write-Host "Starting deployment: $deploymentName" -ForegroundColor Cyan
    Write-Host "Mode: COMPLETE" -ForegroundColor Red
    
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
        Write-Host "`n=== FINAL RESOURCES ===" -ForegroundColor Yellow
        $finalResources = Get-AzResource -ResourceGroupName $resourceGroupName
        $finalResources | ForEach-Object {
            Write-Host "  ✅ $($_.Name) ($($_.ResourceType))" -ForegroundColor Green
        }
        
    } else {
        Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "`nERROR in deployment: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check the Azure portal for detailed error information" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== CLEAN INFRASTRUCTURE DEPLOYMENT COMPLETE ===" -ForegroundColor Green