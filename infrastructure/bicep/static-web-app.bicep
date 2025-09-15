@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('GitHub repository URL for the frontend')
param repositoryUrl string = 'https://github.com/chokshi76-collab/GRCResponder'

@description('GitHub repository token for deployment')
@secure()
param repositoryToken string = ''

// Generate unique names with environment suffix
var uniqueSuffix = take(uniqueString(resourceGroup().id, environmentName), 8)
var staticWebAppName = 'swa-pdfai-frontend-${environmentName}-${uniqueSuffix}'

// Static Web App for Frontend - Create without GitHub integration first
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    // Only include GitHub properties if token is provided
    repositoryUrl: !empty(repositoryToken) ? repositoryUrl : null
    branch: !empty(repositoryToken) ? 'main' : null
    repositoryToken: !empty(repositoryToken) ? repositoryToken : null
    buildProperties: !empty(repositoryToken) ? {
      appLocation: '/demo'
      outputLocation: ''
    } : null
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

// Custom domain and SSL will be automatically handled by Static Web Apps

// Outputs
output staticWebAppName string = staticWebApp.name
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
output staticWebAppId string = staticWebApp.id

// Output the deployment details
output deploymentInfo object = {
  name: staticWebAppName
  url: 'https://${staticWebApp.properties.defaultHostname}'
  resourceGroup: resourceGroup().name
  environment: environmentName
  repositoryUrl: repositoryUrl
  branch: 'main'
  buildLocation: '/demo'
}