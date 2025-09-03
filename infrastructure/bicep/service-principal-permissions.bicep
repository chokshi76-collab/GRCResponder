// Service Principal Permissions Module
// Grants necessary permissions to the GitHub Actions service principal for full IaC operations

@description('The object ID of the service principal that needs permissions')
param servicePrincipalObjectId string = 'fc6bf2d2-9da2-49d8-a673-4eab4d4b2b44'

@description('The resource group name for scoped permissions')
param resourceGroupName string

@description('The subscription ID for role assignments')
param subscriptionId string

// Built-in Azure role definitions
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var deploymentOperatorRoleId = '8de5b822-6209-428e-986c-c854b1c6b2d1'
var userAccessAdministratorRoleId = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'

// Get reference to the existing resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope: subscription(subscriptionId)
}

// Contributor role assignment for general resource management
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup.id, servicePrincipalObjectId, contributorRoleId)
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions service principal - Contributor access for resource management'
  }
}

// Deployment Operator role assignment for what-if operations
resource deploymentOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup.id, servicePrincipalObjectId, deploymentOperatorRoleId)
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', deploymentOperatorRoleId)
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions service principal - Deployment Operator for what-if analysis'
  }
}

// User Access Administrator for managing role assignments (limited scope)
resource userAccessAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup.id, servicePrincipalObjectId, userAccessAdministratorRoleId)
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', userAccessAdministratorRoleId)
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions service principal - User Access Administrator for role management within resource group'
  }
}

// Outputs for verification
output contributorRoleAssignmentId string = contributorRoleAssignment.id
output deploymentOperatorRoleAssignmentId string = deploymentOperatorRoleAssignment.id
output userAccessAdminRoleAssignmentId string = userAccessAdminRoleAssignment.id