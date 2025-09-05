# Set Direct Environment Variables for Immediate Testing
# Location: scripts/set-direct-values.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$functionAppName = "pdf-ai-agent-func-dev"
$keyVaultName = "kv-ebfk54eja3"

Write-Host "=== SETTING DIRECT VALUES FOR IMMEDIATE TESTING ===" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Yellow

# Step 1: Get actual values from Key Vault
Write-Host "`n1. Retrieving actual values from Key Vault..." -ForegroundColor Cyan
try {
    $endpointValue = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceEndpoint" -AsPlainText
    $keyValue = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceKey" -AsPlainText
    
    Write-Host "Retrieved endpoint: $endpointValue" -ForegroundColor Green
    Write-Host "Retrieved key: [REDACTED - Length: $($keyValue.Length)]" -ForegroundColor Green
    
} catch {
    Write-Host "Error retrieving Key Vault secrets: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Set direct values in Function App
Write-Host "`n2. Setting direct values in Function App..." -ForegroundColor Cyan
try {
    $settings = @{
        "AZURE_FORM_RECOGNIZER_ENDPOINT" = $endpointValue
        "AZURE_FORM_RECOGNIZER_KEY" = $keyValue
    }
    
    Write-Host "Setting environment variables..." -ForegroundColor Gray
    Update-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSetting $settings
    
    Write-Host "Successfully set direct values:" -ForegroundColor Green
    Write-Host "  ✓ AZURE_FORM_RECOGNIZER_ENDPOINT" -ForegroundColor Green
    Write-Host "  ✓ AZURE_FORM_RECOGNIZER_KEY" -ForegroundColor Green
    
} catch {
    Write-Host "Error setting Function App settings: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Restart Function App to pick up new values
Write-Host "`n3. Restarting Function App..." -ForegroundColor Cyan
try {
    Restart-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -Force
    Write-Host "Function App restart initiated" -ForegroundColor Green
} catch {
    Write-Host "Error restarting Function App: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Wait and test
Write-Host "`n4. Waiting 30 seconds for restart..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

Write-Host "`n5. Testing configuration..." -ForegroundColor Cyan
$testUrl = "https://$functionAppName.azurewebsites.net/api/health"

$maxRetries = 3
for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Write-Host "Test attempt $i of $maxRetries..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri $testUrl -Method GET -TimeoutSec 30
        
        if ($response) {
            Write-Host "`nSUCCESS! Health check response:" -ForegroundColor Green
            $response | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor White
            
            if ($response.azure_integration -eq "ACTIVE") {
                Write-Host "`n🎉 AZURE INTEGRATION IS NOW ACTIVE!" -ForegroundColor Green
                Write-Host "Your Universal AI Tool Platform is fully operational!" -ForegroundColor Green
                break
            }
        }
    } catch {
        Write-Host "Attempt $i failed - Function App may still be starting..." -ForegroundColor Yellow
    }
    
    if ($i -lt $maxRetries) {
        Write-Host "Waiting 15 seconds before retry..." -ForegroundColor Gray
        Start-Sleep -Seconds 15
    }
}

Write-Host "`n=== DIRECT VALUES CONFIGURED ===" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Green
Write-Host "Status: Using direct environment variables (immediate testing)" -ForegroundColor Green
Write-Host "PDF API: https://$functionAppName.azurewebsites.net/api/tools/process_pdf" -ForegroundColor Cyan
Write-Host "`nNote: For production, consider switching back to Key Vault references" -ForegroundColor Yellow