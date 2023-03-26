If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}


$NomDUDomaine = (Get-WmiObject WIN32_ComputerSystem).Domain
$NomDomaineSplit = $NomDUDomaine.Split(".")

$a = $NomDomaineSplit[0]
$b = $NomDomaineSplit[1]


$CSVFile = "$PSScriptRoot\Liste_Utilisateurs.csv"
$CSVData = Import-CSV -Path $CSVFile -Delimiter ";" -Encoding UTF8

Foreach ($Utilisateur in $CSVData) {

    $UtilisateurPrenom = $Utilisateur.Prenom
    $UtilisateurNom = $Utilisateur.Nom
    $UtilisateurFonction = $Utilisateur.fonction
    $UtilisateurAgence = $Utilisateur.agence
    $UtilisateurService = $Utilisateur.service
    $UtilisateurLogin = $UtilisateurPrenom + "." + $UtilisateurNom
    $UtilisateurEmail = "$UtilisateurLogin@$NomDUDomaine"
    $UtilisateurMotDePasse = "Password123"
    
    $UtilisateurAgenceMAJ = $UtilisateurAgence.ToUpper()
    $UtilisateurServiceMAJ = $UtilisateurService.ToUpper()

    # Vérifier la présence de l'utilisateur dans l'AD
    if (Get-ADUser -Filter { SamAccountName -eq $UtilisateurLogin }) {
        Write-Warning "L'identifiant $UtilisateurLogin existe déjà dans l'AD"
    }
    else {

        $OU_Level1_Name = (Get-ADOrganizationalUnit -filter * -SearchScope onelevel | Where-Object Name -NotMatch "Domain*").Name

        New-ADUser -Name "$UtilisateurNom $UtilisateurPrenom" `
            -DisplayName "$UtilisateurNom $UtilisateurPrenom" `
            -GivenName $UtilisateurPrenom `
            -Surname $UtilisateurNom `
            -SamAccountName $UtilisateurLogin `
            -UserPrincipalName "$UtilisateurLogin@$NomDUDomaine" `
            -EmailAddress $UtilisateurEmail `
            -Title $UtilisateurFonction `
            -AccountPassword(ConvertTo-SecureString $UtilisateurMotDePasse -AsPlainText -Force) `
            -ChangePasswordAtLogon $false `
            -Enabled $true `
            #-Path "OU=$UtilisateurService,OU=$UTILISATEURS,OU=$UtilisateurAgence,OU=$SITES,OU=$OU_Level1_Name,DC=$a,DC=$b"`

        sleep 5

        try{
            $OUUser = (Get-ADUser $UtilisateurLogin).DistinguishedName
            Move-ADObject -Identity "$OUUser" -TargetPath "OU=$UtilisateurServiceMAJ,OU=UTILISATEURS,OU=$UtilisateurAgenceMAJ,OU=SITES,OU=$OU_Level1_Name,DC=$a,DC=$b" -Confirm:$false

        }

        catch {
            Write-Host "Erreur, l'utilisateur $UtilisateurLogin n'a pas été déplacé dans l'OU"
         }

        finally {

            $OUUser1 = (Get-ADUser $UtilisateurLogin).DistinguishedName
            Write-Output "Création de l'utilisateur : $UtilisateurLogin ($UtilisateurNom $UtilisateurPrenom) dans l'OU $OUUser1"
         }


        Add-ADGroupMember -Identity "CN=$UtilisateurService,OU=GG,OU=GROUPES,OU=$OU_Level1_Name,DC=$a,DC=$b" -Members $UtilisateurLogin
        


    }
}

pause