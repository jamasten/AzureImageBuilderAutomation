# Azure Image Builder Automation

This solution will deploy build automation to any existing Azure Image Builder image template. The build automation uses an Automation Runbook with a Schedule to check if a new Azure Marketplace image version has been released since you're last image template build. If the Marketplace image version is newer, a new build will be initiated on the Image Template. The role assignment given to the Automation Account is the minimum required, adhering to least privilege. However, currently Azure US Government does not support the role assignment and requires the Contributor role as a workaround.

If a resource ID for an existing Log Analytics Workspace is specified during deployment, the Automation Runbook's job logs and streams will be captured in the workspace. This will allow you to create alerts around the Image Template builds so you will know when a new Image Version has been added to your Compute Gallery or when a build fails.

## Resources

The following resources are deployed with this solution:

- Action Group
- Automation Account
  - Diagnostic Setting
  - Job Schedule
  - Modules
  - Runbook
  - Schedule
  - Webhook
- Role Definitions
- Role Assignments
- Schedule Query Rules

## Prerequisites

This solution assumes certain resources have already been deployed to your Azure environment:

Required:

- Resource Group
- Image Template

Optional:

- Log Analytics Workspace

## Deployment Options

To deploy this solution, the principal must have Owner privileges on the Azure subscription.

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureImageBuilder%2Fmain%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureImageBuilder%2Fmain%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/AzureImageBuilder/main/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/AzureImageBuilder/main/solution.json'
````
