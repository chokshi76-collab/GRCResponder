# Debug deployment issues
Write-Host "Debugging deployment issues..." -ForegroundColor Yellow

# First, let's validate the template
Write-Host "1. Validating Bicep template..." -ForegroundColor Cyan
az deployment group validate `
  --resource-group "pdf-ai-agent-rg-dev" `
  --template-file "infrastructure/bicep/main.bicep" `
  --parameters "infrastructure/bicep/parameters.dev.json" `
  --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Template validation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "2. Checking if parameters file exists..." -ForegroundColor Cyan
if (Test-Path "infrastructure/bicep/parameters.dev.json") {
    Write-Host "Parameters file exists" -ForegroundColor Green
    Get-Content "infrastructure/bicep/parameters.dev.json"
} else {
    Write-Host "Parameters file NOT found!" -ForegroundColor Red
    Write-Host "Creating minimal parameters file..." -ForegroundColor Yellow
    
    $parametersContent = @{
        '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        contentVersion = "1.0.0.0"
        parameters = @{
            environmentName = @{
                value = "dev"
            }
        }
    }
    
    $parametersContent | ConvertTo-Json -Depth 10 | Out-File "infrastructure/bicep/parameters.dev.json" -Encoding UTF8
    Write-Host "Created parameters file" -ForegroundColor Green
}

Write-Host "3. Checking resource group..." -ForegroundColor Cyan
az group show --name "pdf-ai-agent-rg-dev" --output table

Write-Host "4. Testing simple deployment (what-if)..." -ForegroundColor Cyan
az deployment group what-if `
  --resource-group "pdf-ai-agent-rg-dev" `
  --template-file "infrastructure/bicep/main.bicep" `
  --parameters "infrastructure/bicep/parameters.dev.json" `
  --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980"