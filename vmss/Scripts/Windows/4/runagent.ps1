param
(
   [string]$url,
   [string]$pool,
   [string]$pat,
   [string]$runArgs
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# run the customer warmup script if it exists
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   $now = Get-Date
   echo $now > c:\start.txt

   # run as local admin elevated
   Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -ArgumentList "-ExecutionPolicy Unrestricted $warmup"
   $now = Get-Date
   echo $now > c:\finish.txt
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir -Verb RunAs

# schedule the build agent to run
$start1 = (Get-Date).AddSeconds(15)
$time1 = New-ScheduledTaskTrigger -At $start1 -Once 
if([string]::IsNullOrEmpty($runArgs))
{  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" }
else
{  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" $runArgs }

Register-ScheduledTask -TaskName "BuildAgent" -Trigger $time1 -Action $cmd1 -Force

# delete the status folder from custom script extension directory
$start2 = (Get-Date).AddSeconds(15)
$time2 = New-ScheduledTaskTrigger -At $start2 -Once 
$cmd2 = New-ScheduledTaskAction -Execute Powershell.exe -Argument 'Remove-Item "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status" -Recurse -ErrorAction Ignore'
Register-ScheduledTask -TaskName "ExtensionCleanup" -User System -Trigger $time2 -Action $cmd2 -Force
