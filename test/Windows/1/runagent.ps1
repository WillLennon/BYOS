$start = (Get-Date).AddSeconds(2)
$time = New-ScheduledTaskTrigger -At $start -Once 
$cmd = New-ScheduledTaskAction -Execute \agent\run.cmd -WorkingDirectory \agent
Register-ScheduledTask -TaskName "BuildAgent" -User System -Trigger $time -Action $cmd -TaskPath \agent -Force
