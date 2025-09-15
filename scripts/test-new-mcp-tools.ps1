# Test new MCP tools with proper parameters
$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api"

Write-Host "Testing New MCP Tools - Advanced Functionality" -ForegroundColor Green
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow

# Test CSV Analyzer with sample data
Write-Host "`n=== Testing CSV Analyzer (Advanced) ===" -ForegroundColor Cyan
try {
    $csvData = @"
customer_id,energy_usage_kwh,billing_amount,service_type,outage_minutes
CUST001,1250.5,89.50,residential,0
CUST002,2100.8,142.30,commercial,15
CUST003,950.2,67.80,residential,0
CUST004,3200.1,220.15,industrial,45
CUST005,1150.0,82.25,residential,30
"@

    $csvPayload = @{
        parameters = @{
            csv_data = $csvData
            analysis_type = "comprehensive"
            include_recommendations = $true
        }
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Uri "$baseUrl/tools/analyze_csv" -Method POST -Body $csvPayload -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ CSV Analysis: SUCCESS" -ForegroundColor Green
    Write-Host "Analysis ID: $($response.result.analysis_id)" -ForegroundColor Yellow
    Write-Host "Status: $($response.result.status)" -ForegroundColor Yellow
    Write-Host "Message: $($response.result.message)" -ForegroundColor Cyan
    if ($response.result.utilities_insights) {
        Write-Host "Utilities Context Detected: $($response.result.utilities_insights.detected_context -join ', ')" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ CSV Analysis: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Knowledge Search
Write-Host "`n=== Testing Knowledge Search (Semantic) ===" -ForegroundColor Cyan
try {
    $searchPayload = @{
        parameters = @{
            query = "NERC CIP compliance requirements"
            search_type = "semantic"
            max_results = 5
            include_metadata = $true
        }
    } | ConvertTo-Json -Depth 2

    $response = Invoke-RestMethod -Uri "$baseUrl/tools/knowledge_search" -Method POST -Body $searchPayload -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ Knowledge Search: SUCCESS" -ForegroundColor Green
    Write-Host "Search ID: $($response.result.search_id)" -ForegroundColor Yellow
    Write-Host "Status: $($response.result.status)" -ForegroundColor Yellow
    Write-Host "Results Found: $($response.result.total_results)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Knowledge Search: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Compliance Analyzer
Write-Host "`n=== Testing Compliance Analyzer ===" -ForegroundColor Cyan
try {
    $compliancePayload = @{
        parameters = @{
            document_content = "This document outlines security management controls for critical assets in the bulk electric system. Personnel access controls and training records must be maintained. Network security perimeters must be protected with firewalls."
            compliance_domain = "nerc_cip"
            include_remediation = $true
        }
    } | ConvertTo-Json -Depth 2

    $response = Invoke-RestMethod -Uri "$baseUrl/tools/compliance_analyzer" -Method POST -Body $compliancePayload -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ Compliance Analysis: SUCCESS" -ForegroundColor Green
    Write-Host "Analysis ID: $($response.result.analysis_id)" -ForegroundColor Yellow
    Write-Host "Overall Score: $($response.result.overall_score)" -ForegroundColor Yellow
    Write-Host "Risk Level: $($response.result.risk_level)" -ForegroundColor Yellow
    Write-Host "Violations Found: $($response.result.violations.Count)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Compliance Analysis: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Advanced MCP Tools Testing Complete!" -ForegroundColor Green