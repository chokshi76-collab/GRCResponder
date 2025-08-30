# Update Bicep template to use Azure Key Vault for secrets
Write-Host "Updating Bicep template to use Azure Key Vault..." -ForegroundColor Green

# Get current user's object ID for Key Vault access
$currentUser = Get-AzContext
$userObjectId = (Get-AzADUser -UserPrincipalName $currentUser.Account.Id).Id

if (-not $userObjectId) {
    Write-Host "Getting user object ID from Azure AD..." -ForegroundColor Yellow
    $userObjectId = (Get-AzADUser -Mail $currentUser.Account.Id).Id
}

Write-Host "User Object ID: $userObjectId" -ForegroundColor Cyan

# Updated main.bicep with Key Vault
$mainBicepWithVault = @"
targetScope = 'resourceGroup'

@description('Environment name (e.g., dev, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('SQL Administrator username')
param sqlAdminUsername string = 'sqladmin'

@description('Object ID of the user/service principal that will have access to Key Vault')
param keyVaultAccessObjectId string

// Variables
var prefix = 'pdf-ai-agent'
var storageAccountName = 'pdfaiagentstorage001'
var keyVaultName = '`${prefix}-kv-`${environmentName}-`${uniqueString(resourceGroup().id)}'

// Generate a secure password for SQL
var sqlAdminPassword = '`${uniqueString(resourceGroup().id, 'sql')}Aa1!'

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: keyVaultAccessObjectId
        permissions: {
          keys: ['all']
          secrets: ['all']
          certificates: ['all']
        }
      }
    ]
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store SQL password in Key Vault
resource sqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-admin-password'
  properties: {
    value: sqlAdminPassword
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Store Storage connection string in Key Vault
resource storageConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=`${storageAccount.name};EndpointSuffix=`${environment().suffixes.storage};AccountKey=`${storageAccount.listKeys().keys[0].value}'
  }
}

// Document Intelligence
resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '`${prefix}-docint-`${environmentName}'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: '`${prefix}-docint-`${environmentName}'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Store Document Intelligence key in Key Vault
resource docIntelligenceKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'document-intelligence-key'
  properties: {
    value: documentIntelligence.listKeys().key1
  }
}

// AI Search
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: '`${prefix}-search-`${environmentName}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

// Store Search admin key in Key Vault
resource searchAdminKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'search-admin-key'
  properties: {
    value: searchService.listAdminKeys().primaryKey
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: '`${prefix}-sql-`${environmentName}'
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: '`${prefix}-db-`${environmentName}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// Store SQL connection string in Key Vault
resource sqlConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connection-string'
  properties: {
    value: 'Server=tcp:`${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=`${sqlDatabase.name};Persist Security Info=False;User ID=`${sqlAdminUsername};Password=`${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

// SQL Firewall rule to allow Azure services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Function App (for future use)
resource functionAppPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '`${prefix}-plan-`${environmentName}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '`${prefix}-func-`${environmentName}'
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: functionAppPlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|18'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(SecretUri=`${storageConnectionSecret.properties.secretUri})'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}

// Give Function App access to Key Vault
resource functionAppKeyVaultAccess 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}

// Outputs
output keyVaultName string = keyVault.name
output storageAccountName string = storageAccount.name
output documentIntelligenceEndpoint string = documentIntelligence.properties.endpoint
output searchServiceName string = searchService.name
output searchServiceEndpoint string = 'https://`${searchService.name}.search.windows.net'
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output functionAppName string = functionApp.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
"@

# Updated parameters file
$parametersJsonWithVault = @"
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

# Write updated files
$mainBicepWithVault | Out-File -FilePath "infrastructure/bicep/main.bicep" -Encoding UTF8
$parametersJsonWithVault | Out-File -FilePath "infrastructure/bicep/parameters.dev.json" -Encoding UTF8

Write-Host "Bicep template updated with Azure Key Vault!" -ForegroundColor Green
Write-Host ""
Write-Host "Security improvements:" -ForegroundColor Cyan
Write-Host "  - SQL password auto-generated and stored in Key Vault" -ForegroundColor Yellow
Write-Host "  - Storage connection string stored in Key Vault" -ForegroundColor Yellow  
Write-Host "  - Document Intelligence key stored in Key Vault" -ForegroundColor Yellow
Write-Host "  - Search admin key stored in Key Vault" -ForegroundColor Yellow
Write-Host "  - Function App uses managed identity for Key Vault access" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your Object ID ($userObjectId) added for Key Vault access" -ForegroundColor Green