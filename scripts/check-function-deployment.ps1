# Check Azure Function App deployment status
$functionAppName = "func-pdfai-dev-tjqwgu4v"
$resourceGroup = "pdf-ai-agent-rg-dev"

Write-Host "=== CHECKING FUNCTION APP DEPLOYMENT STATUS ===" -ForegroundColor Green

# Check if Function App is running
Write-Host "`nChecking Function App status..." -ForegroundColor Yellow
az functionapp show --name $functionAppName --resource-group $resourceGroup --query "{name:name,state:state,defaultHostName:defaultHostName}" --output table

# Check deployment source
Write-Host "`nChecking deployment source configuration..." -ForegroundColor Yellow
az functionapp deployment source show --name $functionAppName --resource-group $resourceGroup

# Check recent deployments
Write-Host "`nChecking deployment history..." -ForegroundColor Yellow
az functionapp deployment list --name $functionAppName --resource-group $resourceGroup --query "[].{id:id,status:status,author:author,deploymentTime:receivedTime}" --output table

# Check function app logs
Write-Host "`nChecking recent logs..." -ForegroundColor Yellow
az functionapp logs tail --name $functionAppName --resource-group $resourceGroup --timeout 30

# Check if MCP server endpoint is accessible
Write-Host "`nTesting Function App endpoint..." -ForegroundColor Yellow
$functionUrl = "https://$functionAppName.azurewebsites.net"
Write-Host "Function App URL: $functionUrl"

try {
    $response = Invoke-WebRequest -Uri $functionUrl -Method GET -TimeoutSec 10
    Write-Host "✅ Function App is accessible - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Function App not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. If no GitHub deployment detected, we'll deploy manually"
Write-Host "2. Check if .github/workflows directory exists in your repo"
Write-Host "3. Implement actual MCP tool functions"