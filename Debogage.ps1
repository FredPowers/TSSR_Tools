If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}


# Debogage



Do {
  
    Write-Host "################ MENU ##################"
    write-host “1.  Vérifier la configuration IP” -ForegroundColor Cyan
    write-host "2.  Comparer l'IP d'un hote entre le cache dns et l'enregistrement sur le serveur DNS (Client)" -ForegroundColor DarkCyan
    write-host "3.  Vider le cache DNS et renouveller l'inscription dynamique (Client)" -ForegroundColor Cyan
    write-host "4.  Vérification du Pare-Feu" -ForegroundColor DarkCyan
    write-host "5.  Vérification du proxy" -ForegroundColor Cyan
    Write-Host "6.  Effectuer un Traceroute" -ForegroundColor DarkCyan
    write-host "7.  Vérification des utilisateurs" -ForegroundColor Cyan
    write-host "8.  Vérification serveur DNS (serveur)" -ForegroundColor DarkCyan
    write-host "9.  Vérification serveur DHCP (serveur)" -ForegroundColor Cyan
    write-host "10. Vérification des GPO appliquées (Client)" -ForegroundColor DarkCyan
    Write-Host "11. Affichage de l'arborescence des OU (Serveur)" -ForegroundColor Cyan
    Write-Host "x.  Exit" -ForegroundColor Red
    Write-Host "########################################"
    Write-Host ""
    $choix = read-host “faire un choix”

    switch ($choix) {



        ######################################################################################################
        # 1. Vérifier la configuration IP

        1 {

            #Vérifier la configuration IP de la carte physique connectée au réseau



            $Interface_Status = (Get-NetAdapter -Physical).Status

            if ($Interface_Status -eq "Up") {

                $InterfaceUp = (Get-NetAdapter -Physical | where Status -eq "Up").Name


                $IP = (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias $InterfaceUp).IPAddress
                $GW = (Get-NetRoute -InterfaceAlias $InterfaceUp -DestinationPrefix 0.0.0.0/0).NextHop
                $DNS = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceUp -AddressFamily IPv4).ServerAddresses
                $MasqueCIDR = (get-netipaddress | where { $_.interfaceAlias -eq $InterfaceUp -and $_.AddressFamily -eq "IPv4" }).PrefixLength
                $Mac = (Get-netadapter -Name $InterfaceUp).MacAddress
                $DHCP = (Get-NetIPInterface | where { $_.InterfaceAlias -eq $InterfaceUp -and $_.AddressFamily -eq "IPv4" }).Dhcp

                Write-Host ""
                Write-Host "####### Configuration IP #######" -ForegroundColor Green
                Write-Host ""
                Write-Host "Adresse IP   : $IP/$MasqueCIDR"
                Write-Host "Passerelle   : $GW"
                Write-Host "Adresse DNS  : $DNS"
                Write-Host "Adresse Mac  : $Mac"
                Write-Host "DHCP         : $DHCP"

                Write-Host ""
                Write-Host ""
                Write-Host ""

                write-host "## Ping vers la passerelle ##" -ForegroundColor Cyan

(New-Object System.Net.NetworkInformation.Ping).Send($GW) | fl Status, Address, RoundtripTime

                pause

                Cls

            }

            else {

                Write-Host ""
                Get-NetAdapter -Physical
                Write-Host ""
                Write-Host "Aucune carte réseau n'est connecté" -ForegroundColor Red
                Write-Host ""

                pause

                Cls


            }

        }



        ##########################################################################################################
        # 2. Comparer l'IP d'un hote entre le fichier host et le serveur DNS

        2 {
            #Vérifier l'adresse IP d'une machine en comparant l'adresse IP enregistrée sur le serveur DNS et celle enregistrée dans le fichier Host

            write-host "#### Comparaison du cache dns et l'enregistrement du serveur DNS ####" -ForegroundColor Cyan
            Write-Host ""

            $Nom_Hote = Read-Host "Indiquer le nom d'hôte à vérifier"

            $IP_hote_cache = (Get-DnsClientCache $Nom_Hote -ErrorAction SilentlyContinue).data

            $IP_Hote_ServerDns = (Resolve-DnsName $Nom_Hote -ErrorAction SilentlyContinue).IPAddress

            if ($? -eq "False") {
                Write-Host
                Write-Host "Le nom d'hote n'a n'y été trouvé dans le cache ni sur le serveur DNS"
                Write-Host
                pause
                Cls
                break
            }
            else {
                write-host
                Write-Host "IP de l'hote dans le cache du PC : $IP_hote_cache"
                Write-Host
                Write-Host "IP de l'hote sur le serveur DNS  : $IP_Hote_ServerDns"
                Write-Host
            }

            if ($IP_hote_cache -ne $IP_Hote_ServerDns) {
                write-host "Le IP sont différentes entre le cache et l'enregistrement sur le serveur dns" -ForegroundColor Red
                Write-Host
                $Reponse = Read-Host "Voulez-vous effacer le cache dns du PC ? [y/n]"
                Write-Host

                Do {

                    if ($Reponse -eq "y") {
                        Clear-DnsClientCache
                        $a = "a"
                        write-host "Le cache a été vidé"
                        pause
                    }
                    elseif ($Reponse -eq "n") {
                        Cls
                        Powershell $PSCommandPath
                    }
                    else {
                        Write-Host "Merci de répondre par 'y' ou 'n'"
                        Write-Host
                        $Reponse = Read-Host "Voulez-vous effacer le cache dns du PC ? [y/n]"
                    }

                }
               until ($a -eq "a")
               Cls
               Powershell $PSCommandPath
            }
            else {
                Write-Host "Les IP concordent" -ForegroundColor Green
                Write-Host
                Pause
                Cls
            }

        }



        #######################################################################################################
        # 3. Vider le cache DNS et renouveller l'inscription dynamique

        3 {

            #vider le cache DNS et renouveller l'inscription dynamique des noms DNS et des adresses IP

            Clear-DnsClientCache

            Register-DnsClient

            pause

            Cls

        }



        #########################################################################################
        # 4. Vérification du Pare-Feu

        4 {

            Do {
  
                Write-Host "################ MENU ##################"
                write-host “1. Vérifier l'activation du Pare-Feu” -ForegroundColor Green
                write-host "2. Désactiver le Pare-Feu" -ForegroundColor DarkGreen
                write-host "3. Activer le Pare-Feu" -ForegroundColor Green
                write-Host "4. Activer les requêtes ping entrantes et sortantes (IPv4) - Règles du Pare-Feu"
                Write-Host "x. Exit" -ForegroundColor Red
                Write-Host "########################################"
                Write-Host ""
                $choix = read-host “faire un choix”

                switch ($choix) {

                    1 {

                        Get-NetFirewallProfile | ft Name, Enabled

                        pause

                        Cls
                    }

                    2 {

                        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

                        pause

                        Cls
                    }


                    3 {

                        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

                        pause

                        Cls
                    }


                    4 {

                        Set-NetFirewallRule -DisplayName "Diagnostics de réseau de base - Demande d'écho ICMP (ICMPv4-Entrant)" -Enabled True -Profile Domain, Public, Private
                        Set-NetFirewallRule -DisplayName "Diagnostics de réseau de base - Demande d'écho ICMP (ICMPv4-Sortant)" -Enabled True -Profile Domain, Public, Private

                        pause

                        Cls
                    }

                    x {
                        Cls

                        Powershell $PSCommandPath
                    }

                }

            }

            until ($choix -eq "x")

            Cls

        }


        #######################################################################################################
        # 5. Vérifier si le proxy est configuré

        5 {

            $ErrorActionPreference = 'silentlycontinue'

            Do {
  
                Write-Host "################ MENU ##################"
                write-host “1. Vérifier l'activation du Proxy” -ForegroundColor Green
                write-host "2. Désactiver le Proxy" -ForegroundColor DarkGreen
                Write-Host "3. Activer et configurer le proxy" -ForegroundColor Green
                Write-Host "x. Exit" -ForegroundColor Red
                Write-Host "########################################"
                Write-Host ""
                $choix = read-host “faire un choix”

                switch ($choix) {

                    1 {

                        $Proxy_Actif = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable
                        $Config_Proxy = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer
                        $Proxy_Exclusion = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride

                        if ($Proxy_Actif -eq 0) {
                            Write-Host "Le Proxy n'est pas activé" -ForegroundColor Red
                            Write-Host ""
                        }

                        else {
                            Write-Host "Le proxy est activé" -ForegroundColor Green

                            Write-Host ""

                            write-host "Adresse et port du proxy : $Config_Proxy"
                            Write-Host ""
                            Write-Host "Exclusions : $Proxy_Exclusion"
                            Write-Host
                        }

                        Pause

                        Cls
                    }

                    2 {

                        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0

                        pause

                        Cls
                    }

                    3 {

                        $Proxy_IP = Read-Host "Indiquer l'IP du proxy"
                        Write-Host ""
                        $Proxy_Port = Read-Host "Indiquer le port du proxy"
                        Write-Host ""
                        $Proxy_Exclusion = Read-Host "Indiquer les adresses à exclure séparées par un point-virgule, laisser vide si besoin"

                        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1

                        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $Proxy_IP':'$Proxy_Port

                        if ($Proxy_Exclusion -notlike $null) {

                            $test_Path = [bool] (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride)

                            if ($test_Path -eq $false) {

                                New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $Proxy_Exclusion
                            }

                            else {
                                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $Proxy_Exclusion
                            }

                        }


                        Pause

                        Cls

                    }


                    x {
                        Cls

                        Powershell $PSCommandPath
                    }

                }

            }

            until ($choix -eq "x")

            Cls

        }



        #######################################################################################################
        # 6. Traceroute

        6 {
            $Target = Read-host "Indiquer le nom d'hôte ou l'IP"
            Test-NetConnection -TraceRoute $Target

            pause

            Cls
        }


        #######################################################################################################
        # 7. Vérification des utilisateurs

        7 {

            Do {
  
                Write-Host "################ MENU ##################"
                write-host “1. Utilisateurs AD” -ForegroundColor Green
                write-host "2. Utilisateurs Locaux" -ForegroundColor DarkGreen
                Write-Host "x. Exit" -ForegroundColor Red
                Write-Host "########################################"
                Write-Host ""
                $choix = read-host “faire un choix”

                switch ($choix) {

                    1 { get-aduser -Filter * | select SamAccountName, Name, Enabled }

                    2 {
                        get-localuser | where { ($_.Name -Notmatch "CSEP"`
                                    -and $_.Name -notmatch "Default*"`
                                    -and $_.Name -notmatch "Invité*"`
                                    -and $_.Name -notmatch "UserAccess*"`
                                    -and $_.Name -notmatch "WDAG*") } |  select Name, Enabled, LastLogon, PasswordLastSet
                    }


                    x {
                        exit
                    }

                }
            }


            until ($choix -eq "x")

            Cls

        }

        #######################################################################################################
        #8.  Vérification serveur DNS

        8 {

            Do {
  
                Write-Host "################ MENU ##################"
                write-host “1. Tester le serveur DNS” -ForegroundColor Cyan
                write-host "2. Afficher les zones DNS du serveur" -ForegroundColor DarkCyan
                write-host "3. Affichage des enregistrements pour une zone" -ForegroundColor Cyan
                Write-Host "4. Vérifier la configuration du cache DNS" -ForegroundColor DarkCyan
                write-host "5. Vérifier le cache DNS" -ForegroundColor Cyan
                write-host "6. Vider le cache DNS" -ForegroundColor DarkCyan
                Write-Host "x. Exit" -ForegroundColor Red
                Write-Host "########################################"
                Write-Host ""
                $choix = read-host “faire un choix”

                switch ($choix) { 


                    1 {
                        $InterfaceUp = (Get-NetAdapter -Physical | where { $_.status -like "Up" }).Name
                        $IP_Host = (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias $InterfaceUp).IPAddress

                        Write-Host "###### Zones DNS ######" -ForegroundColor Green
                        Write-Host ""
                        Get-DnsServerZone
                        write-host ""

                        Read-Host "Indiquer le nom de la zone à tester"
                        Write-Host ""

                        Test-DnsServer -IPAddress $IP_Host -ZoneName $NomZone

                        Pause

                        Cls

                    }

                    2 {
                        Get-DnsServerZone
    
                        Pause
    
                        Cls

                    }

                    3 {

                        Write-Host "###### Zones DNS ######" -ForegroundColor Green
                        Write-Host ""
                        Get-DnsServerZone
                        write-host ""

                        $NomZone = Read-Host "Indiquer le nom de la zone oçu vérifier les enregistrements"
                        Write-Host ""
                        Get-DnsServerResourceRecord -ZoneName $NomZone
                        Write-Host ""
                        Pause
                        Cls
                    }


                    4 {
                        Get-DnsServerCache

                        Pause

                        Cls
                    }


                    5 {
                        Show-DnsServerCache

                        Pause

                        Cls
                    }


                    6 {
                        Clear-DnsServerCache

                        Pause

                        Cls
                    }
                    x { exit }

                }

            }

            until ($choix -eq "x")

        }
        #######################################################################################################
        # 9. Vérification serveur DHCP (serveur)

        9 {
            Get-DhcpServerv4Scope
        }


        #######################################################################################################
        # "10. Vérification des GPO appliquées"

        10 {

            $Location = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

            Do {

                write-host “1. gpresult_session - résultat dans le terminal” -ForegroundColor Cyan
                write-host "2. gpresult_session - résultat dans un fichier texte" -ForegroundColor Cyan
                write-host “3. gpresult_session - résultat dans un fichier html” -ForegroundColor Cyan
                write-host "4. gpresult_ordinateur - résultat dans le terminal" -ForegroundColor DarkCyan
                write-host “5. gpresult_ordinateur - résultat dans un fichier texte” -ForegroundColor DarkCyan
                write-host "6. gpresult_ordinateur - résultat dans un fichier html" -ForegroundColor DarkCyan
                write-host "x. exit" -ForegroundColor Red

                $choix = read-host “faire un choix”

                switch ($choix) {

  

                    1 {

                        powershell gpresult /R /SCOPE user

                        pause

                        Clear-Host
                    }

                    2 {
                        powershell gpresult /R /SCOPE user > $Location\gpresult_session.txt

                        pause

                        Clear-Host
    
                    }


                    3 {
                        powershell gpresult /H $Location\gpresult_session.html /SCOPE user

                        pause

                        Clear-Host
    
                    }


                    4 {
                        powershell gpresult /R /SCOPE computer

                        pause

                        Clear-Host
    
                    }



                    5 {
                        powershell gpresult /SCOPE computer /R > $Location\gpresult_ordinateur.txt

                        pause

                        Clear-Host
    
                    }


                    6 {
                        powershell gpresult /H $Location\gpresult_ordinateur.html /SCOPE computer

                        pause

                        Clear-Host
    
                    }

                }
            }

            until ($choix -eq "x")


            Clear-Host

            powershell $PSCommandPath


        }


        #######################################################################################################
        # 11. Affichage de l'arborescence des OU (Serveur)

        11 {

            $ErrorActionPreference = 'SilentlyContinue'



            $OU_Level1_Name = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | where Name -NotMatch "Domain*").Name

            $OU_Level1_DistinguishedName = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | where Name -NotMatch "Domain*").DistinguishedName


            $OU_Level2_Name = ($OU_Level1_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).Name

            $OU_Level2_DistinguishedName = ($OU_Level1_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).DistinguishedName


            $OU_Level3_Name = ($OU_Level2_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).Name

            $OU_Level3_DistinguishedName = ($OU_Level2_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).DistinguishedName


            $OU_Level4_Name = ($OU_Level3_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).Name

            $OU_Level4_DistinguishedName = ($OU_Level3_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).DistinguishedName


            $OU_Level5_Name = ($OU_Level4_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).Name

            $OU_Level5_DistinguishedName = ($OU_Level4_DistinguishedName | Foreach-Object { Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel }).DistinguishedName


            # affichage dans le terminal Powershell

            $OU_Level1_Name | Foreach-Object {
                write-host "L1 $_" -ForegroundColor Green

                $OU_Identity = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                $OU2_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity -SearchScope OneLevel).Name

                $OU2_Name | Foreach-Object {
                    if ($_ -notlike $null) {
                        Write-Host "  ==>L2 $_" -ForegroundColor DarkCyan
                    }

                    $OU_Identity2 = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                    $OU3_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity2 -SearchScope OneLevel).Name

                    $OU3_Name | Foreach-Object {
                        if ($_ -notlike $null) {
                            Write-Host "    ==>L3 $_" -ForegroundColor Cyan
                        }

                        $OU_Identity3 = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                        $OU4_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity3 -SearchScope OneLevel).Name

                        $OU4_Name | Foreach-Object {
                            if ($_ -notlike $null) {
                                Write-Host "      ==>L4 $_" -ForegroundColor Yellow 
                            }

                            $OU_Identity4 = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                            $OU5_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity4 -SearchScope OneLevel).Name

                            $OU5_Name | Foreach-Object {
                                if ($_ -notlike $null) {
                                    Write-Host "        ==>L5 $_" -ForegroundColor Magenta
                                }

                                $OU_Identity5 = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                                $OU6_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity5 -SearchScope OneLevel).Name

                                $OU6_Name | Foreach-Object {
                                    if ($_ -notlike $null) {
                                        Write-Host "          ==>L6 $_" -ForegroundColor DarkGreen
                                    }

                                    $OU_Identity6 = (Get-ADOrganizationalUnit -Filter * | where name -eq $_).DistinguishedName
                                    $OU7_Name = (Get-ADOrganizationalUnit -Filter * -SearchBase $OU_Identity6 -SearchScope OneLevel).Name

                                    $OU7_Name | Foreach-Object {
                                        if ($_ -notlike $null) {
                                            Write-Host "            ==>L7 $_" -ForegroundColor Gray
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
            }


            Pause

            Cls

        }


        #######################################################################################################
        # x. Exit

        x {
            exit
        }


    }
}

until ($choix -eq "x")