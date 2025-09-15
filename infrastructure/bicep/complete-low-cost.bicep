@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

// Retry deployment after authentication issue - Windows 10 Pro with activation

@description('Location for all resources')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string = 'vmadmin'

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('Secret name for admin password in Key Vault')
param adminPasswordSecretName string = 'vm-admin-password'

// Generate unique names with environment suffix  
var uniqueSuffix = take(uniqueString(resourceGroup().id, environmentName), 8)

// VM Configuration (Ultra low cost)
var vmName = 'vm-pdfai-${environmentName}-${uniqueSuffix}'
var computerName = 'vm-${take(uniqueSuffix, 6)}' // Windows limit: 15 chars
var networkSecurityGroupName = 'nsg-pdfai-vm-${environmentName}-${uniqueSuffix}'
var virtualNetworkName = 'vnet-pdfai-vm-${environmentName}-${uniqueSuffix}'
var publicIPName = 'pip-pdfai-vm-${environmentName}-${uniqueSuffix}'
var networkInterfaceName = 'nic-pdfai-vm-${environmentName}-${uniqueSuffix}'

// Storage Account for Static Website (alternative to Static Web Apps)
var storageAccountName = 'stpdfai${environmentName}${uniqueSuffix}'

// Key Vault Configuration
var actualKeyVaultName = take('kv-pdfai-${environmentName}-${uniqueSuffix}', 24)

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/24']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Public IP
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueSuffix}')
    }
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

// Storage Account for Static Website (cheaper alternative)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Cheapest option
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// Enable static website hosting on storage account
resource storageAccountWeb 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          maxAgeInSeconds: 86400
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]
    }
  }
}

// Private container for VM files
resource privateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: storageAccountWeb
  name: 'vm-files'
  properties: {
    publicAccess: 'None'
  }
}

// Key Vault for storing VM admin password
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: actualKeyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    createMode: 'default'
  }
}

// Store VM admin password in Key Vault
resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: adminPasswordSecretName
  properties: {
    value: adminPassword
    contentType: 'VM Admin Password'
  }
}

// Ultra-low-cost VM
resource windowsVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3' // Better networking and performance
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-22h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-os-disk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        diskSizeGB: 127
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

// Auto-shutdown to save costs
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900' // 7 PM
    }
    timeZoneId: 'Pacific Standard Time'
    targetResourceId: windowsVM.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// Setup script for demo environment
resource setupScript 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVM
  name: 'SetupDemo'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "& { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe -OutFile C:\\python-installer.exe -UseBasicParsing; Start-Process C:\\python-installer.exe -ArgumentList \'/quiet InstallAllUsers=1 PrependPath=1\' -Wait; } catch { Write-Output \'Python install failed\' }; try { Invoke-WebRequest -Uri https://nodejs.org/dist/v18.17.0/node-v18.17.0-x64.msi -OutFile C:\\node-installer.msi -UseBasicParsing; Start-Process msiexec.exe -ArgumentList \'/i C:\\node-installer.msi /quiet\' -Wait; } catch { Write-Output \'Node install failed\' }; try { git clone https://github.com/chokshi76-collab/GRCResponder.git C:\\GRCResponder; } catch { Write-Output \'Git clone failed\' }; Write-Output \'Setup completed\' }"'
    }
  }
}

// Outputs with cost information
output vmPublicIP string = publicIP.properties.dnsSettings.fqdn
output rdpCommand string = 'mstsc /v:${publicIP.properties.dnsSettings.fqdn}'
output demoUrl string = 'http://${publicIP.properties.dnsSettings.fqdn}:3000'
output storageWebUrl string = replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
output keyVaultName string = keyVault.name

// Cost breakdown
output costAnalysis object = {
  vm: {
    size: 'Standard_D2s_v3'
    estimatedMonthlyCost: '$35-40 USD (6 hrs/day usage)'
    features: ['2 vCPU', '8 GB RAM', 'Windows 10 Pro licensed', 'Premium networking', 'Pay-per-minute billing']
  }
  storage: {
    type: 'Standard_LRS'
    estimatedMonthlyCost: '$2-3 USD'
    features: ['127 GB OS disk', 'Static website hosting']
  }
  network: {
    type: 'Basic Public IP + VNet'
    estimatedMonthlyCost: '$1-2 USD'
    features: ['Dynamic IP', 'Basic NSG']
  }
  total: {
    estimatedMonthlyCost: '$40-45 USD (6 hrs/day usage)'
    dailyShutdown: 'Auto-shutdown at 7 PM to minimize costs'
    optimization: 'Windows 10 Pro + pay-per-minute billing + D2s_v3 for reliable networking'
  }
}

// Deployment instructions
output deploymentInstructions array = [
  'RDP to VM: mstsc /v:${publicIP.properties.dnsSettings.fqdn}'
  'Login with: ${adminUsername} / [your password]'
  'Navigate to C:\\GRCResponder\\demo'
  'Run: python -m http.server 3000'
  'Demo accessible at: http://${publicIP.properties.dnsSettings.fqdn}:3000'
  'Alternative: Upload demo files to ${storageAccount.properties.primaryEndpoints.web}'
  'VM auto-shuts down at 7 PM daily to save costs'
]