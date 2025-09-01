# Fixed Claude Desktop Configuration for PDF AI Agent MCP Server
# This uses a simpler Node.js bridge approach that should work better

Write-Host "Configuring Claude Desktop with fixed MCP server connection..." -ForegroundColor Green

# First, let's find the correct Node.js path
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "Node.js not found in PATH. Checking common locations..." -ForegroundColor Yellow
    
    $commonNodePaths = @(
        "$env:ProgramFiles\nodejs\node.exe",
        "$env:ProgramFiles(x86)\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
    )
    
    foreach ($path in $commonNodePaths) {
        if (Test-Path $path) {
            $nodePath = @{ Source = $path }
            Write-Host "Found Node.js at: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $nodePath) {
        Write-Host "ERROR: Node.js not found. Please install Node.js from https://nodejs.org" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Using Node.js at: $($nodePath.Source)" -ForegroundColor Green

# Define the Claude Desktop config directory path
$claudeConfigDir = "$env:APPDATA\Claude"
if (-Not (Test-Path $claudeConfigDir)) {
    New-Item -ItemType Directory -Path $claudeConfigDir -Force
}

# Create a temporary bridge script file
$bridgeScriptPath = "$claudeConfigDir\mcp-bridge.js"
$bridgeScript = @"
const https = require('https');
const readline = require('readline');

const baseUrl = 'https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
});

function sendResponse(id, result = null, error = null) {
    const response = {
        jsonrpc: '2.0',
        id: id
    };
    
    if (error) {
        response.error = error;
    } else {
        response.result = result;
    }
    
    console.log(JSON.stringify(response));
}

function makeHttpRequest(endpoint, data, requestId) {
    const postData = JSON.stringify(data);
    
    const options = {
        hostname: 'func-pdfai-dev-tjqwgu4v.azurewebsites.net',
        port: 443,
        path: '/api/mcp' + endpoint,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        }
    };
    
    const req = https.request(options, (res) => {
        let responseData = '';
        res.on('data', (chunk) => {
            responseData += chunk;
        });
        
        res.on('end', () => {
            try {
                const parsed = JSON.parse(responseData);
                sendResponse(requestId, parsed);
            } catch (e) {
                sendResponse(requestId, null, {
                    code: -32603,
                    message: 'Failed to parse server response'
                });
            }
        });
    });
    
    req.on('error', (error) => {
        sendResponse(requestId, null, {
            code: -32603,
            message: error.message
        });
    });
    
    req.write(postData);
    req.end();
}

rl.on('line', (line) => {
    try {
        const request = JSON.parse(line);
        
        if (request.method === 'initialize') {
            sendResponse(request.id, {
                protocolVersion: '2024-11-05',
                capabilities: {
                    tools: {}
                },
                serverInfo: {
                    name: 'PDF AI Agent MCP Server',
                    version: '1.0.0'
                }
            });
        } else if (request.method === 'tools/list') {
            makeHttpRequest('/tools/list', {}, request.id);
        } else if (request.method === 'tools/call') {
            makeHttpRequest('/tools/call', {
                name: request.params?.name || '',
                arguments: request.params?.arguments || {}
            }, request.id);
        } else {
            sendResponse(request.id, null, {
                code: -32601,
                message: 'Method not found'
            });
        }
    } catch (error) {
        sendResponse(1, null, {
            code: -32700,
            message: 'Parse error'
        });
    }
});
"@

Write-Host "Creating MCP bridge script at: $bridgeScriptPath" -ForegroundColor Yellow
$bridgeScript | Out-File -FilePath $bridgeScriptPath -Encoding UTF8

# Create the simplified configuration
$config = @{
    mcpServers = @{
        "pdf-ai-agent" = @{
            command = $nodePath.Source
            args = @($bridgeScriptPath)
        }
    }
}

$configFile = "$claudeConfigDir\claude_desktop_config.json"
$configJson = $config | ConvertTo-Json -Depth 10

Write-Host "Writing simplified configuration to: $configFile" -ForegroundColor Yellow
$configJson | Out-File -FilePath $configFile -Encoding UTF8

Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "- Config: $configFile" -ForegroundColor White
Write-Host "- Bridge: $bridgeScriptPath" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close Claude Desktop completely" -ForegroundColor White
Write-Host "2. Restart Claude Desktop" -ForegroundColor White
Write-Host "3. Check MCP server status in Settings > Features > MCP Servers" -ForegroundColor White
Write-Host "4. Test with a new conversation" -ForegroundColor White
Write-Host ""
Write-Host "Test the connection by asking:" -ForegroundColor Yellow
Write-Host '"What MCP tools are available to help me process documents?"' -ForegroundColor White