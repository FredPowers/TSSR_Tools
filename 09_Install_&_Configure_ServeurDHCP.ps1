#installation du rôle DHCP et de la console d'administration
Install-WindowsFeature DHCP -IncludeManagementTools

#Autoriser le DHCP au niveau de l'AD ----------------------------------------------
$NomServeur = (gwmi WIN32_ComputerSystem).Name
$NomDuDomaine = (gwmi WIN32_ComputerSystem).Domain

Add-DHCPServerInDC -DNSName "$NomServeur.$NomDuDomaine"


#Configuration du scope DHCP ----------------------------------------------------------

#création de l'option de serveur DNS --------------------------------------------------------
$NomDNSServeur = Read-Host "entrer l'adresse IP du serveur DNS"
$PasserelleRouteur = Read-Host "entrer l'adresse IP de la passerelle"
Set-DhcpServerv4OptionValue -DNSServer $NomDNSServeur -DNSDomain $NomDUDomaine -Router $PasserelleRouteur

#Création du scope ---------------------------------------------------------------------------------
$NomScope = Read-Host "entrer le nom de l'étendue"
$PremiereIP = Read-Host "entrer la première IP"
$DernièreIP = Read-Host "entrer la dernière IP"
$Masque = Read-Host "entrer le masque de sous-réseaux"
$Description = Read-Host "Indiquer la description de l'étendue"
Add-DhcpServerv4Scope -Name $NomScope -StartRange $PremiereIP -EndRange $DernièreIP -SubnetMask $Masque -Description $Description

pause