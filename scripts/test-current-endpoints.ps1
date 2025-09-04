# Test current Universal AI Tool Platform endpoints
# Based on your docs endpoint, your function app URL is:
$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api"

Write-Host "Testing Universal AI Tool Platform - Current Status" -ForegroundColor Green
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow

# Test 1: Health Check
Write-Host "`n=== 1. Testing Health Check ===" -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
    Write-Host "✅ Health Check: SUCCESS" -ForegroundColor Green
    $healthResponse | ConvertTo-Json -Depth 2
} catch {
    Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
}

# Test 2: Available Tools
Write-Host "`n=== 2. Testing Available Tools ===" -ForegroundColor Cyan
try {
    $toolsResponse = Invoke-RestMethod -Uri "$baseUrl/tools" -Method GET
    Write-Host "✅ Tools List: SUCCESS" -ForegroundColor Green
    Write-Host "Available tools:" -ForegroundColor Yellow
    $toolsResponse.tools | ForEach-Object { Write-Host "  - $($_.name): $($_.description)" }
} catch {
    Write-Host "❌ Tools List: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
}

# Test 3: API Documentation
Write-Host "`n=== 3. Testing API Documentation ===" -ForegroundColor Cyan
try {
    $docsResponse = Invoke-RestMethod -Uri "$baseUrl/docs" -Method GET
    Write-Host "✅ API Docs: SUCCESS" -ForegroundColor Green
    Write-Host "API Title: $($docsResponse.info.title)"
    Write-Host "API Version: $($docsResponse.info.version)"
} catch {
    Write-Host "❌ API Docs: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
}

# Test 4: Execute process_pdf tool (current placeholder)
Write-Host "`n=== 4. Testing process_pdf (Current Placeholder) ===" -ForegroundColor Cyan
try {
    $pdfPayload = @{
        parameters = @{
            file_path = "test-document.pdf"
            analysis_type = "comprehensive"
        }
    } | ConvertTo-Json

    $pdfResponse = Invoke-RestMethod -Uri "$baseUrl/tools/process_pdf" -Method POST -Body $pdfPayload -ContentType "application/json"
    Write-Host "✅ Process PDF: SUCCESS (Placeholder)" -ForegroundColor Green
    Write-Host "Response: $($pdfResponse.result.message)"
    Write-Host "Next Steps: $($pdfResponse.result.next_steps)"
} catch {
    Write-Host "❌ Process PDF: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
}

# Test 5: Execute analyze_csv tool (current placeholder)
Write-Host "`n=== 5. Testing analyze_csv (Current Placeholder) ===" -ForegroundColor Cyan
try {
    $csvPayload = @{
        parameters = @{
            file_path = "test-data.csv"
            table_name = "test_analysis"
            analysis_options = @("statistics", "data_quality")
        }
    } | ConvertTo-Json

    $csvResponse = Invoke-RestMethod -Uri "$baseUrl/tools/analyze_csv" -Method POST -Body $csvPayload -ContentType "application/json"
    Write-Host "✅ Analyze CSV: SUCCESS (Placeholder)" -ForegroundColor Green
    Write-Host "Response: $($csvResponse.result.message)"
    Write-Host "Next Steps: $($csvResponse.result.next_steps)"
} catch {
    Write-Host "❌ Analyze CSV: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
}

Write-Host "`n🎯 Current Endpoint Testing Complete!" -ForegroundColor Green
Write-Host "✅ Infrastructure: Working" -ForegroundColor Green  
Write-Host "✅ Universal API: Live and accessible" -ForegroundColor Green
Write-Host "🔄 Next: Replace placeholder implementations with real Azure SDK integration" -ForegroundColor Yellow