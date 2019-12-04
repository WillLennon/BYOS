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
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"
$agentRun = Join-Path -Path $agentDir -ChildPath "run.cmd"

# configure the build agent
$configParameters = " --unattended --url $url --runAsAutoLogon --noRestart  --pool $pool --auth pat --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# run the build agent
Write-Host "Running " $agentRun
Start-Process $agentRun -NoNewWindow -WorkingDirectory $agentDir

Write-Host "Done"
