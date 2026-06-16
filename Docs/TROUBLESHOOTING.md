# 🔧 Guide de Dépannage - ClickByChris Setup Tool

[![Windows](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows)
[![Status](https://img.shields.io/badge/Status-Updated-success.svg)](../CHANGELOG.md)

---

## 📑 Table des Matières

- [🔍 Diagnostic Rapide](#-diagnostic-rapide)
- [❌ Erreurs PowerShell](#-erreurs-powershell)
- [❌ Erreurs d'Installation](#-erreurs-dinstallation)
- [❌ Erreurs d'Interface](#-erreurs-dinterface)
- [🐌 Problèmes de Performance](#-problèmes-de-performance)
- [🌐 Problèmes Réseau](#-problèmes-réseau)
- [📊 Problèmes de Logs](#-problèmes-de-logs)
- [🆘 Impossible de Résoudre ?](#-impossible-de-résoudre-)

---

## 🔍 **Diagnostic Rapide**

### ✅ **Checklist Initiale**

Avant d'aller plus loin, vérifie :

```powershell
# 1️⃣ Vérifier Windows
[System.Environment]::OSVersion.VersionString
# Doit afficher : Microsoft Windows NT 10.0.xxxxx

# 2️⃣ Vérifier PowerShell
$PSVersionTable.PSVersion
# Doit afficher : 5.1 ou supérieur

# 3️⃣ Vérifier l'accès administrateur
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
# Doit afficher : True

# 4️⃣ Vérifier la connexion internet
Test-Connection google.com -Count 1
# Doit afficher : Reply from 142.251.x.x

# 5️⃣ Vérifier l'espace disque
Get-PSDrive C | Select-Object Used,Free
# Free doit être > 500 MB

❌ Erreurs PowerShell
1️⃣ "PowerShell scripts are disabled on this system"

Symptôme :

cannot be loaded because running scripts is disabled on this system.

Cause : La politique d'exécution empêche les scripts de s'exécuter.

Solution :

# Ouvre PowerShell EN TANT QU'ADMINISTRATEUR

# Affiche la politique actuelle
Get-ExecutionPolicy -Scope CurrentUser

# Modifie la politique
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Confirme la modification
Get-ExecutionPolicy -Scope CurrentUser
# Doit afficher : RemoteSigned

✅ Relance le script après
2️⃣ "Access Denied" / "Permission Denied"

Symptôme :

Access is denied.
Cannot open file 'ClickByChris_Setup_Tool.ps1'

Causes Possibles :

    ❌ Pas d'accès administrateur
    ❌ Antivirus bloque le fichier
    ❌ Fichier en lecture seule

Solutions :

Option A : Lancer en Administrateur

# Clique droit sur PowerShell
# → "Exécuter en tant qu'administrateur"
# Puis relance le script

Option B : Débloquer le fichier

# Si le fichier vient d'internet, il peut être bloqué

# Vérifier l'état
Get-Item "ClickByChris_Setup_Tool.ps1" -Stream Zone.Identifier

# Débloquer
Unblock-File -Path "ClickByChris_Setup_Tool.ps1"

Option C : Antivirus

# Ajoute une exception antivirus (Windows Defender)
Add-MpPreference -ExclusionPath "C:\Tools\ClickByChris-Setup-Tool"

# Ou désactiver temporairement
# ⚠️ À faire avec prudence
Set-MpPreference -DisableRealtimeMonitoring $true
# ... Lance le script ...
# Réactive après
Set-MpPreference -DisableRealtimeMonitoring $false

3️⃣ "The script failed to run"

Symptôme :

The script 'install.ps1' cannot be executed because it contains a ":" character.

Cause : Chemin du fichier contient un caractère spécial ou espaces.

Solution :

# Utilise des guillemets si le chemin contient des espaces
& "C:\Program Files\ClickByChris-Setup-Tool\ClickByChris_Setup_Tool.ps1"

# Ou renomme le dossier sans espaces
Move-Item "C:\Program Files\My Tool" "C:\Tools\MyTool"

4️⃣ "Module not found"

Symptôme :

The 'PSWindowsUpdate' module cannot be found.

Cause : Un module PowerShell requis est manquant.

Solution :

# Installer le module manquant
Install-Module PSWindowsUpdate -Force -Scope CurrentUser

# Ou pour tous les modules requis
Install-Module -Name @("PSWindowsUpdate", "Posh-SSH") -Force

❌ Erreurs d'Installation
1️⃣ "Winget not found"

Symptôme :

winget : The term 'winget' is not recognized

Cause : Windows Package Manager (winget) n'est pas installé.

Solution :

Option A : Installation depuis le Microsoft Store (Recommandé)

# Ouvre Microsoft Store et cherche "App Installer"
# Clique sur "Get" ou "Install"

Option B : Installation manuelle

# Télécharge depuis GitHub
$url = "https://github.com/microsoft/winget-cli/releases/download/v1.6.10471/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Invoke-WebRequest -Uri $url -OutFile winget.msixbundle
Add-AppxPackage winget.msixbundle

# Vérifie l'installation
winget --version

2️⃣ "No suitable package found"

Symptôme :

No suitable package found for 'Google.Chrome'

Cause : Le package n'existe pas sur winget ou le nom est mal orthographié.

Solution :

# Cherche le bon nom du package
winget search chrome

# Utilise le bon ID exact
winget install --id Google.Chrome --accept-package-agreements --accept-source-agreements

Packages Courants :

Google.Chrome
Microsoft.Edge
Mozilla.Firefox
OpenJS.NodeJS
Microsoft.VisualStudioCode
Python.Python.3.11
Git.Git
7zip.7zip

3️⃣ "Installation timeout"

Symptôme :

The operation timed out trying to download package.

Cause : 

    Connexion internet lente
    Serveur de téléchargement indisponible
    Package trop gros

Solutions :

# Option A : Vérifier la connexion
Test-Connection google.com
Invoke-WebRequest -Uri https://www.google.com -TimeoutSec 10

# Option B : Augmenter le timeout dans le script
# Modifie le fichier install.ps1 et cherche $timeout = 300
# Change à $timeout = 600 (10 minutes au lieu de 5)

# Option C : Installer manuellement
# Télécharge depuis le site officiel
# https://www.google.com/chrome/

4️⃣ "Package already installed"

Symptôme :

Package 'Google.Chrome' is already installed.

Solution :

# Rien à faire, le script continue automatiquement

# Si tu veux forcer la réinstallation
winget uninstall Google.Chrome
winget install Google.Chrome --accept-package-agreements

# Ou depuis le script, modifie settings.json
{
  "modules": {
    "chrome": false  # Désactiver pour sauter
  }
}

5️⃣ "Antivirus blocked the installation"

Symptôme :

Installation was blocked by antivirus.
File quarantined.

Solutions :

# Option A : Ajouter une exception (Windows Defender)
Add-MpPreference -ExclusionPath "C:\Program Files\Google\Chrome"
Add-MpPreference -ExclusionPath "$env:USERPROFILE\ClickByChris"

# Option B : Désactiver temporairement
Set-MpPreference -DisableRealtimeMonitoring $true
# ... Lance l'installation ...
Set-MpPreference -DisableRealtimeMonitoring $false

# Option C : Désinstaller du quarantaine (Defender)
# Panneau de Contrôle → Virus & threat protection
# → Manage settings → Virus & threat protection settings
# → Exclusions → Ajouter les chemins

❌ Erreurs d'Interface
1️⃣ "Window not appearing"

Symptôme : La fenêtre GUI ne s'affiche pas ou est invisible.

Solutions :

# Option A : Vérifier les droits d'administrateur
# Doit être lancé EN TANT QU'ADMINISTRATEUR
Start-Process powershell -Verb RunAs

# Option B : Relancer en mode console
.\ClickByChris_Setup_Tool.ps1 -NoGUI

# Option C : Vérifier la résolution d'écran
Get-WmiObject -Class Win32_VideoController | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution

# Si ≤ 1280x720, l'interface peut être mal positionnée
# Relance avec une résolution > 1920x1080

2️⃣ "Button not clickable" / "GUI frozen"

Symptôme : Les boutons ne répondent pas ou l'interface est gelée.

Solutions :

# Option A : Fermer et relancer
# Appuie sur Ctrl+C pour arrêter le script

# Option B : Vérifier les processus
Get-Process | Where-Object {$_.Name -like "*PowerShell*"} | Stop-Process -Force

# Option C : Redémarrer PowerShell complètement
# Ferme toutes les fenêtres PowerShell
# Rouvre une nouvelle fenêtre en Admin
# Relance le script

3️⃣ "Text overlapping" / "Layout broken"

Symptôme : Les textes se chevauchent ou l'interface est mal positionnée.

Solutions :

# Option A : Vérifier la résolution
# L'interface est optimisée pour 1920x1080
# Si tu as une autre résolution, l'affichage peut être dégradé

# Change ta résolution Windows
# Paramètres → Affichage → Résolution d'écran → 1920x1080

# Option B : Utiliser une résolution inférieure depuis le script
# Modifie ClickByChris_Setup_Tool.ps1
# Cherche : $form.Size = New-Object System.Drawing.Size(1920,1080)
# Change à : $form.Size = New-Object System.Drawing.Size(1280,720)

🐌 Problèmes de Performance
1️⃣ "Installation très lente"

Symptôme : Installation prend plus de 2h pour 10 logiciels.

Causes :

    Connexion internet lente
    PC surchargé
    Antivirus ralentit les écritures disque
    HDD vieux ou fragmenté

Solutions :

# Option A : Vérifier la vitesse internet
$start = Get-Date
Invoke-WebRequest -Uri "https://www.google.com" -OutFile test.html
$end = Get-Date
($end - $start).TotalSeconds  # En secondes

# Option B : Libérer de la RAM
# Ferme Chrome, Discord, Visual Studio, etc.
# Regarde le gestionnaire des tâches
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10

# Option C : Désactiver l'antivirus temporairement
# ⚠️ À faire avec prudence
Set-MpPreference -DisableRealtimeMonitoring $true
# ... Lance l'installation ...
Set-MpPreference -DisableRealtimeMonitoring $false

# Option D : Installer moins de logiciels à la fois
# Modifie settings.json et installe en 2-3 batchs

# Option E : Défragmenter le disque (HDD seulement)
defrag C: -U -V

2️⃣ "PowerShell consomme 100% CPU"

Symptôme : PowerShell utilise toute la CPU pendant l'installation.

C'est normal ! L'installation parallèle utilise plusieurs threads.

Mais si c'est excessif :

# Réduis le nombre de threads parallèles
# Modifie ClickByChris_Setup_Tool.ps1
# Cherche : $maxThreads = 4
# Change à : $maxThreads = 2

# Relance le script

3️⃣ "Disque à 100% pendant l'installation"

C'est normal ! L'installation écrit beaucoup de données.

Mais si c'est problématique :

# Option A : Fermer les applications gourmandes
# Chrome, Visual Studio, Games, etc.

# Option B : Utiliser un disque plus rapide
# Bouge le dossier ClickByChris sur un SSD

# Option C : Installer en mode séquentiel
# Au lieu de 4 logiciels en parallèle, n'en installer que 1

🌐 Problèmes Réseau
1️⃣ "Pas d'accès internet"

Symptôme :

No internet connection detected.

Vérifications :

# Test la connexion
Test-NetConnection google.com

# Test le DNS
Resolve-DnsName google.com

# Test le ping
ping google.com

# Vérifier les paramètres réseau
Get-NetIPConfiguration

Solutions :

    Vérifier le câble Ethernet / WiFi
    Redémarrer la box internet
    Vérifier les pare-feu
    Contacter ton FAI

2️⃣ "Proxy corporate bloque les téléchargements"

Symptôme :

The proxy server is blocking downloads.

Solutions :

# Option A : Configurer le proxy
[System.Net.ServicePointManager]::DefaultConnectionLimit = 4
$proxy = New-Object System.Net.WebProxy("http://proxy.company.com:8080", $true)
[System.Net.ServicePointManager]::DefaultWebProxy = $proxy

# Option B : Bypass le proxy pour certains domaines
$proxy.BypassList = @("*.microsoft.com", "*.github.com")

# Option C : Utiliser le proxy du système (automatique)
# Modifie install.ps1 et cherche les paramètres de proxy

3️⃣ "Certificat SSL expiré / invalide"

Symptôme :

The SSL certificate is invalid.

Solutions :

# ⚠️ À ne faire que si tu fais confiance au serveur !

# Option A : Ignorer la validation SSL (risqué)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Option B : Mettre à jour les certificats Windows
# Paramètres → Heure et langue → Date et heure
# Vérifie que la date/heure est correcte

# Option C : Mettre à jour .NET Framework
# Télécharge depuis : https://dotnet.microsoft.com/download

4️⃣ "Serveur winget indisponible"

Symptôme :

The package source is unavailable.

Solutions :

# Vérifier l'état du serveur
winget source list

# Réinitialiser les sources
winget source reset --force

# Vérifier la version de winget
winget --version

# Mettre à jour winget
# Depuis Microsoft Store → App Installer → Mettre à jour

📊 Problèmes de Logs
1️⃣ "Logs introuvables"

Symptôme : Le dossier logs n'existe pas après l'installation.

Localisation :

# Les logs doivent être ici
$env:USERPROFILE\ClickByChris\logs\

# Ouvre ce dossier
explorer $env:USERPROFILE\ClickByChris\logs\

# Ou liste les fichiers
Get-ChildItem "$env:USERPROFILE\ClickByChris\logs\" -Recurse

Si le dossier n'existe pas :

# Le script crée le dossier automatiquement
# Mais tu peux le créer manuellement
mkdir "$env:USERPROFILE\ClickByChris\logs"

# Relance l'installation

2️⃣ "Fichiers log vides"

Cause : Le script n'a pas écrit dans les logs (erreur en amont).

Solutions :

# Relance le script en mode verbose
.\ClickByChris_Setup_Tool.ps1 -Verbose

# Ou depuis PowerShell
$VerbosePreference = "Continue"
.\ClickByChris_Setup_Tool.ps1

# Cela affichera plus de détails

3️⃣ "Logs très volumineux (> 100 MB)"

Cause : Installation de beaucoup de logiciels avec mode verbose.

Solutions :

# Désactiver le mode verbose dans settings.json
{
  "install_options": {
    "verbose_mode": false
  }
}

# Ou nettoyer les anciens logs
Remove-Item "$env:USERPROFILE\ClickByChris\logs\*" -Recurse -Force -Confirm:$false

# Garder seulement les 10 derniers
Get-ChildItem "$env:USERPROFILE\ClickByChris\logs\" | Sort-Object CreationTime -Descending | Select-Object -Skip 10 | Remove-Item -Force

🆘 Impossible de Résoudre ?
📋 Collecte d'Informations pour le Support

Avant de demander de l'aide, collecte ces informations :

# 1️⃣ Informations système
$info = @{
    OS = [System.Environment]::OSVersion.VersionString
    PowerShell = $PSVersionTable.PSVersion
    Admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    RAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    CPU = (Get-WmiObject Win32_Processor).Name
}
$info | Out-String | Write-Host

# 2️⃣ Dernier fichier log
$lastLog = Get-ChildItem "$env:USERPROFILE\ClickByChris\logs\" | Sort-Object CreationTime -Descending | Select-Object -First 1
if ($lastLog) {
    Get-Content $lastLog.FullName | Tail -50
}

# 3️⃣ Messages d'erreur exact
# Copie-colle le message d'erreur complet

# 4️⃣ Capture d'écran de l'erreur
# Prends une screenshot

🐛 Signaler un Bug sur GitHub

Va sur : https://github.com/christophe939/ClickByChris-Setup-Tool/issues

    Clique sur "New Issue"
    Sélectionne "Bug Report"
    Remplis :
        Titre : Description courte du bug
        Description : Détails et étapes pour reproduire
        Fichier log : Copie-colle le .log (ou attache-le)
        Screenshot : Si applicable
        Système : Windows 10/11, version PowerShell, etc.

Exemple :

## Titre
Installation de Chrome échoue avec une erreur de timeout

## Description
Quand j'essaie d'installer Google Chrome via le script,
j'obtiens un erreur "The installation timed out".

## Étapes pour reproduire
1. Lancer ClickByChris_Setup_Tool.ps1
2. Sélectionner uniquement Google Chrome
3. Cliquer sur "Installer"
4. Attendre 5 minutes

## Message d'erreur exact

No suitable package found for 'Google.Chrome'


## Informations système
- OS: Windows 11 (22H2)
- PowerShell: 5.1
- RAM: 8 GB
- Connexion: ADSL 10 Mbps

💬 Poser une Question

Va sur : https://github.com/christophe939/ClickByChris-Setup-Tool/discussions

    Clique sur "New Discussion"
    Sélectionne "Questions & Answers"
    Demande ta question

Exemple :

## Titre
Comment installer uniquement certains logiciels ?

## Question
Je veux installer Chrome et VS Code, mais pas tous les autres.
Existe-t-il un moyen de ne sélectionner que ceux-ci ?

Je pensais que je pouvais modifier le fichier settings.json,
mais je n'arrive pas à le faire fonctionner correctement.

Peux-tu m'aider ?

📧 Contact Direct

Email : christophe939@gmail.com

Mentionne :

    ❌ Le problème
    📋 Les étapes pour reproduire
    📸 Screenshot si possible
    📄 Fichier .log en attachement

✅ Checklist Avant de Contacter le Support

    J'ai vérifié les prérequis (Windows 10+, PowerShell 5.1+)
    J'ai lancé en tant qu'administrateur
    J'ai désactivé/excepted l'antivirus
    J'ai vérifié la connexion internet
    J'ai lu ce guide de dépannage complètement
    J'ai collecté les informations système
    J'ai joints les fichiers logs

Si tu as checké tout ça, tu peux contacter le support ! 🚀


---

# 🤝 **CONTRIBUTING.md**

```markdown
# 🤝 Guide de Contribution - ClickByChris Setup Tool

[![Windows](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Contributing](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)](#-types-de-contributions)

Merci de ton intérêt pour contribuer au projet ! 🎉

---

## 📑 Table des Matières

- [🎯 Code de Conduite](#-code-de-conduite)
- [❓ Comment Contribuer ?](#-comment-contribuer-)
- [🐛 Signaler un Bug](#-signaler-un-bug)
- [✨ Proposer une Fonctionnalité](#-proposer-une-fonctionnalité)
- [🍴 Workflow Fork & Pull Request](#-workflow-fork--pull-request)
- [📝 Conventions de Code](#-conventions-de-code)
- [🔗 Ajouter un Nouveau Module](#-ajouter-un-nouveau-module)
- [📚 Documentation](#-documentation)
- [🧪 Tests](#-tests)
- [🎯 Roadmap](#-roadmap)
- [💬 Questions ?](#-questions-)

---

## 🎯 **Code de Conduite**

Nous nous engageons à créer une communauté accueillante et bienveillante.

### ✅ **À Faire**

- ✅ Sois respectueux envers les autres contributeurs
- ✅ Accueille le feedback constructif
- ✅ Focus sur ce qui est meilleur pour la communauté
- ✅ Reconnais les contributeurs
- ✅ Signale les comportements inappropriés

### ❌ **À NE PAS Faire**

- ❌ Harcèlement ou discrimination
- ❌ Langage offensant ou insultes
- ❌ Spam ou auto-promotion
- ❌ Partage de données personnelles sans consentement
- ❌ Tout ce qui viole les lois

**Violation ?** → Contact : christophe939@gmail.com

---

## ❓ **Comment Contribuer ?**

### 🐛 **1️⃣ Signaler un Bug**

Tu as trouvé une erreur ? Aide-nous à l'améliorer !

→ [Aller aux Issues](https://github.com/christophe939/ClickByChris-Setup-Tool/issues)

**Format :**
```markdown
## Bug Title
[Description courte du bug]

## Description
[Explique le problème en détail]

## Steps to Reproduce
1. [Première étape]
2. [Deuxième étape]
3. [...]

## Expected Behavior
[Ce qui devrait se passer]

## Actual Behavior
[Ce qui se passe réellement]

## Screenshots
[Si applicable, attache une capture d'écran]

## System Information
- OS: Windows 11
- PowerShell: 5.1
- RAM: 8 GB

✨ 2️⃣ Proposer une Fonctionnalité

Tu as une idée géniale ? On veut l'entendre !

→ Aller aux Discussions

Format :

## Feature Title
[Titre de la fonctionnalité]

## Description
[Explique la fonctionnalité en détail]

## Why?
[Pourquoi cette fonctionnalité serait utile ?]

## Implementation Example
[Si possible, un exemple de code]

## Additional Context
[Liens, références, contexte supplémentaire]

💻 3️⃣ Soumettre du Code

Tu veux contribuer du code ? Parfait !

→ Consulte le workflow Fork & Pull Request
📚 4️⃣ Améliorer la Documentation

Améliorer la documentation est aussi important que le code !

    Corriger les typos
    Ajouter des exemples
    Clarifier les instructions
    Ajouter des sections manquantes
    Traduire en d'autres langues

→ Suis le workflow Fork & Pull Request
🐛 Signaler un Bug
✅ Avant de Signaler

    Vérifie que le bug n'est pas déjà signalé
    Teste avec la dernière version
    Consulte le guide de dépannage
    Vérifie les prérequis (Windows 10+, PowerShell 5.1+)

📋 Informations à Fournir

# Collecte ces informations
$info = @{
    "OS" = [System.Environment]::OSVersion.VersionString
    "PowerShell" = $PSVersionTable.PSVersion.ToString()
    "ClickByChris Version" = "1.0.0"  # Consulte le fichier version.json
    "Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Aussi fournir
# - Fichier .log complet (ou tail -50)
# - Screenshot de l'erreur
# - Étapes exactes pour reproduire

🚫 Bugs Non-Acceptés

    Erreurs provenant de logiciels tiers (contacte le support du logiciel)
    Erreurs sur des OS non supportés (Windows 7, etc.)
    Erreurs dues à une configuration système invalide

✨ Proposer une Fonctionnalité
✅ Avant de Proposer

    Vérife que la fonctionnalité n'existe pas déjà
    Vérife qu'elle n'a pas été proposée ailleurs
    Assure-toi qu'elle est pertinente pour le projet

📋 Sois Spécifique

❌ Mauvais :

Ajouter plus de logiciels

✅ Bon :

Ajouter support pour Spotify (plateforme musicale)
- Utilisé par les développeurs pour la musique
- Facile à installer via winget (Spotify.Spotify)
- Demande de plusieurs utilisateurs

🍴 Workflow Fork & Pull Request
Étape 1️⃣ : Fork le Repo

    Va sur GitHub : ClickByChris-Setup-Tool
    Clique sur "Fork" (en haut à droite)
    Clique sur "Create fork"

Tu as maintenant une copie du repo sur ton compte !
Étape 2️⃣ : Clone Ton Fork Localement

# Clone ton fork (pas l'original !)
git clone https://github.com/TON_USERNAME/ClickByChris-Setup-Tool.git

# Navigue dans le dossier
cd ClickByChris-Setup-Tool

# Ajoute l'original comme "upstream"
git remote add upstream https://github.com/christophe939/ClickByChris-Setup-Tool.git

# Vérifie
git remote -v
# Doit afficher :
# origin  https://github.com/TON_USERNAME/... (fetch)
# origin  https://github.com/TON_USERNAME/... (push)
# upstream https://github.com/christophe939/... (fetch)
# upstream https://github.com/christophe939/... (push)

Étape 3️⃣ : Crée une Branche

# Mets à jour depuis l'original
git fetch upstream
git checkout main
git merge upstream/main

# Crée une branche pour ta contribution
git checkout -b feature/ma-nouvelle-fonctionnalite

# Ou pour un bug fix
git checkout -b bugfix/mon-bug-fix

# Norme de nommage :
# - feature/... pour une nouvelle fonctionnalité
# - bugfix/... pour un bug fix
# - docs/... pour la documentation
# - refactor/... pour du refactoring
# - test/... pour des tests

Étape 4️⃣ : Fais tes Modifications

Édite les fichiers que tu veux changer.

Respecte les conventions → Voir Conventions de Code

# Vérify tes changements
git status
git diff

# Teste ton code (important !)
.\ClickByChris_Setup_Tool.ps1

# Ou teste un module spécifique
.\install.ps1 -Module "Google.Chrome"

Étape 5️⃣ : Commit tes Changements

# Ajoute les fichiers changés
git add .

# Commit avec un message clair
git commit -m "feat: Ajouter support pour Spotify"

# Ou plusieurs commits
git commit -m "feat: Ajouter Spotify au module audio"
git commit -m "docs: Mettre à jour README avec Spotify"
git commit -m "test: Ajouter tests pour Spotify"

# Format des messages :
# feat:     Nouvelle fonctionnalité
# fix:      Bug fix
# docs:     Documentation
# style:    Formatting (pas de logique changée)
# refactor: Code refactor
# test:     Tests
# chore:    Build, deps, etc.

Étape 6️⃣ : Push vers ton Fork

# Push ta branche
git push origin feature/ma-nouvelle-fonctionnalite

# Ou si tu as déjà poussé
git push origin feature/ma-nouvelle-fonctionnalite --force

Étape 7️⃣ : Crée une Pull Request

    Va sur GitHub vers ton fork
    Tu veras un message "Compare & pull request"
    Clique dessus
    Ou va sur https://github.com/christophe939/ClickByChris-Setup-Tool/pulls

Format de PR :

## Description
[Explique rapidement ce que change ta PR]

## Type de changement
- [ ] Nouvelle fonctionnalité
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactoring
- [ ] Autre

## Tests
- [ ] J'ai testé sur Windows 10
- [ ] J'ai testé sur Windows 11
- [ ] Tous les tests passent
- [ ] J'ai ajouté des tests

## Checklist
- [ ] Mon code suit les conventions
- [ ] J'ai mis à jour la documentation
- [ ] J'ai ajouté des logs/commentaires
- [ ] Je ne casse pas de fonctionnalités existantes
- [ ] Les commits sont clairs et logiques

## Lié à
Fixes #123 (numéro de l'issue si applicable)

Étape 8️⃣ : Review & Merge

    👀 Le mainteneur review ta PR
    💬 Réponds aux commentaires et demandes
    ✅ Quand c'est bon, la PR est mergée !
    🎉 Félicitations, tu as contribué !

📝 Conventions de Code
PowerShell

# ✅ BON
function Install-Package {
    param(
        [string]$PackageName,
        [switch]$Force
    )
    
    Write-Host "Installing $PackageName..." -ForegroundColor Green
    
    # Comment expliquant la logique
    if ($Force) {
        # ...
    }
}

# ❌ MAUVAIS
function install {
    $pkg = $args[0]
    echo "Installing..."
    # Code sans commentaires
}

Règles :

    Fonctions en PascalCase : Install-Package
    Variables en camelCase :  $ packageName
    Constants en UPPER_CASE :  $ MAX_RETRIES
    Commentaires expliquant le "pourquoi", pas le "quoi"
    Indentation 4 espaces
    Pas de lignes > 120 caractères

JSON

{
  "modules": {
    "chrome": true,
    "vscode": true
  },
  "settings": {
    "verbose": false,
    "timeout": 300
  }
}

Règles :

    Indentation 2 espaces
    Clés en snake_case
    Guillemets doubles
    Pas de commentaires (utilise un fichier JSON Schema)

Markdown

# Titre Principal
## Sous-titre
### Sous-sous-titre

**Gras** et *italique*

- Liste non-ordonnée
  - Sous-liste
  
1. Liste ordonnée
2. Deuxième item

[Lien](https://example.com)

```code block```

Règles :

    Ligne vide entre les sections
    Listes sans mélanger - et *
    Lien avec description claire
    80 caractères par ligne (flexible)

🔗 Ajouter un Nouveau Module
Étape 1️⃣ : Vérifier que le Package Existe

winget search "nom-du-logiciel"

# Exemple pour Spotify
winget search spotify
# Affiche : Spotify.Spotify

Étape 2️⃣ : Modifier settings.json

{
  "modules": {
    "chrome": true,
    "spotify": false
  }
}

Étape 3️⃣ : Modifier install.ps1

Ajoute dans la section des modules :

# Spotify
if ($settings.modules.spotify) {
    Write-Host "Installing Spotify..." -ForegroundColor Cyan
    winget install --id Spotify.Spotify --accept-package-agreements --accept-source-agreements
}

Étape 4️⃣ : Mettre à Jour la Documentation

Ajoute dans FEATURES.md :

| **Spotify** | Plateforme musicale | ✅ Stable | `Spotify.Spotify` |

Étape 5️⃣ : Tester

# Teste que le module s'installe correctement
.\ClickByChris_Setup_Tool.ps1

# Sélectionne Spotify et installe

Étape 6️⃣ : Commit & Push

git add .
git commit -m "feat: Add Spotify module"
git push origin feature/add-spotify

📚 Documentation
À Documenter

    Nouvelles fonctionnalités dans FEATURES.md
    Bugs fixes dans CHANGELOG.md
    Instructions d'installation dans INSTALLATION.md
    Mise à jour version dans version.json
    Commentaires dans le code PowerShell

Format du CHANGELOG

## [1.1.0] - 2026-06-20

### Added
- ✨ Nouvelle fonctionnalité X
- ✨ Nouvelle fonctionnalité Y

### Fixed
- 🐛 Bug du module Chrome
- 🐛 Problème de timeout

### Changed
- 🔄 Interface améliorée
- 🔄 Performance optimisée

🧪 Tests
À Tester

Avant de soumettre une PR, teste :

# Test 1 : Installation simple
.\ClickByChris_Setup_Tool.ps1

# Test 2 : Mode batch
.\install.ps1 -ConfigFile settings.json -NoConfirm

# Test 3 : Logs générés
Get-ChildItem "$env:USERPROFILE\ClickByChris\logs"

# Test 4 : Erreurs gérées
# Teste avec antivirus activé
# Teste avec internet lent
# Teste avec espace disque faible

Environnements à Tester

    Windows 10 (Build 19041+)
    Windows 11
    PowerShell 5.1
    PowerShell 7.0+
    Avec antivirus activé
    Avec UAC activé
    Avec proxy corporate (si applicable)

🎯 Roadmap
v1.1.0 (Août 2026)

    Interface graphique améliorée
    Support du français complet
    Mode désinstallation
    Plus de modules (Figma, Slack, etc.)

v1.2.0 (Octobre 2026)

    Marketplace de modules personnalisés
    Thèmes (Dark/Light)
    Configuration en GUI
    Historique des installations

v2.0.0 (2027)

    Réécriture en C# / WPF
    Support Linux (WSL)
    API pour intégrations
    Multi-langue

💬 Questions ?
📧 Contact

    Email : christophe939@gmail.com
    GitHub Issues : Pour les bugs
    GitHub Discussions : Pour les questions
    Discord : (À venir)

🙏 Merci !

Merci d'avoir lu ce guide et d'envisager de contribuer ! 🎉

Chaque contribution compte, qu'elle soit :

    💻 Du code
    📚 De la documentation
    🐛 Des rapports de bugs
    💡 Des idées
    🌍 Des traductions

On est hâte de voir tes contributions ! 🚀

Dernière mise à jour : Juin 2026
Mainteneur : @christophe939