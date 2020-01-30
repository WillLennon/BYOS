$agentDir = "\agent"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"

# run the build agent
Write-Host "Running " $agentRun
Start-Process $agentRun -NoNewWindow -WorkingDirectory $agentDir

Write-Host "Done"
