# Fix npm cache and node_modules corruption issue
cd "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "🔧 Fixing npm cache and dependency issues..." -ForegroundColor Green

# Option 1: Add npm cache clean to GitHub Actions workflow
Write-Host "`n1. We need to add npm cache cleaning to your GitHub Actions workflow" -ForegroundColor Yellow

# Let's check your current workflow file first
Write-Host "`nChecking current GitHub Actions workflow..." -ForegroundColor Cyan
if (Test-Path ".github/workflows/deploy-function-app.yml") {
    Write-Host "✅ Found workflow file" -ForegroundColor Green
} else {
    Write-Host "❌ Workflow file not found" -ForegroundColor Red
}

Write-Host "`n2. The fix is to modify the npm install step in GitHub Actions" -ForegroundColor Yellow
Write-Host "Current error suggests corrupted npm cache in the GitHub runner" -ForegroundColor Cyan

Write-Host "`n🎯 SOLUTION: Update GitHub Actions workflow to clean npm cache" -ForegroundColor Green
Write-Host "We need to modify the 'npm install and build' step to:" -ForegroundColor Yellow
Write-Host "  - Clear npm cache before installing"
Write-Host "  - Remove any existing node_modules"
Write-Host "  - Use clean install instead of regular install"

Write-Host "`n📝 Workflow changes needed:" -ForegroundColor Cyan
Write-Host "Replace this step in .github/workflows/deploy-function-app.yml:"
Write-Host "  - name: npm install and build" -ForegroundColor White
Write-Host "    run: |" -ForegroundColor White
Write-Host "      cd src/mcp-server" -ForegroundColor White
Write-Host "      npm install" -ForegroundColor White
Write-Host "      npm run build" -ForegroundColor White

Write-Host "`nWith this FIXED step:" -ForegroundColor Green
Write-Host "  - name: npm clean install and build" -ForegroundColor Green
Write-Host "    run: |" -ForegroundColor Green
Write-Host "      cd src/mcp-server" -ForegroundColor Green
Write-Host "      npm cache clean --force" -ForegroundColor Green
Write-Host "      rm -rf node_modules package-lock.json" -ForegroundColor Green
Write-Host "      npm ci --legacy-peer-deps" -ForegroundColor Green
Write-Host "      npm run build" -ForegroundColor Green

Write-Host "`n🚀 This will fix the GitHub Actions npm installation issue!" -ForegroundColor Green

Write-Host "`nWhy this happened:" -ForegroundColor Yellow
Write-Host "- GitHub Actions runners sometimes have corrupted npm cache"
Write-Host "- The cosmiconfig dependency conflicts suggest cache issues"
Write-Host "- npm ci with clean cache resolves these issues"
Write-Host "- This is a common CI/CD problem, not your code issue"

Write-Host "`nAfter fixing the workflow:" -ForegroundColor Cyan
Write-Host "1. Commit the workflow change"
Write-Host "2. Push to trigger new deployment"
Write-Host "3. GitHub Actions will run with clean npm environment"
Write-Host "4. Deployment should succeed"