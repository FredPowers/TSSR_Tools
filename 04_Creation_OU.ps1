If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}


#Création des OU

Write-Host ""
Write-Host ""


<#

$NOM_OU_Base
      |
      |__GROUPES
      |     |
      |     |__DL
      |     |
      |     |__GG
      |
      |
      |__PARTAGES
      |
      |__SERVEURS
      |
      |__SITES
           |
           |__$Nom_Site
                  |
                  |__IMPRIMANTES
                  |      |                  
                  |      |__$Nom_Service
                  |      |
                  |      |__$Nom_Service
                  |      |
                  |      |__$Nom_Service
                  |
                  |__ORDINATEURS
                  |      |
                  |      |__$Nom_Service
                  |      |
                  |      |__$Nom_Service
                  |      |
                  |      |__$Nom_Service
                  |
                  |__UTILISATEURS
                         |
                         |__$Nom_Service
                         |
                         |__$Nom_Service
                         |
                         |__$Nom_Service
                  

#>




# OU de 1er niveau
$NOM_OU_Base = Read-Host "entrer le nom de l'OU Principale"

Write-Host ""
# déclarations des nom des OU de troisième niveau
$Nom_Site1 = Read-host "indiquer le nom du ou des sites séparé par une virgule. (3 ème niveau d'OU) ex : RENNES,NANTES"

$Nom_Site = $Nom_Site1.Split(",")

Write-Host ""
# déclaration des noms des OU de 4ème niveau
$Nom_Service1 = Read-Host "indiquer les OU 'Service' à intégrer aux OU ORDINATEURS ET UTILISATEURS, ex : DIRECTION,PRODUCTION,INFORMATIQUE"
$Nom_Service = $Nom_Service1.Split(",")

write-host ""

$NomDUDomaine = (Get-WmiObject WIN32_ComputerSystem).Domain
$NomDomaineSplit = $NomDUDomaine.Split(".")

$count = ($NomDomaineSplit | Measure-Object).count

if ($count -eq 2) {
    $a = $NomDomaineSplit[0]
    $b = $NomDomaineSplit[1]
    $DC = "DC=$a,DC=$b"
}

if ($count -eq 3) {
    $a = $NomDomaineSplit[0]
    $b = $NomDomaineSplit[1]
    $c = $NomDomaineSplit[2]

    $DC = "DC=$a,DC=$b,DC=$c"
}


#création de l'OU de 1er niveau
New-ADOrganizationalUnit -Name $NOM_OU_Base -Path "$DC" -ProtectedFromAccidentalDeletion $false

# création des OU de second niveau
New-ADOrganizationalUnit -Name "GROUPES" -Path "OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "PARTAGES" -Path "OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "SERVEURS" -Path "OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "SITES" -Path "OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
# OU 3ème niveau
New-ADOrganizationalUnit -Name "GG" -Path "OU=GROUPES,OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "DL" -Path "OU=GROUPES,OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false

ForEach ($Site in $Nom_Site) {
    #OU 3ème niveau
    New-ADOrganizationalUnit -Name $Site -Path "OU=SITES,OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
    $List = "ORDINATEURS UTILISATEURS IMPRIMANTES".Split(" ")
    Foreach ($Item in $List) {
        # OU 4ème niveau
        New-ADOrganizationalUnit -Name $Item -Path "OU=$Site,OU=SITES,OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
        Foreach ($ItemService in $Nom_Service) {
            # OU 5ème niveau
            New-ADOrganizationalUnit -Name $ItemService -Path "OU=$Item,OU=$Site,OU=SITES,OU=$NOM_OU_Base,$DC" -ProtectedFromAccidentalDeletion $false
        }
    }
}






$ErrorActionPreference = 'SilentlyContinue'



$OU_Level1_Name = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | Where-Object Name -NotMatch "Domain*").Name

#$OU_Level1_DistinguishedName = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | Where-Object Name -NotMatch "Domain*").DistinguishedName


#$OU_Level2_Name = ($OU_Level1_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).Name

#$OU_Level2_DistinguishedName = ($OU_Level1_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).DistinguishedName


#$OU_Level3_Name = ($OU_Level2_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).Name

#$OU_Level3_DistinguishedName = ($OU_Level2_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).DistinguishedName


#$OU_Level4_Name = ($OU_Level3_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).Name

#$OU_Level4_DistinguishedName = ($OU_Level3_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).DistinguishedName


#$OU_Level5_Name = ($OU_Level4_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).Name

#$OU_Level5_DistinguishedName = ($OU_Level4_DistinguishedName | Foreach-Object {Get-ADOrganizationalUnit -Filter * -SearchBase $_ -SearchScope OneLevel}).DistinguishedName




Write-Host ""
Write-Host "#### Vérifiaction de l'arborescence créée ####" -ForegroundColor Green

# affichage dans le terminal Powershell

$ErrorActionPreference = 'SilentlyContinue'



$OU_Level1_Name = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | where Name -NotMatch "Domain*").Name

            

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
pause
