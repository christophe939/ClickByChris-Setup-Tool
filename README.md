# 🚀 ClickByChris Setup Tool

**Prépare ton PC Windows en quelques clics !**

Automatise l'installation de tes apps, drivers et optimisations Windows. Simple, rapide, sécurisé.

---

## ⚡ Installation Ultra-Rapide (1 commande = 30 secondes) ⭐

### **🔥 Méthode RECOMMANDÉE**

1️⃣ Ouvre **PowerShell en tant qu'ADMINISTRATEUR**
   - Clic droit sur le menu Démarrer
   - Choisis **"Terminal (Admin)"** ou **"PowerShell (Admin)"**

2️⃣ Copie-colle cette commande et appuie sur **Entrée** :

```powershell
irm tinyurl.com/ClickByChris | iex
```

3️⃣ **C'est tout ! L'outil se télécharge et se lance automatiquement ! 🎉**

---

## 📦 Installation Manuelle (Alternative)

<details>
<summary>👉 Clique ici si tu préfères l'installation manuelle</summary>

### **1️⃣ Télécharger**

👉 Va ici : https://github.com/christophe939/ClickByChris-Setup-Tool/releases

👉 Clique sur la **dernière version** (ex: `v1.0.0`)

👉 Télécharge le fichier : `ClickByChris-Setup-Tool-v1.0.0.zip`

---

### **2️⃣ Décompresser**

👉 Fais **clic droit** sur le ZIP

👉 Clique sur **"Extraire tout"**

👉 Choisis un dossier (par exemple : `C:\ClickByChris`)

---

### **3️⃣ Lancer le script**

👉 Va dans le dossier décompressé

👉 **Clic droit** sur : `Launch_ClickByChris.cmd`

👉 Choisis **"Exécuter en tant qu'administrateur"**

---

### **4️⃣ L'interface s'affiche !**

L'interface WPF s'ouvre → Tu vois un menu avec plein d'options

**C'est tout ! 🎉**

</details>

---

## 🎮 Qu'est-ce que tu peux faire ?

### **Mode TOUT FAIRE (le plus facile) ⭐**

```
Clique sur le bouton "TOUT FAIRE"
        ↓
L'outil installe TOUT automatiquement
        ↓
À la fin : un rapport s'affiche ✅
```

**C'est tout ! Rien à faire, ça le fait tout seul !**

---

### **Ou choisis ce que tu veux faire :**

| Fonction | Qu'est-ce que ça fait ? |
|---|---|
| 📦 **Installer Apps** | Chrome, Firefox, Discord, VLC, 7-Zip, Office, etc |
| 🔧 **Runtimes** | .NET, Visual C++, DirectX, Java (pour les jeux) |
| ⚡ **Optimisations** | Nettoie Windows, enlève le bloatware inutile |
| 🎮 **Drivers** | Trouve et installe tes drivers GPU et chipset |
| 📁 **Structure Dossiers** | Crée une organisation logique sur ton disque |
| 🎵 **Lecteur Musique** | Écoute ta musique en attendant |
| 📊 **Rapports** | Exporte ce qui a été fait en CSV |

---

## ✅ Vérification Après Installation

Après que le script finisse :

✅ Ouvre ton **Panneau de Contrôle** → **Programmes et Fonctionnalités**

✅ Vérifie que les apps sont là : Chrome, Discord, VLC, etc

✅ Essaie de lancer une app pour la tester

✅ Check tes dossiers : ils sont bien organisés ?

✅ Si tout marche → **C'est bon ! 🎉**

---

## 🆘 Besoin d'Aide ?

### 💬 **Rejoins notre Discord !**

**Tu préfères discuter en direct ?**

