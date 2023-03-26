If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
}


Do{
  
    Write-Host "################ MENU ##################"
    write-host “1. Configuration IP Manuelle” -ForegroundColor Cyan
    write-host "2. Configuration IP en DHCP" -ForegroundColor DarkCyan
    Write-Host "x. Exit" -ForegroundColor Red
    Write-Host "########################################"
    Write-Host ""
    $choix = read-host “faire un choix”

    switch ($choix)
    {



######################################################################################################
# 1. Configuration IP Manuelle

        1{

            $Interface = (Get-NetAdapter -physical | where Name -Match "Ether*").Name
            $InterfaceIndex = (Get-NetAdapter -physical | where Name -Match "Ether*").InterfaceIndex
            

            # Désactiver l'interface
            # Disable-NetAdapter -Name $Interface -Confirm:$false

            $AdresseIP_Actuelle = (Get-NetIPAddress | Where {$_.InterfaceIndex -eq $InterfaceIndex -and $_.AddressFamily -eq "IPv4"}).IPAddress
            $Masque_Actuelle = (Get-NetIPAddress | Where {$_.InterfaceIndex -eq $InterfaceIndex -and $_.AddressFamily -eq "IPv4"}).PrefixLength
            $Passerelle_Actuelle = (Get-NetRoute | Where-Object DestinationPrefix -eq '0.0.0.0/0').NextHop
            
            $AdresseIP = Read-Host "entrer l'adresse IP"
            $MasqueCIDR = Read-Host "entrer le masque de sous-réseau en notation CIDR"
            $Passerelle = Read-Host "enrtrer l'IP de la passerelle par défault"
            $DNS = Read-Host "entrer l'IP du/des serveurs DNS, ex : 10.53.0.5,8.8.8.8 si plusieurs serveurs DNS"


            # Modifier l'adresse IP, le masque de sous-réseau et la passerelle par défaut
            if ($AdresseIP_Actuelle -eq $null) {
                New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $AdresseIP -PrefixLength $MasqueCIDR -Confirm:$false
                Set-NetIPInterface -InterfaceIndex $InterfaceIndex -InterfaceMetric 10 -Confirm:$false
                Set-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -Dhcp Disabled -Confirm:$false
                New-NetRoute -DestinationPrefix 0.0.0.0/0 -InterfaceIndex $InterfaceIndex -NextHop $Passerelle -RouteMetric 10 -Confirm:$false
            }

            else {
                Remove-NetIPAddress –InterfaceIndex $InterfaceIndex –IPAddress $AdresseIP_Actuelle –PrefixLength $Masque_Actuelle -Confirm:$false

                New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $AdresseIP -PrefixLength $MasqueCIDR -Confirm:$false
                Set-NetIPInterface -InterfaceIndex $InterfaceIndex -InterfaceMetric 10 -Confirm:$false
                Set-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -Dhcp Disabled -Confirm:$false

                Get-NetRoute | where { $_.NextHop -eq "$Passerelle_Actuelle" } | Remove-NetRoute -Confirm:$false

                New-NetRoute -DestinationPrefix 0.0.0.0/0 -InterfaceIndex $InterfaceIndex -NextHop $Passerelle -RouteMetric 10 -Confirm:$false

                Set-DnsClientServerAddress -InterfaceAlias $Interface -ServerAddresses $DNS -Confirm:$false
            }


            pause

            Cls

        }


    ###########################################################################################
    # 2. Configuration IP en DHCP

       2{

            Get-NetAdapter -Physical
            Write-Host ""
            $Interface = Read-Host "entrer l'interface à configurer en DHCP"

            $Passerelle = (Get-NetRoute -InterfaceAlias $Interface -DestinationPrefix 0.0.0.0/0).NextHop
            $PasserelleBool = [Bool] (Get-NetRoute -InterfaceAlias $Interface -DestinationPrefix 0.0.0.0/0).NextHop

            if ($PasserelleBool -eq $true)
            {
                Remove-NetRoute -InterfaceAlias $Interface -NextHop $Passerelle
            }

            Set-NetIPInterface -InterfaceAlias $Interface -Dhcp Enabled

            sleep 1

            Set-DnsClientServerAddress -InterfaceAlias $Interface -ResetServerAddresses

            sleep 1

            ipconfig /release

            ipconfig /renew

            Pause

            Cls
        }


        x{
            exit
        }


    }
}

until ($choix -eq "x")
