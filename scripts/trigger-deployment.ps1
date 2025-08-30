# Trigger GitHub Actions deployment by making a small change to the MCP server
Write-Host "=== TRIGGERING GITHUB ACTIONS DEPLOYMENT ===" -ForegroundColor Green

# Add a comment to the index.ts file to trigger the workflow
$indexFile = "src/mcp-server/src/index.ts"

if (Test-Path $indexFile) {
    Write-Host "`n1. Adding deployment trigger comment to index.ts..." -ForegroundColor Yellow
    
    # Read the current content
    $content = Get-Content $indexFile -Raw
    
    # Add a timestamp comment at the top
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $triggerComment = "// Deployment triggered: $timestamp`n"
    
    # Prepend the comment
    $newContent = $triggerComment + $content
    
    # Write back to file
    $newContent | Out-File $indexFile -Encoding UTF8
    
    Write-Host "✅ Added trigger comment to index.ts" -ForegroundColor Green
    
    # Commit and push the change
    Write-Host "`n2. Committing and pushing to trigger deployment..." -ForegroundColor Yellow
    
    try {
        git add $indexFile
        git commit -m "Trigger deployment - update timestamp"
        git push origin main
        
        Write-Host "✅ Changes pushed! GitHub Actions should now trigger automatically." -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Error pushing changes: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ index.ts file not found at $indexFile" -ForegroundColor Red
    Write-Host "Let's check the file structure..." -ForegroundColor Yellow
    
    if (Test-Path "src/mcp-server") {
        Write-Host "`nContents of src/mcp-server:" -ForegroundColor Cyan
        Get-ChildItem "src/mcp-server" -Recurse
    } else {
        Write-Host "❌ src/mcp-server directory not found!" -ForegroundColor Red
    }
}

Write-Host "`n=== ALTERNATIVE: Manual Trigger ===" -ForegroundColor Cyan
Write-Host "You can also manually trigger the workflow:"
Write-Host "1. Go to: https://github.com/chokshi76-collab/GRCResponder/actions"
Write-Host "2. Click on 'Deploy MCP Server to Azure Function App'"
Write-Host "3. Click the 'Run workflow' button"
Write-Host "4. Click the green 'Run workflow' button"

Write-Host "`n🎯 After triggering, monitor the deployment progress in GitHub Actions" -ForegroundColor Green