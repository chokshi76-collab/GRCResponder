@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('User Object ID for Key Vault access')
param userObjectId string

// Generate unique names
var uniqueSuffix = uniqueString(resourceGroup().id, environmentName)
var storageAccountName = 'stpdfai${environmentName}${uniqueSuffix}'

// Test with just a storage account first
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

output storageAccountName string = storageAccount.name