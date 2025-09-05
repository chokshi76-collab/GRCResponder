# set-keyvault-reference-for-key.ps1
# This script applies the correct Key Vault reference to the Document Intelligence key.

# --- Configuration ---
$resourceGroupName = "pdf-ai-agent-rg-dev"
$functionAppName = "pdf-ai-agent-func-dev"
$keyVaultName = "kv-ebfk54eja3"
$secretNameForKey = "DocumentIntelligenceKey"

# --- Script ---
Write-Host "---"
Write-Host "TARGETED FIX: SETTING KEY VAULT REFERENCE FOR THE AI KEY"
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Function App: $functionAppName"
Write-Host "---"

try {
    Write-Host "Step 1: Constructing the correct Key Vault reference..."
    $keyVaultReference = "@Microsoft.KeyVault(VaultName=$keyVaultName;SecretName=$secretNameForKey)"
    Write-Host "  - Reference: $keyVaultReference"

    Write-Host "Step 2: Fetching current application settings..."
    $app = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName
    $appSettings = $app.SiteConfig.AppSettings

    Write-Host "Step 3: Updating the specific setting for AZURE_FORM_RECOGNIZER_KEY..."
    $settingsToUpdate = @{}
    foreach ($setting in $appSettings) {
        $settingsToUpdate[$setting.Name] = $setting.Value
    }
    $settingsToUpdate["AZURE_FORM_RECOGNIZER_KEY"] = $keyVaultReference
    
    Write-Host "Step 4: Applying the updated configuration to Azure..."
    Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName -AppSettings $settingsToUpdate
    
    Write-Host ""
    Write-Host "SUCCESS: The Key Vault reference for AZURE_FORM_RECOGNIZER_KEY has been set." -ForegroundColor Green
    Write-Host "The next step is to restart the Function App to apply this change."

}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "---"
Write-Host "Targeted fix script finished."
Write-Host "---"