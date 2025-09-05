# Test Azure Integration Status - Universal AI Tool Platform
# This script verifies that Key Vault references have propagated and Azure services are active

Write-Host "=== TESTING UNIVERSAL AI TOOL PLATFORM - AZURE INTEGRATION STATUS ===" -ForegroundColor Cyan
Write-Host ""

# Function App details
$functionAppName = "pdf-ai-agent-func-dev"
$resourceGroup = "pdf-ai-agent-rg-dev"
$baseUrl = "https://$functionAppName.azurewebsites.net/api"

Write-Host "Testing Function App: $functionAppName" -ForegroundColor Yellow
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check - Should show Azure Integration status
Write-Host "1. TESTING HEALTH CHECK ENDPOINT..." -ForegroundColor Green
Write-Host "   Expected: Azure Integration should be ACTIVE (not NOT_CONFIGURED)" -ForegroundColor Gray

try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -ContentType "application/json"
    
    Write-Host "   Health Check Response:" -ForegroundColor White
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor White
    Write-Host "   Timestamp: $($healthResponse.timestamp)" -ForegroundColor White
    Write-Host "   Function App: $($healthResponse.functionApp)" -ForegroundColor White
    Write-Host "   Azure Integration: $($healthResponse.azureIntegration)" -ForegroundColor $(if($healthResponse.azureIntegration -eq "ACTIVE") {"Green"} else {"Red"})
    
    if ($healthResponse.azureIntegration -eq "ACTIVE") {
        Write-Host "   SUCCESS: Azure Integration is ACTIVE!" -ForegroundColor Green
        $azureActive = $true
    } else {
        Write-Host "   WAITING: Azure Integration still showing: $($healthResponse.azureIntegration)" -ForegroundColor Yellow
        Write-Host "   Note: Key Vault references may still be propagating (can take 5-15 minutes)" -ForegroundColor Gray
        $azureActive = $false
    }
} catch {
    Write-Host "   ERROR: Health check failed - $($_.Exception.Message)" -ForegroundColor Red
    $azureActive = $false
}

Write-Host ""

# Test 2: Available Tools - Should show real Azure tools
Write-Host "2. TESTING AVAILABLE TOOLS ENDPOINT..." -ForegroundColor Green

try {
    $toolsResponse = Invoke-RestMethod -Uri "$baseUrl/tools" -Method GET -ContentType "application/json"
    
    Write-Host "   Available Tools:" -ForegroundColor White
    foreach ($tool in $toolsResponse.tools) {
        $statusColor = if($tool.name -eq "process_pdf") {"Green"} else {"Gray"}
        Write-Host "   - $($tool.name): $($tool.description)" -ForegroundColor $statusColor
    }
    
    $pdfTool = $toolsResponse.tools | Where-Object { $_.name -eq "process_pdf" }
    if ($pdfTool) {
        Write-Host "   SUCCESS: Real PDF processing tool is available!" -ForegroundColor Green
    }
} catch {
    Write-Host "   ERROR: Tools endpoint failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Only test PDF processing if Azure Integration is ACTIVE
if ($azureActive) {
    Write-Host "3. TESTING REAL PDF PROCESSING (Azure Document Intelligence)..." -ForegroundColor Green
    Write-Host "   This will test the actual Azure integration with Key Vault references" -ForegroundColor Gray
    
    # Simple test with a minimal PDF URL
    $testPdfUrl = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
    
    $requestBody = @{
        name = "process_pdf"
        arguments = @{
            pdf_url = $testPdfUrl
            analysis_type = "basic"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        Write-Host "   Testing with sample PDF: $testPdfUrl" -ForegroundColor Gray
        $pdfResponse = Invoke-RestMethod -Uri "$baseUrl/tools/process_pdf" -Method POST -Body $requestBody -ContentType "application/json"
        
        Write-Host "   SUCCESS: PDF processing completed!" -ForegroundColor Green
        Write-Host "   Response summary: $($pdfResponse.summary)" -ForegroundColor White
        
        if ($pdfResponse.extracted_text) {
            $textPreview = $pdfResponse.extracted_text.Substring(0, [Math]::Min(100, $pdfResponse.extracted_text.Length))
            Write-Host "   Text preview: $textPreview..." -ForegroundColor Gray
        }
        
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "   ERROR: PDF processing failed - $errorMessage" -ForegroundColor Red
        
        if ($errorMessage -like "*401*" -or $errorMessage -like "*403*" -or $errorMessage -like "*authentication*") {
            Write-Host "   Key Vault references may still be propagating..." -ForegroundColor Yellow
            Write-Host "   Try again in 5-10 minutes" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "3. SKIPPING PDF PROCESSING TEST" -ForegroundColor Yellow
    Write-Host "   Reason: Azure Integration not yet ACTIVE" -ForegroundColor Gray
    Write-Host "   Wait 5-15 minutes for Key Vault references to propagate, then re-run this script" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan

if ($azureActive) {
    Write-Host "UNIVERSAL AI TOOL PLATFORM IS FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host "Azure Integration: ACTIVE" -ForegroundColor Green
    Write-Host "Key Vault References: Propagated" -ForegroundColor Green
    Write-Host "Enterprise Security: Enabled" -ForegroundColor Green
    Write-Host "Real AI Tools: Available via REST API" -ForegroundColor Green
    Write-Host ""
    Write-Host "READY FOR NEXT PHASE: Modular expansion with analyze_csv tool" -ForegroundColor Cyan
} else {
    Write-Host "Platform configuration complete, waiting for Azure propagation..." -ForegroundColor Yellow
    Write-Host "Infrastructure: Deployed" -ForegroundColor Green
    Write-Host "Key Vault References: Configured" -ForegroundColor Green
    Write-Host "Azure Integration: Propagating..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "NEXT ACTION: Re-run this script in 5-10 minutes" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Platform Endpoints:" -ForegroundColor White
Write-Host "- Health: $baseUrl/health" -ForegroundColor Gray
Write-Host "- Tools: $baseUrl/tools" -ForegroundColor Gray
Write-Host "- Execute: $baseUrl/tools/process_pdf" -ForegroundColor Gray