param
(
   [string]$url,
   [string]$pool,
   [string]$token
)

function Log-Message 
{
   param ([string] $message)

   $now = [DateTime]::UtcNow.ToString('u')
   $text = $now + " " + $message
   $logfile = Join-Path -Path $PSScriptRoot -ChildPath "extension.log"
   Add-Content -Path $logfile -Value $text
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$agentDir = $PSScriptRoot

Log-Message "Installing extension"
Log-Message ("URL: " + $url)
Log-Message ("Pool: " + $pool) 
Log-Message ("agentDir: " + $agentDir)

$agentExe = Join-Path -Path $agentDir -ChildPath "bin\Agent.Listener.exe"
$agentZip = Get-ChildItem -Path .\* -File -Include vsts-agent*.zip
$agentConfig = Join-Path -Path $agentDir -ChildPath "config.cmd"

Log-Message ("agentExe: " + $agentExe)
Log-Message ("agentZip: " + $agentZip)
Log-Message ("agentConfig: " + $agentConfig)

#unzip the agent if it doesn't exist already
if (!(Test-Path -Path $agentExe))
{
   Log-Message "Unzipping Agent"
   try
   {
      [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, $agentDir)
   }
   catch
   {
      Log-Message $Error[0]
   }
   exit -100
}

# create administrator account
Log-Message  "Creating AzDevOps account"
$username = 'AzDevOps'
Set-Content -Path username.txt -Value $username
$password = (New-Guid).ToString()
Set-Content -Path password.txt -Value $password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

if (!(Get-LocalUser -Name $username -ErrorAction Ignore))
{
  Log-Message "Creating AzDevOps user"
  New-LocalUser -Name $username -Password $securePassword
}
else
{
  Log-Message "Setting AzDevOps password"
  Set-LocalUser -Name $username -Password $securePassword 
}
if ((Get-LocalGroup -Name "Users" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "Users" -Member $username -ErrorAction Ignore))
{
  Log-Message "Adding AzDevOps to Users"
  Add-LocalGroupMember -Group "Users" -Member $username
}
if ((Get-LocalGroup -Name "Administrators" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction Ignore))
{
  Log-Message "Adding AzDevOps to Administrators"
  Add-LocalGroupMember -Group "Administrators" -Member $username
}
if ((Get-LocalGroup -Name "docker-users" -ErrorAction Ignore) -and
    !(Get-LocalGroupMember -Group "docker-users" -Member $username -ErrorAction Ignore))
{
  Log-Message "Adding AzDevOps to docker-users"
  Add-LocalGroupMember -Group "docker-users" -Member $username
}

# run the customer warmup script if it exists
# note that this runs as SYSTEM on windows
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   # run as local admin elevated
   Log-Message "Running warmup script"
   Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -WorkingDirectory \ -ArgumentList "-ExecutionPolicy Unrestricted $warmup"
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $token"
$config = $agentConfig + $configParameters
Log-Message "Configuring agent"
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir
Log-Message "Finished configuration."
