# Debug Environment Variables in Function App
# Location: scripts/debug-env-vars.ps1

param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$functionAppName = "pdf-ai-agent-func-dev"

Write-Host "=== DEBUGGING ENVIRONMENT VARIABLES ===" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Yellow

# Get current Function App settings
Write-Host "`n1. Getting current Function App settings..." -ForegroundColor Cyan
try {
    $settings = Get-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName
    
    Write-Host "Environment Variables (Key Vault related):" -ForegroundColor Green
    foreach ($setting in $settings) {
        if ($setting.Name -like "*AZURE_FORM_RECOGNIZER*" -or $setting.Name -like "*DOCUMENT_INTELLIGENCE*") {
            Write-Host "  $($setting.Name) = $($setting.Value)" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "Error getting Function App settings: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test Key Vault access directly
Write-Host "`n2. Testing Key Vault access directly..." -ForegroundColor Cyan
$keyVaultName = "kv-ebfk54eja3"

try {
    $endpointSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceEndpoint" -AsPlainText
    $keySecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceKey" -AsPlainText
    
    Write-Host "Key Vault Secrets Retrieved Successfully:" -ForegroundColor Green
    Write-Host "  Endpoint: $endpointSecret" -ForegroundColor White
    Write-Host "  Key: [REDACTED - Length: $($keySecret.Length)]" -ForegroundColor White
    
} catch {
    Write-Host "Error accessing Key Vault: $($_.Exception.Message)" -ForegroundColor Red
}

# Suggest fix based on findings
Write-Host "`n3. Diagnosis and Recommendation:" -ForegroundColor Cyan

Write-Host "`nIf the Function App environment variables show Key Vault references like:" -ForegroundColor Yellow
Write-Host "  @Microsoft.KeyVault(VaultName=...)" -ForegroundColor Gray
Write-Host "`nThen the issue is that Key Vault references can take 15-30 minutes to fully resolve." -ForegroundColor Yellow

Write-Host "`nAlternatively, we can set the values directly (less secure but faster for testing):" -ForegroundColor Yellow
Write-Host "  AZURE_FORM_RECOGNIZER_ENDPOINT = [actual endpoint value]" -ForegroundColor Gray
Write-Host "  AZURE_FORM_RECOGNIZER_KEY = [actual key value]" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. If showing Key Vault references: Wait 15-30 minutes for Azure to resolve them" -ForegroundColor Gray
Write-Host "2. If urgent: Use direct values temporarily for testing" -ForegroundColor Gray
Write-Host "3. For production: Always use Key Vault references (current setup)" -ForegroundColor Gray