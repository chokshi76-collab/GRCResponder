@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

// Generate unique names with environment suffix
var uniqueSuffix = take(uniqueString(resourceGroup().id, environmentName), 8)
var storageAccountName = 'stpdfai${environmentName}${uniqueSuffix}'
var cdnProfileName = 'cdn-pdfai-${environmentName}-${uniqueSuffix}'
var cdnEndpointName = 'pdfai-demo-${environmentName}-${uniqueSuffix}'

// Storage Account for Static Website Hosting
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

// Enable static website hosting
resource storageAccountStaticWebsite 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccountName}/default/$web'
  dependsOn: [
    storageAccount
  ]
  properties: {
    publicAccess: 'Blob'
  }
}

// CDN Profile
resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: cdnProfileName
  location: 'global'
  sku: {
    name: 'Standard_Microsoft'
  }
}

// CDN Endpoint
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = {
  parent: cdnProfile
  name: cdnEndpointName
  location: 'global'
  properties: {
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
          originHostHeader: replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    originGroups: []
    defaultOriginGroup: {
      id: resourceId('Microsoft.Cdn/profiles/endpoints/originGroups', cdnProfile.name, cdnEndpointName, 'default')
    }
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'text/javascript'
      'application/x-javascript'
      'application/javascript'
      'application/json'
      'application/xml'
    ]
    isCompressionEnabled: true
    optimizationType: 'GeneralWebDelivery'
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountUrl string = storageAccount.properties.primaryEndpoints.web
output cdnEndpointUrl string = 'https://${cdnEndpoint.properties.hostName}'
output storageAccountKey string = storageAccount.listKeys().keys[0].value

// Output deployment info
output deploymentInfo object = {
  storageAccount: storageAccountName
  staticWebsiteUrl: storageAccount.properties.primaryEndpoints.web
  cdnUrl: 'https://${cdnEndpoint.properties.hostName}'
  environment: environmentName
  deploymentInstructions: [
    'Upload files to the $web container in the storage account'
    'Files will be available at both the storage URL and CDN URL'
    'Use CDN URL for production traffic'
  ]
}