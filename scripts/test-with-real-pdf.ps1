# test-with-real-pdf.ps1
# This script performs a true end-to-end test of the PDF processing tool
# by providing a real, publicly accessible PDF URL.

# --- Configuration ---
$functionAppUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api"
$toolEndpoint = "/tools/process_pdf"
$requestUrl = $functionAppUrl + $toolEndpoint

# This is a sample invoice PDF hosted by Microsoft for documentation purposes.
$realPdfUrl = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# --- Script ---
Write-Host "---"
Write-Host "PERFORMING END-TO-END TEST WITH A REAL PDF"
Write-Host "Function App URL: $functionAppUrl"
Write-Host "PDF for Analysis: $realPdfUrl"
Write-Host "---"

try {
    Write-Host "Step 1: Constructing the request body..."
    $body = @{
        parameters = @{
            file_path = $realPdfUrl
            analysis_type = "text"
        }
    } | ConvertTo-Json -Depth 3

    Write-Host "Step 2: Invoking the 'process_pdf' tool..."
    # Use -TimeoutSec 300 (5 minutes) because the first analysis can be slow
    $response = Invoke-RestMethod -Uri $requestUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300

    Write-Host "Step 3: Analyzing the response..."
    
    if ($response.status -eq "success") {
        Write-Host ""
        Write-Host "***************************************************" -ForegroundColor Green
        Write-Host "   ✅ SUCCESS: AI DOCUMENT ANALYSIS COMPLETE" -ForegroundColor Green
        Write-Host "***************************************************" -ForegroundColor Green
        Write-Host ""
        Write-Host "AI Model: $($response.data.modelId)"
        Write-Host "Pages Processed: $($response.data.pages.Count)"
        Write-Host "Extracted Content Snippet:"
        Write-Host "'$($response.data.content.Substring(0, 150))...'"
        Write-Host ""
        Write-Host "The Universal AI Tool Platform is fully operational."

    } else {
        Write-Host "ERROR: The API returned a failure status." -ForegroundColor Red
        Write-Host "Response:"
        Write-Host ($response | ConvertTo-Json -Depth 5)
    }
}
catch {
    Write-Host "A critical error occurred while calling the API: $_" -ForegroundColor Red
    $errorResponse = $_.Exception.Response.GetResponseStream()
    $streamReader = New-Object System.IO.StreamReader($errorResponse)
    $errorBody = $streamReader.ReadToEnd()
    Write-Host "Error Body: $errorBody"
}

Write-Host "---"
Write-Host "End-to-end test finished."
Write-Host "---"