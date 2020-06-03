param
(
   [string]$url,
   [string]$pool,
   [string]$token
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$agentDir = $PSScriptRoot
$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path .\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"

#unzip the agent if it doesn't exist already
if (!(Test-Path -Path $agentExe))
{
   Write-Host "Unzipping agent"
   [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
}

# create administrator account
$username = 'AzDevOps'
Set-Content -Path username.txt -Value $username
$password = (New-Guid).ToString()
Set-Content -Path password.txt -Value $password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

if (!(Get-LocalUser -Name $username -ErrorAction Ignore))
{
  New-LocalUser -Name $username -Password $securePassword
}
else
{
  Set-LocalUser -Name $username -Password $securePassword 
}
if ((Get-LocalGroup -Name "Users" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "Users" -Member $username -ErrorAction Ignore))
{
  Add-LocalGroupMember -Group "Users" -Member $username
}
if ((Get-LocalGroup -Name "Administrators" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction Ignore))
{
  Add-LocalGroupMember -Group "Administrators" -Member $username
}
if ((Get-LocalGroup -Name "docker-users" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "docker-users" -Member $username -ErrorAction Ignore))
{
  Add-LocalGroupMember -Group "docker-users" -Member $username
}

# run the customer warmup script if it exists
# note that this runs as SYSTEM on windows
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   # run as local admin elevated
   Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -WorkingDirectory \ -ArgumentList "-ExecutionPolicy Unrestricted $warmup"
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $token"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
