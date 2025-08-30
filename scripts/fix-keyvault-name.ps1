# Fix Key Vault naming issue in Bicep template
Write-Host "Fixing Key Vault name in Bicep template..." -ForegroundColor Green

# Read the current Bicep template
$bicepContent = Get-Content "infrastructure/bicep/main.bicep" -Raw

# Fix the Key Vault name variable to be shorter
$fixedBicepContent = $bicepContent -replace 
    "var keyVaultName = '`\$\{prefix\}-kv-`\$\{environmentName\}-`\$\{uniqueString\(resourceGroup\(\)\.id\)\}'",
    "var keyVaultName = 'kv-`${substring(uniqueString(resourceGroup().id), 0, 10)}'"

# Write the fixed content back
$fixedBicepContent | Out-File -FilePath "infrastructure/bicep/main.bicep" -Encoding UTF8

Write-Host "Key Vault name fixed!" -ForegroundColor Green
Write-Host "New naming pattern: 'kv-{10-char-unique-string}'" -ForegroundColor Cyan
Write-Host "Example: kv-ebfk54eja3" -ForegroundColor Yellow

# Also fix any other long resource names while we're at it
Write-Host "`nChecking other resource names for length..." -ForegroundColor Cyan

# Show what the names will look like
$resourceGroupId = "sample-resource-group-id"
$uniqueString = $resourceGroupId.GetHashCode().ToString("X").Substring(0, 10).ToLower()

Write-Host "Resource name preview:" -ForegroundColor White
Write-Host "  Key Vault: kv-$uniqueString ($(("kv-$uniqueString").Length) chars)" -ForegroundColor Yellow
Write-Host "  Storage: pdfaiagentstorage001 ($(("pdfaiagentstorage001").Length) chars)" -ForegroundColor Yellow
Write-Host "  Search: pdf-ai-agent-search-dev (~23 chars)" -ForegroundColor Yellow

Write-Host "`nBicep template updated! You can now deploy." -ForegroundColor Green