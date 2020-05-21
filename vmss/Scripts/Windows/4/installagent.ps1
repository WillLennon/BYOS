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
  $password = (New-Guid).ToString()
  echo $password > c:\password.txt
  net user $username /delete
  net user $username $password /add /y
  net localgroup Administrators $username /add
  net localgroup docker-users $username /add
}

# disable UAC so the warmup script doesn't prompt when we elevate
$osversion = (Get-CimInstance Win32_OperatingSystem).Version 
$version = $osversion.split(".")[0] 
 
if ($version -eq 10) 
{ 
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0" 
} 
else
{ 
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0" 
}

# run the customer warmup script if it exists
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   echo fileexists > c:\fileexists.txt
   if (![String]::IsNullOrEmpty($username) -and
       ![String]::IsNullOrEmpty($password))
   {
      # run as local admin
      $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
      # This is wonky.  
      # We want to run powershell both elevated and as the local admin, but Powershell won't let you do both -Credential and -Verb.
      # So start a process as the local admin and then have that process start another elevated process that runs the warmup script.
      Start-Process powershell.exe -Credential $credential -Wait -ArgumentList "Start-Process powershell.exe -ArgumentList $warmup -WorkingDirectory '\' -Wait -Verb RunAs"
   }
   else
   {
      # run as system
      echo runassystem > c:\runassystem.txt
      Start-Process powershell.exe -Wait -ArgumentList $warmup -WorkingDirectory '\' -Verb RunAs
   }
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# schedule the build agent to run
Start-Process -FilePath Powershell.exe -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs $username $password"
