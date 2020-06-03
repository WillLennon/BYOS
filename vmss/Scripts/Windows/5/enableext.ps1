param
(
   [string]$runArgs
)

function Log-Message 
{
   param ([string] $message)

   $now = [DateTime]::UtcNow.ToString('u')
   $text = $now + " " + $message
   Add-Content -Path status.txt -Value $text
}


Log-Message "Enabling Extension"
Log-Message "runArgs: " + $runArgs

$username = Get-Content username.txt
$password = Get-Content password.txt

if([string]::IsNullOrEmpty($username))
{
   Log-Message "username not found"
   exit
}

if([string]::IsNullOrEmpty($password))
{
   Log-Message "password not found"
   exit
}

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

$runCmd = Join-Path -Path $PSScriptRoot -ChildPath "run.cmd"

Log-Message $runCmd

if([string]::IsNullOrEmpty($runArgs))
{
   Start-Process -FilePath $runCmd -Credential $credential
}
else
{
   Start-Process -FilePath $runCmd -Credential $credential -ArgumentList $runArgs
}

Log-Message "Deleting password"
Remove-Item password.txt
Log-Message "Finished"
