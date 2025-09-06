# Test Azure Document Intelligence credentials directly

Write-Host "=== DIAGNOSING PDF PROCESSOR ISSUE ===" -ForegroundColor Yellow

# 1. Check environment variables in Function App
Write-Host "`n1. Checking Function App environment variables..." -ForegroundColor Cyan
$appSettings = az functionapp config appsettings list --name "pdf-ai-agent-func-dev" --resource-group "pdf-ai-agent-rg-dev" | ConvertFrom-Json
$endpoint = ($appSettings | Where-Object {$_.name -eq "AZURE_FORM_RECOGNIZER_ENDPOINT"}).value
$key = ($appSettings | Where-Object {$_.name -eq "AZURE_FORM_RECOGNIZER_KEY"}).value

Write-Host "Endpoint: $endpoint"
Write-Host "Key: $($key.Substring(0, 8))..." -ForegroundColor Green

# 2. Test Document Intelligence service directly
Write-Host "`n2. Testing Document Intelligence service directly..." -ForegroundColor Cyan
$headers = @{
    "Ocp-Apim-Subscription-Key" = $key
    "Content-Type" = "application/json"
}

$testUrl = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
$body = @{
    urlSource = $testUrl
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$endpoint/formrecognizer/documentModels/prebuilt-read:analyze?api-version=2023-07-31" -Method POST -Headers $headers -Body $body -TimeoutSec 30
    Write-Host "Direct API call SUCCESS" -ForegroundColor Green
    Write-Host "Operation ID: $($response.operationId)" -ForegroundColor Green
} catch {
    Write-Host "Direct API call FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}

# 3. Test health endpoint response time
Write-Host "`n3. Testing Function App health endpoint..." -ForegroundColor Cyan
$startTime = Get-Date
try {
    $healthResponse = Invoke-RestMethod -Uri "https://pdf-ai-agent-func-dev.azurewebsites.net/api/health" -TimeoutSec 10
    $duration = (Get-Date) - $startTime
    Write-Host "Health endpoint SUCCESS - Response time: $($duration.TotalSeconds) seconds" -ForegroundColor Green
} catch {
    $duration = (Get-Date) - $startTime
    Write-Host "Health endpoint FAILED after $($duration.TotalSeconds) seconds: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test PDF processor with timeout monitoring
Write-Host "`n4. Testing PDF processor endpoint with timeout monitoring..." -ForegroundColor Cyan
$testPayload = @{
    file_path = $testUrl
    analysis_type = "text"
} | ConvertTo-Json

$startTime = Get-Date
try {
    $response = Invoke-RestMethod -Uri "https://pdf-ai-agent-func-dev.azurewebsites.net/api/tools/process_pdf" -Method POST -Body $testPayload -ContentType "application/json" -TimeoutSec 15
    $duration = (Get-Date) - $startTime
    Write-Host "PDF processor SUCCESS - Response time: $($duration.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "Azure Integration: $($response.azure_integration)" -ForegroundColor Green
    if ($response.error_message) {
        Write-Host "Error: $($response.error_message)" -ForegroundColor Red
    }
} catch {
    $duration = (Get-Date) - $startTime
    Write-Host "PDF processor FAILED after $($duration.TotalSeconds) seconds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DIAGNOSIS COMPLETE ===" -ForegroundColor Yellow