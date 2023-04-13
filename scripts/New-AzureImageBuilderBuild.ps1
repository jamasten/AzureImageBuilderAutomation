[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$EnvironmentName,

	[Parameter(Mandatory)]
	[string]$ImageTemplateName,

	[Parameter(Mandatory)]
	[string]$ImageTemplateResourceGroupName,

	[Parameter(Mandatory)]
	[string]$Location,

	[Parameter(Mandatory)]
	[string]$SubscriptionId,

	[Parameter(Mandatory)]
	[string]$TenantId
)

$ErrorActionPreference = 'Stop'

try 
{
    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.ImageBuilder'
    Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Imported the required modules."

    # Connect to Azure using the Managed Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Connected to Azure."

	# Get the date / time and status of the last AIB Image Template build
	$ImageBuild = Get-AzImageBuilderTemplate -ResourceGroupName $ImageTemplateResourceGroupName -Name $ImageTemplateName
	$ImageBuildDate = $ImageBuild.LastRunStatusStartTime
	if(!$ImageBuildDate)
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Last Build Start Time: None."
	}
	else 
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Last Build Start Time: $ImageBuildDate."
	}
	$ImageBuildStatus = $ImageBuild.LastRunStatusRunState
	if(!$ImageBuildStatus)
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Last Build Run State: None."
	}
	else 
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Last Build Run State: $ImageBuildStatus."
	}


	# Get the date of the latest marketplace image version
	$ImageVersionDateRaw = (Get-AzVMImage -Location $Location -PublisherName $ImageBuild.Source.Publisher -Offer $ImageBuild.Source.Offer -Skus $ImageBuild.Source.Sku | Sort-Object -Property 'Version' -Descending | Select-Object -First 1).Version.Split('.')[-1]
	$Year = '20' + $ImageVersionDateRaw.Substring(0,2)
	$Month = $ImageVersionDateRaw.Substring(2,2)
	$Day = $ImageVersionDateRaw.Substring(4,2)
	$ImageVersionDate = Get-Date -Year $Year -Month $Month -Day $Day -Hour 00 -Minute 00 -Second 00
	Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Marketplace Image, Latest Version Date: $ImageVersionDate."

	# If the latest Image Template build is in a failed state, output a message and throw an error
	if($ImageBuildStatus -eq 'Failed')
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Latest Image Template build failed. Review the build log and correct the issue."
		throw
	}
	# If the latest Marketplace Image Version was released after the last AIB Image Template build then trigger a new AIB Image Template build
	elseif($ImageVersionDate -gt $ImageBuildDate)
	{   
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Image Template build initiated with new Marketplace Image Version."
		Start-AzImageBuilderTemplate -ResourceGroupName $ImageTemplateResourceGroupName -Name $ImageTemplateName
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Image Template build succeeded. New Image Version available in Compute Gallery."
	}
	else 
	{
		Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Image Template build not required. Marketplace Image Version is older than the latest Image Template build."
	}
}
catch {
	Write-Output "$ImageTemplateName | $ImageTemplateResourceGroupName | Latest Image Template build failed. Review the build log and correct the issue."
	throw
}