Write-Host "Starting windows_startup.ps1"

$cwd = Convert-Path .
Write-Host "Current folder:" $cwd
dir

$agentDir = "\agent"
$provisionerDir = "\provisioner"

if (!(Test-Path -Path $agentDir))
{
   Write-Host "Creating agent folder"
   New-Item -ItemType directory -Path $agentDir
}
else
{
   Write-Host "agent folder already exists"
}

if (!(Test-Path -Path $provisionerDir))
{
   Write-Host "Creating provisioner folder"
   New-Item -ItemType directory -Path $provisionerDir
}
else
{
   Write-Host "provisioner folder already exists"
}
