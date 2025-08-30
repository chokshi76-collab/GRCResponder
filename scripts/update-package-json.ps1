# Update package.json to include @azure/functions dependency
# Skip local npm install - let GitHub Actions handle it

Write-Host "Updating package.json for Azure Functions..." -ForegroundColor Yellow

$workingDir = "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"
Set-Location $workingDir

$packageJsonPath = "src\mcp-server\package.json"

# Read current package.json
$packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json

# Add @azure/functions to dependencies if not present
if (-not $packageJson.dependencies."@azure/functions") {
    Write-Host "Adding @azure/functions to package.json..." -ForegroundColor Green
    
    # Add the dependency
    $packageJson.dependencies | Add-Member -MemberType NoteProperty -Name "@azure/functions" -Value "^4.0.0"
    
    # Convert back to JSON and save
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath -Encoding UTF8
    
    Write-Host "✅ @azure/functions added to package.json" -ForegroundColor Green
} else {
    Write-Host "✅ @azure/functions already in package.json" -ForegroundColor Green
}

# Show the updated dependencies
Write-Host "`nCurrent dependencies:" -ForegroundColor Cyan
$packageJson.dependencies | Format-Table

# Commit the package.json change
Write-Host "Committing package.json update..." -ForegroundColor Green
git add src/mcp-server/package.json
git commit -m "Add @azure/functions dependency to package.json"
git push origin main

Write-Host "`n✅ DEPENDENCY MANAGEMENT STRATEGY:" -ForegroundColor Green
Write-Host "• Local machine: NO npm install (we skip this)" -ForegroundColor White
Write-Host "• GitHub Actions: Handles ALL dependency installation" -ForegroundColor White
Write-Host "• This prevents local environment issues" -ForegroundColor White

Write-Host "`n=== MONITORING ===" -ForegroundColor Cyan
Write-Host "Watch GitHub Actions: https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor Yellow
Write-Host "Look for:" -ForegroundColor White
Write-Host "  ✅ Install dependencies (should include @azure/functions)" -ForegroundColor White
Write-Host "  ✅ Build TypeScript" -ForegroundColor White
Write-Host "  ✅ Deploy to Azure Function App" -ForegroundColor White