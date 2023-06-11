If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

Import-Module ActiveDirectory


Do {
    #Création des groupes globaux

    Write-Host "###### Création des groupes globaux ######" -ForegroundColor Green
    Write-Host ""

    $OU_GG_Path = (Get-ADOrganizationalUnit -Filter "Name -eq 'GG'").DistinguishedName

    $GroupeGlobal = Read-Host "Indiquer le nom du groupe, laisser vide pour mettre fin au script"

    if ($GroupeGlobal -like $null) {
        exit
    } 

    New-ADGroup -Name $GroupeGlobal -Path $OU_GG_Path -GroupScope global


    Write-Host ""
    Write-Host "###### Groupes de partage DL actuels ######" -ForegroundColor Green


    $DL = (Get-ADGroup -Filter * | where-object Name -like "DL*").Name
    $DL_Count = ($DL | measure).count
    $DL_CountBis = $DL_Count - 1

    For ($x = 0; $x -le $DL_CountBis; $x++) {
        write-host "$x" $DL[$x]
    }





    write-host ""

    # Ajout du groupe dans un groupe de partage DL

    $Numero_DL = Read-Host "Indiquer le numéro du DL auquel sera ajouté le groupe global precedemment créé, laiser vide pour ne rien ajouter."
    Write-Host ""

    $Partage = $DL[$Numero_DL]

    if ($Numero_DL -Notlike $null) {
        Add-AdGroupMember -Identity $Partage -Members $GroupeGlobal
        write-host "Le groupe $GroupeGlobal a été ajouté en tant que membre du groupe $Partage"
        Write-Host ""
        pause
        Cls
    }


    elseif ($Numero_DL -like $null) {
        Write-Host ""
        write-host "Pas de groupe indiqué."
        Write-Host ""
        pause
        Cls
    }

    else {
        Write-Error "$Error[0]" -ErrorAction SilentlyContinue
        pause
        Cls
    }

}


until ($GroupeGlobal -like $null)