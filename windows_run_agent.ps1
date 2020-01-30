# Schedule a task to start the build agent in 10 seconds.
# We cannot start it ourselves because Azure ScaleSets will keep the VM stuck in the Updating state until it times out several hours later.

$agentDir = "\agent"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"
$start= (Get-Date).AddSeconds(10)
$time = New-ScheduledTaskTrigger -At $start -Once 
$cmd = New-ScheduledTaskAction -Execute $agentRun -WorkingDirectory $agentDir
Register-ScheduledTask -TaskName "BuildAgent" -Trigger $time -Action $cmd -TaskPath $agentDir
