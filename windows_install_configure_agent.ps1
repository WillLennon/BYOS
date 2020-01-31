param
(
   [string]$url,
   [string]$pool,
   [string]$pat
)

$errorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($url))
{
   Write-Error "URL is null"
}

if ([string]::IsNullOrEmpty($pool))
{
   Write-Error "Pool is null"
}

if ([string]::IsNullOrEmpty($pat))
{
   Write-Error "PAT is null"
}

Write-Host "URL: " $url
Write-Host "Pool:" $pool
Write-Host "PAT: " $pat

Add-Type -AssemblyName System.IO.Compression.FileSystem

$agentDir = "\agent"
$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path .\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"

#
# install the build agent if necessary
#
if (!(Test-Path -Path $agentDir))
{
   Write-Host "Creating agent folder"
   New-Item -ItemType directory -Path $agentDir
}

Copy-item ./windows_run_agent.ps1 /agent/windows_run_agent.ps1

if (!(Test-Path -Path $agentExe))
{
   Write-Host "Unzipping agent"
   [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
}

# configure the build agent
$configParameters = " --unattended --url $url --runAsAutoLogon --noRestart  --pool ""$pool"" --auth pat --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# schedule the build agent to run immediately
$start = (Get-Date).AddSeconds(5)
$time = New-ScheduledTaskTrigger -At $start -Once 
$cmd = New-ScheduledTaskAction -Execute \agent\run.cmd -WorkingDirectory \agent
Register-ScheduledTask -TaskName "BuildAgent" -Trigger $time -Action $cmd -TaskPath \agent -Force
