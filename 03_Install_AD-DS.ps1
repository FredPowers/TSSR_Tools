If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}


Do {
  
    Write-Host "################ MENU ##################"
    write-host “1. Installer le rôle AD DS - Nouveau Domaine - Nouvelle fôret” -ForegroundColor Cyan
    write-host "2. Installer le rôle AD DS - Créer un CD secondaire" -ForegroundColor DarkCyan
    Write-Host "3. Installer le rôle AD DS - Créer un domaine enfant" -ForegroundColor Cyan
    Write-Host "4. Rétrograder le CD & Désinstaller le Rôle AD DS" -ForegroundColor DarkCyan
    Write-Host "5. Audit AD avec Ping Castle" -ForegroundColor Cyan
    Write-Host "6. Vue d'ensemble de l'AD avec Modern Active Directory" -ForegroundColor DarkCyan
    Write-Host "x. Exit" -ForegroundColor Red
    Write-Host "########################################"
    Write-Host ""
    $choix = read-host “faire un choix”

    switch ($choix) {  
  

        #################################################################################
        #1. Installer le rôle AD DS - Nouveau Domaine - Nouvelle fôret

        1 {

            write-host ""
            $NomDomaine = Read-Host "entrer le nom de domaine"

            #Installation du rôle AD DS
            Add-WindowsFeature AD-Domain-Services -IncludeManagementTools

            #Création d'une nouvelle forêt et d'un nouveau domaine Active Directory, installation du DNS et promouvoir le serveur en contrôleur de domaine
            $NomDomaineSplit = $NomDomaine.Split(".")
            $a = $NomDomaineSplit[0]

            Install-ADDSForest -DomainName $NomDomaine -InstallDNS -DomainNetBiosName $a

            pause
            }


        #################################################################################
        #2. Installer le rôle AD - Créer un CD secondaire
        # l'AD primaire sera synchronisé ainsi que le zone DNS directe et inverse.

        2 {

            write-host ""
            $NomDomaine = Read-Host "entrer le nom de domaine"
            write-host
            $NomDC1 = Read-Host "entrer le nom FQDN du controleur de domaine primaire"

            Add-WindowsFeature AD-Domain-Services -IncludeManagementTools

            Install-ADDSDomainController `
                -Credential (Get-Credential) `
                -InstallDNS `
                -DomainName $NomDomaine `
                -CreateDnsDelegation:$false `
                -ReplicationSourceDC $NomDC1 `
                -CriticalReplicationOnly:$false `
                -SkipPreChecks:$false `
                -Confirm:$false `
                -Force:$true `

        }

        #################################################################################
        #3. Installer le rôle AD - Créer un domaine enfant

        3 {
            Add-WindowsFeature AD-Domain-Services -IncludeManagementTools

            $NomDomaineParent = Read-Host "entrer le nom du domaine parent"

            $NomDuNouveauDomaine = Read-Host "entrer le nom du nouveau domaine"

            Install-AddsDomain `
                -domaintype childdomain `
                -parentdomainname $NomDomaineParent `
                -newdomainname $NomDuNouveauDomaine `
                -CreateDnsDelegation:$false `
                -InstallDns:$true `


        }



        #################################################################################
        #4. Rétrograder le CD & Désinstaller le Rôle AD DS"

        4 {

            Import-Module ADDSDeployment

            Uninstall-ADDSDomainController `
                -ForceRemoval:$true `
                -Confirm:$false `
                -DemoteOperationMasterRole:$true `
                #-IgnoreLastDCInDomainMismatch `
                #-IgnoreLastDNSServerForZone `
                #-RemoveApplicationPartitions `
                #-Force:$true `

            Sleep 3

            # Commande pour Désinstaller AD-Domain-Services après le redémarrage du PC
            <#
            if ([bool](Get-ADDomainController) -eq $false){
                # Désinstaller le rôle AD DS
                Remove-WindowsFeature AD-Domain-Services -IncludeManagementTools
            }
            else{
                echo "échec de la rétrogradation du CD"
            }
            #>

            pause
        }

        #################################################################################
        #5. Audit AD avec Ping Castle
        # le rapport au format html sera générer dans le même dossier que le script Install_AD-DS.ps1

        5 {
            if (Test-Path "C:\PingCastle\PingCastle.exe"){
                Start-Process -FilePath "C:\PingCastle\PingCastle.exe"
            }
            else{

                # Téléchargemnt du logiciel depuis le site officiel https://www.pingcastle.com/
                if (Test-Path "C:\PingCastle" -PathType Container){
                    Invoke-WebRequest -Uri "https://github.com/vletoux/pingcastle/releases/download/3.0.0.0/PingCastle_3.0.0.0.zip" `
                    -OutFile "C:\PingCastle\PingCastle_3.0.0.0.zip"
                }
                else{
                    New-Item -ItemType Directory -Path "C:\PingCastle"
                    Sleep 1
                    Invoke-WebRequest -Uri "https://github.com/vletoux/pingcastle/releases/download/3.0.0.0/PingCastle_3.0.0.0.zip" `
                    -OutFile "C:\PingCastle\PingCastle_3.0.0.0.zip"
                }

            # Décompression du .zip
            Add-Type -AssemblyName System.IO.Compression.FileSystem

            $zipFile = "C:\PingCastle\PingCastle_3.0.0.0.zip"
            $extractPath = "C:\PingCastle"

            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractPath)

            # Lancement de PingCastle.exe
            Start-Process -FilePath "C:\PingCastle\PingCastle.exe"
            }

        }

        #################################################################################
        #6. Vue d'ensemble de l'AD avec Modern Active Directory

        6 {
            # Installation via la gallerie powershell
            Install-Module ModernActiveDirectory

            
            get-ADModernReport

        }





    }
}

until ($choix -eq "x")