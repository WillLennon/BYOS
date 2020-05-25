param
(
   [string]$url,
   [string]$pool,
   [string]$pat,
   [string]$runArgs
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$agentDir = "\agent"
$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path .\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"

# install the build agent if necessary
if (!(Test-Path -Path $agentDir))
{
   Write-Host "Creating agent folder"
   New-Item -ItemType directory -Path $agentDir
}

# copy run script to the agent folder
$runFile = "runagent.ps1"
$runFileSource = Get-ChildItem -Path .\* -Recurse -Include $runFile
$runFileDest = Join-Path -Path $agentDir -ChildPath $runFile
Copy-item $runFileSource $runFileDest

#unzip the agent if it doesn't exist already
if (!(Test-Path -Path $agentExe))
{
   Write-Host "Unzipping agent"
   [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
}

# create administrator account
$username = 'AzDevOps'
$password = (New-Guid).ToString()
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
if (!(Get-LocalUser -Name $username -ErrorAction Ignore))
{
  New-LocalUser -Name $username -Password $securePassword
  Add-LocalGroupMember -Group "Users" -Member $username
  Add-LocalGroupMember -Group "Administrators" -Member $username
  if (Get-LocalGroupMember -Name $username -ErrorAction Ignore)
  {
    Add-LocalGroupMember -Group "docker-users" -Member $username
  }
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
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# schedule the build agent to run
$argList = "-ExecutionPolicy Unrestricted -File $runFileDest -username $username -password $password $runArgs"
Start-Process -FilePath Powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs"
