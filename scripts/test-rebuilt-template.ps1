# Test the fixed main.bicep template
Write-Host "Testing fixed main.bicep template..." -ForegroundColor Yellow

# First validate
Write-Host "1. Validating fixed template..." -ForegroundColor Cyan
az deployment group validate `
  --resource-group "pdf-ai-agent-rg-dev" `
  --template-file "infrastructure/bicep/main.bicep" `
  --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980"

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Template validation passed!" -ForegroundColor Green
    
    Write-Host "2. Running what-if analysis..." -ForegroundColor Cyan
    az deployment group what-if `
      --resource-group "pdf-ai-agent-rg-dev" `
      --template-file "infrastructure/bicep/main.bicep" `
      --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980"
      
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: What-if analysis completed!" -ForegroundColor Green
        Write-Host "Template is ready for deployment!" -ForegroundColor Green
    }
} else {
    Write-Host "ERROR: Template validation failed" -ForegroundColor Red
}