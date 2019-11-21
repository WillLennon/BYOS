Write-Host "Starting windows_startup.ps1"

$cwd = Convert-Path .
Write-Host "Current folder:" $cwd

Write-Host "Parent folder:"
cd ..
dir -s

$agentDir = "\agent"
$provisionDir = "\provisioner"

if (!(Test-Path -Path $agentDir))
{
   Write-Host "Creating agent folder"
   New-Item -ItemType directory -Path $agentDir
}
else
{
   Write-Host "agent folder already exists"
}

cd $agentDir

$cwd = Convert-Path .
Write-Host "Current folder:" $cwd

dir
