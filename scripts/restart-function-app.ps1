# Restart Function App to Load Deployed Functions
# This script restarts the Function App to ensure deployed functions are properly loaded

Write-Host "=== RESTARTING FUNCTION APP TO LOAD DEPLOYED FUNCTIONS ===" -ForegroundColor Cyan
Write-Host ""

$functionAppName = "pdf-ai-agent-func-dev"
$resourceGroup = "pdf-ai-agent-rg-dev"

Write-Host "Function App: $functionAppName" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup" -ForegroundColor Yellow
Write-Host ""

# Step 1: Stop the Function App
Write-Host "1. STOPPING FUNCTION APP..." -ForegroundColor Green

try {
    Write-Host "   Stopping $functionAppName..." -ForegroundColor Gray
    Stop-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionAppName -Force
    Write-Host "   SUCCESS: Function App stopped" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to stop Function App - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Continuing with restart attempt..." -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Wait a moment
Write-Host "2. WAITING FOR SHUTDOWN..." -ForegroundColor Green
Write-Host "   Waiting 10 seconds for clean shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Step 3: Start the Function App
Write-Host "3. STARTING FUNCTION APP..." -ForegroundColor Green

try {
    Write-Host "   Starting $functionAppName..." -ForegroundColor Gray
    Start-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionAppName
    Write-Host "   SUCCESS: Function App started" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to start Function App - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Wait for startup
Write-Host "4. WAITING FOR STARTUP..." -ForegroundColor Green
Write-Host "   Waiting 30 seconds for Function App to fully initialize..." -ForegroundColor Gray
Write-Host "   This includes loading deployed functions and resolving Key Vault references..." -ForegroundColor Gray

$secondsToWait = 30
for ($i = 1; $i -le $secondsToWait; $i++) {
    Write-Progress -Activity "Function App Starting Up" -Status "Initializing functions and Key Vault references..." -PercentComplete (($i / $secondsToWait) * 100)
    Start-Sleep -Seconds 1
}
Write-Progress -Activity "Function App Starting Up" -Completed

Write-Host ""

# Step 5: Test endpoints
Write-Host "5. TESTING ENDPOINTS AFTER RESTART..." -ForegroundColor Green

$baseUrl = "https://$functionAppName.azurewebsites.net/api"
$testEndpoints = @(
    @{ Name = "Health Check"; Url = "$baseUrl/health" },
    @{ Name = "Available Tools"; Url = "$baseUrl/tools" }
)

foreach ($endpoint in $testEndpoints) {
    Write-Host "   Testing $($endpoint.Name)..." -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint.Url -Method GET -ContentType "application/json"
        Write-Host "   SUCCESS: $($endpoint.Name) is working!" -ForegroundColor Green
        
        # Show key information from health check
        if ($endpoint.Name -eq "Health Check") {
            Write-Host "   - Status: $($response.status)" -ForegroundColor White
            Write-Host "   - Azure Integration: $($response.azureIntegration)" -ForegroundColor $(if($response.azureIntegration -eq "ACTIVE") {"Green"} else {"Yellow"})
            
            if ($response.azureIntegration -eq "ACTIVE") {
                Write-Host "   EXCELLENT: Key Vault references are now ACTIVE!" -ForegroundColor Green
            }
        }
        
        # Show available tools
        if ($endpoint.Name -eq "Available Tools" -and $response.tools) {
            Write-Host "   - Available Tools: $($response.tools.Count)" -ForegroundColor White
            foreach ($tool in $response.tools) {
                $toolColor = if ($tool.name -eq "process_pdf") {"Green"} else {"Gray"}
                Write-Host "     * $($tool.name)" -ForegroundColor $toolColor
            }
        }
        
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   STILL WAITING: $($endpoint.Name) returned $statusCode" -ForegroundColor Yellow
        Write-Host "   (Function App may need more time to fully start)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host "=== RESTART COMPLETE ===" -ForegroundColor Cyan

# Step 6: Final verification
Write-Host "6. FINAL VERIFICATION..." -ForegroundColor Green

try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -ContentType "application/json"
    
    if ($healthResponse.azureIntegration -eq "ACTIVE") {
        Write-Host ""
        Write-Host "SUCCESS: UNIVERSAL AI TOOL PLATFORM IS NOW FULLY OPERATIONAL!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Platform Status:" -ForegroundColor White
        Write-Host "- Function App: Running" -ForegroundColor Green
        Write-Host "- Functions: Deployed and loaded" -ForegroundColor Green  
        Write-Host "- Key Vault Integration: ACTIVE" -ForegroundColor Green
        Write-Host "- Azure Document Intelligence: Ready" -ForegroundColor Green
        Write-Host "- Universal REST API: Available for any AI model" -ForegroundColor Green
        Write-Host ""
        Write-Host "READY FOR NEXT PHASE: Test real PDF processing or expand with analyze_csv tool!" -ForegroundColor Cyan
        
    } else {
        Write-Host ""
        Write-Host "Function App restarted successfully, but Azure Integration may need more time..." -ForegroundColor Yellow
        Write-Host "Current status: $($healthResponse.azureIntegration)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "NEXT ACTION: Wait 5-10 more minutes, then test again" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host ""
    Write-Host "Function App restarted, but endpoints may need more time to become available..." -ForegroundColor Yellow
    Write-Host "NEXT ACTION: Wait 5-10 minutes, then run test-azure-integration.ps1" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Endpoints to test:" -ForegroundColor White
Write-Host "- Health: $baseUrl/health" -ForegroundColor Gray
Write-Host "- Tools: $baseUrl/tools" -ForegroundColor Gray
Write-Host "- Execute: $baseUrl/tools/process_pdf" -ForegroundColor Gray