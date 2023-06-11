If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}


# installation du module NTFSSecurity pour facilité la gestion des droits NTFS

$NTFSSecurity = Get-Module -ListAvailable | where Name -like "NTFSSecurity"

if ($NTFSSecurity -eq $null) {
    write-host "installation du module NTFSSecurity pour facilité la gestion des droits NTFS" -ForegroundColor Green
    Write-Host ""
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force
    Install-Module NTFSSecurity -Verbose -Confirm:$false -Force
}

#création des dossiers et des partages

Write-Host "##### Création des repertoires et du partage en FullAccess pour 'utilisateurs authentifiés' #####" -ForegroundColor Green
Write-Host ""

Do {

    $Chemin = read-host "entrer le chemin complet du dossier à créer (ex: C:\nom_dossier, D:\dossier1\nom_dossier$)

Laisser vide pour que le script prenne fin."

    if ($Chemin -like $null) {
        exit
    }

    Write-Host ""

    $Description = Read-Host "Indiquer la description du partage"

    # Création du dossier
    Write-Host "Création du dossier" -ForegroundColor Green
    Write-Host ""
    mkdir $Chemin

    $Dossier = ($Chemin.Split("\\"))[-1]

    # Création du partage du dossier
    Write-Host "Création du partage du dossier - FullAccess pour 'Utilisateurs authentifiés" -ForegroundColor Green
    write-host ""

    new-smbshare -Verbose $Chemin -Name Partage_$Dossier -FullAccess “Utilisateurs authentifiés” -Description $Description


    # Création des 4 groupes DL (RO,RW,CT,NO)
    Write-Host "Création des 4 groupes DL (RO,RW,CT,NO) dans l'OU DL" -ForegroundColor Green
    Write-Host ""
    $OU_DL_Path = (Get-ADOrganizationalUnit -Filter "Name -eq 'DL'").DistinguishedName

    New-ADGroup -Name "DL_'$Dossier'_RO" -Path $OU_DL_Path -GroupScope DomainLocal -Verbose
    New-ADGroup -Name "DL_'$Dossier'_RW" -Path $OU_DL_Path -GroupScope DomainLocal -Verbose
    New-ADGroup -Name "DL_'$Dossier'_CT" -Path $OU_DL_Path -GroupScope DomainLocal -Verbose
    New-ADGroup -Name "DL_'$Dossier'_NO" -Path $OU_DL_Path -GroupScope DomainLocal -Verbose


    # Ajout des groupes précédemment créés sur les droits NTFS du dossier partagé
    Write-Host "Ajout des groupes précédemment créés sur les droits NTFS du dossier partagé" -ForegroundColor Green
    write-host ""

    Add-NTFSAccess -Verbose –Path $Chemin –Account "DL_'$Dossier'_RO" –AccessRights ReadAndExecute
    Add-NTFSAccess -Verbose –Path $Chemin –Account "DL_'$Dossier'_RW" –AccessRights Modify
    Add-NTFSAccess -Verbose –Path $Chemin –Account "DL_'$Dossier'_CT" –AccessRights FullControl
    Add-NTFSAccess -Verbose –Path $Chemin –Account "DL_'$Dossier'_NO" -AccessType Deny –AccessRights FullControl

    Cls

}

until ($Chemin -like $null)


