# SYTA Super Launcher

`syta-super-launcher.bat` est un lanceur Windows mono-fichier pour un environnement de code assisté par IA orienté WSL.

Il ouvre une interface interactive en terminal, gère les projets dans `C:\.CODEX`, et lance plusieurs outils IA dans WSL avec un flux cohérent.

## Ce Que C'est

Ce dépôt publie volontairement un seul fichier portable :

- `syta-super-launcher.bat`

Ce fichier embarque son propre runtime et extrait ses scripts temporaires au lancement. Ces fichiers extraits servent uniquement au fonctionnement du lanceur. Les vrais outils sont installés dans l'environnement Windows ou WSL de l'utilisateur, pas dans le dossier temporaire.

## Objectif Principal

Le but est de simplifier un environnement IA de développement autour de WSL.

Le lanceur peut :

- créer et ouvrir des dossiers projet dans `C:\.CODEX`
- lancer plusieurs CLI de code IA depuis un menu unique
- installer les outils manquants
- lancer des mises à jour légères ou complètes
- mémoriser les projets récents
- afficher un pré-diagnostic avant les lancements

## Modes Principaux

### Code

Crée ou ouvre un dossier projet dans `C:\.CODEX`, puis lance un des outils suivants dans WSL :

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

Avant le lancement, le lanceur affiche un panneau de préflight avec :

- le chemin du projet
- l'état d'installation détecté
- la version détectée
- l'indice d'auth/config
- le chemin binaire ou config quand disponible

### Install

Installe ou répare l'environnement.

Cibles actuelles :

- `WSL Ubuntu`
- `PowerShell 7`
- `Install all AI CLI tools`
- `Codex CLI`
- `OpenCode`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `Oh My OpenCode Slim`

Pour les outils basés sur Node, l'installateur privilégie `nvm` et tente de préserver la version Node déjà utilisée au lieu de basculer brutalement vers une nouvelle version vide qui ferait disparaître les CLI globales existantes.

Il tente aussi de corriger un problème Linux fréquent en installant `libatomic1` sur les distributions apt lorsque c'est nécessaire.

### Light Update

Met à jour uniquement les CLI IA de code :

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

### Update All

Lance une mise à jour plus large de la chaîne d'outils :

- `apt`
- `Homebrew`
- `npm`
- `pnpm`
- `pipx`
- `uv`
- `rustup`
- `cargo-install-update`
- `dotnet` global tools

## Racine Des Projets

Le lanceur utilise toujours :

```text
C:\.CODEX
```

Si ce dossier n'existe pas, il est créé automatiquement.

Les projets récents sont stockés ici :

```text
C:\.CODEX\.syta-launcher-state.json
```

## Fonctionnement Technique

Au démarrage, `syta-super-launcher.bat` extrait ses scripts embarqués dans un dossier runtime temporaire unique.

Ce runtime alimente :

- l'interface interactive
- les flux d'installation
- les flux de mise à jour
- le pont WSL
- la couche de diagnostic

L'intérêt est de garder un seul fichier portable tout en conservant un comportement proche d'une petite application.

## Prérequis

Environnement recommandé :

- Windows 10 ou Windows 11
- WSL disponible
- Ubuntu dans WSL
- Windows Terminal recommandé

L'expérience visée est :

- lanceur côté Windows
- outils côté Linux dans WSL
- installations utilisateur dans le `$HOME` WSL

## Détails D'Installation

### Outils Côté WSL

Les outils Linux sont installés dans l'environnement utilisateur WSL.

Exemples :

- `nvm` dans `~/.nvm`
- CLI npm globales dans la version Node active sous `nvm`
- configuration OpenCode dans `~/.config/opencode`

Ils ne sont pas installés dans le dossier temporaire d'extraction du lanceur.

### Node et npm

L'installateur utilise `nvm` quand c'est possible.

Point important :

- les CLI npm globales dépendent de la version Node active
- changer de version Node peut donner l'impression que des outils ont disparu

Pour éviter cela, le lanceur tente maintenant de conserver et réutiliser la version `nvm` déjà active ou par défaut.

### OpenCode

OpenCode est géré à part car il peut être configuré sans que le binaire soit réellement disponible dans le `PATH`.

Le lanceur essaie de distinguer :

- `Installed`
- `Configured only`
- `Missing`

## Diagnostic

L'interface affiche des diagnostics heuristiques sur :

- l'état installé/manquant
- la version détectée
- les indices d'auth/config
- l'origine de l'installation comme `nvm`, `system`, `user-local` ou `config-only`

Ces diagnostics sont pratiques mais ne constituent pas une vérification parfaite de l'authentification réelle auprès des fournisseurs.

## PowerShell 7

Le lanceur inclut un chemin d'installation Windows pour PowerShell 7.

Ce chemin vise à :

- installer PowerShell 7 via `winget`
- vérifier `pwsh.exe`
- définir le `defaultProfile` de Windows Terminal sur `PowerShell`

## Build Stamp

Le lanceur affiche un identifiant de build dans l'interface et dans `SmokeTest`, afin de confirmer facilement que l'utilisateur exécute bien la bonne version du fichier.

## Pourquoi Un Seul Fichier

Le dépôt se concentre sur la portabilité.

Au lieu de publier un dossier complet de scripts auxiliaires, tout est embarqué dans un seul fichier pour le partage et l'utilisation rapide.

## Limites

Limites actuelles :

- les diagnostics restent heuristiques
- certains flux dépendent de la présence correcte des composants Windows et WSL sur la machine cible
- `super.ps1` n'est pas publié ici, car ce dépôt se concentre volontairement sur l'expérience mono-fichier

## Utilisation

1. Téléchargez `syta-super-launcher.bat`.
2. Double-cliquez dessus.
3. Choisissez un mode.
4. Suivez les menus interactifs.

## Auteur

Made by Sylvain T.

## Licence

Aucun fichier de licence n'est inclus pour le moment.

Si vous voulez publier ce projet plus largement, ajoutez une licence explicite.
