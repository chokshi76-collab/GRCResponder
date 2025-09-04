# Navigate to repository directory
cd "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "Checking package.json syntax..." -ForegroundColor Yellow

# First, let's see the current package.json content around the error area
Write-Host "`nChecking package.json for syntax errors..." -ForegroundColor Cyan
Get-Content "src/mcp-server/package.json" | Select-Object -Skip 20 -First 15

Write-Host "`nValidating JSON syntax..." -ForegroundColor Cyan
try {
    $packageContent = Get-Content "src/mcp-server/package.json" -Raw
    $packageJson = $packageContent | ConvertFrom-Json
    Write-Host "✅ JSON syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "❌ JSON syntax error found:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    Write-Host "`nMost common issues to check:" -ForegroundColor Yellow
    Write-Host "1. Missing comma after a dependency"
    Write-Host "2. Extra comma at end of dependencies list"
    Write-Host "3. Mismatched quotes"
    Write-Host "4. Missing closing braces"
}

Write-Host "`n🔧 Creating corrected package.json..." -ForegroundColor Green

# Create the corrected package.json content
$correctedPackageJson = @"
{
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
}
"@

# Write the corrected package.json
$correctedPackageJson | Out-File -FilePath "src/mcp-server/package.json" -Encoding UTF8

Write-Host "✅ Corrected package.json created" -ForegroundColor Green

Write-Host "`nValidating the corrected JSON..." -ForegroundColor Cyan
try {
    $newPackageContent = Get-Content "src/mcp-server/package.json" -Raw
    $newPackageJson = $newPackageContent | ConvertFrom-Json
    Write-Host "✅ Corrected JSON syntax is valid" -ForegroundColor Green
    Write-Host "Dependencies count: $($newPackageJson.dependencies.PSObject.Properties.Count)"
} catch {
    Write-Host "❌ Still has JSON syntax error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Commit the fixed package.json"
Write-Host "2. Push to trigger deployment"
Write-Host "3. Watch GitHub Actions for successful build"

Write-Host "`nCommit commands:" -ForegroundColor Green
Write-Host "git add src/mcp-server/package.json"
Write-Host "git commit -m `"Fix package.json syntax error for Azure storage blob dependency`""
Write-Host "git push origin main"