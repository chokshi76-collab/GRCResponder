# PDF AI AGENT - TEST ENDPOINTS AFTER ROLLBACK
# Verify that Function App endpoints are working again after rollback

Write-Host "=== PDF AI AGENT - ENDPOINT VERIFICATION AFTER ROLLBACK ===" -ForegroundColor Green
Write-Host "Testing Function App: func-pdfai-dev-tjqwgu4v.azurewebsites.net" -ForegroundColor White

$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api"

# Function to test an endpoint
function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Name,
        [string]$Method = "GET"
    )
    
    Write-Host "`nTesting $Name..." -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method $Method -TimeoutSec 30
        Write-Host "✅ SUCCESS: $Name is working!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor White
        return $true
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        Write-Host "❌ FAILED: $Name returned error $statusCode" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n=== ENDPOINT TESTS ===" -ForegroundColor Yellow

$results = @{}

# Test 1: Health Check
$results["Health"] = Test-Endpoint -Url "$baseUrl/health" -Name "Health Check"

# Test 2: API Documentation
$results["Docs"] = Test-Endpoint -Url "$baseUrl/docs" -Name "API Documentation"

# Test 3: List Tools
$results["Tools"] = Test-Endpoint -Url "$baseUrl/tools" -Name "List Tools"

# Test 4: Execute a tool (process_pdf)
Write-Host "`nTesting Execute Tool (process_pdf)..." -ForegroundColor Cyan
try {
    $body = @{
        arguments = @{
            pdf_url = "https://example.com/test.pdf"
        }
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$baseUrl/tools/process_pdf" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ SUCCESS: Execute Tool is working!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor White
    $results["ExecuteTool"] = $true
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    Write-Host "❌ FAILED: Execute Tool returned error $statusCode" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    $results["ExecuteTool"] = $false
}

# Summary
Write-Host "`n=== ROLLBACK VERIFICATION SUMMARY ===" -ForegroundColor Yellow
$successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
$totalCount = $results.Count

Write-Host "Results: $successCount/$totalCount endpoints working" -ForegroundColor White

foreach ($test in $results.GetEnumerator()) {
    $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $($test.Key)" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
}

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 ROLLBACK SUCCESSFUL!" -ForegroundColor Green
    Write-Host "All endpoints are working. Ready to add real PDF processing!" -ForegroundColor Green
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. ✅ Rollback complete" -ForegroundColor Green
    Write-Host "2. 🔄 Add Azure Document Intelligence SDK integration" -ForegroundColor Cyan
    Write-Host "3. 🧪 Test real PDF processing functionality" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️ PARTIAL SUCCESS" -ForegroundColor Yellow
    Write-Host "Some endpoints are still not working. May need to wait longer for deployment." -ForegroundColor Yellow
    Write-Host "Try running this script again in 2-3 minutes." -ForegroundColor White
}

Write-Host "`nFunction App URL: https://func-pdfai-dev-tjqwgu4v.azurewebsites.net" -ForegroundColor Cyan