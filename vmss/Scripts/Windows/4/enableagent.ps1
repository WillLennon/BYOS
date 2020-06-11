param
(
   [string]$url,
   [string]$pool,
   [string]$token,
   [string]$runArgs
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

Log-Message "Installing extension"
Log-Message ("URL: " + $url)
Log-Message ("Pool: " + $pool) 
Log-Message ("runArgs: " + $runArgs)
Log-Message ("agentDir: " + $agentDir)

$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path $agentDir\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"

Log-Message ("agentExe: " + $agentExe)
Log-Message ("agentZip: " + $agentZip)
Log-Message ("agentConfig: " + $agentConfig)

#unzip the agent if it doesn't exist already
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

# create administrator account
Log-Message  "Creating AzDevOps account"
$username = 'AzDevOps'
$password = (New-Guid).ToString()

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

# run the customer warmup script if it exists
# note that this runs as SYSTEM on windows
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   # run as local admin elevated
   Log-Message "Running warmup script"
   try
   {
      Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -WorkingDirectory \ -ArgumentList "-ExecutionPolicy Unrestricted $warmup"
   }
   catch
   {
      Log-Message $Error[0]
      exit -101
   }
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $token"
Log-Message "Configuring agent"
try
{
   Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
}
catch
{
   Log-Message $Error[0]
   exit -102
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

   $windows = Get-WindowsEdition -Online
   if ($windows.Edition -like '*datacenter*' -or
       $windows.Edition -like '*server*' )
   {
      Register-ScheduledTask -TaskName "PipelinesAgent" -User $username -Password $password -Trigger $time1 -Action $cmd1 -Force
   }
   else
   {
      Register-ScheduledTask -TaskName "PipelinesAgent" -User System -Trigger $time1 -Action $cmd1 -Force
   }
}
catch
{
    Log-Message $Error[0]
    exit -103
}
Log-Message "Finished"
