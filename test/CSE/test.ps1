param
(
   [int]$sleep,
   [int]$exitCode,
   [switch]$throw
)

function Log-Message 
{
   param ([string] $message)

   $now = [DateTime]::UtcNow.ToString('u')
   $text = $now + " " + $message
   $logFile = "c:\script.log"
   if (!(Test-Path -Path $logFile))
   {
      Set-Content -Path $logFile -Value ""
   }
   Add-Content -Path $logFile -Value $text
   Write-Host $text
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

Log-Message "Test CSE"
Log-Message ("sleep: " + $sleep)
Log-Message ("exitCode: " + $exitCode)
Log-Message ("throw: " + $throw) 

Log-Message "sleeping"
Start-Sleep $sleep

if ($throw)
{
   Log-Message "throwing"
   throw [System.Exception] "throwing exception"
}

Log-Message "exiting"
exit 5
