param
(
   [string]$inputsFile
)

$errorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($inputsFile))
{
   $inputsFile = "./CreateScaleset.parameters.json"
}

# For more details about the input parameters, see
# https://docs.microsoft.com/en-us/cli/azure/vmss?view=azure-cli-latest#az-vmss-create

class Inputs 
{
    [string] $SubscriptionId
    [string] $AzureRegion
    [string] $ScaleSetName
    [string] $ResourceGroup
    [string] $Image
    [string] $VMSKU
    [string] $StorageSKU
    [string] $AuthenticationType
    [string] $AdminUsername
    [string] $AdminPassword
}

Write-Host
Write-Host "Reading inputs from" $inputsFile

$inputs = [Inputs]((Get-Content $inputsFile)  -replace '^\s*//.*' | Out-String | ConvertFrom-Json)
$inputs

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
    --vm-sku $inputs.VMSKU `
    --storage-sku $inputs.StorageSKU `
    --authentication-type $inputs.AuthenticationType `
    --admin-username $inputs.AdminUsername `
    --admin-password $inputs.AdminPassword `
    --instance-count 0 `
    --disable-overprovision `
    --upgrade-policy-mode manual `
    --load-balancer '""' `

Write-Host "Done"
