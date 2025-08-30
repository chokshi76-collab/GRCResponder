# Fix npm dependencies and package-lock.json for GitHub Actions deployment
Write-Host "=== FIXING NPM DEPENDENCIES FOR DEPLOYMENT ===" -ForegroundColor Green

$mcpServerPath = "src/mcp-server"

# Navigate to MCP server directory
if (Test-Path $mcpServerPath) {
    Set-Location $mcpServerPath
    Write-Host "✅ Changed to $mcpServerPath directory" -ForegroundColor Green
    
    # Remove existing node_modules and package-lock.json if they exist
    Write-Host "`n1. Cleaning existing dependencies..." -ForegroundColor Yellow
    if (Test-Path "node_modules") {
        Remove-Item -Recurse -Force "node_modules"
        Write-Host "   ✅ Removed node_modules" -ForegroundColor Green
    }
    
    if (Test-Path "package-lock.json") {
        Remove-Item -Force "package-lock.json"
        Write-Host "   ✅ Removed old package-lock.json" -ForegroundColor Green
    }
    
    # Install dependencies to generate package-lock.json
    Write-Host "`n2. Installing dependencies with npm install..." -ForegroundColor Yellow
    try {
        npm install
        Write-Host "   ✅ Dependencies installed successfully!" -ForegroundColor Green
        
        # Verify package-lock.json was created
        if (Test-Path "package-lock.json") {
            Write-Host "   ✅ package-lock.json created" -ForegroundColor Green
        } else {
            Write-Host "   ❌ package-lock.json not created" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "   ❌ npm install failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`n   Let's try fixing the package.json first..." -ForegroundColor Yellow
        
        # Check if package.json exists and show its content
        if (Test-Path "package.json") {
            Write-Host "`n   Current package.json:" -ForegroundColor Cyan
            Get-Content "package.json"
        }
    }
    
    # Build TypeScript to make sure everything compiles
    Write-Host "`n3. Testing TypeScript build..." -ForegroundColor Yellow
    try {
        npm run build
        Write-Host "   ✅ TypeScript build successful!" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ TypeScript build failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Return to root directory
    Set-Location "..\\.."
    
    # Commit the package-lock.json
    Write-Host "`n4. Committing package-lock.json..." -ForegroundColor Yellow
    try {
        git add "$mcpServerPath/package-lock.json"
        git add "$mcpServerPath/package.json"  # In case we modified it
        git commit -m "Add package-lock.json for proper CI/CD deployment"
        git push origin main
        
        Write-Host "   ✅ package-lock.json committed and pushed!" -ForegroundColor Green
        
    } catch {
        Write-Host "   ❌ Failed to commit: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ $mcpServerPath directory not found!" -ForegroundColor Red
    Write-Host "Current directory contents:" -ForegroundColor Yellow
    Get-ChildItem
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Check if the commit triggered a new GitHub Actions run"
Write-Host "2. Monitor the 'Install dependencies' step to see if it now passes"
Write-Host "3. If it still fails, we may need to adjust the workflow"

Write-Host "`n🎯 After running this script, check GitHub Actions again!" -ForegroundColor Green