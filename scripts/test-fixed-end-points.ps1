# Test the fixed MCP Server HTTP endpoints
# Should now work with proper Azure Functions v4 implementation

Write-Host "Testing Fixed MCP Server Endpoints..." -ForegroundColor Yellow

$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net"

# Test 1: Health check endpoint
Write-Host "`n1. Testing health check..." -ForegroundColor Green
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/api/mcp" -Method GET -TimeoutSec 30
    Write-Host "✅ Health check successful!" -ForegroundColor Green
    Write-Host "Service: $($healthResponse.service)" -ForegroundColor Cyan
    Write-Host "Status: $($healthResponse.status)" -ForegroundColor Cyan
    Write-Host "Version: $($healthResponse.version)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: List tools endpoint
Write-Host "`n2. Testing tools list..." -ForegroundColor Green
try {
    $toolsResponse = Invoke-RestMethod -Uri "$baseUrl/api/mcp/tools/list" -Method POST -ContentType "application/json" -Body "{}" -TimeoutSec 30
    Write-Host "✅ Tools list successful!" -ForegroundColor Green
    Write-Host "Available tools:" -ForegroundColor Cyan
    foreach ($tool in $toolsResponse.tools) {
        Write-Host "  • $($tool.name): $($tool.description)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Tools list failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Execute a tool
Write-Host "`n3. Testing tool execution..." -ForegroundColor Green
$testToolPayload = @{
    name = "process_pdf"
    arguments = @{
        pdf_url = "https://example.com/test.pdf"
    }
} | ConvertTo-Json

try {
    $toolResponse = Invoke-RestMethod -Uri "$baseUrl/api/mcp/tools/call" -Method POST -ContentType "application/json" -Body $testToolPayload -TimeoutSec 30
    Write-Host "✅ Tool execution successful!" -ForegroundColor Green
    Write-Host "Response: $($toolResponse.content[0].text)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Tool execution failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== RESULTS SUMMARY ===" -ForegroundColor Yellow
Write-Host "If all tests passed, your MCP server is working correctly!" -ForegroundColor Green
Write-Host "Ready for Claude Desktop integration" -ForegroundColor Green

Write-Host "`n=== NEXT PHASE ===" -ForegroundColor Cyan
Write-Host "1. Configure Claude Desktop MCP connection" -ForegroundColor White
Write-Host "2. Test all 5 tools from Claude Desktop" -ForegroundColor White
Write-Host "3. Implement real Azure service integrations" -ForegroundColor White

Write-Host "`nMCP Server Endpoints:" -ForegroundColor Yellow
Write-Host "• Health: GET  $baseUrl/api/mcp" -ForegroundColor White
Write-Host "• Tools:  POST $baseUrl/api/mcp/tools/list" -ForegroundColor White  
Write-Host "• Call:   POST $baseUrl/api/mcp/tools/call" -ForegroundColor White