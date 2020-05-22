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

      # run as local admin elevated
      Start-Process -FilePath PowerShell.exe -Verb RunAs -Wait -ArgumentList $warmup
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
Start-Process -FilePath $agentConfig -ArgumentList $configParameters -NoNewWindow -Wait -WorkingDirectory $agentDir -Verb RunAs

# schedule the build agent to run
Start-Process -FilePath Powershell.exe -ArgumentList "-ExecutionPolicy Unrestricted $runFileDest $runArgs"
