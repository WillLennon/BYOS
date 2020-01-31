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

# install the build agent if necessary
if (!(Test-Path -Path $agentDir))
{
   Write-Host "Creating agent folder"
   New-Item -ItemType directory -Path $agentDir
}

# copy run script to the agent folder
$runScript = "windows_run_agent.ps1"
$runPath = Join-Path -Path $agentDir -ChildPath $runScript
Copy-item $runScript $runPath

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
Start-Process -FilePath Powershell.exe -ArgumentList $runPath -NoNewWindow -Wait
