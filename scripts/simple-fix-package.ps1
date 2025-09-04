# Simple fix for package.json syntax error
cd "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "Checking current package.json..." -ForegroundColor Yellow
Get-Content "src/mcp-server/package.json" | Select-Object -Skip 15 -First 20

Write-Host "`nCreating corrected package.json..." -ForegroundColor Green

# Create the JSON content as a single string with proper escaping
$jsonContent = '{
  "name": "pdf-ai-agent-mcp",
  "version": "1.0.0",
  "description": "PDF AI Agent MCP Server with Azure backend for PDF processing, CSV analysis, and web scraping",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "start": "node dist/index.js",
    "clean": "rimraf dist",
    "watch": "tsc --watch",
    "install-deps": "npm install"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.6.0",
    "@azure/keyvault-secrets": "^4.8.0",
    "@azure/identity": "^4.0.1",
    "@azure/ai-form-recognizer": "^5.0.0",
    "@azure/search-documents": "^12.1.0",
    "@azure/storage-blob": "^12.24.0",
    "mssql": "^10.0.2",
    "puppeteer": "^21.11.0",
    "csv-parser": "^3.0.0",
    "csv-stringify": "^6.4.6",
    "@azure/functions": "^4.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/mssql": "^9.1.5",
    "typescript": "^5.3.3",
    "tsx": "^4.7.0",
    "rimraf": "^5.0.5"
  },
  "engines": {
    "node": ">=18.0.0"
  },
  "keywords": [
    "mcp",
    "pdf",
    "ai",
    "azure",
    "document-intelligence",
    "csv",
    "web-scraping"
  ],
  "author": "PDF AI Agent",
  "license": "MIT"
}'

# Write the corrected package.json
$jsonContent | Out-File -FilePath "src/mcp-server/package.json" -Encoding UTF8

Write-Host "Package.json has been corrected!" -ForegroundColor Green

# Validate the JSON
Write-Host "`nValidating JSON syntax..." -ForegroundColor Cyan
try {
    $testJson = Get-Content "src/mcp-server/package.json" -Raw | ConvertFrom-Json
    Write-Host "✅ JSON syntax is now valid!" -ForegroundColor Green
    Write-Host "Dependencies count: $($testJson.dependencies.PSObject.Properties.Count)"
} catch {
    Write-Host "❌ JSON still has issues: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nNext: Commit and deploy" -ForegroundColor Yellow
Write-Host "git add src/mcp-server/package.json"
Write-Host "git commit -m 'Fix package.json syntax for Azure storage blob dependency'"
Write-Host "git push origin main"