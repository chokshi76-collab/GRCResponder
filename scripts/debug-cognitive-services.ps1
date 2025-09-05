# Debug Cognitive Services Resources
# Location: scripts/debug-cognitive-services.ps1
param([string]$Environment = "dev")

$resourceGroupName = "pdf-ai-agent-rg-$Environment"

Write-Host "=== DEBUGGING COGNITIVE SERVICES ===" -ForegroundColor Green
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Yellow

# Get all Cognitive Services in the resource group
Write-Host "`nFinding all Cognitive Services resources..." -ForegroundColor Cyan
$cognitiveServices = Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName

if ($cognitiveServices) {
    Write-Host "Found $($cognitiveServices.Count) Cognitive Services resource(s):" -ForegroundColor Green
    
    foreach ($service in $cognitiveServices) {
        Write-Host "`n--- Resource Details ---" -ForegroundColor White
        Write-Host "Name: $($service.AccountName)" -ForegroundColor Yellow
        Write-Host "Kind: $($service.Kind)" -ForegroundColor Yellow
        Write-Host "SKU: $($service.Sku.Name)" -ForegroundColor Yellow
        Write-Host "Endpoint: $($service.Endpoint)" -ForegroundColor Yellow
        Write-Host "Location: $($service.Location)" -ForegroundColor Yellow
        Write-Host "ResourceType: $($service.ResourceType)" -ForegroundColor Yellow
    }
    
    # Check for Document Intelligence specifically
    Write-Host "`n=== CHECKING FOR DOCUMENT INTELLIGENCE ===" -ForegroundColor Cyan
    
    # Try different possible Kind values for Document Intelligence
    $possibleKinds = @("FormRecognizer", "DocumentIntelligence", "CognitiveServices", "TextAnalytics")
    
    foreach ($kind in $possibleKinds) {
        $match = $cognitiveServices | Where-Object { $_.Kind -eq $kind }
        if ($match) {
            Write-Host "Found with Kind '$kind': $($match.AccountName)" -ForegroundColor Green
        }
    }
    
    # Try looking for Document Intelligence in the name
    $nameMatch = $cognitiveServices | Where-Object { $_.AccountName -like "*doc*" -or $_.AccountName -like "*form*" -or $_.AccountName -like "*intelligence*" }
    if ($nameMatch) {
        Write-Host "`nFound by name pattern:" -ForegroundColor Green
        foreach ($match in $nameMatch) {
            Write-Host "  - $($match.AccountName) (Kind: $($match.Kind))" -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host "No Cognitive Services resources found in $resourceGroupName" -ForegroundColor Red
    
    # Let's check what resources exist in the resource group
    Write-Host "`nChecking all resources in resource group..." -ForegroundColor Cyan
    $allResources = Get-AzResource -ResourceGroupName $resourceGroupName
    
    if ($allResources) {
        Write-Host "Found $($allResources.Count) total resources:" -ForegroundColor Yellow
        foreach ($resource in $allResources) {
            Write-Host "  - $($resource.Name) ($($resource.ResourceType))" -ForegroundColor Gray
        }
    } else {
        Write-Host "No resources found in resource group!" -ForegroundColor Red
    }
}

Write-Host "`n=== RECOMMENDATION ===" -ForegroundColor Cyan
Write-Host "Based on the results above, we can update the script to use the correct Kind value." -ForegroundColor White