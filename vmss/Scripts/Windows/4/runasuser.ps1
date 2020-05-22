param
(
   [string]$url,
   [string]$pool,
   [string]$pat,
   [string]$runArgs
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# run the customer warmup script if it exists
$warmup = "\warmup.ps1"
if (Test-Path -Path $warmup)
{
   if (![String]::IsNullOrEmpty($username))
   {
      $now = Get-Date
      echo $now > c:\start.txt
      # run as local admin

      # This is wonky.  
      # We want to run powershell both elevated and as the local admin, but Powershell won't let you do both -Credential and -Verb.
      # So start a process as the local admin and then have that process start another elevated process that runs the warmup script.
      Start-Process -FilePath PowerShell.exe -Credential $credential -Wait -ArgumentList $warmup
      $now = Get-Date
      echo $now > c:\finish.txt
   }
   else
   {
      # run as system
      echo runassystem > c:\runassystem.txt
      Start-Process -FilePath PowerShell.exe -Wait -ArgumentList $warmup -WorkingDirectory '\' -Verb RunAs
   }
}

# configure the build agent
$configParameters = " --unattended --url $url --pool ""$pool"" --auth pat --noRestart --replace --token $pat"
$config = $agentConfig + $configParameters
Write-Host "Running " $config
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir

# schedule the build agent to run
Start-Process -FilePath Powershell.exe -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs $username $password"

