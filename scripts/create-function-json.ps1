# Create function.json in the correct location for Azure Functions

Write-Host "Creating function.json for Azure Function App..." -ForegroundColor Yellow

$workingDir = "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"
Set-Location $workingDir

# Azure Functions expects this structure:
# src/mcp-server/
# ├── mcp/                    <- Function name (can be any name)
# │   ├── function.json       <- HTTP trigger configuration
# │   └── index.js           <- Compiled TypeScript output
# ├── src/
# │   └── index.ts           <- Your TypeScript source
# └── package.json

# Step 1: Create the function directory
$functionDir = "src\mcp-server\mcp"
Write-Host "Creating function directory: $functionDir" -ForegroundColor Green

if (-not (Test-Path $functionDir)) {
    New-Item -ItemType Directory -Path $functionDir -Force
    Write-Host "✅ Created directory: $functionDir" -ForegroundColor Green
} else {
    Write-Host "✅ Directory already exists: $functionDir" -ForegroundColor Green
}

# Step 2: Create function.json
$functionJsonPath = "$functionDir\function.json"
Write-Host "Creating function.json at: $functionJsonPath" -ForegroundColor Green

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
Write-Host "✅ function.json created successfully!" -ForegroundColor Green

# Step 3: Show the file structure
Write-Host "`nCurrent file structure:" -ForegroundColor Cyan
tree $workingDir\src\mcp-server /F

# Step 4: Verify file contents
Write-Host "`nfunction.json contents:" -ForegroundColor Cyan
Get-Content $functionJsonPath

Write-Host "`n=== WHAT THIS DOES ===" -ForegroundColor Yellow
Write-Host "• Creates HTTP trigger for Azure Functions" -ForegroundColor White
Write-Host "• Maps requests to /api/mcp/* routes" -ForegroundColor White
Write-Host "• Points to compiled JavaScript at ../dist/index.js" -ForegroundColor White
Write-Host "• Allows anonymous access (no authentication required)" -ForegroundColor White

Write-Host "`n=== NEXT STEP ===" -ForegroundColor Cyan
Write-Host "Now update your index.ts file with the HTTP-enabled version, then commit and push!" -ForegroundColor White