$start = (Get-Date).AddSeconds(2)
$time = New-ScheduledTaskTrigger -At $start -Once 
$cmd = New-ScheduledTaskAction -Execute c:\agent\run.cmd -WorkingDirectory c:\agent
Register-ScheduledTask -TaskName "BuildAgent" -Trigger $time -Action $cmd -TaskPath c:\agent -Force
