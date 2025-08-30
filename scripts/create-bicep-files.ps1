# Create Bicep infrastructure files
Write-Host "Creating Bicep infrastructure files..." -ForegroundColor Green

# Create directories
New-Item -ItemType Directory -Force -Path "infrastructure"
New-Item -ItemType Directory -Force -Path "infrastructure/bicep"

# Create main.bicep file
$mainBicep = @"
targetScope = 'resourceGroup'

@description('Environment name (e.g., dev, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('SQL Administrator username')
param sqlAdminUsername string = 'sqladmin'

@description('SQL Administrator password')
@secure()
param sqlAdminPassword string

// Variables
var prefix = 'pdf-ai-agent'
var storageAccountName = 'pdfaiagentstorage001'

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
          value: 'DefaultEndpointsProtocol=https;AccountName=`${storageAccount.name};EndpointSuffix=`${environment().suffixes.storage};AccountKey=`${storageAccount.listKeys().keys[0].value}'
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
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output documentIntelligenceEndpoint string = documentIntelligence.properties.endpoint
output searchServiceName string = searchService.name
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output functionAppName string = functionApp.name
"@

# Create parameters.dev.json file
$parametersJson = @"
{
  "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "dev"
    },
    "sqlAdminPassword": {
      "value": "TempPassword123!"
    }
  }
}
"@

# Write files
$mainBicep | Out-File -FilePath "infrastructure/bicep/main.bicep" -Encoding UTF8
$parametersJson | Out-File -FilePath "infrastructure/bicep/parameters.dev.json" -Encoding UTF8

Write-Host "Bicep files created successfully!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  - infrastructure/bicep/main.bicep" -ForegroundColor Yellow
Write-Host "  - infrastructure/bicep/parameters.dev.json" -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: Using temporary SQL password 'TempPassword123!' - change this in production!" -ForegroundColor Yellow