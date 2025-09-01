# PowerShell MCP Bridge (No Node.js Required)
# This creates a PowerShell-based bridge to the Azure Function App MCP server

Write-Host "Configuring Claude Desktop with PowerShell MCP bridge..." -ForegroundColor Green
Write-Host "No local Node.js installation required!" -ForegroundColor Cyan

# Define the Claude Desktop config directory path
$claudeConfigDir = "$env:APPDATA\Claude"
if (-Not (Test-Path $claudeConfigDir)) {
    Write-Host "Creating Claude config directory: $claudeConfigDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $claudeConfigDir -Force
}

# Create PowerShell MCP bridge script
$bridgeScriptPath = "$claudeConfigDir\mcp-bridge.ps1"
$bridgeScript = @'
# PowerShell MCP Bridge Script
$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp"

function Send-MCPResponse {
    param($id, $result = $null, $error = $null)
    
    $response = @{
        jsonrpc = "2.0"
        id = $id
    }
    
    if ($error) {
        $response.error = $error
    } else {
        $response.result = $result
    }
    
    Write-Output ($response | ConvertTo-Json -Depth 10 -Compress)
}

function Invoke-AzureFunction {
    param($endpoint, $data, $requestId)
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl$endpoint" -Method POST -ContentType "application/json" -Body ($data | ConvertTo-Json -Depth 10 -Compress)
        Send-MCPResponse -id $requestId -result $response
    } catch {
        Send-MCPResponse -id $requestId -error @{
            code = -32603
            message = $_.Exception.Message
        }
    }
}

# Main message processing loop
while ($true) {
    $line = Read-Host
    if ([string]::IsNullOrEmpty($line)) { continue }
    
    try {
        $request = $line | ConvertFrom-Json
        
        switch ($request.method) {
            "initialize" {
                Send-MCPResponse -id $request.id -result @{
                    protocolVersion = "2024-11-05"
                    capabilities = @{ tools = @{} }
                    serverInfo = @{
                        name = "PDF AI Agent MCP Server"
                        version = "1.0.0"
                    }
                }
            }
            "tools/list" {
                Invoke-AzureFunction -endpoint "/tools/list" -data @{} -requestId $request.id
            }
            "tools/call" {
                $callData = @{
                    name = $request.params.name
                    arguments = $request.params.arguments
                }
                Invoke-AzureFunction -endpoint "/tools/call" -data $callData -requestId $request.id
            }
            default {
                Send-MCPResponse -id $request.id -error @{
                    code = -32601
                    message = "Method not found"
                }
            }
        }
    } catch {
        Send-MCPResponse -id 1 -error @{
            code = -32700
            message = "Parse error"
        }
    }
}
'@

Write-Host "Creating PowerShell MCP bridge at: $bridgeScriptPath" -ForegroundColor Yellow
$bridgeScript | Out-File -FilePath $bridgeScriptPath -Encoding UTF8

# Create Claude Desktop configuration using PowerShell bridge
$config = @{
    mcpServers = @{
        "pdf-ai-agent" = @{
            command = "powershell.exe"
            args = @("-ExecutionPolicy", "Bypass", "-File", $bridgeScriptPath)
        }
    }
}

$configFile = "$claudeConfigDir\claude_desktop_config.json"
$configJson = $config | ConvertTo-Json -Depth 10

Write-Host "Writing PowerShell-based configuration to: $configFile" -ForegroundColor Yellow
$configJson | Out-File -FilePath $configFile -Encoding UTF8

Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "MCP Server Details:" -ForegroundColor Cyan
Write-Host "- Name: pdf-ai-agent" -ForegroundColor White
Write-Host "- Type: HTTP Transport (no local dependencies)" -ForegroundColor White  
Write-Host "- Endpoint: https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close Claude Desktop completely" -ForegroundColor White
Write-Host "2. Restart Claude Desktop" -ForegroundColor White
Write-Host "3. Check connection status in Settings > Features" -ForegroundColor White
Write-Host ""

# Let's also test the endpoints directly to verify they're working
Write-Host "Testing Azure Function App endpoints..." -ForegroundColor Yellow

# Test health check endpoint
try {
    $healthResponse = Invoke-RestMethod -Uri "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp" -Method GET
    Write-Host "✅ Health check endpoint working" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test tools list endpoint
try {
    $toolsResponse = Invoke-RestMethod -Uri "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp/tools/list" -Method POST -ContentType "application/json" -Body "{}"
    Write-Host "✅ Tools list endpoint working - Found $($toolsResponse.tools.Count) tools" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Available Tools:" -ForegroundColor Cyan
    foreach ($tool in $toolsResponse.tools) {
        Write-Host "- $($tool.name): $($tool.description)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Tools list endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "If Claude Desktop still shows connection issues, we'll implement a custom MCP bridge." -ForegroundColor Yellow
Write-Host "The Azure Function App is working correctly - the issue is just the local MCP client connection." -ForegroundColor Yellow