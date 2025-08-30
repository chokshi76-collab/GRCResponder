# Get current user's Object ID for Key Vault access
Write-Host "Getting your Azure AD Object ID..." -ForegroundColor Green

# Method 1: Try to get from current context
$context = Get-AzContext
Write-Host "Current account: $($context.Account.Id)" -ForegroundColor Cyan

# Method 2: Get Object ID using different approaches
$userObjectId = $null

try {
    # Try using the account ID as UPN
    $user = Get-AzADUser -UserPrincipalName $context.Account.Id -ErrorAction SilentlyContinue
    if ($user) {
        $userObjectId = $user.Id
        Write-Host "Found Object ID via UPN: $userObjectId" -ForegroundColor Green
    }
} catch {
    Write-Host "Method 1 failed, trying alternative..." -ForegroundColor Yellow
}

if (-not $userObjectId) {
    try {
        # Try using mail attribute
        $user = Get-AzADUser -Mail $context.Account.Id -ErrorAction SilentlyContinue
        if ($user) {
            $userObjectId = $user.Id
            Write-Host "Found Object ID via Mail: $userObjectId" -ForegroundColor Green
        }
    } catch {
        Write-Host "Method 2 failed, trying search..." -ForegroundColor Yellow
    }
}

if (-not $userObjectId) {
    try {
        # Try searching by display name or email
        $users = Get-AzADUser | Where-Object { $_.Mail -eq $context.Account.Id -or $_.UserPrincipalName -eq $context.Account.Id }
        if ($users) {
            $userObjectId = $users[0].Id
            Write-Host "Found Object ID via search: $userObjectId" -ForegroundColor Green
        }
    } catch {
        Write-Host "Search failed..." -ForegroundColor Yellow
    }
}

if (-not $userObjectId) {
    Write-Host "Could not automatically find Object ID." -ForegroundColor Red
    Write-Host "Please run this command manually and copy the Object ID:" -ForegroundColor Yellow
    Write-Host "az ad signed-in-user show --query id -o tsv" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or find it in the Azure Portal:" -ForegroundColor Yellow
    Write-Host "1. Go to portal.azure.com" -ForegroundColor White
    Write-Host "2. Search for 'Azure Active Directory'" -ForegroundColor White
    Write-Host "3. Click 'Users'" -ForegroundColor White
    Write-Host "4. Find your user and copy the 'Object ID'" -ForegroundColor White
    Write-Host ""
    $userObjectId = Read-Host "Please enter your Object ID"
}

if ($userObjectId) {
    Write-Host "Using Object ID: $userObjectId" -ForegroundColor Green
    
    # Update the parameters file with the correct Object ID
    $parametersJson = @"
{
  "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "dev"
    },
    "keyVaultAccessObjectId": {
      "value": "$userObjectId"
    }
  }
}
"@

    $parametersJson | Out-File -FilePath "infrastructure/bicep/parameters.dev.json" -Encoding UTF8
    Write-Host "Parameters file updated with your Object ID!" -ForegroundColor Green
} else {
    Write-Host "Cannot proceed without Object ID. Please run the manual command above." -ForegroundColor Red
}