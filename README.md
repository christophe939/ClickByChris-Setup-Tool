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

## Compatibilit

Cible recommandée :
- Windows 10
- Windows 11
- Windows PowerShell 5.1 minimum
- PowerShell 7 recommandé si disponible

Le launcher tente d'utiliser PowerShell 7 si disponible, sinon il bascule sur Windows PowerShell.

## Structure du projet

```text
ClickByChris_Setup_Tool_V1_0_4/
├─ ClickByChris_Setup_Tool_V1_0_4.ps1
├─ Launch_ClickByChris_V1_0_4.cmd
├─ install.ps1
├─ settings.json
├─ version.json
├─ README.md
├─ CHANGELOG.md
├─ LICENSE
└─ Assets/
   ├─ logo.png
   ├─ Icons/
   │  └─ V2/
   └─ Sounds/
      └─ Startup/
