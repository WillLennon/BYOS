param
(
   [string]$runArgs
)

$runCmd = Join-Path -Path $PSScriptRoot -ChildPath "run.cmd"
$username = Get-Content username.txt
$password = Get-Content password.txt

$argList = "-ExecutionPolicy Unrestricted -File $runCmd -username $username -password $password $runArgs"
Start-Process -FilePath Powershell.exe -Verb RunAs -ArgumentList $argList

