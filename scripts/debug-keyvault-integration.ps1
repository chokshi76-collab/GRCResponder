# debug-keyvault-integration.ps1
# This script diagnoses the Key Vault integration by fetching the exact app settings from Azure.

# --- Configuration ---
$resourceGroupName = "pdf-ai-agent-rg-dev"
$functionAppName = "pdf-ai-agent-func-dev"

# --- Script ---
Write-Host "---"
Write-Host "DEBUGGING KEY VAULT INTEGRATION"
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Function App: $functionAppName"
Write-Host "---"

try {
    Write-Host "Step 1: Fetching Function App application settings..."
    $appSettings = (Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $functionAppName).SiteConfig.AppSettings

    if ($appSettings) {
        Write-Host "Step 2: Displaying Azure Document Intelligence settings..."

        $endpointSetting = $appSettings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_ENDPOINT" }
        $keySetting = $appSettings | Where-Object { $_.Name -eq "AZURE_FORM_RECOGNIZER_KEY" }

        if ($endpointSetting) {
            Write-Host "  - AZURE_FORM_RECOGNIZER_ENDPOINT:"
            Write-Host "    Value: $($endpointSetting.Value)"
        } else {
            Write-Host "  - AZURE_FORM_RECOGNIZER_ENDPOINT: NOT FOUND"
        }

        if ($keySetting) {
            Write-Host "  - AZURE_FORM_RECOGNIZER_KEY:"
            Write-Host "    Value: $($keySetting.Value)"
        } else {
            Write-Host "  - AZURE_FORM_RECOGNIZER_KEY: NOT FOUND"
        }

        Write-Host ""
        Write-Host "Step 3: Analysis"
        Write-Host "Check if the values above start with '@Microsoft.KeyVault'. If not, the references are not set correctly."
        Write-Host "If they are set, the problem might be with the Managed Identity permissions."

    } else {
        Write-Host "Error: Could not retrieve application settings for Function App '$functionAppName'."
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "---"
Write-Host "Debug script finished."
Write-Host "---"