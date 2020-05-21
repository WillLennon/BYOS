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

# create the local administrator account
$username = $null
$password = $null
$windows = Get-WindowsEdition -Online

if ($windows.Edition -like '*datacenter*' -or
    $windows.Edition -like '*server*' )
{
  $username = 'AzDevOps'
  $password = (New-Guid).ToString()
      echo $password > password.txt
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
   echo fileexists > fileexists.txt
   if (![String]::IsNullOrEmpty($username) -and
       ![String]::IsNullOrEmpty($password))
   {
      # run as local admin
      $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
      Start-Process powershell.exe -Credential $credential -Wait -WorkingDirectory "\" -ArgumentList "start-process powershell.exe $warmup -verb runas"
   }
   else
   {
      # run as system
      echo runassystem > runassystem.txt
      Start-Process powershell.exe -Wait -WorkingDirectory "\" -ArgumentList $warmup -Verb runas
   }
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# schedule the build agent to run
Start-Process -FilePath Powershell.exe -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs $username $password"
