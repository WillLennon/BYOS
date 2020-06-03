param
(
   [string]$runArgs
)

$username = Get-Content username.txt
$password = Get-Content password.txt

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

$runCmd = Join-Path -Path $PSScriptRoot -ChildPath "run.cmd"

if([string]::IsNullOrEmpty($runArgs))
{
   Start-Process -FilePath $runCmd -Credential $credential
}
else
{
   Start-Process -FilePath $runCmd -Credential $credential -ArgumentList $runArgs
}

Remove-Item password.txt
