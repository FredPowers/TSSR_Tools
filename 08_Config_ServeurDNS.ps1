#Installation du Rôle DNS et configuration

<#
installation si besoin
#>

Do {
  
    Write-Host "################ MENU ##################"
    write-host “1. Installer le rôle DNS” -ForegroundColor Cyan
    write-host "2. Créer un redirecteur inconditionnel" -ForegroundColor DarkCyan
    Write-Host "3. Créer un redirecteur conditionnel" -ForegroundColor Cyan
    write-host "4. Créer une zone de résolution directe" -ForegroundColor DarkCyan
    write-host "5. Créer une zone de résolution inverse" -ForegroundColor Cyan
    write-host "6. Ajouter un enregistrement de type A & PTR" -ForegroundColor DarkCyan
    Write-Host "7. Ajouter un enregistrement de type CNAME" -ForegroundColor Cyan
    Write-Host "8. Configurer un serveur DNS Secondaire" -ForegroundColor DarkCyan
    Write-Host "x. Exit" -ForegroundColor Red
    Write-Host "########################################"
    Write-Host ""
    $choix = read-host “faire un choix”

    switch ($choix) {  
  

        #################################################################################
        #1. Installer le rôle DNS

        1 {
            Install-WindowsFeature DNS -IncludeManagementTools
    
            Pause
    
            CLs
        }

        #################################################################################
        #2. Créer un redirecteur inconditionnel

        2 {

            # créer un redirecteur inconditionnel

 
            $AdresseIP = Read-Host "Indiquer l'adresse IP du redirecteur"

            # -replicationScope "Forest" pour créer un redirecteur AD intégré
            Add-DnsServerForwarder -IPAddress $AdresseIP -PassThru

            Pause

            Cls
        }

        #################################################################################
        #3. Créer un redirecteur conditionnel

        3 {
            # créer un redirecteur conditionnel - qui pointe vers un serveur DNS qui heberge un fichier de zone précis.

            $AdresseIP = Read-Host "Indiquer l'adresse IP du redirecteur"

            $domaine = Read-Host "Indiquer le nom de domaine visé"

            write-host
        
            Add-DnsServerConditionalForwarderZone -Name $domaine -MasterServers $AdressIP -PassThru

            Pause

            Cls
        }



        #################################################################################
        #4. Créer une zone de résolution directe

        4 {
            Write-Host "###### affichage des zones ######" -ForegroundColor Green
            Write-Host

            Get-DnsServerZone
            Write-Host

            
            $NomDuDomaine = (gwmi WIN32_ComputerSystem).Domain

            $NomZone = Read-Host "Indiquer le nom de la nouvelle zone"
            Write-Host ""

            Add-DnsServerPrimaryZone -Name "$NomZone.$NomDuDomaine" -ReplicationScope "Forest" –PassThru

            Write-Host "###### affichage des zones ######" -ForegroundColor Green
            Write-Host ""

            Get-DnsServerZone   

            Pause

            Cls
        }


        #################################################################################
        #5. Créer une zone de résolution inverse

        5 {
            Write-Host "###### affichage des zones ######" -ForegroundColor Green
            Write-Host

            Get-DnsServerZone
            Write-Host

            $IPReseau = Read-Host "Indiquer l'adresse du réseau avec le masque CIDR, ex : 192.168.0.0/24"
            Add-DnsServerPrimaryZone -NetworkId $IPReseau -ReplicationScope Domain

            Pause

            Cls
        }

        #################################################################################
        #6. Ajouter un enregistrement de type A & PTR

        6 {

            Write-Host "###### affichage des zones ######" -ForegroundColor Green
            Write-Host

            Get-DnsServerZone
            Write-Host
            $NomZone = Read-Host "Indiquer le nom de la zone concernée"
            $NOMHost = Read-Host "Indiquer le NOM de l'hôte"
            $IP = Read-Host "Indiquer l'IP de l'hôte"
            #$TTL = Read-Host "Indiquer le TTL, ex : 01:00:00 pour 1h"

            Add-DnsServerResourceRecordA -Name $NOMHost -IPv4Address $IP -ZoneName $NomZone <#-TimeToLive $TTL#> –CreatePtr

            Pause

            Cls
        }

        ##################################################################################
        #7. Ajouter un enregistrement de type CNAME

        7 { 
            $NomDuDomaine = (gwmi WIN32_ComputerSystem).Domain

            Write-Host "###### affichage des zones ######" -ForegroundColor Green
            Write-Host

            Get-DnsServerZone
            Write-Host
            $NomZone = Read-Host "Indiquer le nom de la zone"
            $NOMHost = Read-Host "Indiquer le nom d'hôte pour qui sera créé le CName"
            $Alias = Read-Host "Indiquer l'Alias"
            

            Add-DnsServerResourceRecordCName -Name $Alias -HostNameAlias "$NOMHost.$NomDuDomaine"  -ZoneName $NomZone
            Pause

            Cls
        }

        ##################################################################################
         #8. Configurer un serveur DNS Secondaire

        8 { 
            # autoriser le transfert au niveau du serveur DNS primaire
            # Set-DnsServerPrimaryZone <nom zone> -SecureSecondaries TransferAnyServer -Notify Notify

            $NomZonePrimaire = Read-Host "Indiquer le nom de la zone primaire à répliquer"

            Write-Host

            $IPServeurDNSPrimaire = Read-Host "Indiquer l'IP du serveur DNS primaire"

            Install-WindowsFeature DNS -IncludeManagementTools

            Add-DnsServerSecondaryZone -Name $NomZonePrimaire -ZoneFile "$NomZonePrimaire.dns" -MasterServers $IPServeurDNSPrimaire

            # à tester pour avoir la zone directe primaire du serveur dns primaire
            #Get-DnsServerZone -ComputerName win-olpn33s5q3m.mytest.contoso.com |`
            #where {("Primary" -eq $_.ZoneType) -and ($False -eq $_.IsAutoCreated) -and ("TrustAnchors" -ne $_.ZoneName)} |`
            #%{ $_ | Add-DnsServerSecondaryZone -MasterServers 172.23.90.136 -ZoneFile "$($_.ZoneName).dns"}
            
            Pause

            Cls
        }



        ##################################################################################
        #x. exit

        x { exit }


    }

}

until ($choix -eq "x")


