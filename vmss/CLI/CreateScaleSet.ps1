param
(
   [string]$inputsFile
)

$errorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($inputsFile))
{
   #Write-Error "Please provide a json file with input parameters"
   $inputsFile = "./createScaleset.parameters.json"
}


class Inputs 
{
    [string] $SubscriptionId
    [string] $AzureRegion
    [string] $ScaleSetName
    [string] $ResourceGroup
    [string] $Image
    [string] $SKU
}

Write-Host
Write-Host "Reading inputs from" $inputsFile

$inputs = [Inputs](Get-Content $inputsFile | Out-String | ConvertFrom-Json)

Write-Host "SubscriptionId:" $inputs.SubscriptionId
Write-Host "Azure Region:" $inputs.AzureRegion
Write-Host "ScaleSet Name:" $inputs.ScaleSetName
Write-Host "Resource Group:" $inputs.ResourceGroup
Write-Host "Image:" $inputs.Image
Write-Host "SKU:" $inputs.SKU
Write-Host

Write-Host "Setting Azure Subscription"
az account set --subscription $inputs.SubscriptionId

$exists = az group exists --name $inputs.ResourceGroup
$rgExists = [System.Convert]::ToBoolean($exists)

if (-not $rgExists)
{
    Write-Host "Creating Resource Group" $inputs.ResourceGroup "in region" $inputs.AzureRegion
    az group create --name $inputs.ResourceGroup --location $inputs.AzureRegion
}
else
{
    Write-Host "Resource Group" $inputs.ResourceGroup "already exists."
}


Write-Host "Creating ScaleSet"

az vmss create `
    --name $inputs.ScaleSetName `
    --resource-group $inputs.ResourceGroup `
    --image $inputs.Image `
    --vm-sku $inputs.SKU `
    --instance-count 0 `
    --disable-overprovision `
    --upgrade-policy-mode manual `
    --storage-sku Standard_LRS `
    --load-balancer '""'

Write-Host "Done"

