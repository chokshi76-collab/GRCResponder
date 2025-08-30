# Deploy HTTP-enabled MCP Server to Azure Function App
# This fixes the 404 errors by adding proper HTTP triggers

Write-Host "Deploying HTTP-enabled MCP Server..." -ForegroundColor Yellow

$workingDir = "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"
Set-Location $workingDir

# Step 1: Create function.json file
Write-Host "1. Creating function.json configuration..." -ForegroundColor Green
$functionDir = "src\mcp-server\src"
if (-not (Test-Path $functionDir)) {
    New-Item -ItemType Directory -Path $functionDir -Force
}

# Copy the function.json content to the correct location
$functionJsonPath = "$functionDir\function.json"
$functionJsonContent = @'
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"],
      "route": "mcp/{*path}"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ],
  "scriptFile": "../dist/index.js"
}
'@

Set-Content -Path $functionJsonPath -Value $functionJsonContent -Encoding UTF8
Write-Host "✅ function.json created at: $functionJsonPath" -ForegroundColor Green

# Step 2: Update package.json to include @azure/functions
Write-Host "2. Adding Azure Functions dependencies..." -ForegroundColor Green
Set-Location "src\mcp-server"

# Check if @azure/functions is in package.json
$packageJson = Get-Content "package.json" | ConvertFrom-Json
if (-not ($packageJson.dependencies."@azure/functions")) {
    npm install @azure/functions --save
    Write-Host "✅ Added @azure/functions dependency" -ForegroundColor Green
} else {
    Write-Host "✅ @azure/functions already installed" -ForegroundColor Green
}

# Step 3: Replace the index.ts file with HTTP version
Write-Host "3. Updating index.ts for HTTP triggers..." -ForegroundColor Green
# The new index.ts content is in the artifact above - copy it manually or use the artifact

# Step 4: Commit and push changes
Write-Host "4. Committing changes to GitHub..." -ForegroundColor Green
Set-Location $workingDir
git add .
git commit -m "Fix: Add HTTP triggers for Azure Function App - resolve 404 errors"
git push origin main

Write-Host "✅ Changes pushed to GitHub" -ForegroundColor Green

# Step 5: Wait for GitHub Actions to complete
Write-Host "5. Monitoring GitHub Actions deployment..." -ForegroundColor Green
Write-Host "Check: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Cyan

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Wait for GitHub Actions to complete (watch for green checkmark)" -ForegroundColor White
Write-Host "2. Test endpoints again with: .\scripts\test-mcp-server-endpoint.ps1" -ForegroundColor White
Write-Host "3. Expected working URLs:" -ForegroundColor White
Write-Host "   - GET  https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp" -ForegroundColor Yellow
Write-Host "   - POST https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp/tools/list" -ForegroundColor Yellow
Write-Host "   - POST https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api/mcp/tools/call" -ForegroundColor Yellow