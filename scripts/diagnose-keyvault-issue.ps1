# Diagnose Key Vault Reference Issue - Find Root Cause
# Location: scripts/diagnose-keyvault-issue.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$functionAppName = "pdf-ai-agent-func-dev"
$keyVaultName = "kv-ebfk54eja3"

Write-Host "=== DIAGNOSING KEY VAULT REFERENCE ISSUE ===" -ForegroundColor Green

# Step 1: Check Function App Managed Identity
Write-Host "`n1. Checking Function App Managed Identity..." -ForegroundColor Cyan
$functionApp = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$principalId = $functionApp.IdentityPrincipalId
$identityType = $functionApp.IdentityType

Write-Host "Identity Type: $identityType" -ForegroundColor Yellow
Write-Host "Principal ID: $principalId" -ForegroundColor Yellow

if (-not $principalId) {
    Write-Host "ISSUE FOUND: No managed identity assigned to Function App" -ForegroundColor Red
    return
}

# Step 2: Check Key Vault Access Policy
Write-Host "`n2. Checking Key Vault Access Policy..." -ForegroundColor Cyan
$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName
$accessPolicies = $keyVault.AccessPolicies

$hasAccess = $false
foreach ($policy in $accessPolicies) {
    if ($policy.ObjectId -eq $principalId) {
        Write-Host "Found access policy for Function App:" -ForegroundColor Green
        Write-Host "  Object ID: $($policy.ObjectId)" -ForegroundColor White
        Write-Host "  Permissions to Secrets: $($policy.PermissionsToSecrets -join ', ')" -ForegroundColor White
        $hasAccess = $true
        break
    }
}

if (-not $hasAccess) {
    Write-Host "ISSUE FOUND: Function App does not have access policy in Key Vault" -ForegroundColor Red
    Write-Host "Fixing access policy..." -ForegroundColor Yellow
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $principalId -PermissionsToSecrets get,list
    Write-Host "Access policy set" -ForegroundColor Green
}

# Step 3: Test Key Vault Secret Access from Function App Identity
Write-Host "`n3. Testing Key Vault secret access..." -ForegroundColor Cyan
try {
    # Use the Function App's managed identity context
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, $null, $null, "https://vault.azure.net/").AccessToken
    
    Write-Host "Access token obtained for Key Vault" -ForegroundColor Green
} catch {
    Write-Host "Could not obtain access token: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Check Function App Configuration Format
Write-Host "`n4. Checking Function App environment variable format..." -ForegroundColor Cyan
$settings = Get-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName

$endpointSetting = $settings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_ENDPOINT" }
$keySetting = $settings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_KEY" }

if ($endpointSetting) {
    Write-Host "AZURE_FORM_RECOGNIZER_ENDPOINT = $($endpointSetting.Value)" -ForegroundColor White
    
    if ($endpointSetting.Value -like "@Microsoft.KeyVault*") {
        Write-Host "  Format: Key Vault Reference (correct)" -ForegroundColor Green
    } else {
        Write-Host "  Format: Direct Value" -ForegroundColor Yellow
    }
} else {
    Write-Host "AZURE_FORM_RECOGNIZER_ENDPOINT: NOT SET" -ForegroundColor Red
}

if ($keySetting) {
    Write-Host "AZURE_FORM_RECOGNIZER_KEY = [REDACTED]" -ForegroundColor White
    
    if ($keySetting.Value -like "@Microsoft.KeyVault*") {
        Write-Host "  Format: Key Vault Reference (correct)" -ForegroundColor Green
    } else {
        Write-Host "  Format: Direct Value" -ForegroundColor Yellow
    }
} else {
    Write-Host "AZURE_FORM_RECOGNIZER_KEY: NOT SET" -ForegroundColor Red
}

# Step 5: Check Key Vault Secret Existence
Write-Host "`n5. Verifying Key Vault secrets exist..." -ForegroundColor Cyan
try {
    $endpointSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceEndpoint"
    $keySecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceKey"
    
    Write-Host "DocumentIntelligenceEndpoint: EXISTS" -ForegroundColor Green
    Write-Host "DocumentIntelligenceKey: EXISTS" -ForegroundColor Green
} catch {
    Write-Host "Error accessing secrets: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Check Function App Runtime and Configuration
Write-Host "`n6. Checking Function App runtime configuration..." -ForegroundColor Cyan
Write-Host "Runtime Stack: $($functionApp.SiteConfig.LinuxFxVersion)" -ForegroundColor White
Write-Host "Runtime Version: $($functionApp.SiteConfig.NodeVersion)" -ForegroundColor White

# Step 7: Recommendations
Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan

if ($identityType -ne "SystemAssigned") {
    Write-Host "FIX 1: Enable system-assigned managed identity" -ForegroundColor Red
}

if (-not $hasAccess) {
    Write-Host "FIX 2: Set proper Key Vault access policy" -ForegroundColor Red
}

if ($endpointSetting.Value -notlike "@Microsoft.KeyVault*") {
    Write-Host "FIX 3: Convert to Key Vault references" -ForegroundColor Yellow
}

Write-Host "`nNext step: Apply the correct Key Vault reference format" -ForegroundColor Green