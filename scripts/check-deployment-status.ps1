# Check GitHub Actions deployment status and test Function App
$functionAppName = "func-pdfai-dev-tjqwgu4v"
$functionUrl = "https://$functionAppName.azurewebsites.net"

Write-Host "=== CHECKING DEPLOYMENT STATUS ===" -ForegroundColor Green

Write-Host "`n1. GitHub Actions should be running now!" -ForegroundColor Yellow
Write-Host "   Go to: https://github.com/chokshi76-collab/GRCResponder/actions"
Write-Host "   Look for: 'Deploy MCP Server to Azure Function App' workflow"

Write-Host "`n2. Testing Function App endpoint..." -ForegroundColor Yellow
Write-Host "   URL: $functionUrl"

# Test the function app endpoint
$maxAttempts = 5
$attempt = 1
$deployed = $false

while ($attempt -le $maxAttempts -and -not $deployed) {
    Write-Host "`n   Attempt $attempt of $maxAttempts..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $functionUrl -Method GET -TimeoutSec 15
        Write-Host "   ✅ SUCCESS! Function App is accessible" -ForegroundColor Green
        Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   Response Length: $($response.Content.Length) bytes" -ForegroundColor Green
        
        if ($response.Content.Length -gt 100) {
            Write-Host "`n   Response Preview:" -ForegroundColor White
            Write-Host $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
        }
        
        $deployed = $true
    } catch {
        Write-Host "   ⏳ Not yet accessible: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($attempt -lt $maxAttempts) {
            Write-Host "   Waiting 30 seconds before retry..." -ForegroundColor Cyan
            Start-Sleep -Seconds 30
        }
    }
    
    $attempt++
}

if (-not $deployed) {
    Write-Host "`n   ⚠️  Function App not yet accessible" -ForegroundColor Yellow
    Write-Host "   This is normal - deployment may still be in progress" -ForegroundColor Cyan
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Check GitHub Actions progress at:"
Write-Host "   https://github.com/chokshi76-collab/GRCResponder/actions"
Write-Host "`n2. Once deployment completes (usually 2-5 minutes):"
Write-Host "   - Function App endpoint will be accessible"
Write-Host "   - We'll test the MCP server functionality"
Write-Host "   - Implement actual tool logic"
Write-Host "`n3. If deployment fails:"
Write-Host "   - Check the Actions log for errors"
Write-Host "   - We'll troubleshoot together"

Write-Host "`n🎯 Current Status: Deployment in progress..." -ForegroundColor Green
Write-Host "📱 Run this script again in 2-3 minutes to check if deployment completed"