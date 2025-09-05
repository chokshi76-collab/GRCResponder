# fix-bicep-syntax.ps1
# Corrects the syntax error in main.bicep by properly inserting the Key Vault references.

# --- Configuration ---
$bicepFilePath = ".\infrastructure\bicep\main.bicep"

# --- Script ---
Write-Host "---"
Write-Host "FIXING BICEP SYNTAX: Correcting comma issue in appSettings"
Write-Host "File: $bicepFilePath"
Write-Host "---"

try {
    Write-Host "Step 1: Reading the Bicep file content..."
    $bicepContent = Get-Content -Path $bicepFilePath -Raw

    # Define the incorrect block that the previous script created
    $incorrectBlock = @"
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
"@
    
    # Define the correct block with the comma
    $correctBlock = @"
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        },
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-endpoint)'
        },
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-key)'
        }
"@

    # We will search for a unique part of the incorrect block to be more robust
    $searchPattern = [regex]::Escape($incorrectBlock)
    
    # Let's also define a simpler search in case formatting is slightly different
    $simpleSearch = @"
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        }
"@
    $simpleReplacement = @"
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        },
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-endpoint)'
        },
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=document-intelligence-key)'
        }
"@

    if ($bicepContent -match [regex]::Escape($simpleSearch)) {
        Write-Host "Step 2: Found the syntax error. Applying the correction..."
        $newBicepContent = $bicepContent.Replace($simpleSearch, $simpleReplacement)
        
        Write-Host "Step 3: Saving the corrected Bicep file..."
        Set-Content -Path $bicepFilePath -Value $newBicepContent

        Write-Host ""
        Write-Host "SUCCESS: The Bicep syntax error has been corrected." -ForegroundColor Green
    } else {
        Write-Host "NOTICE: Could not find the specific syntax error. It may have already been fixed. Please check main.bicep." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "---"
Write-Host "NEXT ACTION: Commit the updated 'main.bicep' file and push to GitHub."
Write-Host "The pipeline should now pass the Bicep deployment stage."
Write-Host "---"