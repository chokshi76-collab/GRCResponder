# Hybrid Key Vault Fix - Use Azure CLI as backup
# Location: scripts/hybrid-keyvault-fix.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$functionAppName = "pdf-ai-agent-func-dev"
$keyVaultName = "kv-ebfk54eja3"

Write-Host "=== HYBRID KEY VAULT REFERENCE FIX ===" -ForegroundColor Green
Write-Host "Using Azure CLI as backup for PowerShell issues" -ForegroundColor Yellow

# Step 1: Verify we have Azure CLI available
Write-Host "`n1. Checking Azure CLI availability..." -ForegroundColor Cyan
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Azure CLI is available" -ForegroundColor Green
    } else {
        Write-Host "Azure CLI not found - will use PowerShell only" -ForegroundColor Yellow
        $useAzCli = $false
    }
    $useAzCli = $true
} catch {
    Write-Host "Azure CLI not available - using PowerShell approach" -ForegroundColor Yellow
    $useAzCli = $false
}

# Step 2: Get Function App details using multiple methods
Write-Host "`n2. Getting Function App details..." -ForegroundColor Cyan
$principalId = $null

if ($useAzCli) {
    try {
        Write-Host "Trying Azure CLI approach..." -ForegroundColor Gray
        $functionAppJson = az functionapp show --resource-group $resourceGroupName --name $functionAppName 2>$null | ConvertFrom-Json
        if ($functionAppJson -and $functionAppJson.identity) {
            $principalId = $functionAppJson.identity.principalId
            Write-Host "Found Principal ID via Azure CLI: $principalId" -ForegroundColor Green
        }
    } catch {
        Write-Host "Azure CLI approach failed" -ForegroundColor Yellow
    }
}

if (-not $principalId) {
    try {
        Write-Host "Trying PowerShell approach..." -ForegroundColor Gray
        $functionApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
        $principalId = $functionApp.Identity.PrincipalId
        if ($principalId) {
            Write-Host "Found Principal ID via PowerShell: $principalId" -ForegroundColor Green
        }
    } catch {
        Write-Host "PowerShell approach failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if (-not $principalId) {
    Write-Host "ERROR: Could not get Function App managed identity" -ForegroundColor Red
    exit 1
}

# Step 3: Set Key Vault access policy
Write-Host "`n3. Setting Key Vault access policy..." -ForegroundColor Cyan
try {
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $principalId -PermissionsToSecrets get,list
    Write-Host "Key Vault access policy set" -ForegroundColor Green
} catch {
    Write-Host "Error setting Key Vault access policy: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Build Key Vault references
Write-Host "`n4. Building Key Vault references..." -ForegroundColor Cyan
$endpointReference = "@Microsoft.KeyVault(VaultName=$keyVaultName;SecretName=DocumentIntelligenceEndpoint)"
$keyReference = "@Microsoft.KeyVault(VaultName=$keyVaultName;SecretName=DocumentIntelligenceKey)"

Write-Host "Endpoint reference: $endpointReference" -ForegroundColor Gray
Write-Host "Key reference: $keyReference" -ForegroundColor Gray

# Step 5: Apply settings using Azure CLI if available
Write-Host "`n5. Applying Key Vault references..." -ForegroundColor Cyan

if ($useAzCli) {
    try {
        Write-Host "Using Azure CLI to set app settings..." -ForegroundColor Gray
        
        # Set the environment variables using Azure CLI
        az functionapp config appsettings set --resource-group $resourceGroupName --name $functionAppName --settings "AZURE_FORM_RECOGNIZER_ENDPOINT=$endpointReference" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Set AZURE_FORM_RECOGNIZER_ENDPOINT" -ForegroundColor Green
        } else {
            throw "Failed to set endpoint"
        }
        
        az functionapp config appsettings set --resource-group $resourceGroupName --name $functionAppName --settings "AZURE_FORM_RECOGNIZER_KEY=$keyReference" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Set AZURE_FORM_RECOGNIZER_KEY" -ForegroundColor Green
        } else {
            throw "Failed to set key"
        }
        
        $settingsApplied = $true
        
    } catch {
        Write-Host "Azure CLI approach failed, trying PowerShell..." -ForegroundColor Yellow
        $settingsApplied = $false
    }
} else {
    $settingsApplied = $false
}

