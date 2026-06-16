<div align="center">

# ClickByChris Setup Tool 🚀

**Une solution complète pour préparer rapidement votre PC Windows**

[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Release](https://img.shields.io/github/v/release/christophe939/ClickByChris-Setup-Tool?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)

**Version 1.0.0 • Juin 2026**

[📥 Télécharger](#-installation-rapide) • [📖 Documentation](#-documentation-complète) • [🐛 Signaler un bug](https://github.com/christophe939/ClickByChris-Setup-Tool/issues) • [💬 Discussions](https://github.com/christophe939/ClickByChris-Setup-Tool/discussions)

</div>

---

## 📋 Table des Matières

- [✨ Features](#-features-principales)
- [🚀 Installation](#-installation-rapide)
- [💻 Utilisation](#-utilisation)
- [🔧 Compatibilité](#-compatibilité)
- [📖 Documentation](#-documentation-complète)
- [📝 Changelog](#-changelog)
- [❓ FAQ](#-faq)
- [📄 License](#-license)
- [👨‍💻 Auteur](#-auteur)

---

## ✨ Features Principales

### 🎨 Interface & UX
- ✅ **Interface WPF moderne** avec dark mode élégant
- ✅ **Détection multi-écran** avancée (1920x1080 à 4K)
- ✅ **Scaling responsive** automatique selon résolution
- ✅ **Menu de navigation** intuitif et fluide

### 📦 Installation & Compatibilité
- ✅ **Installation d'applications** via winget
- ✅ **Composants Visual C++** automatisés
- ✅ **.NET Desktop Runtime** & WebView2
- ✅ **Points de restauration** système avant modifications

### ⚡ Optimisations & Nettoyage
- ✅ **Optimisations Windows** safe et stables
- ✅ **Suppression bloatware** intelligente
- ✅ **Gestion de la confidentialité** avancée
- ✅ **Rapports d'exécution** en CSV

### 🛠️ Structure & Outils
- ✅ **Structure de dossiers** personnalisée et automatisée
- ✅ **Raccourcis intelligents** personnalisés
- ✅ **Lecteur musique intégré** avec album art
- ✅ **Gestion des drivers** (AMD, NVIDIA, Intel)

### 📊 Logs & Support
- ✅ **Logs détaillés** en temps réel
- ✅ **Export rapports** et statistiques complètes
- ✅ **Mode assistant** "TOUT FAIRE" automatisé
- ✅ **Support multi-langue** (FR/EN)

---

## 🚀 Installation Rapide

### 📥 Méthode 1 : Depuis la Release (RECOMMANDÉE)

**Étape 1 : Télécharger**

👉 Accède à https://github.com/christophe939/ClickByChris-Setup-Tool/releases
👉 Télécharge : ClickByChris-Setup-Tool-v1.0.0.zip


**Étape 2 : Extraire**
```powershell
# Clique droit sur le ZIP → "Extraire tout"
# Ou dans PowerShell (Admin) :
Expand-Archive -Path "ClickByChris-Setup-Tool-v1.0.0.zip" -DestinationPath "$env:USERPROFILE\ClickByChris"

Étape 3 : Lancer

# Option 1 : Utiliser le launcher
.\Launch_ClickByChris.cmd

# Option 2 : PowerShell direct
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\ClickByChris_Setup_Tool.ps1

📥 Méthode 2 : Cloner le Repository

# Clone le repository
git clone https://github.com/christophe939/ClickByChris-Setup-Tool.git

# Va dans le dossier
cd ClickByChris-Setup-Tool

# Lance le script
.\ClickByChris_Setup_Tool.ps1

💻 Utilisation
🎯 Lancement Rapide

Via le launcher (RECOMMANDÉ)

.\Launch_ClickByChris.cmd

Via PowerShell directement

# Définir la politique d'exécution (une seule fois)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Lancer le script
.\ClickByChris_Setup_Tool.ps1

🎮 Utilisation de l'Interface

    Au démarrage : Sélectionne ta résolution d'écran
    Menu Principal : Choisis les modules que tu veux exécuter
    Mode Assistant : Clique sur "TOUT FAIRE" pour automatiser tout
    Logs en temps réel : Regarde la progression dans le panneau logs
    À la fin : Exports tes rapports en CSV

🔧 Compatibilité
Composant 	Minimum 	Recommandé
Windows 	Windows 10 (Build 19041+) 	Windows 11
PowerShell 	5.1 	7.0+
RAM 	2 GB 	4 GB+
Disque 	1 GB libre 	5 GB libre
Internet 	Requis (winget) 	Requis
✅ Systèmes Testés

    ✅ Windows 10 (Build 19041 à 22631)
    ✅ Windows 11 (Build 22000+)
    ✅ Multi-monitors (tested up to 4K)

📖 Documentation Complète

Pour des instructions détaillées, consulte le guide complet :

    📄 INSTALLATION.md - Guide d'installation pas à pas
    📄 CHANGELOG.md - Historique complet des versions
    📄 LICENSE - Licence MIT

❓ FAQ
❌ Erreur : "PowerShell scripts are disabled"

Solution :

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

❌ Erreur : "Winget not found"

Solution :

    Sur Windows 11 : Winget est pré-installé
    Sur Windows 10 : Installe depuis le Microsoft Store (App Installer)

# Vérifier la version
winget --version

❌ Le script se ferme immédiatement

Solution :

    Vérifie que tu es en administrateur
    Vérifie ta version PowerShell : $PSVersionTable.PSVersion
    Désactive temporairement ton antivirus

❓ Puis-je exécuter ce script sur un autre PC ?

OUI ! Le script est portable. Tu peux :

    Le copier sur USB
    Le lancer sur plusieurs PCs
    Le partager avec d'autres

📝 Changelog

Pour voir toutes les modifications de cette version, consulte : CHANGELOG.md
🎉 Version 1.0.0 (Actuelle)

✅ Interface WPF moderne avec dark mode
✅ Détection multi-écran avancée
✅ Installation applications via winget
✅ Optimisations Windows complètes
✅ Logs détaillés et rapports CSV
✅ Lecteur musique intégré
✅ Support multi-langue (FR/EN)

→ Voir le CHANGELOG complet
🤝 Support & Contribution
🐛 Signaler un Bug

Trouve un problème ? Ouvre une issue :
👉 Créer une issue
💬 Questions & Discussions

Tu as une question ? Rejoins les discussions :
👉 GitHub Discussions
🌟 Aimer ce projet ?

N'oublie pas de mettre une ⭐ Star sur le repository !
📄 License

Ce projet est sous licence MIT - tu es libre d'utiliser, modifier et distribuer le code.

Voir le fichier LICENSE pour plus de détails.

MIT License

Copyright (c) 2026 Christophe (ClickByChris)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

👨‍💻 Auteur
<div align="center">
Christophe (ClickByChris)

<img src="https://img.shields.io/badge/GitHub-christophe939-black?style=for-the-badge&logo=github" alt="GitHub" />

Windows Setup Tool Expert | PowerShell Enthusiast | Open Source Contributor
</div> <div align="center">
🚀 Prêt à Commencer ?
📥 Télécharge la dernière version
🐛 Signale un bug

Merci d'utiliser ClickByChris Setup Tool ! 🎉

Made with ❤️ by Christophe
</div> ``` <div align="center">

# ClickByChris Setup Tool 🚀

**Une solution complète pour préparer rapidement votre PC Windows**

[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Release](https://img.shields.io/github/v/release/christophe939/ClickByChris-Setup-Tool?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)

**Version 1.0.0 • Juin 2026**

[📥 Télécharger](#-installation-rapide) • [📖 Documentation](#-documentation-complète) • [🐛 Signaler un bug](https://github.com/christophe939/ClickByChris-Setup-Tool/issues) • [💬 Discussions](https://github.com/christophe939/ClickByChris-Setup-Tool/discussions)

</div>

---

## 📋 Table des Matières

- [✨ Features](#-features-principales)
- [🚀 Installation](#-installation-rapide)
- [💻 Utilisation](#-utilisation)
- [🔧 Compatibilité](#-compatibilité)
- [📖 Documentation](#-documentation-complète)
- [📝 Changelog](#-changelog)
- [❓ FAQ](#-faq)
- [📄 License](#-license)
- [👨‍💻 Auteur](#-auteur)

---

## ✨ Features Principales

### 🎨 Interface & UX
- ✅ **Interface WPF moderne** avec dark mode élégant
- ✅ **Détection multi-écran** avancée (1920x1080 à 4K)
- ✅ **Scaling responsive** automatique selon résolution
- ✅ **Menu de navigation** intuitif et fluide

### 📦 Installation & Compatibilité
- ✅ **Installation d'applications** via winget
- ✅ **Composants Visual C++** automatisés
- ✅ **.NET Desktop Runtime** & WebView2
- ✅ **Points de restauration** système avant modifications

### ⚡ Optimisations & Nettoyage
- ✅ **Optimisations Windows** safe et stables
- ✅ **Suppression bloatware** intelligente
- ✅ **Gestion de la confidentialité** avancée
- ✅ **Rapports d'exécution** en CSV

### 🛠️ Structure & Outils
- ✅ **Structure de dossiers** personnalisée et automatisée
- ✅ **Raccourcis intelligents** personnalisés
- ✅ **Lecteur musique intégré** avec album art
- ✅ **Gestion des drivers** (AMD, NVIDIA, Intel)

### 📊 Logs & Support
- ✅ **Logs détaillés** en temps réel
- ✅ **Export rapports** et statistiques complètes
- ✅ **Mode assistant** "TOUT FAIRE" automatisé
- ✅ **Support multi-langue** (FR/EN)

---

## 🚀 Installation Rapide

### 📥 Méthode 1 : Depuis la Release (RECOMMANDÉE)

**Étape 1 : Télécharger**

👉 Accède à https://github.com/christophe939/ClickByChris-Setup-Tool/releases
👉 Télécharge : ClickByChris-Setup-Tool-v1.0.0.zip


**Étape 2 : Extraire**
```powershell
# Clique droit sur le ZIP → "Extraire tout"
# Ou dans PowerShell (Admin) :
Expand-Archive -Path "ClickByChris-Setup-Tool-v1.0.0.zip" -DestinationPath "$env:USERPROFILE\ClickByChris"

Étape 3 : Lancer

# Option 1 : Utiliser le launcher
.\Launch_ClickByChris.cmd

# Option 2 : PowerShell direct
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\ClickByChris_Setup_Tool.ps1

📥 Méthode 2 : Cloner le Repository

# Clone le repository
git clone https://github.com/christophe939/ClickByChris-Setup-Tool.git

# Va dans le dossier
cd ClickByChris-Setup-Tool

# Lance le script
.\ClickByChris_Setup_Tool.ps1

💻 Utilisation
🎯 Lancement Rapide

Via le launcher (RECOMMANDÉ)

.\Launch_ClickByChris.cmd

Via PowerShell directement

# Définir la politique d'exécution (une seule fois)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Lancer le script
.\ClickByChris_Setup_Tool.ps1

🎮 Utilisation de l'Interface

    Au démarrage : Sélectionne ta résolution d'écran
    Menu Principal : Choisis les modules que tu veux exécuter
    Mode Assistant : Clique sur "TOUT FAIRE" pour automatiser tout
    Logs en temps réel : Regarde la progression dans le panneau logs
    À la fin : Exports tes rapports en CSV

🔧 Compatibilité
Composant 	Minimum 	Recommandé
Windows 	Windows 10 (Build 19041+) 	Windows 11
PowerShell 	5.1 	7.0+
RAM 	2 GB 	4 GB+
Disque 	1 GB libre 	5 GB libre
Internet 	Requis (winget) 	Requis
✅ Systèmes Testés

    ✅ Windows 10 (Build 19041 à 22631)
    ✅ Windows 11 (Build 22000+)
    ✅ Multi-monitors (tested up to 4K)

📖 Documentation Complète

Pour des instructions détaillées, consulte le guide complet :

📄 INSTALLATION.md - Guide d'installation pas à pas
📄 CHANGELOG.md - Historique complet des versions
📄 LICENSE - Licence MIT
❓ FAQ
❌ Erreur : "PowerShell scripts are disabled"

Solution :

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

❌ Erreur : "Winget not found"

Solution :

    Sur Windows 11 : Winget est pré-installé
    Sur Windows 10 : Installe depuis le Microsoft Store (App Installer)

# Vérifier la version
winget --version

❌ Le script se ferme immédiatement

Solution :

    Vérifie que tu es en administrateur
    Vérifie ta version PowerShell : $PSVersionTable.PSVersion
    Désactive temporairement ton antivirus

❓ Puis-je exécuter ce script sur un autre PC ?

OUI ! Le script est portable. Tu peux :

    Le copier sur USB
    Le lancer sur plusieurs PCs
    Le partager avec d'autres

📝 Changelog

Pour voir toutes les modifications de cette version, consulte : CHANGELOG.md
🎉 Version 1.0.0 (Actuelle)

✅ Interface WPF moderne avec dark mode
✅ Détection multi-écran avancée
✅ Installation applications via winget
✅ Optimisations Windows complètes
✅ Logs détaillés et rapports CSV
✅ Lecteur musique intégré
✅ Support multi-langue (FR/EN)

→ Voir le CHANGELOG complet
🤝 Support & Contribution
🐛 Signaler un Bug

Trouve un problème ? Ouvre une issue :
👉 Créer une issue
💬 Questions & Discussions

Tu as une question ? Rejoins les discussions :
👉 GitHub Discussions
🌟 Aimer ce projet ?

N'oublie pas de mettre une ⭐ Star sur le repository !
📄 License

Ce projet est sous licence MIT - tu es libre d'utiliser, modifier et distribuer le code.

Voir le fichier LICENSE pour plus de détails.

MIT License

Copyright (c) 2026 Christophe (ClickByChris)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

👨‍💻 Auteur
<div align="center">
Christophe (ClickByChris)

<img src="https://img.shields.io/badge/GitHub-christophe939-black?style=for-the-badge&logo=github" alt="GitHub" />

Windows Setup Tool Expert | PowerShell Enthusiast | Open Source Contributor
</div> <div align="center">
🚀 Prêt à Commencer ?
📥 Télécharge la dernière version
Questions ? 📧 Crée une issue

Merci d'utiliser ClickByChris Setup Tool ! 🎉

Made with ❤️ by Christophe
</div> ``` <div align="center">

# ClickByChris Setup Tool 🚀

**Une solution complète pour préparer rapidement votre PC Windows**

[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Release](https://img.shields.io/github/v/release/christophe939/ClickByChris-Setup-Tool?style=for-the-badge)](https://github.com/christophe939/ClickByChris-Setup-Tool/releases)

**Version 1.0.0 • Juin 2026**

[📥 Télécharger](#-installation-rapide) • [📖 Documentation](#-documentation-complète) • [🐛 Signaler un bug](https://github.com/christophe939/ClickByChris-Setup-Tool/issues) • [💬 Discussions](https://github.com/christophe939/ClickByChris-Setup-Tool/discussions)

</div>

---

## 📋 Table des Matières

- [✨ Features](#-features-principales)
- [🚀 Installation](#-installation-rapide)
- [💻 Utilisation](#-utilisation)
- [🔧 Compatibilité](#-compatibilité)
- [📖 Documentation](#-documentation-complète)
- [📝 Changelog](#-changelog)
- [❓ FAQ](#-faq)
- [📄 License](#-license)
- [👨‍💻 Auteur](#-auteur)

---

## ✨ Features Principales

### 🎨 Interface & UX
- ✅ **Interface WPF moderne** avec dark mode élégant
- ✅ **Détection multi-écran** avancée (1920x1080 à 4K)
- ✅ **Scaling responsive** automatique selon résolution
- ✅ **Menu de navigation** intuitif et fluide

### 📦 Installation & Compatibilité
- ✅ **Installation d'applications** via winget
- ✅ **Composants Visual C++** automatisés
- ✅ **.NET Desktop Runtime** & WebView2
- ✅ **Points de restauration** système avant modifications

### ⚡ Optimisations & Nettoyage
- ✅ **Optimisations Windows** safe et stables
- ✅ **Suppression bloatware** intelligente
- ✅ **Gestion de la confidentialité** avancée
- ✅ **Rapports d'exécution** en CSV

### 🛠️ Structure & Outils
- ✅ **Structure de dossiers** personnalisée et automatisée
- ✅ **Raccourcis intelligents** personnalisés
- ✅ **Lecteur musique intégré** avec album art
- ✅ **Gestion des drivers** (AMD, NVIDIA, Intel)

### 📊 Logs & Support
- ✅ **Logs détaillés** en temps réel
- ✅ **Export rapports** et statistiques complètes
- ✅ **Mode assistant** "TOUT FAIRE" automatisé
- ✅ **Support multi-langue** (FR/EN)

---

## 🚀 Installation Rapide

### 📥 Méthode 1 : Depuis la Release (RECOMMANDÉE)

**Étape 1 : Télécharger**
