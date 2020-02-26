param
(
   [string]$runArgs
)

# schedule the build agent to run
$start1 = (Get-Date).AddSeconds(15)
$time1 = New-ScheduledTaskTrigger -At $start1 -Once 
$cmd1 = New-ScheduledTaskAction -Execute "C:\agent\run.cmd" -WorkingDirectory "C:\agent" $runArgs
Register-ScheduledTask -TaskName "BuildAgent" -User System -Trigger $time1 -Action $cmd1 -TaskPath "C:\agent" -Force

# delete the status folder from custom script extension directory
$start2 = (Get-Date).AddSeconds(15)
$time2 = New-ScheduledTaskTrigger -At $start2 -Once 
$cmd2 = New-ScheduledTaskAction -Execute Powershell.exe -Argument 'Remove-Item "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status" -Recurse -ErrorAction Ignore'
Register-ScheduledTask -TaskName "ExtensionCleanup" -User System -Trigger $time2 -Action $cmd2 -Force