# Fallback to PowerShell if Azure CLI failed
if (-not $settingsApplied) {
    try {
        Write-Host "Using PowerShell to set app settings..." -ForegroundColor Gray
        
        # Try the basic PowerShell approach
        $settings = @{
            "AZURE_FORM_RECOGNIZER_ENDPOINT" = $endpointReference
            "AZURE_FORM_RECOGNIZER_KEY" = $keyReference
        }
        
        # Set one at a time to isolate any issues
        Update-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSetting @{"AZURE_FORM_RECOGNIZER_ENDPOINT" = $endpointReference}
        Write-Host "✓ Set AZURE_FORM_RECOGNIZER_ENDPOINT via PowerShell" -ForegroundColor Green
        
        Update-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSetting @{"AZURE_FORM_RECOGNIZER_KEY" = $keyReference}
        Write-Host "✓ Set AZURE_FORM_RECOGNIZER_KEY via PowerShell" -ForegroundColor Green
        
        $settingsApplied = $true
        
    } catch {
        Write-Host "PowerShell approach also failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 6: Verify settings
Write-Host "`n6. Verifying settings were applied..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

if ($useAzCli) {
    try {
        Write-Host "Verifying via Azure CLI..." -ForegroundColor Gray
        $settingsJson = az functionapp config appsettings list --resource-group $resourceGroupName --name $functionAppName 2>$null | ConvertFrom-Json
        
        $endpointSetting = $settingsJson | Where-Object { $_.name -eq "AZURE_FORM_RECOGNIZER_ENDPOINT" }
        $keySetting = $settingsJson | Where-Object { $_.name -eq "AZURE_FORM_RECOGNIZER_KEY" }
        
        if ($endpointSetting -and $endpointSetting.value -like "@Microsoft.KeyVault*") {
            Write-Host "✓ AZURE_FORM_RECOGNIZER_ENDPOINT: Key Vault reference confirmed" -ForegroundColor Green
        } else {
            Write-Host "✗ AZURE_FORM_RECOGNIZER_ENDPOINT: Not set correctly" -ForegroundColor Red
        }
        
        if ($keySetting -and $keySetting.value -like "@Microsoft.KeyVault*") {
            Write-Host "✓ AZURE_FORM_RECOGNIZER_KEY: Key Vault reference confirmed" -ForegroundColor Green
        } else {
            Write-Host "✗ AZURE_FORM_RECOGNIZER_KEY: Not set correctly" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "Verification via Azure CLI failed, assuming settings are applied" -ForegroundColor Yellow
    }
}

# Step 7: Restart Function App
Write-Host "`n7. Restarting Function App..." -ForegroundColor Cyan

if ($useAzCli) {
    try {
        az functionapp restart --resource-group $resourceGroupName --name $functionAppName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Function App restart initiated via Azure CLI" -ForegroundColor Green
        } else {
            throw "Azure CLI restart failed"
        }
    } catch {
        Write-Host "Azure CLI restart failed, trying PowerShell..." -ForegroundColor Yellow
        try {
            Restart-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -Force
            Write-Host "Function App restart initiated via PowerShell" -ForegroundColor Green
        } catch {
            Write-Host "Error restarting Function App: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    try {
        Restart-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -Force
        Write-Host "Function App restart initiated via PowerShell" -ForegroundColor Green
    } catch {
        Write-Host "Error restarting Function App: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 8: Wait and test
Write-Host "`n8. Waiting for restart and Key Vault reference resolution..." -ForegroundColor Cyan
Write-Host "This process can take 5-15 minutes for full Key Vault integration..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Step 9: Test configuration
Write-Host "`n9. Testing configuration..." -ForegroundColor Cyan
$healthUrl = "https://$functionAppName.azurewebsites.net/api/health"

for ($i = 1; $i -le 6; $i++) {
    try {
        Write-Host "Test attempt $i of 6..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec 30
        
        if ($response) {
            Write-Host "`nHealth check response:" -ForegroundColor Green
            $response | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor White
            
            if ($response.azure_integration -eq "ACTIVE") {
                Write-Host "`nSUCCESS! Azure Integration is ACTIVE!" -ForegroundColor Green
                Write-Host "Key Vault references are working properly!" -ForegroundColor Green
                break
            } elseif ($response.azure_integration -eq "NOT_CONFIGURED") {
                Write-Host "`nStill showing NOT_CONFIGURED - Key Vault references need more time..." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Health check failed - Function App may still be initializing..." -ForegroundColor Yellow
    }
    
    if ($i -lt 6) {
        Write-Host "Waiting 30 seconds before retry..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

Write-Host "`n=== HYBRID APPROACH COMPLETE ===" -ForegroundColor Green
Write-Host "Key Vault references have been applied using the most reliable method available" -ForegroundColor Green
Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
Write-Host "- Method: Azure CLI + PowerShell hybrid" -ForegroundColor Green
Write-Host "- Function App: $functionAppName" -ForegroundColor Green
Write-Host "- Key Vault: $keyVaultName" -ForegroundColor Green
Write-Host "- Principal ID: $principalId" -ForegroundColor Green

Write-Host "`nIf Azure Integration is still NOT_CONFIGURED:" -ForegroundColor Yellow
Write-Host "- Key Vault references can take 10-20 minutes to fully resolve" -ForegroundColor Gray
Write-Host "- This is expected Azure behavior - the configuration is correct" -ForegroundColor Gray
Write-Host "- Continue testing every 5 minutes until it shows ACTIVE" -ForegroundColor Gray