param
(
   [string]$url,
   [string]$pool,
   [string]$token,
   [string]$runArgs,
   [switch]$interactive
)

function Log-Message 
{
   param ([string] $message)

   $now = [DateTime]::UtcNow.ToString('u')
   $text = $now + " " + $message
   $logFile = "script.log"
   if (!(Test-Path -Path $logFile))
   {
      Set-Content -Path $logFile -Value ""
   }
   Add-Content -Path $logFile -Value $text
   Write-Host $text
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$agentDir = $PSScriptRoot

Log-Message "Installing extension v8"
Log-Message ("URL: " + $url)
Log-Message ("Pool: " + $pool) 
Log-Message ("runArgs: " + $runArgs)
Log-Message ("interactive: " + $interactive)
Log-Message ("agentDir: " + $agentDir)

$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path $agentDir\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"

Log-Message ("agentExe: " + $agentExe)
Log-Message ("agentZip: " + $agentZip)
Log-Message ("agentConfig: " + $agentConfig)

$version = (Get-WmiObject Win32_OperatingSystem).Version
Log-Message ("Windows version: " + $version)
$windows = Get-WindowsEdition -Online
Log-Message ("Windows edition: " + $windows.Edition)

# Determine if we should run as local user AzDevOps or as LocalSystem
# We can only run as the local user if this is Windows 10 Server/DataCenter
$runAsUser = (($version -like '10.*') `
              -and ($windows.Edition -like '*datacenter*' -or $windows.Edition -like '*server*' ))
Log-Message ("runAsUser: " + $runAsUser)

# If the agent was already configured.  Abort.
if (Test-Path -Path (Join-Path -Path $agentDir -ChildPath ".agent"))
{
   Log-Message "Agent was already configured.  Doing nothing."
   exit 0
}

# Disable Windows Updates so the machine won't spontaneously reboot
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name AUOptions -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoRebootWithLoggedOnUsers -Value 0

# set the agent working directory to 'C:\a' if the environment variable is not set already
$workDir = [System.Environment]::GetEnvironmentVariable('VSTS_AGENT_INPUT_WORK')
if (![string]::IsNullOrEmpty($workDir))
{
    Log-Message ("Found WorkDir: " + $workDir)
}
else
{
    $drive = (Get-Location).Drive.Name + ":"
    $workDir = Join-Path -Path $drive -ChildPath "a"
    [System.Environment]::SetEnvironmentVariable('VSTS_AGENT_INPUT_WORK', $workDir, 'process')
    [System.Environment]::SetEnvironmentVariable('VSTS_AGENT_INPUT_WORK', $workDir, 'machine')
    Log-Message ("Setting WorkDir: " + $workDir)
}

# unzip the agent if it doesn't exist already
if (!(Test-Path -Path $agentExe))
{
   Log-Message "Unzipping Agent"
   try
   {
      [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
      Remove-Item $agentZip
   }
   catch
   {
      Log-Message $Error[0]
      exit -100
   }
}

if ($runAsUser)
{
   # create administrator account
   $username = 'AzDevOps'
   $password = (New-Guid).ToString()
   $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

   if (!(Get-LocalUser -Name $username -ErrorAction Ignore))
   {
      Log-Message "Creating AzDevOps user"
      New-LocalUser -Name $username -Password $securePassword
   }
   else
   {
      Log-Message "Setting AzDevOps password"
      Set-LocalUser -Name $username -Password $securePassword 
   }

   # Confirm the local user exists or abort if not
   if (!(Get-LocalUser -Name $username))
   {
      Log-Message "Failed to create AzDevOps user"
      exit -105
   }

   if ((Get-LocalGroup -Name "Users" -ErrorAction Ignore) -and
       !(Get-LocalGroupMember -Group "Users" -Member $username -ErrorAction Ignore))
   {
      Log-Message "Adding AzDevOps to Users"
      Add-LocalGroupMember -Group "Users" -Member $username
   }
   if ((Get-LocalGroup -Name "Administrators" -ErrorAction Ignore) -and
       !(Get-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction Ignore))
   {
      Log-Message "Adding AzDevOps to Administrators"
      Add-LocalGroupMember -Group "Administrators" -Member $username
   }
   if ((Get-LocalGroup -Name "docker-users" -ErrorAction Ignore) -and
       !(Get-LocalGroupMember -Group "docker-users" -Member $username -ErrorAction Ignore))
   {
      Log-Message "Adding AzDevOps to docker-users"
      Add-LocalGroupMember -Group "docker-users" -Member $username
   }

   if ($interactive)
   {
      Log-Message "Configuring agent to reboot, autologon, and run unelevated as AzDevOps with interactive UI"
      $configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --replace --runAsAutoLogon --overwriteAutoLogon --windowsLogonAccount $username --windowsLogonPassword $password --token $token"
      try
      {
         Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
      }
      catch
      {
         Log-Message $Error[0]
         exit -102
      }
   }
   else
   {
      Log-Message "Configuring agent to run elevated as AzDevOps without interactive UI"
      $configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --replace --runAsService --windowsLogonAccount $username --windowsLogonPassword $password --token $token"
      try
      {
         Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
      }
      catch
      {
         Log-Message $Error[0]
         exit -106
      }

      Log-Message "Scheduling agent to run"
      $runCmd = Join-Path -Path $agentDir -ChildPath "run.cmd"
      try
      {
         if([string]::IsNullOrEmpty($runArgs))
         {
            $cmd1 = New-ScheduledTaskAction -Execute $runCmd -WorkingDirectory $agentDir
         }
         else
         {
            $cmd1 = New-ScheduledTaskAction -Execute $runCmd -WorkingDirectory $agentDir $runArgs
         }

         $start1 = (Get-Date).AddSeconds(10)
         $time1 = New-ScheduledTaskTrigger -At $start1 -Once 
         Register-ScheduledTask -TaskName "PipelinesAgent" -User $username -Password $password -RunLevel Highest -Trigger $time1 -Action $cmd1 -Force
      }
      catch
      {
          Log-Message $Error[0]
          exit -108
      }
   }
}
else
{
   Log-Message "Configuring agent to run as Local System"

   $configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --replace --runAsService --token $token"
   try
   {
      Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
   }
   catch
   {
      Log-Message $Error[0]
      exit -107
   }

   $runCmd = Join-Path -Path $agentDir -ChildPath "run.cmd"
   Log-Message "Scheduling agent to run"

   try
   {
      if([string]::IsNullOrEmpty($runArgs))
      {
         $cmd1 = New-ScheduledTaskAction -Execute $runCmd -WorkingDirectory $agentDir
      }
      else
      {
         $cmd1 = New-ScheduledTaskAction -Execute $runCmd -WorkingDirectory $agentDir $runArgs
      }

      $start1 = (Get-Date).AddSeconds(10)
      $time1 = New-ScheduledTaskTrigger -At $start1 -Once 
      Register-ScheduledTask -TaskName "PipelinesAgent" -User System -Trigger $time1 -Action $cmd1 -Force
   }
   catch
   {
       Log-Message $Error[0]
       exit -103
   }
}

Log-Message "Finished"
