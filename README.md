# ClickByChris Setup Tool

**ClickByChris Setup Tool** est un outil Windows permettant de préparer rapidement un PC avec une interface simple, moderne et centralisée.

Il permet notamment de :
- analyser les informations principales du PC ;
- installer des applications utiles via `winget` ;
- installer des composants de compatibilité ;
- appliquer des optimisations Windows sélectionnées ;
- créer une structure de dossiers propre ;
- créer des raccourcis utiles ;
- consulter les logs d'exécution ;
- utiliser un mode assisté **TOUT FAIRE** avec résumé avant exécution.

## Compatibilité

Cible recommandée :
- Windows 10
- Windows 11
- Windows PowerShell 5.1 minimum
- PowerShell 7 recommandé si disponible

Le launcher tente d'utiliser PowerShell 7 si disponible, sinon il bascule sur Windows PowerShell.

## Structure du projet

```text
Tool ClickByChris60/
├─ ClickByChris_Setup_Tool_V1_0_3_REPORTS_PLUS_FIXED.ps1
├─ Launch_ClickByChris_V1_0_3.cmd
├─ settings.json
├─ README.md
├─ CHANGELOG.md
├─ LICENSE
└─ Assets/
   ├─ logo.png
   ├─ Icons/
   │  └─ V2/
   └─ Sounds/
      └─ Startup/
```

## Lancement

Méthode recommandée :

```text
Launch_ClickByChris_V1_0_3.cmd
```

Ou depuis PowerShell :

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\ClickByChris_Setup_Tool_V1_0_3_REPORTS_PLUS_FIXED.ps1"
```

Si PowerShell 7 n'est pas installé, le script peut fonctionner avec Windows PowerShell selon les fonctions utilisées.

## Fonctions principales

### Accueil
Page principale avec les actions recommandées et les accès rapides.

### Infos PC
Affiche les informations principales :
- nom du PC ;
- fabricant ;
- modèle ;
- processeur ;
- carte graphique ;
- RAM ;
- version Windows ;
- BIOS ;
- disque système.

### Applications
Installation ou mise à jour d'applications via `winget`.

### Compatibilité
Installation de composants nécessaires pour certains logiciels ou anciens jeux :
- Microsoft Visual C++ Redistributable ;
- .NET Desktop Runtime ;
- autres composants utiles selon la configuration.

### Optimisation Windows
Optimisations organisées par niveau :
- **Safe** : réglages raisonnables pour la majorité des PC ;
- **Gaming** : options orientées jeu ;
- **Avancé / Risqué** : actions sensibles qui demandent une validation claire.

### Assistant TOUT FAIRE
Affiche une fenêtre de confirmation permettant de choisir les actions à exécuter.

### Logs et rapports
Chaque action produit :
- des logs en temps réel ;
- un résumé final ;
- un rapport CSV dans le dossier `Logs`.

## Sécurité et responsabilité

Cet outil peut modifier certains réglages Windows.  
Il doit être utilisé avec prudence, surtout pour les options avancées.

Avant d'utiliser les fonctions d'optimisation ou le mode **TOUT FAIRE**, il est recommandé de :
- lire les descriptions des actions ;
- créer ou vérifier un point de restauration ;
- tester d'abord dans une machine virtuelle ou sur un PC non critique.

L'auteur ne peut pas garantir que chaque réglage sera adapté à tous les PC. Certaines actions peuvent être bloquées par Windows, par l'édition installée, par les droits administrateur ou par les politiques système.

## Auteur

Projet créé par **ClickByChris / Christophe**.
