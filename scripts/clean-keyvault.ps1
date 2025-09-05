# Clean Key Vault Configuration Script
# Location: scripts/clean-keyvault.ps1
param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"
$subscriptionId = "d4d5edc0-d0d0-491c-8d55-4bf5481b5b49"

Write-Host "=== KEY VAULT CONFIGURATION ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Step 1: Set context
Write-Host "1. Setting Azure context..." -ForegroundColor Cyan
Set-AzContext -SubscriptionId $subscriptionId

# Step 2: Find Key Vault
Write-Host "2. Finding Key Vault..." -ForegroundColor Cyan
$keyVaults = Get-AzKeyVault -ResourceGroupName $resourceGroupName
$keyVault = $keyVaults | Select-Object -First 1
if (-not $keyVault) {
    Write-Host "Key Vault not found!" -ForegroundColor Red
    exit 1
}
$keyVaultName = $keyVault.VaultName
Write-Host "Found: $keyVaultName" -ForegroundColor Green

# Step 3: Find Document Intelligence
Write-Host "3. Finding Document Intelligence..." -ForegroundColor Cyan
$cognitiveServices = Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName

# Use name pattern matching instead of Kind (Kind property is blank in newer Azure PowerShell)
$documentIntelligence = $cognitiveServices | Where-Object { 
    $_.AccountName -like "*docint*" -or 
    $_.AccountName -like "*di-*" -or 
    $_.AccountName -like "*form*" -or
    $_.AccountName -like "*intelligence*"
} | Select-Object -First 1

if (-not $documentIntelligence) {
    Write-Host "Document Intelligence not found!" -ForegroundColor Red
    Write-Host "Available Cognitive Services:" -ForegroundColor Yellow
    $cognitiveServices | ForEach-Object { Write-Host "  - $($_.AccountName)" -ForegroundColor Gray }
    exit 1
}
$docName = $documentIntelligence.AccountName
$docEndpoint = $documentIntelligence.Endpoint
Write-Host "Found: $docName" -ForegroundColor Green

# Step 4: Get keys
Write-Host "4. Getting access keys..." -ForegroundColor Cyan
$keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $docName
$docKey = $keys.Key1
Write-Host "Retrieved keys" -ForegroundColor Green

# Step 5: Store in Key Vault
Write-Host "5. Storing in Key Vault..." -ForegroundColor Cyan
$endpointSecure = ConvertTo-SecureString $docEndpoint -AsPlainText -Force
$keySecure = ConvertTo-SecureString $docKey -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceEndpoint" -SecretValue $endpointSecure | Out-Null
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "DocumentIntelligenceKey" -SecretValue $keySecure | Out-Null
Write-Host "Stored secrets" -ForegroundColor Green

# Step 6: Find Function App
Write-Host "6. Finding Function App..." -ForegroundColor Cyan
$functionApps = Get-AzFunctionApp -ResourceGroupName $resourceGroupName
$functionApp = $functionApps | Select-Object -First 1
if (-not $functionApp) {
    Write-Host "Function App not found!" -ForegroundColor Red
    exit 1
}
$functionAppName = $functionApp.Name
Write-Host "Found: $functionAppName" -ForegroundColor Green

# Step 7: Configure references
Write-Host "7. Configuring references..." -ForegroundColor Cyan
$endpointRef = "@Microsoft.KeyVault(VaultName=" + $keyVaultName + ";SecretName=DocumentIntelligenceEndpoint)"
$keyRef = "@Microsoft.KeyVault(VaultName=" + $keyVaultName + ";SecretName=DocumentIntelligenceKey)"

$settings = @{
    "AZURE_FORM_RECOGNIZER_ENDPOINT" = $endpointRef
    "AZURE_FORM_RECOGNIZER_KEY" = $keyRef
}

Update-AzFunctionAppSetting -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSetting $settings
Write-Host "Configured references" -ForegroundColor Green

# Step 8: Set access policy
Write-Host "8. Setting access policy..." -ForegroundColor Cyan
$functionAppDetails = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName
$principalId = $functionAppDetails.IdentityPrincipalId

if ($principalId) {
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $principalId -PermissionsToSecrets get,list | Out-Null
    Write-Host "Access granted" -ForegroundColor Green
} else {
    Write-Host "No managed identity" -ForegroundColor Yellow
}

# Step 9: Test
Write-Host "9. Testing (waiting 10 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

$testUrl = "https://" + $functionAppName + ".azurewebsites.net/api/health"
try {
    $response = Invoke-RestMethod -Uri $testUrl -Method GET -TimeoutSec 30
    Write-Host "SUCCESS!" -ForegroundColor Green
    $response | ConvertTo-Json | Write-Host
} catch {
    Write-Host "Test pending - wait 2-3 minutes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Green
Write-Host "Key Vault: $keyVaultName" -ForegroundColor Green
Write-Host "Function App: $functionAppName" -ForegroundColor Green
Write-Host "PDF API: https://$functionAppName.azurewebsites.net/api/tools/process_pdf" -ForegroundColor Cyan