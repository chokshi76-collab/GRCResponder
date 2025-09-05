# fix-bicep-appsettings.ps1
# Corrects the main.bicep template to use a Key Vault reference for the Document Intelligence key.

# --- Configuration ---
$bicepFilePath = ".\infrastructure\bicep\main.bicep"

# --- Script ---
Write-Host "---"
Write-Host "FIXING INFRASTRUCTURE AS CODE: Correcting main.bicep"
Write-Host "File: $bicepFilePath"
Write-Host "---"

try {
    Write-Host "Step 1: Reading the content of the Bicep file..."
    $bicepContent = Get-Content -Path $bicepFilePath -Raw

    Write-Host "Step 2: Identifying the incorrect line..."
    # This targets the line where the key's value is incorrectly assigned from a parameter.
    $lineToReplace = "value: docIntelligenceKey"
    
    Write-Host "Step 3: Defining the correct Key Vault reference..."
    $correctLine = "value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=DocumentIntelligenceKey)'"

    if ($bicepContent -match $lineToReplace) {
        Write-Host "  - Found incorrect line: '$lineToReplace'"
        Write-Host "  - Replacing with: '$correctLine'"
        
        $newBicepContent = $bicepContent -replace [regex]::Escape($lineToReplace), $correctLine
        
        Write-Host "Step 4: Saving the corrected Bicep file..."
        Set-Content -Path $bicepFilePath -Value $newBicepContent

        Write-Host ""
        Write-Host "SUCCESS: The main.bicep file has been corrected." -ForegroundColor Green
        Write-Host "The IaC template is now aligned with enterprise security best practices."

    } else {
        Write-Host "NOTICE: The Bicep file appears to already be corrected. No changes made." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "---"
Write-Host "NEXT ACTION: Commit the updated 'main.bicep' file and push to GitHub."
Write-Host "The GitHub Actions pipeline will then deploy the corrected infrastructure."
Write-Host "---"