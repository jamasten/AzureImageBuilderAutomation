targetScope = 'subscription'


@description('The distribution group that will recieve email alerts when an AIB image build either succeeds or fails.')
param DistributionGroup string = ''

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The resource ID for an existing image template.')
param ImageTemplateResourceId string

@description('The location for the resources deployed in this solution.')
param Location string = deployment().location

@description('The resource ID for an existing log analytics workspace.')
param LogAnalyticsWorkspaceResourceId string = ''

@description('The name of the target resource group for the resources in this solution.')
param ResourceGroupName string

@description('The key / values pairs of meta data for the resources.')
param Tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')


var ActionGroupName = 'ag-${NamingStandard}'
var AutomationAccountName = 'aa-${NamingStandard}'
var LocationShortName = LocationShortNames[Location]
var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  chinaeast: 'ce'
  chinaeast2: 'ce2'
  chinanorth: 'cn'
  chinanorth2: 'cn2'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne2'
  norwayeast: 'ne'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southindia: 'si'
  southeastasia: 'sa'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'io'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var NamingStandard = 'aib-${Environment}-${LocationShortName}'
var TimeZone = TimeZones[Location]
var TimeZones = {
  australiacentral: 'AUS Eastern Standard Time'
  australiacentral2: 'AUS Eastern Standard Time'
  australiaeast: 'AUS Eastern Standard Time'
  australiasoutheast: 'AUS Eastern Standard Time'
  brazilsouth: 'E. South America Standard Time'
  brazilsoutheast: 'E. South America Standard Time'
  canadacentral: 'Eastern Standard Time'
  canadaeast: 'Eastern Standard Time'
  centralindia: 'India Standard Time'
  centralus: 'Central Standard Time'
  chinaeast: 'China Standard Time'
  chinaeast2: 'China Standard Time'
  chinanorth: 'China Standard Time'
  chinanorth2: 'China Standard Time'
  eastasia: 'China Standard Time'
  eastus: 'Eastern Standard Time'
  eastus2: 'Eastern Standard Time'
  francecentral: 'Central Europe Standard Time'
  francesouth: 'Central Europe Standard Time'
  germanynorth: 'Central Europe Standard Time'
  germanywestcentral: 'Central Europe Standard Time'
  japaneast: 'Tokyo Standard Time'
  japanwest: 'Tokyo Standard Time'
  jioindiacentral: 'India Standard Time'
  jioindiawest: 'India Standard Time'
  koreacentral: 'Korea Standard Time'
  koreasouth: 'Korea Standard Time'
  northcentralus: 'Central Standard Time'
  northeurope: 'GMT Standard Time'
  norwayeast: 'Central Europe Standard Time'
  norwaywest: 'Central Europe Standard Time'
  southafricanorth: 'South Africa Standard Time'
  southafricawest: 'South Africa Standard Time'
  southcentralus: 'Central Standard Time'
  southindia: 'India Standard Time'
  southeastasia: 'Singapore Standard Time'
  swedencentral: 'Central Europe Standard Time'
  switzerlandnorth: 'Central Europe Standard Time'
  switzerlandwest: 'Central Europe Standard Time'
  uaecentral: 'Arabian Standard Time'
  uaenorth: 'Arabian Standard Time'
  uksouth: 'GMT Standard Time'
  ukwest: 'GMT Standard Time'
  usdodcentral: 'Central Standard Time'
  usdodeast: 'Eastern Standard Time'
  usgovarizona: 'Mountain Standard Time'
  usgoviowa: 'Central Standard Time'
  usgovtexas: 'Central Standard Time'
  usgovvirginia: 'Eastern Standard Time'
  westcentralus: 'Mountain Standard Time'
  westeurope: 'Central Europe Standard Time'
  westindia: 'India Standard Time'
  westus: 'Pacific Standard Time'
  westus2: 'Pacific Standard Time'
  westus3: 'Mountain Standard Time'
}


resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' existing = {
  name: ResourceGroupName
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2015-07-01' = if(environment().name == 'AzureCloud') {
  name: guid('Image Template Build Automation', subscription().id)
  properties: {
    roleName: 'Image Template Build Automation (${subscription().subscriptionId})'
    description: 'Allow Image Template build automation using a Managed Identity on an Automation Account.'
    permissions: [
      {
        actions: [
          'Microsoft.VirtualMachineImages/imageTemplates/run/action'
          'Microsoft.VirtualMachineImages/imageTemplates/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/skus/versions/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/skus/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/read'
          'Microsoft.Compute/locations/publishers/read'
        ]
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

module roleAssignments 'modules/roleAssignment.bicep' = {
  name: 'RoleAssignment_${Timestamp}'
  scope: rg
  params: {
    PrincipalId: automationAccount.outputs.principalId
    RoleDefinitionId: environment().name == 'AzureCloud' ? roleDefinition.name : 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
}

module monitoring 'modules/monitoring.bicep' = if(!empty(LogAnalyticsWorkspaceResourceId) && !empty(DistributionGroup)) {
  name: 'Monitoring_${Timestamp}'
  scope: rg
  params: {
    ActionGroupName: ActionGroupName
    DistributionGroup: DistributionGroup
    Location: Location
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    Tags: Tags
  }
}

module automationAccount 'modules/buildAutomation.bicep' = {
  name: 'AutomationAccount_${Timestamp}'
  scope: rg
  params: {
    AutomationAccountName: AutomationAccountName
    ImageTemplateResourceId: ImageTemplateResourceId
    Location: Location
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    TimeZone: TimeZone
  }
}
