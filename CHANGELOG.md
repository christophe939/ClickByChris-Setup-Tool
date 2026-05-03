# Changelog

Toutes les modifications importantes du projet sont listées ici.

## [1.0.3] - Version de test multi-PC avec rapports

### Ajouté
- Rapport d'exécution détaillé après les actions principales.
- Export automatique des rapports en CSV dans le dossier `Logs`.
- Logs plus détaillés pour les installations via `winget`.
- Fenêtre de résumé visuel après les actions terminées.
- Support amélioré du mode **TOUT FAIRE**.
- Vérifications multi-PC :
  - PowerShell ;
  - PowerShell 7 ;
  - winget ;
  - droits administrateur ;
  - assets ;
  - icônes ;
  - son de démarrage.

### Corrigé
- Correction du problème `Run-All -Plan` avec conversion `PSCustomObject` / `Hashtable`.
- Correction du problème `RuntimeMap.ContainsKey` avec `OrderedDictionary`.
- Gestion plus propre du message Windows sur le point de restauration déjà créé dans les dernières 24h.
- Correction des problèmes d'encodage UTF-8 / BOM.
- Suppression de l'ancien module Audio Premium dans l'usage normal.

### Modifié
- Le projet est maintenant orienté **multi-PC**.
- Les chemins sont davantage portables.
- Le son de démarrage est conservé, mais le lecteur audio complet est retiré.
- L'interface se concentre sur les fonctions de préparation Windows.

## [1.0.2] - Correction TOUT FAIRE

### Corrigé
- Correction de l'erreur de conversion du plan d'exécution dans le mode **TOUT FAIRE**.
- Amélioration de la compatibilité entre objets PowerShell et hashtables.

## [1.0.1] - Ajout des premiers rapports

### Ajouté
- Premiers rapports d'exécution.
- États `OK`, `WARN`, `ERROR`, `SKIP`.
- Export CSV basique.

## [1.0.0] - Base de test

### Ajouté
- Version de base multi-PC.
- Launcher `.cmd`.
- Structure `Assets`, `Config`, `Logs`, `Temp`.
- Son de démarrage.
- Suppression visuelle du module Audio Premium.
