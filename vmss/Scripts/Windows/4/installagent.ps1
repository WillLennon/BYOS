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

# testing
$installFile = "installagent.ps1"
$installFileSource = Get-ChildItem -Path .\* -Recurse -Include $installFile
$installFileDest = Join-Path -Path $agentDir -ChildPath $installFile
Copy-item $installFileSource $installFileDest

#unzip the agent if it doesn't exist already
if (!(Test-Path -Path $agentExe))
{
   Write-Host "Unzipping agent"
   [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
}

# create the local administrator account
$username = $null
$password = $null
$windows = Get-WindowsEdition -Online

if ($windows.Edition -like '*datacenter*' -or
    $windows.Edition -like '*server*' )
{
  $username = 'AzDevOps'
  $password = '*)Ns80nlsdfy89nL)' # (New-Guid).ToString()
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
  
  # TEST run a process as this user to break it in.
  Start-Process -FilePath PowerShell.exe -Credential $credential -Wait -ArgumentList "Echo hello > hello.txt"
}

# TEST disable powershell execution policy
Set-ExecutionPolicy Unrestricted

# TEST disable UAC so the warmup script doesn't prompt when we elevate
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0" 

# run the rest of the script as the local user (unelevated)
Start-Process -FilePath Powershell.exe -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs"
