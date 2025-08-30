# Test minimal Bicep deployment
Write-Host "Testing minimal Bicep template..." -ForegroundColor Yellow

# First validate the minimal template
Write-Host "1. Validating minimal template..." -ForegroundColor Cyan
az deployment group validate `
  --resource-group "pdf-ai-agent-rg-dev" `
  --template-file "infrastructure/bicep/minimal-test.bicep" `
  --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980"

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Minimal template validation passed!" -ForegroundColor Green
    
    # Try deploying the minimal template
    Write-Host "2. Deploying minimal template..." -ForegroundColor Cyan
    az deployment group create `
      --resource-group "pdf-ai-agent-rg-dev" `
      --template-file "infrastructure/bicep/minimal-test.bicep" `
      --parameters userObjectId="402ed151-67f7-4f36-bc74-ac2b9c9e1980" `
      --name "minimal-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
      
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Minimal deployment worked!" -ForegroundColor Green
        Write-Host "The issue is in the main.bicep template" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Even minimal deployment failed" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: Minimal template validation failed" -ForegroundColor Red
}