👉 **[Discord ClickByChris](https://discord.gg/clickbychris)**

Sur Discord tu peux :
- 🆘 Demander de l'aide rapidement
- 💡 Suggérer des features
- 🐛 Signaler des bugs
- 👥 Discuter avec la communauté
- 📢 Recevoir les annonces en premier

---

### 📧 **Ou par Email**

📧 **chris.clickby@gmail.com**

**Utilise le [template d'email](./Docs/EMAIL_TEMPLATE.md)** pour bien décrire ton problème

---

### 📖 **Documentation Complète**

| Doc | Utilité |
|-----|---------|
| [📋 Installation Détaillée](./Docs/INSTALLATION.md) | Guide complet, étape par étape |
| [🔧 Dépannage / FAQ](./Docs/TROUBLESHOOTING.md) | Solutions aux problèmes courants |
| [✨ Toutes les Fonctionnalités](./Docs/FEATURES.md) | Explication complète de chaque feature |
| [🛡️ Sécurité](./Docs/SECURITY.md) | Signaler une vulnérabilité |
| [📧 Template d'Email](./Docs/EMAIL_TEMPLATE.md) | Modèle pour nous contacter |
| [🎮 Discord](./Docs/DISCORD_SERVER.md) | Guide du serveur Discord |
| [📝 Changelog](./CHANGELOG.md) | Historique des versions |

---

## ⚠️ Erreurs Courantes

### **La commande PowerShell ne marche pas**

```
❌ Erreur : "irm n'est pas reconnu" ou "execution policy"

Solution :
1. Lance PowerShell en ADMINISTRATEUR
2. Tape cette commande :
   Set-ExecutionPolicy Bypass -Scope Process -Force
3. Relance : irm tinyurl.com/ClickByChris | iex
```

---

### **L'interface ne s'affiche pas**

```
❌ Erreur : "Could not load file or assembly"

Solution :
1. Télécharge .NET 6.0 Runtime
2. Installe-le
3. Relance ClickByChris
```

---

### **Winget ne marche pas**

```
❌ "winget" is not recognized as an internal or external command

Solution :
1. Ouvre le Microsoft Store
2. Cherche "App Installer"
3. Clique sur "Obtenir"
4. Relance ClickByChris
```

---

### **Erreur : Access Denied**

```
❌ Access to the path is denied

Solution :
1. Ferme ClickByChris
2. Relance PowerShell en ADMINISTRATEUR
3. Relance la commande
```

---

### **Autre problème ?**

👉 Vois le [Troubleshooting complet](./Docs/TROUBLESHOOTING.md)

---

## 🔒 Sécurité

**ClickByChris est sécurisé ! ✅**

- ✅ **Code open-source** : Tu peux voir ce qu'il fait
- ✅ **Pas de tracking** : On ne collecte rien
- ✅ **Pas de pubs** : Gratuit et sans pubs
- ✅ **Scripts vérifiés** : Pour éviter les malware

### **Tu as trouvé une faille de sécurité ?**

👉 Vois le [document Sécurité](./Docs/SECURITY.md)

---

## 🎯 Exemple d'Utilisation

### **Scénario : Je viens d'installer Windows 11**

```
1️⃣ Ouvre PowerShell (Admin)
2️⃣ Tape : irm tinyurl.com/ClickByChris | iex
3️⃣ Clique sur "TOUT FAIRE"
4️⃣ Attends 15-20 minutes
5️⃣ Ton PC est prêt ! 🎉
```

**Résultat :**
- ✅ Windows est optimisé
- ✅ Tous les drivers sont installés
- ✅ Chrome, Discord, Office, etc sont là
- ✅ Tes dossiers sont bien organisés
- ✅ Aucune config à faire manuellement !

---

## 📊 Tableau de Compatibilité

| Windows | Supporté | Notes |
|---|---|---|
| Windows 11 | ✅ OUI | Recommandé |
| Windows 10 | ✅ OUI | Testé et approuvé |
| Windows 7/8 | ❌ NON | Trop vieux |

| Architecture | Supportée |
|---|---|
| 64-bit | ✅ OUI |
| 32-bit | ❌ NON |

---

## 🚀 Features Planifiées (v1.1.0+)

- 🔜 Interface sombre (Dark Mode)
- 🔜 Support multi-langue (FR, EN, ES, DE)
- 🔜 Planificateur de nettoyage automatique
- 🔜 Statistiques d'utilisation système
- 🔜 Gestionnaire de mises à jour auto
- 🔜 Support des applications Winget supplémentaires

---

## 📝 Changelog

### **Version 1.0.0 - Juin 2026**

#### ✨ Features
- ✅ Installation automatique des apps
- ✅ Installation des runtimes (.NET, Visual C++, etc)
- ✅ Optimisations Windows
- ✅ Installation des drivers
- ✅ Création de structure de dossiers
- ✅ Lecteur de musique intégré
- ✅ Génération de rapports CSV

#### 🐛 Bugs Fixes
- Interface WPF stable
- Gestion d'erreurs améliorée
- Support Windows 10 et 11

#### 📚 Documentation
- README complet
- Troubleshooting guide
- SECURITY policy
- Installation guide

👉 [Voir le changelog complet](./CHANGELOG.md)

---

## 🤝 Contribution

Tu veux aider à améliorer ClickByChris ?

Regarde [CONTRIBUTING.md](./CONTRIBUTING.md) pour savoir comment contribuer ! 🙏

---

## 📜 License

Ce projet est sous **MIT License**.

Tu peux :
- ✅ L'utiliser gratuitement
- ✅ Le modifier
- ✅ Le redistribuer
- ✅ L'utiliser commercialement

**Condition :** Mentionne simplement l'auteur original.

👉 [Voir la license complète](./LICENSE)

---

## 👨‍💻 Créateur

**ClickByChris - Christophe**

| Lien | URL |
|---|---|
| 📧 Email | chris.clickby@gmail.com |
| 🌍 GitHub | [@christophe939](https://github.com/christophe939) |
| 🎮 Discord | [Serveur ClickByChris](https://discord.gg/clickbychris) |

---

## 🙏 Merci !

Merci d'utiliser **ClickByChris Setup Tool** ! 🚀

Si tu l'aimes, laisse une ⭐ sur GitHub !

Des questions ? Rejoins le [Discord](https://discord.gg/clickbychris) ! 🎮

---

<div align="center">

### 🚀 Installation en 1 commande :

```powershell
irm tinyurl.com/ClickByChris | iex
```

**Version 1.0.0 - Juin 2026**

Made with ❤️ by ClickByChris

</div>
