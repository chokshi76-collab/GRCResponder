# Enable Managed Identity for Function App
# Location: scripts/enable-managed-identity.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$keyVaultName = "kv-ebfk54eja3"
$functionAppName = "pdf-ai-agent-func-dev"

Write-Host "=== ENABLING MANAGED IDENTITY ===" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Yellow
Write-Host "Key Vault: $keyVaultName" -ForegroundColor Yellow

# Step 1: Enable system-assigned managed identity
Write-Host "`n1. Enabling system-assigned managed identity..." -ForegroundColor Cyan
try {
    $identity = Update-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -IdentityType SystemAssigned
    $principalId = $identity.IdentityPrincipalId
    
    if ($principalId) {
        Write-Host "Success! Principal ID: $principalId" -ForegroundColor Green
    } else {
        Write-Host "Failed to get Principal ID" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error enabling managed identity: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Grant Key Vault access
Write-Host "`n2. Granting Key Vault access..." -ForegroundColor Cyan
try {
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $principalId -PermissionsToSecrets get,list
    Write-Host "Success! Function App can now access Key Vault" -ForegroundColor Green
} catch {
    Write-Host "Error setting Key Vault access policy: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Wait for propagation and test
Write-Host "`n3. Testing configuration (waiting 30 seconds for propagation)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

$testUrl = "https://$functionAppName.azurewebsites.net/api/health"
try {
    $response = Invoke-RestMethod -Uri $testUrl -Method GET -TimeoutSec 30
    Write-Host "`nSUCCESS! Health check response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor White
    
    # Check if Azure Integration is now ACTIVE
    if ($response -and $response.status -eq "success") {
        Write-Host "`n🎉 AZURE INTEGRATION SHOULD NOW BE ACTIVE!" -ForegroundColor Green
    }
} catch {
    Write-Host "`nHealth check not responding yet - this is normal" -ForegroundColor Yellow
    Write-Host "Wait 2-3 more minutes and test manually at:" -ForegroundColor Yellow
    Write-Host $testUrl -ForegroundColor Cyan
}

Write-Host "`n=== MANAGED IDENTITY CONFIGURED ===" -ForegroundColor Green
Write-Host "Status: Function App now has secure access to Key Vault" -ForegroundColor Green
Write-Host "Next: Test real PDF processing!" -ForegroundColor Cyan