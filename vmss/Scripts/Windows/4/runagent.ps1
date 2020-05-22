param
(
   [string]$url,
   [string]$pool,
   [string]$pat,
   [string]$runArgs
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$agentDir = $PSScriptRoot
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"

# run the customer warmup script if it exists
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   $now = Get-Date
   echo $now > c:\start.txt

   # run as local admin elevated
   Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -WorkingDirectory \ -ArgumentList "-ExecutionPolicy Unrestricted $warmup"
   $now = Get-Date
   echo $now > c:\finish.txt
}

# configure the build agent
# the agent will register with Azure DevOps but will not start
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -Wait -WorkingDirectory $agentDir -Verb RunAs

# now schedule the build agent to run
# we cannot just run this because the extension won't exit if a process we started is still running
$start1 = (Get-Date).AddSeconds(15)
$time1 = New-ScheduledTaskTrigger -At $start1 -Once 
if([string]::IsNullOrEmpty($runArgs))
{
  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent"
}
else
{
  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" -Argument $runArgs
}

$windows = Get-WindowsEdition -Online

if ($windows.Edition -like '*datacenter*' -or
    $windows.Edition -like '*server*' )
{
  # for reasons unknown we cannot run this as the local user on Windows 10 client machines
  Register-ScheduledTask -TaskName "BuildAgent" -User $username -Password $password -Trigger $time1 -Action $cmd1 -Force
}
else
{
  Register-ScheduledTask -TaskName "BuildAgent" -User System -Trigger $time1 -Action $cmd1 -Force
}

# Schedule a task to delete the status folder from custom script extension directory
$start2 = (Get-Date).AddSeconds(15)
$time2 = New-ScheduledTaskTrigger -At $start2 -Once 
$cmd2 = New-ScheduledTaskAction -Execute Powershell.exe -Argument 'Remove-Item "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status" -Recurse -ErrorAction Ignore'
Register-ScheduledTask -TaskName "ExtensionCleanup" -User System -Trigger $time2 -Action $cmd2 -Force
