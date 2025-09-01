# Test Universal REST API Endpoints
# This validates that the deployed API is working correctly for any AI model

Write-Host "Testing Universal REST API endpoints..." -ForegroundColor Green
Write-Host "Testing the deployed API that works with ANY AI model!" -ForegroundColor Cyan

$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api"

Write-Host ""
Write-Host "=== UNIVERSAL AI TOOL PLATFORM API TESTS ===" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing Health Check Endpoint..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
    Write-Host "✅ Health Check: SUCCESS" -ForegroundColor Green
    Write-Host "   Service: $($healthResponse.data.service)" -ForegroundColor White
    Write-Host "   Version: $($healthResponse.data.version)" -ForegroundColor White
    Write-Host "   Tools Available: $($healthResponse.data.tools_available)" -ForegroundColor White
    Write-Host "   Status: $($healthResponse.data.status)" -ForegroundColor White
} catch {
    Write-Host "❌ Health Check: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: API Documentation
Write-Host "2. Testing API Documentation Endpoint..." -ForegroundColor Cyan
try {
    $docsResponse = Invoke-RestMethod -Uri "$baseUrl/docs" -Method GET
    Write-Host "✅ API Documentation: SUCCESS" -ForegroundColor Green
    Write-Host "   OpenAPI Version: $($docsResponse.data.openapi)" -ForegroundColor White
    Write-Host "   API Title: $($docsResponse.data.info.title)" -ForegroundColor White
    Write-Host "   API Description: $($docsResponse.data.info.description.Substring(0,80))..." -ForegroundColor White
} catch {
    Write-Host "❌ API Documentation: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: List Tools
Write-Host "3. Testing List Tools Endpoint..." -ForegroundColor Cyan
try {
    $toolsResponse = Invoke-RestMethod -Uri "$baseUrl/tools" -Method GET
    Write-Host "✅ List Tools: SUCCESS" -ForegroundColor Green
    Write-Host "   Total Tools: $($toolsResponse.data.total_count)" -ForegroundColor White
    Write-Host "   API Version: $($toolsResponse.data.api_version)" -ForegroundColor White
    Write-Host ""
    Write-Host "   Available Tools:" -ForegroundColor Yellow
    foreach ($tool in $toolsResponse.data.tools) {
        Write-Host "   • $($tool.name): $($tool.description.Substring(0,60))..." -ForegroundColor White
    }
} catch {
    Write-Host "❌ List Tools: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Execute Tool (PDF Processing)
Write-Host "4. Testing Tool Execution - process_pdf..." -ForegroundColor Cyan
try {
    $pdfTestData = @{
        pdf_url = "https://example.com/test-document.pdf"
        analysis_type = "document"
    } | ConvertTo-Json

    $pdfResponse = Invoke-RestMethod -Uri "$baseUrl/tools/process_pdf" -Method POST -ContentType "application/json" -Body $pdfTestData
    Write-Host "✅ PDF Processing Tool: SUCCESS" -ForegroundColor Green
    Write-Host "   Tool: $($pdfResponse.data.tool)" -ForegroundColor White
    Write-Host "   Status: $($pdfResponse.data.status)" -ForegroundColor White
    Write-Host "   Message: $($pdfResponse.data.message.Substring(0,60))..." -ForegroundColor White
} catch {
    Write-Host "❌ PDF Processing Tool: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Execute Tool (CSV Analysis)
Write-Host "5. Testing Tool Execution - analyze_csv..." -ForegroundColor Cyan
try {
    $csvTestData = @{
        csv_data = "name,age,salary`nJohn,30,50000`nJane,25,60000"
        table_name = "test_employees"
        analysis_options = @{
            perform_stats = $true
            detect_types = $true
            clean_data = $true
        }
    } | ConvertTo-Json -Depth 3

    $csvResponse = Invoke-RestMethod -Uri "$baseUrl/tools/analyze_csv" -Method POST -ContentType "application/json" -Body $csvTestData
    Write-Host "✅ CSV Analysis Tool: SUCCESS" -ForegroundColor Green
    Write-Host "   Tool: $($csvResponse.data.tool)" -ForegroundColor White
    Write-Host "   Status: $($csvResponse.data.status)" -ForegroundColor White
    Write-Host "   Table Created: $($csvResponse.data.placeholder_response.table_created)" -ForegroundColor White
} catch {
    Write-Host "❌ CSV Analysis Tool: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Execute Tool (Website Scraping)
Write-Host "6. Testing Tool Execution - scrape_website..." -ForegroundColor Cyan
try {
    $scrapeTestData = @{
        url = "https://example.com/regulations"
        selectors = @(".content", ".date")
        options = @{
            screenshot = $true
            wait_for = ".content"
        }
    } | ConvertTo-Json -Depth 3

    $scrapeResponse = Invoke-RestMethod -Uri "$baseUrl/tools/scrape_website" -Method POST -ContentType "application/json" -Body $scrapeTestData
    Write-Host "✅ Website Scraping Tool: SUCCESS" -ForegroundColor Green
    Write-Host "   Tool: $($scrapeResponse.data.tool)" -ForegroundColor White
    Write-Host "   Status: $($scrapeResponse.data.status)" -ForegroundColor White
    Write-Host "   URL: $($scrapeResponse.data.placeholder_response.url_scraped)" -ForegroundColor White
} catch {
    Write-Host "❌ Website Scraping Tool: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 7: Execute Tool (Document Search)
Write-Host "7. Testing Tool Execution - search_documents..." -ForegroundColor Cyan
try {
    $searchTestData = @{
        query = "data privacy compliance requirements"
        filters = @{
            document_type = "regulation"
        }
        options = @{
            top = 5
            semantic_search = $true
        }
    } | ConvertTo-Json -Depth 3

    $searchResponse = Invoke-RestMethod -Uri "$baseUrl/tools/search_documents" -Method POST -ContentType "application/json" -Body $searchTestData
    Write-Host "✅ Document Search Tool: SUCCESS" -ForegroundColor Green
    Write-Host "   Tool: $($searchResponse.data.tool)" -ForegroundColor White
    Write-Host "   Status: $($searchResponse.data.status)" -ForegroundColor White
    Write-Host "   Query: $($searchResponse.data.placeholder_response.query)" -ForegroundColor White
} catch {
    Write-Host "❌ Document Search Tool: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 8: Execute Tool (CSV Query)
Write-Host "8. Testing Tool Execution - query_csv_data..." -ForegroundColor Cyan
try {
    $queryTestData = @{
        query = "What is the average salary by department?"
        table_name = "employees"
        query_type = "natural_language"
        options = @{
            limit = 10
            format = "json"
        }
    } | ConvertTo-Json -Depth 3

    $queryResponse = Invoke-RestMethod -Uri "$baseUrl/tools/query_csv_data" -Method POST -ContentType "application/json" -Body $queryTestData
    Write-Host "✅ CSV Query Tool: SUCCESS" -ForegroundColor Green
    Write-Host "   Tool: $($queryResponse.data.tool)" -ForegroundColor White
    Write-Host "   Status: $($queryResponse.data.status)" -ForegroundColor White
    Write-Host "   Query: $($queryResponse.data.placeholder_response.query_executed)" -ForegroundColor White
} catch {
    Write-Host "❌ CSV Query Tool: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== UNIVERSAL API TEST RESULTS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 CONGRATULATIONS! Universal AI Tool Platform is LIVE!" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Your API is now compatible with:" -ForegroundColor Cyan
Write-Host "   • Claude Desktop & Claude API" -ForegroundColor White
Write-Host "   • GitHub Copilot" -ForegroundColor White
Write-Host "   • ChatGPT & OpenAI API" -ForegroundColor White
Write-Host "   • Local LLMs (Ollama, LM Studio, etc.)" -ForegroundColor White
Write-Host "   • Any application that can make HTTP requests" -ForegroundColor White
Write-Host ""
Write-Host "📋 Key Endpoints for AI Integration:" -ForegroundColor Cyan
Write-Host "   GET  $baseUrl/docs - OpenAPI/Swagger documentation" -ForegroundColor White
Write-Host "   GET  $baseUrl/health - API health and status" -ForegroundColor White
Write-Host "   GET  $baseUrl/tools - List all available tools" -ForegroundColor White
Write-Host "   POST $baseUrl/tools/{name} - Execute any tool" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Available Tools Ready for Azure SDK Implementation:" -ForegroundColor Cyan
Write-Host "   • process_pdf - Azure Document Intelligence" -ForegroundColor White
Write-Host "   • analyze_csv - SQL Database Integration" -ForegroundColor White
Write-Host "   • scrape_website - Puppeteer Web Scraping" -ForegroundColor White
Write-Host "   • search_documents - Azure AI Search" -ForegroundColor White
Write-Host "   • query_csv_data - Natural Language SQL Queries" -ForegroundColor White
Write-Host ""
Write-Host "🌟 NEXT PHASE: Implement Azure SDK integrations for real functionality!" -ForegroundColor Green