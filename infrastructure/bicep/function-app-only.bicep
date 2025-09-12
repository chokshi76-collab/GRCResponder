@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

// Generate unique names with environment suffix
var uniqueSuffix = take(uniqueString(resourceGroup().id, environmentName), 8)
var functionAppName = 'func-pdfai-${environmentName}-${uniqueSuffix}'
var appServicePlanName = 'asp-pdfai-${environmentName}-${uniqueSuffix}'
var keyVaultName = 'kv-pdfai-${uniqueSuffix}'
var storageAccountName = 'stpdfai${environmentName}${uniqueSuffix}'

// Reference existing resources
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// App Service Plan for Function App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    reserved: false
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${existingStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${existingStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'KEY_VAULT_URL'
          value: existingKeyVault.properties.vaultUri
        }
        {
          name: 'ENVIRONMENT_NAME'
          value: environmentName
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: '@Microsoft.KeyVault(VaultName=${existingKeyVault.name};SecretName=document-intelligence-endpoint)'
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: '@Microsoft.KeyVault(VaultName=${existingKeyVault.name};SecretName=document-intelligence-key)'
        }
        {
          name: 'AZURE_SIGNALR_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(VaultName=${existingKeyVault.name};SecretName=signalr-connection-string)'
        }
        {
          name: 'TRANSPARENCY_LOG_LEVEL'
          value: 'detailed'
        }
        {
          name: 'WEBSOCKET_MAX_CONNECTIONS'
          value: '100'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'http://localhost:3000'
          'https://localhost:3000'
          '*'
        ]
      }
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      nodeVersion: '~20'
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

// Grant Function App access to Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: existingKeyVault
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
output functionAppName string = functionApp.name
output appServicePlanName string = appServicePlan.name