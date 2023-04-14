[CmdletBinding(SupportsShouldProcess)]
param (
	[Parameter(Mandatory)]
	[string]$TemplateSpecName,

    [Parameter(Mandatory)]
	[string]$Location,

    [Parameter(Mandatory)]
	[string]$ResourceGroupName,
)

New-AzTemplateSpec `
    -Name $TemplateSpecName `
    -ResourceGroupName $ResourceGroupName `
    -Version '1.0' `
    -Location $Location `
    -DisplayName "Add Build Automation to an AIB Image Template" `
    -TemplateFile '.\solution.json' `
    -UIFormDefinitionFile '.\uiDefinition.json' `
    -Force