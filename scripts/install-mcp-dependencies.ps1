# Install MCP Server Dependencies
Write-Host "Installing MCP Server dependencies..." -ForegroundColor Green

# Navigate to MCP server directory
Set-Location "src/mcp-server"

Write-Host "1. Installing production dependencies..." -ForegroundColor Yellow
npm install @modelcontextprotocol/sdk@^0.6.0
npm install @azure/keyvault-secrets@^4.8.0
npm install @azure/identity@^4.0.1
npm install @azure/ai-form-recognizer@^5.0.0
npm install @azure/search-documents@^12.1.0
npm install mssql@^10.0.2
npm install puppeteer@^21.11.0
npm install csv-parser@^3.0.0
npm install csv-stringify@^6.4.6

Write-Host "2. Installing development dependencies..." -ForegroundColor Yellow
npm install --save-dev @types/node@^20.11.0
npm install --save-dev @types/mssql@^9.1.5
npm install --save-dev typescript@^5.3.3
npm install --save-dev tsx@^4.7.0
npm install --save-dev rimraf@^5.0.5

Write-Host "3. Creating TypeScript configuration..." -ForegroundColor Yellow

# Return to root directory
Set-Location "../.."

Write-Host "SUCCESS: All dependencies installed!" -ForegroundColor Green
Write-Host "Next: Create TypeScript config and main MCP server file" -ForegroundColor Yellow