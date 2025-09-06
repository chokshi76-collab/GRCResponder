# diagnose-routes.ps1
# This script lists all functions and their trigger URLs registered in the deployed Function App.

# --- Configuration ---
$resourceGroupName = "pdf-ai-agent-rg-dev"
$functionAppName = "pdf-ai-agent-func-dev"

# --- Script ---
Write-Host "---"
Write-Host "DIAGNOSING FUNCTION APP ROUTES"
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Function App: $functionAppName"
Write-Host "---"

try {
    Write-Host "Step 1: Listing all functions in the app..."
    # Note: Using Azure CLI here as it provides the most direct way to get this info.
    $functions = az functionapp function list --resource-group $resourceGroupName --name $functionAppName | ConvertFrom-Json

    if ($functions.Count -gt 0) {
        Write-Host "Step 2: Displaying registered functions and their trigger URLs..."
        Write-Host ""
        
        foreach ($function in $functions) {
            $name = $function.name
            $invokeUrl = $function.properties.invoke_url_template
            
            Write-Host "  - Function Name: $name"
            Write-Host "    Trigger URL: $invokeUrl"
            Write-Host ""
        }

        Write-Host "Step 3: Analysis"
        Write-Host "Compare the URLs above with the one used in the test script: 'https://$functionAppName.azurewebsites.net/api/tools/process_pdf'"
        Write-Host "Look for the function with a route like '/api/tools/{toolName}' or similar."
        Write-Host "If that function is missing, it confirms a startup error for that specific function."

    } else {
        Write-Host "Error: No functions found in the app. This may indicate a major deployment or startup failure." -ForegroundColor Red
    }
}
catch {
    Write-Host "A critical error occurred: $_" -ForegroundColor Red
    Write-Host "Please ensure you are logged into Azure with 'az login' and your subscription is set correctly."
}

Write-Host "---"
Write-Host "Diagnostic script finished."
Write-Host "---"