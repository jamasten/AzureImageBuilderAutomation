param ActionGroupName string
param DistributionGroup string
param Location string
param LogAnalyticsWorkspaceResourceId string
param Tags object


var Alerts = [
  {
    name: 'Azure Image Builder - Build Failure'
    description: 'Sends an error alert when a build fails on an image template for Azure Image Builder.'
    severity: 0
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image Template build failed"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'Azure Image Builder - Build Success'
    description: 'Sends an informational alert when a build succeeds on an image template for Azure Image Builder.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image Template build succeeded"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]
var LogAnalyticsWorkspaceName = split(LogAnalyticsWorkspaceResourceId, '/')[8]
var LogAnalyticsWorkspaceResourceGroupName = split(LogAnalyticsWorkspaceResourceId, '/')[4]
var LogAnalyticsWorkspaceSubscriptionId = split(LogAnalyticsWorkspaceResourceId, '/')[2]


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: LogAnalyticsWorkspaceName
  scope: resourceGroup(LogAnalyticsWorkspaceSubscriptionId, LogAnalyticsWorkspaceResourceGroupName)
}

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: ActionGroupName
  location: 'global'
  tags: Tags
  properties: {
    emailReceivers: [
      {
        emailAddress: DistributionGroup
        name: DistributionGroup
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    groupShortName: 'AIB Builds'
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = [for i in range(0, length(Alerts)): {
  name: Alerts[i].name
  location: Location
  tags: Tags
  kind: 'LogAlert'
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: false
    skipQueryValidation: false
    criteria: Alerts[i].criteria
    description: Alerts[i].description
    displayName: Alerts[i].name
    enabled: true
    evaluationFrequency: Alerts[i].evaluationFrequency
    severity: Alerts[i].severity
    windowSize: Alerts[i].windowSize
    scopes: [
      logAnalyticsWorkspace.id
    ]
  }
}]


output LogAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
