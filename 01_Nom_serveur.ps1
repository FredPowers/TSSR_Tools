If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}




#changement de nom machine

$NomMachine = Read-Host "entrer le nouveau nom de la machine"
Rename-Computer -NewName $NomMachine

shutdown -r -t 0