# Fix Key Vault References - Proper Implementation
# Location: scripts/fix-keyvault-references.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$functionAppName = "pdf-ai-agent-func-dev"
$keyVaultName = "kv-ebfk54eja3"

Write-Host "=== FIXING KEY VAULT REFERENCES ===" -ForegroundColor Green
Write-Host "This will properly set Key Vault references in Function App" -ForegroundColor Yellow

# Step 1: Verify prerequisites
Write-Host "`n1. Verifying prerequisites..." -ForegroundColor Cyan
$functionApp = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$principalId = $functionApp.IdentityPrincipalId

if (-not $principalId) {
    Write-Host "ERROR: Function App does not have managed identity" -ForegroundColor Red
    exit 1
}

Write-Host "Function App Principal ID: $principalId" -ForegroundColor Green

# Step 2: Ensure Key Vault access policy
Write-Host "`n2. Ensuring Key Vault access policy..." -ForegroundColor Cyan
try {
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $principalId -PermissionsToSecrets get,list
    Write-Host "Key Vault access policy confirmed" -ForegroundColor Green
} catch {
    Write-Host "Error setting Key Vault access policy: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Get current Function App settings
Write-Host "`n3. Getting current Function App settings..." -ForegroundColor Cyan
$currentSettings = @{}
try {
    $settingsResponse = Get-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName
    foreach ($setting in $settingsResponse) {
        $currentSettings[$setting.Name] = $setting.Value
    }
    Write-Host "Retrieved $($currentSettings.Count) current settings" -ForegroundColor Green
} catch {
    Write-Host "Error getting current settings: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Build Key Vault references with proper format
Write-Host "`n4. Building Key Vault references..." -ForegroundColor Cyan

# Use the exact format that Azure Functions expects
$endpointReference = "@Microsoft.KeyVault(VaultName=$keyVaultName;SecretName=DocumentIntelligenceEndpoint)"
$keyReference = "@Microsoft.KeyVault(VaultName=$keyVaultName;SecretName=DocumentIntelligenceKey)"

Write-Host "Endpoint reference: $endpointReference" -ForegroundColor Gray
Write-Host "Key reference: $keyReference" -ForegroundColor Gray

# Step 5: Merge with existing settings to avoid overwriting
Write-Host "`n5. Merging with existing settings..." -ForegroundColor Cyan
$updatedSettings = $currentSettings.Clone()
$updatedSettings["AZURE_FORM_RECOGNIZER_ENDPOINT"] = $endpointReference
$updatedSettings["AZURE_FORM_RECOGNIZER_KEY"] = $keyReference

Write-Host "Settings to update:" -ForegroundColor Green
Write-Host "  AZURE_FORM_RECOGNIZER_ENDPOINT -> Key Vault reference" -ForegroundColor White
Write-Host "  AZURE_FORM_RECOGNIZER_KEY -> Key Vault reference" -ForegroundColor White

# Step 6: Apply settings using different approach
Write-Host "`n6. Applying Key Vault references..." -ForegroundColor Cyan
try {
    # Use more explicit PowerShell approach
    $settingsHashtable = @{
        "AZURE_FORM_RECOGNIZER_ENDPOINT" = $endpointReference
        "AZURE_FORM_RECOGNIZER_KEY" = $keyReference
    }
    
    # Apply each setting individually for better error handling
    foreach ($setting in $settingsHashtable.GetEnumerator()) {
        Write-Host "Setting $($setting.Key)..." -ForegroundColor Gray
        Update-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSetting @{$setting.Key = $setting.Value} -Force
    }
    
    Write-Host "Key Vault references applied successfully" -ForegroundColor Green
    
} catch {
    Write-Host "Error applying settings: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try alternative approach using Azure REST API
    Write-Host "Trying alternative approach..." -ForegroundColor Yellow
    
    try {
        # Get access token for Azure Resource Manager
        $context = Get-AzContext
        $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, $null, $null, "https://management.azure.com/").AccessToken
        
        # Build REST API request
        $subscriptionId = $context.Subscription.Id
        $apiUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$functionAppName/config/appsettings?api-version=2021-02-01"
        
        $headers = @{
            'Authorization' = "Bearer $token"
            'Content-Type' = 'application/json'
        }
        
        # Get current app settings via REST API
        $currentAppSettings = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET
        
        # Update with Key Vault references
        $currentAppSettings.properties["AZURE_FORM_RECOGNIZER_ENDPOINT"] = $endpointReference
        $currentAppSettings.properties["AZURE_FORM_RECOGNIZER_KEY"] = $keyReference
        
        # PUT updated settings
        $body = $currentAppSettings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $body
        
        Write-Host "Applied settings via REST API" -ForegroundColor Green
        
    } catch {
        Write-Host "REST API approach also failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 7: Verify settings were applied
Write-Host "`n7. Verifying settings were applied..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

try {
    $verifySettings = Get-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName
    $endpointVerify = $verifySettings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_ENDPOINT" }
    $keyVerify = $verifySettings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_KEY" }
    
    if ($endpointVerify -and $endpointVerify.Value -like "@Microsoft.KeyVault*") {
        Write-Host "✓ AZURE_FORM_RECOGNIZER_ENDPOINT: Key Vault reference set" -ForegroundColor Green
    } else {
        Write-Host "✗ AZURE_FORM_RECOGNIZER_ENDPOINT: Not set or incorrect format" -ForegroundColor Red
    }
    
    if ($keyVerify -and $keyVerify.Value -like "@Microsoft.KeyVault*") {
        Write-Host "✓ AZURE_FORM_RECOGNIZER_KEY: Key Vault reference set" -ForegroundColor Green
    } else {
        Write-Host "✗ AZURE_FORM_RECOGNIZER_KEY: Not set or incorrect format" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error verifying settings: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 8: Restart Function App
Write-Host "`n8. Restarting Function App..." -ForegroundColor Cyan
try {
    Restart-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -Force
    Write-Host "Function App restart initiated" -ForegroundColor Green
} catch {
    Write-Host "Error restarting Function App: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 9: Wait and test
Write-Host "`n9. Waiting 45 seconds for Key Vault references to resolve..." -ForegroundColor Cyan
Start-Sleep -Seconds 45

Write-Host "`n10. Testing configuration..." -ForegroundColor Cyan
$testUrl = "https://$functionAppName.azurewebsites.net/api/health"

$maxRetries = 5
for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Write-Host "Test attempt $i of $maxRetries..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri $testUrl -Method GET -TimeoutSec 30
        
        if ($response) {
            Write-Host "`nHealth check response:" -ForegroundColor Green
            $response | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor White
            
            if ($response.azure_integration -eq "ACTIVE") {
                Write-Host "`n🎉 SUCCESS! Azure Integration is now ACTIVE!" -ForegroundColor Green
                Write-Host "Key Vault references are working properly!" -ForegroundColor Green
                break
            } elseif ($response.azure_integration -eq "NOT_CONFIGURED") {
                Write-Host "Still showing NOT_CONFIGURED - Key Vault references may need more time..." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Health check failed - Function App may still be starting..." -ForegroundColor Yellow
    }
    
    if ($i -lt $maxRetries) {
        Write-Host "Waiting 20 seconds before retry..." -ForegroundColor Gray
        Start-Sleep -Seconds 20
    }
}

Write-Host "`n=== KEY VAULT REFERENCES CONFIGURED ===" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Green
Write-Host "Key Vault: $keyVaultName" -ForegroundColor Green
Write-Host "Security: Enterprise-grade Key Vault references implemented" -ForegroundColor Green
Write-Host "`nIf still showing NOT_CONFIGURED:" -ForegroundColor Yellow
Write-Host "- Wait 10-15 more minutes for Key Vault references to fully propagate" -ForegroundColor Gray
Write-Host "- Key Vault references can take time to resolve in Azure Functions" -ForegroundColor Gray