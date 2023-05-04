# TSSR_Tools
créer un environnement AD avec rôles DNS,DHCP. Créer des partages de dossier, utilisateurs, groupes sur windows serveur.

.NOTES  
NAME:	TSSR_Tools  
VERSION : 1.0  26/03/2023  
AUTHOR:	Frédéric Puren  


Testé sur windows server 2022

**Scripts à lancer dans l'ordre afin de configurer rapidement un environnement AD avec role DNS,DHCP, partage de dossier, utilisateurs, groupe sur windows serveur.**

Accès à internet necessaire afin de télécharger des modules ou logiciels supplémentaires :

- Script 03_Install_AD-DS.ps1 :
Téléchargement du logiciel PingCastle (Audit de l'AD, rapport html) via "https://github.com/vletoux/pingcastle/releases/download/3.0.0.0/PingCastle_3.0.0.0.zip"

installation du module ModernActiveDirectory (Vue sur l'AD via une page html, en lecture seulement) disponible dans la gallerie powershell

Source : https://github.com/dakhama-mehdi/Modern_ActiveDirectory


- Script 05_Creation_dossiers_Partagés_DL_NTFS.ps1 :
Téléchargement du dépot NuGet qui contient plus de 100000 packages dont le module NTFSSecurity
Le module NTFSSecurity sert à gérer facilement les autorisations NTFS

source : https://www.it-connect.fr/gerer-les-autorisations-ntfs-en-powershell-avec-ntfssecurity/

#Liste des scripts :

- 01_Nom_serveur.ps1
- 02_Config_IP.ps1
- 03_Install_AD-DS.ps1
- 04_Creation_OU.ps1
- 05_Creation_dossiers_Partagés_DL_NTFS.ps1
- 06_Creation_GG.ps1
- 07_Creation_ADUser_via_CSV.ps1
- 08_Config_ServeurDNS.ps1
- 09_Install_&_Configure_ServeurDHCP.ps1
- Debogage.ps1


02_Config_IP  
![02](https://user-images.githubusercontent.com/105367565/227781711-ae2e693a-dd16-4a96-b5be-bae272505b06.png)

03_Install_AD-DS  
![03](https://user-images.githubusercontent.com/105367565/227781729-cb39ebaf-baaf-4aa9-9b21-c65fc9f68c7f.png)

04_Creation_OU  
![04](https://user-images.githubusercontent.com/105367565/227781751-86a46091-fc9e-409a-83d2-6dbcf5e58f12.png)

05_Creation_dossiers_Partagés_DL_NTFS  
![05](https://user-images.githubusercontent.com/105367565/227781773-93105daf-d22a-4c49-83b1-a116bb6cf380.png)

06_Creation_GG  
![06](https://user-images.githubusercontent.com/105367565/227781787-a666f1a5-efd7-460d-846b-d99578fa7d89.png)

07_Creation_ADUser_via_CSV  
![07](https://user-images.githubusercontent.com/105367565/227781800-7d4c270c-d1af-4cf0-8e6c-3c446dd98813.png)

08_Config_ServeurDNS  
![08](https://user-images.githubusercontent.com/105367565/227781814-fe1a242b-954e-4d18-a09f-2827e30f8f5a.png)

09_Install_&_Configure_ServeurDHCP  
![09](https://user-images.githubusercontent.com/105367565/227781842-483eee6f-5ccc-4628-9d90-744fc9275521.png)

Debogage  
![2023-03-26 16_48_38-Window](https://user-images.githubusercontent.com/105367565/227783805-dfd4de53-9a82-49ab-ab14-c2673813ef52.png)


