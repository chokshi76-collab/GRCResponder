# add-keyvault-refs-to-bicep.ps1
# Corrects the main.bicep template by adding the missing Key Vault references to the Function App settings.

# --- Configuration ---
$bicepFilePath = ".\infrastructure\bicep\main.bicep"

# --- Script ---
Write-Host "---"
Write-Host "FIXING IAC: ADDING KEY VAULT REFERENCES TO BICEP"
Write-Host "File: $bicepFilePath"
Write-Host "---"

try {
    Write-Host "Step 1: Reading Bicep file content..."
    $bicepContent = Get-Content -Path $bicepFilePath -Raw

    # Define the block of app settings to be inserted
    $appSettingsToAdd = @"
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-endpoint)'
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-key)'
        }
"@

    # Define the anchor point for insertion (the WEBSITE_RUN_FROM_PACKAGE setting)
    $anchor = @"
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
"@

    if ($bicepContent -match [regex]::Escape($anchor) -and -not ($bicepContent -match 'AZURE_FORM_RECOGNIZER_ENDPOINT')) {
        Write-Host "Step 2: Found the insertion point. Injecting Key Vault references..."
        
        # Replace the anchor with the anchor PLUS the new settings
        $newBicepContent = $bicepContent -replace [regex]::Escape($anchor), ($anchor + $appSettingsToAdd)
        
        Write-Host "Step 3: Saving the corrected Bicep file..."
        Set-Content -Path $bicepFilePath -Value $newBicepContent
        
        Write-Host ""
        Write-Host "SUCCESS: The main.bicep file has been corrected." -ForegroundColor Green
        Write-Host "The Function App is now configured to use Key Vault for AI services."

    } elseif ($bicepContent -match 'AZURE_FORM_RECOGNIZER_ENDPOINT') {
        Write-Host "NOTICE: The Bicep file appears to already contain the Key Vault references. No changes made." -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Could not find the anchor point in the Bicep file. Manual edit may be required." -ForegroundColor Red
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "---"
Write-Host "NEXT ACTION: Commit the updated 'main.bicep' file and push to GitHub."
Write-Host "The GitHub Actions CI/CD pipeline will deploy the fix."
Write-Host "---"