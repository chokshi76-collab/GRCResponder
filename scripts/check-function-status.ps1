# Check Function App Deployment Status
# This script diagnoses why the Function App endpoints are returning 404

Write-Host "=== DIAGNOSING FUNCTION APP DEPLOYMENT STATUS ===" -ForegroundColor Cyan
Write-Host ""

$functionAppName = "pdf-ai-agent-func-dev"
$resourceGroup = "pdf-ai-agent-rg-dev"

# Check if Function App exists and is running
Write-Host "1. CHECKING FUNCTION APP STATUS..." -ForegroundColor Green

try {
    $functionApp = Get-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionAppName
    
    Write-Host "   Function App Status:" -ForegroundColor White
    Write-Host "   - Name: $($functionApp.Name)" -ForegroundColor Gray
    Write-Host "   - State: $($functionApp.State)" -ForegroundColor $(if($functionApp.State -eq "Running") {"Green"} else {"Red"})
    Write-Host "   - Location: $($functionApp.Location)" -ForegroundColor Gray
    Write-Host "   - Runtime Version: $($functionApp.RuntimeVersion)" -ForegroundColor Gray
    Write-Host "   - Site State: $($functionApp.State)" -ForegroundColor Gray
    
    if ($functionApp.State -ne "Running") {
        Write-Host "   WARNING: Function App is not in Running state!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   ERROR: Cannot retrieve Function App details - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   This suggests the Function App may not exist or you lack permissions" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check Function App settings
Write-Host "2. CHECKING FUNCTION APP CONFIGURATION..." -ForegroundColor Green

try {
    $appSettings = Get-AzFunctionAppSetting -ResourceGroupName $resourceGroup -Name $functionAppName
    
    Write-Host "   Key Configuration Settings:" -ForegroundColor White
    
    $keySettings = @(
        "AZURE_FORM_RECOGNIZER_ENDPOINT",
        "AZURE_FORM_RECOGNIZER_KEY", 
        "FUNCTIONS_EXTENSION_VERSION",
        "FUNCTIONS_WORKER_RUNTIME",
        "WEBSITE_NODE_DEFAULT_VERSION"
    )
    
    foreach ($setting in $keySettings) {
        if ($appSettings[$setting]) {
            $value = $appSettings[$setting]
            if ($value -like "*@Microsoft.KeyVault*") {
                Write-Host "   - ${setting}: [KEY VAULT REFERENCE]" -ForegroundColor Green
            } else {
                $displayValue = if ($value.Length -gt 50) { $value.Substring(0, 50) + "..." } else { $value }
                Write-Host "   - ${setting}: $displayValue" -ForegroundColor Gray
            }
        } else {
            Write-Host "   - ${setting}: [NOT SET]" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "   ERROR: Cannot retrieve Function App settings - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check deployment status via Kudu
Write-Host "3. CHECKING DEPLOYMENT STATUS (KUDU API)..." -ForegroundColor Green

try {
    $kuduUrl = "https://$functionAppName.scm.azurewebsites.net/api/deployments"
    
    # Get publishing credentials first
    $publishProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $resourceGroup -Name $functionAppName
    
    # Parse the profile to get credentials
    $profileXml = [xml]$publishProfile
    $ftpProfile = $profileXml.publishData.publishProfile | Where-Object { $_.publishMethod -eq "FTP" }
    $username = $ftpProfile.userName
    $password = $ftpProfile.userPWD
    
    # Create credential for Kudu API
    $pair = "$username`:$password"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    
    $deployments = Invoke-RestMethod -Uri $kuduUrl -Headers $headers -Method GET
    
    if ($deployments.Count -gt 0) {
        $latestDeployment = $deployments[0]
        Write-Host "   Latest Deployment:" -ForegroundColor White
        Write-Host "   - Status: $($latestDeployment.status)" -ForegroundColor $(if($latestDeployment.status -eq "Success") {"Green"} else {"Red"})
        Write-Host "   - Time: $($latestDeployment.end_time)" -ForegroundColor Gray
        Write-Host "   - Message: $($latestDeployment.message)" -ForegroundColor Gray
        
        if ($latestDeployment.status -ne "Success") {
            Write-Host "   WARNING: Latest deployment was not successful!" -ForegroundColor Red
        }
    } else {
        Write-Host "   No deployments found" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   Could not access Kudu API - $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   This is normal if using different authentication" -ForegroundColor Gray
}

Write-Host ""

# Check if functions are listed
Write-Host "4. CHECKING DEPLOYED FUNCTIONS..." -ForegroundColor Green

try {
    $functionListUrl = "https://$functionAppName.azurewebsites.net/admin/functions"
    
    # Try to get function list (this might require master key)
    Write-Host "   Attempting to list deployed functions..." -ForegroundColor Gray
    
    # Alternative: Check the simple root URL
    $rootUrl = "https://$functionAppName.azurewebsites.net"
    $response = Invoke-WebRequest -Uri $rootUrl -Method GET -UseBasicParsing
    
    Write-Host "   Root URL Response Code: $($response.StatusCode)" -ForegroundColor $(if($response.StatusCode -eq 200) {"Green"} else {"Red"})
    
    if ($response.StatusCode -eq 200) {
        Write-Host "   Function App is responding to HTTP requests" -ForegroundColor Green
        
        # Check if it's the default Azure Functions page
        if ($response.Content -like "*Azure Functions*") {
            Write-Host "   Showing default Azure Functions page - functions may not be deployed" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "   Could not access Function App root - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Try to access one specific endpoint to see detailed error
Write-Host "5. DETAILED ENDPOINT TESTING..." -ForegroundColor Green

$testEndpoints = @(
    "https://$functionAppName.azurewebsites.net/api/health",
    "https://$functionAppName.azurewebsites.net/health",
    "https://$functionAppName.azurewebsites.net"
)

foreach ($endpoint in $testEndpoints) {
    try {
        Write-Host "   Testing: $endpoint" -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $endpoint -Method GET -UseBasicParsing
        Write-Host "   - Status: $($response.StatusCode) - SUCCESS" -ForegroundColor Green
        
        if ($response.Content.Length -lt 200) {
            Write-Host "   - Content: $($response.Content)" -ForegroundColor Gray
        } else {
            Write-Host "   - Content: [Large response - function likely working]" -ForegroundColor Gray
        }
        break
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   - Status: $statusCode - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== DIAGNOSIS COMPLETE ===" -ForegroundColor Cyan

Write-Host ""
Write-Host "NEXT ACTIONS:" -ForegroundColor Yellow
Write-Host "1. If Function App is not Running - restart it" -ForegroundColor Gray
Write-Host "2. If no successful deployments - check GitHub Actions" -ForegroundColor Gray  
Write-Host "3. If functions not deployed - trigger manual deployment" -ForegroundColor Gray
Write-Host "4. If Key Vault references not configured - re-run configuration script" -ForegroundColor Gray