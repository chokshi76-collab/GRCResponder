@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string = 'vmadmin'

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('Auto-shutdown time (24-hour format, e.g., 1900 for 7 PM)')
param autoShutdownTime string = '1900'

@description('Time zone for auto-shutdown')
param timeZone string = 'Pacific Standard Time'

// Generate unique names with environment suffix
var uniqueSuffix = take(uniqueString(resourceGroup().id, environmentName), 8)
var vmName = 'vm-pdfai-${environmentName}-${uniqueSuffix}'
var networkSecurityGroupName = 'nsg-pdfai-vm-${environmentName}-${uniqueSuffix}'
var virtualNetworkName = 'vnet-pdfai-vm-${environmentName}-${uniqueSuffix}'
var publicIPName = 'pip-pdfai-vm-${environmentName}-${uniqueSuffix}'
var networkInterfaceName = 'nic-pdfai-vm-${environmentName}-${uniqueSuffix}'
var osDiskName = '${vmName}-os-disk'

// Network Security Group (minimal rules for cost)
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*' // In production, restrict this to your IP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTP'
        properties: {
          description: 'Allow HTTP for demo'
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

// Virtual Network (minimal configuration)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/24'
      ]
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

// Public IP (Basic SKU for cost savings)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Basic' // Cheapest option
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic' // Cheaper than Static
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

// Virtual Machine (Smallest possible size)
resource windowsVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s' // Burstable, cheapest Windows option (~$15/month)
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-core' // Core edition for lower cost
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS' // Cheapest storage
        }
        diskSizeGB: 127 // Minimum for Windows Server
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
        enabled: false // Disable to save costs
      }
    }
  }
}

// Auto-shutdown schedule to minimize costs
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: timeZone
    targetResourceId: windowsVM.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// PowerShell extension to setup demo environment
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
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "& { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe -OutFile C:\\python-installer.exe; Start-Process C:\\python-installer.exe -ArgumentList \'/quiet InstallAllUsers=1 PrependPath=1\' -Wait; Invoke-WebRequest -Uri https://nodejs.org/dist/v18.17.0/node-v18.17.0-x64.msi -OutFile C:\\node-installer.msi; Start-Process msiexec.exe -ArgumentList \'/i C:\\node-installer.msi /quiet\' -Wait; git clone https://github.com/chokshi76-collab/GRCResponder.git C:\\GRCResponder; Write-Output \'Setup complete. Python, Node.js, and demo code installed.\' }"'
    }
  }
}

// Outputs
output vmName string = windowsVM.name
output publicIPAddress string = publicIP.properties.dnsSettings.fqdn
output rdpCommand string = 'mstsc /v:${publicIP.properties.dnsSettings.fqdn}'
output demoUrl string = 'http://${publicIP.properties.dnsSettings.fqdn}:3000'
output estimatedMonthlyCost string = '$15-20 USD (B1s VM + storage + network)'
output costOptimizations array = [
  'Auto-shutdown at ${autoShutdownTime} daily'
  'Standard_LRS storage (cheapest)'
  'Basic SKU Public IP'
  'No boot diagnostics'
  'Minimal network configuration'
  'Windows Server Core edition'
]

// Deployment info with cost breakdown
output deploymentInfo object = {
  vmName: vmName
  size: 'Standard_B1s'
  os: 'Windows Server 2022 Datacenter Core'
  storage: 'Standard_LRS'
  publicIp: publicIP.properties.dnsSettings.fqdn
  autoShutdown: '${autoShutdownTime} ${timeZone}'
  estimatedCosts: {
    vm: '$12-15/month (B1s burstable)'
    storage: '$1-2/month (127GB Standard_LRS)'
    network: '$1-3/month (Basic IP + bandwidth)'
    total: '$15-20/month'
  }
  accessInstructions: [
    'RDP: mstsc /v:${publicIP.properties.dnsSettings.fqdn}'
    'Demo: http://${publicIP.properties.dnsSettings.fqdn}:3000'
    'Credentials: ${adminUsername} / [provided password]'
    'Auto-shuts down at ${autoShutdownTime} to save costs'
  ]
}