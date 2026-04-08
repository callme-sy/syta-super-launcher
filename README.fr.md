# SYTA Super Launcher

Lanceur Windows mono-fichier pour un setup de code IA orienté WSL.

`syta-super-launcher.bat` fournit une interface unique pour créer des projets, lancer des agents de code, installer les outils manquants et exécuter des mises à jour dans un workflow Windows + WSL cohérent.

## Points Forts

- Distribution mono-fichier : un seul `.bat`, aucun dossier auxiliaire à partager
- Workflow orienté WSL : projets rangés dans `C:\.CODEX`
- Interface interactive avec diagnostics et projets récents
- Flux d’installation intégrés pour plusieurs CLI IA de code
- Modes de mise à jour légère et complète
- Runtime portable : les helpers sont extraits dans `%TEMP%` au lancement

## Modes Inclus

| Mode | Rôle |
| --- | --- |
| `Code` | Créer/ouvrir un projet et lancer une CLI IA dans WSL |
| `Install` | Installer ou réparer WSL, PowerShell et les outils pris en charge |
| `Light update` | Mettre à jour uniquement les CLI IA de code |
| `Update all` | Lancer une mise à jour plus large de la chaîne d’outils |

## Outils Pris En Charge

Depuis le menu `Code`, le lanceur peut démarrer :

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

Depuis le menu `Install`, le lanceur prend en charge :

- `WSL Ubuntu`
- `PowerShell 7`
- `Install all AI CLI tools`
- `Codex CLI`
- `OpenCode`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `Oh My OpenCode Slim`

## Racine Des Projets

Le lanceur utilise toujours :

```text
C:\.CODEX
```

Si ce dossier n’existe pas, il est créé automatiquement.

Les projets récents sont stockés dans :

```text
C:\.CODEX\.syta-launcher-state.json
```

## Fonctionnement

`syta-super-launcher.bat` embarque son propre runtime dans le fichier batch lui-même.

Au lancement, il extrait ses helpers dans un répertoire temporaire unique, puis exécute le lanceur depuis cet emplacement. Ce runtime temporaire ne sert qu’au fonctionnement du lanceur.

Les vraies installations se font dans l’environnement utilisateur :

- outils Windows côté Windows
- outils Linux côté WSL
- CLI Node généralement sous `nvm` dans le home WSL

## Philosophie D’Installation

Le lanceur cherche à être utile sur de vraies machines, pas seulement théoriquement élégant.

Comportements importants :

- Il privilégie `nvm` pour les CLI basées sur Node.
- Il essaie de préserver la version Node déjà utilisée par l’utilisateur au lieu de basculer brutalement vers une nouvelle version vide.
- Il tente de réparer `libatomic.so.1` sur les distributions apt lorsque c’est nécessaire pour certains runtimes Node.
- Il distingue autant que possible `Installed`, `Configured only` et `Missing`.

## Diagnostics

L’interface affiche des diagnostics de préflight avant les lancements et les installations.

Ces diagnostics essaient de montrer :

- l’état d’installation
- la version détectée
- les indices d’auth/config
- l’origine de l’installation, par exemple `nvm`, `system`, `user-local` ou `config-only`

Ces vérifications sont heuristiques par nature. Elles sont conçues pour être pratiques et utiles, pas pour remplacer une vérification parfaite de l’authentification réelle auprès de chaque fournisseur.

## Prérequis

Configuration recommandée :

- Windows 10 ou Windows 11
- WSL disponible
- Ubuntu dans WSL
- Windows Terminal recommandé

Le lanceur peut réparer certains éléments manquants, mais l’environnement cible reste :

- un lanceur Windows côté hôte
- des outils de code côté Linux dans WSL
- des installations utilisateur autant que possible

## Démarrage Rapide

1. Téléchargez `syta-super-launcher.bat`.
2. Double-cliquez dessus.
3. Utilisez `Install` d’abord si votre environnement n’est pas prêt.
4. Utilisez `Code` pour créer ou ouvrir un projet puis lancer un outil.

## Portée Du Dépôt

Ce dépôt reste volontairement minimal.

Fichiers publiés :

- `syta-super-launcher.bat`
- `README.md`
- `README.fr.md`
- `LICENSE`

Les scripts auxiliaires extraits ne sont pas publiés séparément, car l’objectif est précisément de conserver une distribution mono-fichier.

## Auteur

Made by Sylvain T.

## Licence

MIT. Voir [LICENSE](./LICENSE).
