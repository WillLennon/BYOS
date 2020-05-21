param
(
   [string]$runArgs
)

# v4
# schedule the build agent to run
$start1 = (Get-Date).AddSeconds(15)
$time1 = New-ScheduledTaskTrigger -At $start1 -Once 
if([string]::IsNullOrEmpty($runArgs))
{  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" }
else
{  $cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" $runArgs }

$windows = Get-WindowsEdition -Online

if ($windows.Edition -like '*datacenter*' -or
    $windows.Edition -like '*server*' )
{
  # create administrator account
  $username = 'AzDevOps'
  $password = (New-Guid).ToString()
  net user $username /delete
  net user $username $password /add /y
  net localgroup Administrators $username /add
  Register-ScheduledTask -TaskName "BuildAgent" -User $username -Password $password -Trigger $time1 -Action $cmd1 -Force
}
else
{
  Register-ScheduledTask -TaskName "BuildAgent" -User System -Trigger $time1 -Action $cmd1 -Force
}

# delete the status folder from custom script extension directory
$start2 = (Get-Date).AddSeconds(15)
$time2 = New-ScheduledTaskTrigger -At $start2 -Once 
$cmd2 = New-ScheduledTaskAction -Execute Powershell.exe -Argument 'Remove-Item "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status" -Recurse -ErrorAction Ignore'
Register-ScheduledTask -TaskName "ExtensionCleanup" -User System -Trigger $time2 -Action $cmd2 -Force
