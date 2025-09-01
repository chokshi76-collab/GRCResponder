# Configure Claude Desktop for PDF AI Agent MCP Server
# This script sets up Claude Desktop to connect to the deployed Azure Function App MCP server

Write-Host "Configuring Claude Desktop for PDF AI Agent MCP Server..." -ForegroundColor Green

# Define the Claude Desktop config directory path
$claudeConfigDir = "$env:APPDATA\Claude"

# Create the directory if it doesn't exist
if (-Not (Test-Path $claudeConfigDir)) {
    Write-Host "Creating Claude config directory: $claudeConfigDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $claudeConfigDir -Force
}

# Define the config file path
$configFile = "$claudeConfigDir\claude_desktop_config.json"

# Create the configuration content
$config = @{
    mcpServers = @{
        "pdf-ai-agent" = @{
            command = "node"
            args = @(
                "-e",
                @"
const https = require('https');
const url = require('url');

const baseUrl = 'https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp';

process.stdin.on('data', async (data) => {
    try {
        const request = JSON.parse(data.toString());
        let endpoint, method = 'POST', body;
        
        if (request.method === 'tools/list') {
            endpoint = '/tools/list';
            body = JSON.stringify({});
        } else if (request.method === 'tools/call') {
            endpoint = '/tools/call';
            body = JSON.stringify({
                name: request.params?.name || '',
                arguments: request.params?.arguments || {}
            });
        } else if (request.method === 'initialize') {
            process.stdout.write(JSON.stringify({
                jsonrpc: '2.0',
                id: request.id,
                result: {
                    protocolVersion: '2024-11-05',
                    capabilities: { tools: {} },
                    serverInfo: {
                        name: 'PDF AI Agent MCP Server',
                        version: '1.0.0'
                    }
                }
            }) + '\n');
            return;
        } else {
            process.stdout.write(JSON.stringify({
                jsonrpc: '2.0',
                id: request.id,
                error: { code: -32601, message: 'Method not found' }
            }) + '\n');
            return;
        }
        
        const urlObj = url.parse(baseUrl + endpoint);
        const options = {
            hostname: urlObj.hostname,
            port: urlObj.port || 443,
            path: urlObj.path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body)
            }
        };
        
        const req = https.request(options, (res) => {
            let responseData = '';
            res.on('data', (chunk) => responseData += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(responseData);
                    process.stdout.write(JSON.stringify({
                        jsonrpc: '2.0',
                        id: request.id,
                        result: parsed
                    }) + '\n');
                } catch (e) {
                    process.stdout.write(JSON.stringify({
                        jsonrpc: '2.0',
                        id: request.id,
                        error: { code: -32603, message: 'Parse error' }
                    }) + '\n');
                }
            });
        });
        
        req.on('error', (error) => {
            process.stdout.write(JSON.stringify({
                jsonrpc: '2.0',
                id: request.id,
                error: { code: -32603, message: error.message }
            }) + '\n');
        });
        
        req.write(body);
        req.end();
        
    } catch (error) {
        process.stdout.write(JSON.stringify({
            jsonrpc: '2.0',
            id: 1,
            error: { code: -32700, message: 'Parse error' }
        }) + '\n');
    }
});
"@
            )
        }
    }
} | ConvertTo-Json -Depth 10

# Write the configuration to the file
Write-Host "Writing configuration to: $configFile" -ForegroundColor Yellow
$config | Out-File -FilePath $configFile -Encoding UTF8

Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart Claude Desktop application" -ForegroundColor White
Write-Host "2. Open a new conversation" -ForegroundColor White
Write-Host "3. Test the connection by asking Claude to list available MCP tools" -ForegroundColor White
Write-Host ""
Write-Host "Expected MCP tools that should be available:" -ForegroundColor Cyan
Write-Host "- process_pdf (PDF document analysis)" -ForegroundColor White
Write-Host "- analyze_csv (CSV data analysis and storage)" -ForegroundColor White
Write-Host "- scrape_website (Web scraping capabilities)" -ForegroundColor White
Write-Host "- search_documents (Vector document search)" -ForegroundColor White
Write-Host "- query_csv_data (SQL database querying)" -ForegroundColor White
Write-Host ""
Write-Host "MCP Server URL: https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp" -ForegroundColor Yellow