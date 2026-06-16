# ✨ Fonctionnalités - ClickByChris Setup Tool

[![Windows](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows11&logoColor=white)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

---

## 📑 Table des Matières

- [🎯 Vue d'Ensemble](#-vue-densemble)
- [🧩 Modules Disponibles](#-modules-disponibles)
- [⚙️ Fonctionnalités Avancées](#️-fonctionnalités-avancées)
- [🎨 Interface & UX](#-interface--ux)
- [📊 Logs & Rapports](#-logs--rapports)
- [🔐 Sécurité](#-sécurité)
- [⚡ Performance](#-performance)
- [🔄 Automatisation](#-automatisation)
- [🌍 Compatibilité](#-compatibilité)

---

## 🎯 Vue d'Ensemble

**ClickByChris Setup Tool** est un **installateur multi-logiciels** automatisé pour Windows qui permet de :

✅ Installer **30+ applications** en un clic  
✅ Gérer les **dépendances** automatiquement  
✅ Configurer l'**environnement de développement**  
✅ Générer des **rapports détaillés**  
✅ Restaurer la **configuration** facilement  

---

## 🧩 Modules Disponibles

### 📱 **Navigateurs & Internet**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **Google Chrome** | Navigateur Chrome avec sync | ✅ Stable | `Google.Chrome` |
| **Microsoft Edge** | Navigateur Chromium Microsoft | ✅ Stable | `Microsoft.Edge` |
| **Firefox** | Navigateur Mozilla | ✅ Stable | `Mozilla.Firefox` |
| **Brave Browser** | Navigateur privé/crypto | ✅ Stable | `BraveSoftware.BraveBrowser` |

### 💻 **Développement & IDEs**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **Visual Studio Code** | Éditeur de code léger | ✅ Stable | `Microsoft.VisualStudioCode` |
| **Visual Studio Community** | IDE complet gratuit | ✅ Stable | `Microsoft.VisualStudio.Community` |
| **Node.js** | Runtime JavaScript | ✅ Stable | `OpenJS.NodeJS` |
| **Python** | Langage de programmation | ✅ Stable | `Python.Python.3.11` |
| **Git** | Gestionnaire de version | ✅ Stable | `Git.Git` |
| **Docker Desktop** | Containerisation | ✅ Stable | `Docker.DockerDesktop` |

### 🛠️ **Utilitaires & Productivité**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **7-Zip** | Compression de fichiers | ✅ Stable | `7zip.7zip` |
| **WinRAR** | Compression avancée | ✅ Stable | `RARLAB.WinRAR` |
| **Notepad++** | Éditeur de texte avancé | ✅ Stable | `Notepad++.Notepad++` |
| **VLC Media Player** | Lecteur vidéo universel | ✅ Stable | `VideoLAN.VLC` |
| **Audacity** | Éditeur audio | ✅ Stable | `Audacity.Audacity` |
| **OBS Studio** | Streaming & enregistrement | ✅ Stable | `OBSProject.OBSStudio` |

### 📊 **Office & Documents**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **LibreOffice** | Suite Office gratuite | ✅ Stable | `TheDocumentFoundation.LibreOffice` |
| **Microsoft Office** | Suite Office Pro | ⚠️ Payant | `Microsoft.Office` |

### 🎮 **Jeux & Divertissement**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **Steam** | Plateforme de jeux | ✅ Stable | `Valve.Steam` |
| **Discord** | Chat & communauté | ✅ Stable | `Discord.Discord` |

### 🔧 **Outils Système**

| Module | Description | Statut | Winget ID |
|--------|-------------|--------|-----------|
| **GPU-Z** | Info carte graphique | ✅ Stable | `TechPowerUp.GPU-Z` |
| **CPU-Z** | Info processeur | ✅ Stable | `CPUID.CPU-Z` |
| **Rufus** | Créateur USB bootable | ✅ Stable | `Rufus.Rufus` |
| **Everything** | Moteur de recherche | ✅ Stable | `voidtools.Everything` |

---

## ⚙️ **Fonctionnalités Avancées**

### 🎨 **Sélection d'Écran**

```powershell
✅ Détection automatique de la résolution
✅ Options de résolution :
   └─ 1920 x 1080 (FHD - Recommandé)
   └─ 1280 x 720 (HD)
   └─ Autre (personnalisé)

📋 Configuration Flexible

Le fichier settings.json permet de :

{
  "modules": {
    "chrome": true,
    "edge": false,
    "vscode": true,
    "nodejs": true,
    "git": true
  },
  "install_options": {
    "skip_confirmations": false,
    "verbose_mode": true,
    "auto_restart": false
  }
}

✅ Activer/désactiver les modules
✅ Configurer le comportement
✅ Paramètres avancés  
🔄 Installation Intelligente

✅ Vérification des dépendances
✅ Détection des doublons
✅ Installation parallèle optimisée
✅ Gestion des erreurs automatique
✅ Retry en cas d'échec

📊 Rapports Détaillés

L'outil génère 3 types de rapports :
1️⃣ installation_*.log (Texte complet)

[2026-06-16 03:30:45] ✅ Installation démarrée
[2026-06-16 03:30:46] ⏳ Vérification des prérequis...
[2026-06-16 03:30:48] ✅ PowerShell 5.1+ détecté
[2026-06-16 03:30:50] 📦 Installation de Google.Chrome...
[2026-06-16 03:31:15] ✅ Chrome installé avec succès
...

2️⃣ rapport_*.csv (Tableau Excel)

Software,Version,Status,Install Time,Size
Google Chrome,v126.0.0.0,Installed,45s,120MB
VS Code,v1.90.0,Installed,30s,85MB
Node.js,v20.3.0,Installed,60s,200MB
...

3️⃣ resume_final_*.txt (Résumé exécutif)

====== RÉSUMÉ FINAL ======
Date : 2026-06-16 03:35:20
Durée : 5m 45s

✅ Installés (15) :
  - Google Chrome
  - Microsoft Edge
  - VS Code
  ...

❌ Échoués (2) :
  - Docker Desktop
  - Visual Studio

⚠️ Avertissements (1) :
  - LibreOffice requiert un redémarrage

🎨 Interface & UX
🖥️ Interface Graphique

╔════════════════════════════════════════════════════╗
║     ClickByChris Setup Tool - Configuration       ║
╠════════════════════════════════════════════════════╣
║                                                    ║
║  Étape 1/4 : Sélection des Modules                ║
║                                                    ║
║  ☑ Google Chrome          ☐ Visual Studio Code    ║
║  ☑ Microsoft Edge         ☑ Node.js               ║
║  ☐ Firefox                ☐ Docker                ║
║  ☑ 7-Zip                  ☑ Git                   ║
║                                                    ║
║  [← Précédent]              [Suivant →]  [Annuler]║
║                                                    ║
╚════════════════════════════════════════════════════╝

🎯 Wizard Multi-Étapes

Étape 1 : Résolution d'écran
Étape 2 : Sélection des modules
Étape 3 : Options avancées
Étape 4 : Confirmation & installation  
🌈 Thème & Design

✅ Interface moderne et épurée
✅ Couleurs cohérentes
✅ Responsive (adapté à tous les écrans)
✅ Accessibilité (contraste, police)  
📊 Logs & Rapports
📁 Localisation

%USERPROFILE%\ClickByChris\
├── logs/
│   ├── installation_20260616_033000.log
│   ├── rapport_installation_20260616_033000.csv
│   ├── resume_final_20260616_033000.txt
│   └── errors_20260616_033000.log
├── cache/
│   └── (fichiers téléchargés)
├── reports/
│   └── rapport_json_20260616_033000.json
└── config/
    └── settings.json

📝 Format des Logs

✅ Timestamps précis (au centième de seconde)
✅ Couleurs ANSI pour la lisibilité
✅ Niveaux de log (INFO, WARN, ERROR, DEBUG)
✅ Export CSV pour Excel
✅ Export JSON pour API  
🔍 Contenu des Rapports

installation.log :

    Toutes les actions exécutées
    Temps d'exécution
    Statuts (succès/erreur)
    Messages détaillés

rapport.csv :

    Nom du logiciel
    Version installée
    Statut final
    Temps d'installation
    Taille téléchargée

resume_final.txt :

    Statistiques globales
    Logiciels installés
    Logiciels échoués
    Recommandations

🔐 Sécurité
🛡️ Vérifications de Sécurité

✅ Vérification des signatures des téléchargements
✅ Scan antivirus (Windows Defender intégré)
✅ Validation des URLs (HTTPS obligatoire)
✅ Isolation des scripts (sandboxing)
✅ Audit complet (qui a installé quoi, quand)  
🔑 Gestion des Permissions

✅ Droits administrateur vérifiés
✅ UAC (User Account Control) respecté
✅ Isolation des privilèges
✅ Pas d'exécution en mode SYSTEM

📋 Confiance & Transparence

✅ Code source public sur GitHub
✅ Aucun tracking ou télémétrie
✅ Aucune donnée envoyée à des serveurs
✅ License MIT (usage libre)
✅ Audit de sécurité disponible  
⚡ Performance
🚀 Optimisations

✅ Installation parallèle (4 logiciels simultanément)
✅ Cache intelligent (réutilisation des téléchargements)
✅ Compression des données temporaires
✅ Nettoyage automatique des fichiers temporaires
✅ Réseau optimisé (connexion réutilisée)  
📈 Benchmark
Scenario 	Durée 	Notes
5 logiciels petits 	~3-5 min 	Chrome, Edge, 7-Zip, etc.
10 logiciels moyens 	~10-15 min 	+ VS Code, Node.js
20 logiciels gros 	~25-35 min 	+ Visual Studio, Docker
Installation complète 	~45-60 min 	30+ logiciels

Dépend de :

    Vitesse internet (upload/download)
    Puissance du PC
    Charge système actuelle

🔄 Automatisation
🤖 Mode Batch (Sans Interaction)

# Installation automatique avec configuration prédéfinie
.\ClickByChris_Setup_Tool.ps1 -ConfigFile settings.json -NoConfirm

📅 Planification (Task Scheduler)

# Programmer une installation automatique
$trigger = New-ScheduledTaskTrigger -AtLogon
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-File C:\Tools\ClickByChris\install.ps1"
Register-ScheduledTask -TaskName "ClickByChris Setup" `
  -Trigger $trigger -Action $action

🔗 Intégration CI/CD

# GitHub Actions (exemple)
name: Auto-Install
on: [push]
jobs:
  install:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Setup Tool
        run: .\ClickByChris_Setup_Tool.ps1

🌍 Compatibilité
🖥️ Systèmes d'Exploitation
OS 	Version Min 	Statut 	Notes
Windows 10 	Build 19041 	✅ Supporté 	La plus courante
Windows 11 	21H2+ 	✅ Supporté 	Recommandé
Windows Server 	2019+ 	⚠️ Limité 	Pas tous les logiciels
Windows 7/8 	- 	❌ Non supporté 	Trop ancien
🔧 PowerShell
Version 	Statut
PowerShell 5.1 	✅ Minimum requis
PowerShell 7.0+ 	✅ Recommandé
PowerShell Core 	✅ Compatible
🌐 Compatibilité Réseau

✅ Proxy corporate (configurable)
✅ VPN (testé)
✅ Connexions lentes (retry automatique)
✅ Mode offline partiel (cache)  
📦 Modules Additionnels (Roadmap)
🔮 Prochaines Versions

    v1.1.0 : Support des thèmes (Dark/Light)
    v1.2.0 : Module de désinstallation
    v1.3.0 : Support du français complet
    v2.0.0 : Interface graphique WPF
    v2.1.0 : Marketplace de modules personnalisés

🎯 Cas d'Usage
👨‍💻 Développeur

{
  "modules": {
    "vscode": true,
    "git": true,
    "nodejs": true,
    "python": true,
    "docker": true
  }
}

👨‍💼 Utilisateur Bureau

{
  "modules": {
    "chrome": true,
    "edge": true,
    "libreoffice": true,
    "vlc": true
  }
}

🎮 Gamer

{
  "modules": {
    "steam": true,
    "discord": true,
    "obs": true,
    "gpu-z": true
  }
}

📞 Support des Fonctionnalités
Fonctionnalité 	Support 	Version
Installation de base 	✅ Full 	1.0.0+
Rapports 	✅ Full 	1.0.0+
Configuration 	✅ Full 	1.0.0+
Interface graphique 	⚠️ Basique 	1.0.0+
Mode batch 	✅ Full 	1.0.0+
Automatisation 	✅ Full 	1.0.0+
🙏 Contributions Bienvenues

Veux-tu ajouter une fonctionnalité ?

→ Consulte CONTRIBUTING.md


