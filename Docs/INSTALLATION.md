# 📖 Installation Guide - ClickByChris Setup Tool

[![Windows](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](../CHANGELOG.md)

---

## 📑 Table des Matières

- [✅ Prérequis](#-prérequis)
- [📥 Méthode 1 : Release (Recommandée)](#-méthode-1--depuis-la-release-recommandée)
- [🖥️ Méthode 2 : Git Clone](#-méthode-2--git-clone)
- [⚡ Méthode 3 : PowerShell Direct](#-méthode-3--powershell-direct-avancée)
- [🚀 Premier Lancement](#-premier-lancement)
- [✔️ Vérification Post-Installation](#-vérification-post-installation)
- [🐛 Dépannage](#-dépannage)
- [📁 Emplacements Importants](#-emplacements-importants)
- [❓ FAQ](#-faq)
- [🆘 Support](#-support)

---

## ✅ Prérequis

Avant de commencer, assure-toi que ton système respecte **les conditions minimales** :

| Composant | Requirement | Notes |
|-----------|-------------|-------|
| **OS** | Windows 10 (Build 19041+) ou Windows 11 | Versions antérieures non supportées |
| **PowerShell** | 5.1 minimum (7.0+ recommandé) | `Get-Host` pour vérifier |
| **RAM** | 4 GB minimum (8 GB recommandé) | Pour les installations volumineuses |
| **Disque** | 500 MB libre minimum | Pour le cache et les logs |
| **Internet** | Connexion active requise | Pour winget et téléchargements |
| **Admin** | Droits administrateur | ⚠️ Obligatoire pour certains modules |

### 🔍 Vérifier ta Configuration

**Ouvre PowerShell** et exécute :

```powershell
# Vérifier Windows
[System.Environment]::OSVersion.VersionString

# Vérifier PowerShell
$PSVersionTable.PSVersion

# Vérifier RAM disponible
Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory

# Vérifier l'espace disque
Get-PSDrive C | Select-Object Used,Free

📥 Méthode 1 : Depuis la Release (RECOMMANDÉE)
✨ La plus simple et sécurisée pour les débutants
Étape 1️⃣ : Télécharger

    Va sur GitHub Releases
    Télécharge le fichier ZIP le plus récent :
        ClickByChris-Setup-Tool-v1.0.0.zip (ou version plus récente)

Étape 2️⃣ : Extraire

    Clique droit sur le fichier ZIP
    Sélectionne "Extraire tout..."
    Choisis un dossier de destination (ex: C:\Tools\ ou C:\Users\{USER}\ClickByChris\)
    Attends la fin de l'extraction

Étape 3️⃣ : Lancer

    Ouvre le dossier extrait
    Double-clique sur Launch_ClickByChris.cmd
    Accepte l'UAC (message de sécurité Windows) : clique sur "Oui"
    Suis le wizard à l'écran ! 🎯

✅ Étapes complètes ✅
└─ L'interface se lancera automatiquement
└─ Sélectionne tes modules
└─ Confirme et patiente

🖥️ Méthode 2 : Git Clone
💻 Pour les développeurs et utilisateurs avancés
Prérequis Additionnels

    Git pour Windows installé

Installation

# 1️⃣ Cloner le repository
git clone https://github.com/christophe939/ClickByChris-Setup-Tool.git

# 2️⃣ Naviguer dans le dossier
cd ClickByChris-Setup-Tool

# 3️⃣ Lancer le script
.\Launch_ClickByChris.cmd

Avantages

✅ Accès à la dernière version en développement
✅ Facilité pour contribuer
✅ Mise à jour rapide : git pull  
⚡ Méthode 3 : PowerShell Direct (Avancée)
🚀 Installation en une seule commande
Sans télécharger manuellement

# 1️⃣ Définir la politique d'exécution (une fois)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2️⃣ Télécharger et exécuter le script
irm https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/install.ps1 | iex

⚠️ Attention : Cette méthode télécharge et exécute depuis internet.
🚀 Premier Lancement
Configuration Initiale
Étape 1️⃣ : Autoriser PowerShell (si nécessaire)

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Étape 2️⃣ : Lancer le Script

# Option A : Depuis le dossier extrait
cd "C:\Chemin\vers\ClickByChris-Setup-Tool"
.\ClickByChris_Setup_Tool.ps1

# Option B : Lancer via CMD
.\Launch_ClickByChris.cmd

Étape 3️⃣ : Suivre le Wizard

1️⃣ Sélectionne ta résolution d'écran
   └─ 1920x1080 (Recommandé)
   └─ 1280x720
   └─ Autre

2️⃣ Choisis tes modules
   ✅ Google Chrome
   ✅ Microsoft Edge
   ✅ 7-Zip
   ✅ Visual Studio Code
   (etc.)

3️⃣ Paramètres avancés (optionnel)
   └─ Mode verbose
   └─ Sauter les confirmations
   └─ Logs détaillés

4️⃣ Confirme et lance l'installation
   └─ L'outil installe automatiquement
   └─ Logs en temps réel
   └─ Résumé final

Étape 4️⃣ : Redémarrage (si recommandé)

Certains logiciels demandent un redémarrage. Enregistre ton travail et accepte si demandé.
✔️ Vérification Post-Installation
Checklist de Vérification

Après l'installation, vérifie les éléments suivants :
✅ Dossier Principal

# Vérifie que le dossier existe
Test-Path $env:USERPROFILE\ClickByChris
# Doit afficher : True

✅ Logs et Rapports

# Ouvre le dossier des logs
explorer $env:USERPROFILE\ClickByChris\logs

Tu dois voir :

    📄 installation_*.log (logs détaillés)
    📊 rapport_installation_*.csv (rapport CSV)
    📋 resume_final_*.txt (résumé)

✅ Logiciels Installés

Vérifie dans Panneau de Contrôle → Programmes que tes logiciels sont présents.

# Affiche la liste des programmes installés
Get-WmiObject -Query "SELECT * FROM Win32_Product" | Select-Object Name, Version

✅ Variables d'Environnement

Certains outils ajoutent des chemins. Redémarre PowerShell et teste :

# Exemple pour 7-Zip
7z --version

# Exemple pour Node.js (si installé)
node --version
npm --version

🐛 Dépannage
❌ Erreur : "PowerShell scripts are disabled"

Cause : La politique d'exécution ne permet pas les scripts.

Solution :

# Définir la politique (ouvre PowerShell en Admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Vérifier la politique
Get-ExecutionPolicy -Scope CurrentUser
# Doit afficher : RemoteSigned

❌ Erreur : "Access Denied"

Cause : Permissions insuffisantes ou antivirus bloquant.

Solutions :

    Lancer en administrateur :
        Clique droit sur Launch_ClickByChris.cmd
        Sélectionne "Exécuter en tant qu'administrateur"

    Désactiver temporairement l'antivirus :
        ⚠️ À faire avec prudence
        Rétablis l'antivirus après

    Ajouter une exception antivirus :
        Ajoute C:\Tools\ClickByChris-Setup-Tool\ à la liste blanche

❌ Erreur : "Le script est très lent"

Cause : Antivirus, connexion lente, ou système surchargé.

Solutions :

    Vérifier la connexion internet :

    Test-Connection google.com

    Désactiver l'antivirus temporairement :
        Windows Defender : Settings → Virus & threat protection → Manage settings

    Fermer les applications gourmandes :
        Ferme Chrome, Discord, etc.

    Lancer en mode Safe Boot (en dernier recours) :

    # Redémarrer en Safe Boot
    bcdedit /set safeboot minimal
    shutdown /r /t 0

    # Après redémarrage, désactiver Safe Boot
    bcdedit /deletevalue safeboot
    shutdown /r /t 0

❌ Erreur : "Fichier ZIP corrompu"

Cause : Téléchargement incomplet ou fichier endommagé.

Solutions :

    Supprimer et retélécharger :
        Supprime le ZIP
        Retélécharge depuis les Releases

    Utiliser 7-Zip pour extraire :

    # Si 7-Zip est déjà installé
    7z x "ClickByChris-Setup-Tool-v1.0.0.zip" -o"C:\Tools\"

⚠️ Avertissement : "Certains logiciels n'ont pas pu être installés"

Cause : Logiciel déjà installé, version incompatible, ou licence.

Solutions :

    Consulter les logs :

    explorer $env:USERPROFILE\ClickByChris\logs\

    Installer manuellement les logiciels qui ont échoué :
        Visiter le site officiel du logiciel
        Télécharger et installer manuellement

    Relancer l'installation pour les logiciels échoués

📁 Emplacements Importants
📂 Structure des Dossiers

%USERPROFILE%\ClickByChris\
├── logs\
│   ├── installation_20260616_032400.log
│   ├── rapport_installation_20260616_032400.csv
│   └── resume_final_20260616_032400.txt
├── cache\
│   └── (fichiers téléchargés)
├── reports\
│   └── (rapports au format JSON)
└── config\
    └── settings.json

🔍 Accès Rapides

# Ouvrir le dossier principal
explorer $env:USERPROFILE\ClickByChris

# Ouvrir les logs
explorer $env:USERPROFILE\ClickByChris\logs

# Ouvrir AppData (données d'application)
explorer $env:APPDATA

# Ouvrir Program Files
explorer "C:\Program Files"

# Ouvrir Program Files (x86)
explorer "C:\Program Files (x86)"

📊 Types de Logs
Fichier 	Contenu 	Format
installation_*.log 	Logs complets et détaillés 	TXT
rapport_*.csv 	Résumé par logiciel installé 	CSV
resume_final_*.txt 	Résumé exécutif 	TXT
errors_*.log 	Erreurs uniquement 	TXT
❓ FAQ
Q1 : Puis-je désinstaller les logiciels après ?

A : Oui, complètement. Utilise :

    Panneau de Contrôle → Programmes et fonctionnalités
    Ou winget uninstall [nom-du-logiciel]

# Exemple
winget uninstall Google.Chrome

Q2 : L'installation affecte-t-elle mon système ?

A : Non, c'est sûr. L'outil :

    ✅ Crée un dossier principal
    ✅ Installe uniquement les logiciels demandés
    ✅ Ne supprime rien existant
    ✅ Ne modifie le registre que si nécessaire

Q3 : Comment mettre à jour l'outil ?

A : Selon ta méthode d'installation :

# Si tu as cloné le repo Git
cd C:\chemin\vers\ClickByChris-Setup-Tool
git pull

# Si tu as la release
# Télécharge la nouvelle version et relance

Q4 : Puis-je personnaliser les logiciels à installer ?

A : Oui ! Modifie le fichier settings.json :

{
  "modules": {
    "chrome": true,
    "edge": false,
    "vscode": true
  }
}

Q5 : Où sont stockés les téléchargements ?

A : Dans le cache local :

$env:USERPROFILE\ClickByChris\cache\

Tu peux nettoyer ce dossier après l'installation.
Q6 : L'outil fonctionne-t-il hors ligne ?

A : Non, internet est obligatoire car l'outil :

    Télécharge les logiciels depuis winget
    Vérifie les versions disponibles
    Récupère les mises à jour

🆘 Support
🐛 Signaler un Bug

    Va sur Issues GitHub
    Clique sur "New Issue"
    Remplis :
        Titre : description courte du bug
        Description : détails et étapes pour reproduire
        Logs : copie-colle ton fichier .log
        Screenshot : si applicable

💬 Poser une Question

    Discussions GitHub
    Format : "Question : [ta question]"

📚 Documentation Supplémentaire

    📖 README - Vue d'ensemble
    🔧 Features - Liste complète des fonctionnalités
    🛠️ Troubleshooting - Guide détaillé de dépannage
    🤝 Contributing - Comment contribuer

📧 Contact Direct

    Email : christophe939@gmail.com
    GitHub : @christophe939

✅ Prochaines Étapes

    ✅ Installation terminée ?
        Consulte la section Vérification Post-Installation

    🎯 Explore les fonctionnalités :
        Ouvre FEATURES.md pour plus de détails

    🆘 Besoin d'aide ?
        Consulte TROUBLESHOOTING.md

    🤝 Veux contribuer ?
        Lis CONTRIBUTING.md

📜 License

Ce projet est sous MIT License. Voir LICENSE pour plus de détails.
🙏 Remerciements

Merci d'utiliser ClickByChris Setup Tool ! 🎉

    ⭐ N'oublie pas de mettre une star sur GitHub
    🐞 Signale les bugs
    💡 Partage tes idées
    🤝 Contribue au projet

Dernière mise à jour : Juin 2026
Mainteneur : ClickByChris