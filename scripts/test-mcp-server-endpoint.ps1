# Test MCP Server Deployment on Azure Function App
# Run this to verify the deployed MCP server is responding

Write-Host "Testing MCP Server Deployment..." -ForegroundColor Yellow

$functionAppName = "func-pdfai-dev-tjqwgu4v"
$baseUrl = "https://$functionAppName.azurewebsites.net"

Write-Host "Function App URL: $baseUrl" -ForegroundColor Cyan

# Test 1: Basic health check
Write-Host "`n1. Testing basic endpoint..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api" -Method GET -TimeoutSec 30
    Write-Host "✅ Basic endpoint responded" -ForegroundColor Green
    Write-Host "Response: $response"
} catch {
    Write-Host "❌ Basic endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check if MCP server is accessible
Write-Host "`n2. Testing MCP server endpoint..." -ForegroundColor Green
try {
    $mcpResponse = Invoke-RestMethod -Uri "$baseUrl/api/mcp" -Method GET -TimeoutSec 30
    Write-Host "✅ MCP endpoint responded" -ForegroundColor Green
    Write-Host "Response: $mcpResponse"
} catch {
    Write-Host "❌ MCP endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check Function App logs
Write-Host "`n3. Checking Function App status..." -ForegroundColor Green
try {
    az functionapp show --name $functionAppName --resource-group "pdf-ai-agent-rg-dev" --query "{name:name, state:state, hostNames:hostNames}" --output table
    Write-Host "✅ Function App details retrieved" -ForegroundColor Green
} catch {
    Write-Host "❌ Could not retrieve Function App status" -ForegroundColor Red
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "If endpoints are responding:" -ForegroundColor Yellow
Write-Host "1. Configure Claude Desktop to connect to: $baseUrl" -ForegroundColor White
Write-Host "2. Test all 5 MCP tools (process_pdf, analyze_csv, etc.)" -ForegroundColor White
Write-Host "3. Implement real Azure service integrations" -ForegroundColor White

Write-Host "`nIf endpoints are not responding:" -ForegroundColor Yellow
Write-Host "1. Check Azure Function App logs in portal" -ForegroundColor White
Write-Host "2. Verify function.json configuration" -ForegroundColor White
Write-Host "3. Ensure proper HTTP triggers are set up" -ForegroundColor White