<div align="center">

# SYTA Super Launcher

**Lanceur Windows mono-fichier pour un setup IA orienté WSL**

<p>
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10/11" />
  <img src="https://img.shields.io/badge/WSL-Ubuntu-0EAD69?style=for-the-badge&logo=ubuntu&logoColor=white" alt="WSL Ubuntu" />
  <img src="https://img.shields.io/badge/Distribution-Fichier%20unique-111111?style=for-the-badge" alt="Fichier unique" />
  <img src="https://img.shields.io/badge/Licence-MIT-4CAF50?style=for-the-badge" alt="Licence MIT" />
</p>

<p>
  <img src="https://img.shields.io/badge/Interface-TUI%20interactive-6A5ACD?style=flat-square" alt="TUI interactive" />
  <img src="https://img.shields.io/badge/Projets-C%3A%5C.CODEX-5C6BC0?style=flat-square" alt="Racine projets" />
  <img src="https://img.shields.io/badge/Runtime-Portable-455A64?style=flat-square" alt="Runtime portable" />
  <img src="https://img.shields.io/badge/Made%20by-Sylvain%20T.-D81B60?style=flat-square" alt="Made by Sylvain T." />
</p>

</div>

---

## Vue d'ensemble

`syta-super-launcher.bat` est un **poste de commande portable, mono-fichier**, pensé pour piloter un environnement de code assisté par IA sur Windows avec WSL.

Il offre un point d’entrée unique pour :

- créer et rouvrir des projets dans `C:\.CODEX`
- rechercher des projets avec un classement plus pertinent, insensible à la casse et aux mots partiels
- lancer des CLI IA de code dans WSL
- installer les outils manquants
- lancer directement l'assistant de nettoyage depuis le menu principal
- reinitialiser les configs suivies des outils quand le setup devient trop charge
- exécuter des mises à jour légères ou complètes
- afficher des diagnostics avant lancement

Tout le runtime est embarqué dans le fichier batch lui-même. Au lancement, il extrait ses scripts dans un dossier temporaire, exécute l’interface depuis là, puis laisse les vrais outils s’installer dans l’environnement utilisateur approprié.

## En Résumé

| Fonction | Rôle |
| --- | --- |
| `Code` | Ouvre un projet et lance une CLI de code dans WSL |
| `Install` | Installe ou répare l’environnement et les outils pris en charge |
| `Cleaner helper` | Analyse les anciennes CLI IA et les doublons du PATH depuis le menu principal |
| `Reset tool configs` | Examine les chemins config/auth suivis et ne supprime que ce que vous confirmez |
| `Light update` | Met à jour uniquement les CLI IA de code |
| `Update all` | Lance une mise à jour plus large de la chaîne d’outils |
| Diagnostics | Affiche l’état d’installation, la version et des indices d’auth/config |
| Menus plus reactifs | Regroupe les diagnostics et affiche des barres de chargement pendant les ecrans plus lents |
| Invite de mise a jour | Peut proposer une nouvelle release du lanceur lorsqu'elle existe |
| Portabilité | Distribution en un seul `.bat` |
| Langue | Détecte automatiquement le français/anglais pour l'interface du lanceur |

## Outils Pris En Charge

### Menu Code

Le lanceur peut démarrer dans WSL :

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

### Menu Install

Le menu d’installation prend actuellement en charge :

- `First install` pour un parcours debutant guide
- `WSL Ubuntu`
- `PowerShell 7`
- `Install core AI CLI tools`
- `Cleaner helper`
- `Reset tool configs`
- `Codex CLI`
- `OpenCode`
- `Oh My OpenAgent`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `Oh My OpenCode Slim`

`First install` est le parcours debutant : il lance WSL Ubuntu si besoin, demande s'il faut installer ou reparer PowerShell 7, puis lance l'installation des CLI IA de base seulement quand Ubuntu est vraiment pret pour un setup CLI utilisateur. Si Ubuntu demande encore un redemarrage ou la creation initiale du compte Linux, SYTA indique de terminer cette etape puis de relancer `First install`.

Le bundle de base installe actuellement :

- `Codex`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

`Oh My Codex / OMX`, `Oh My OpenAgent` et `Oh My OpenCode Slim` restent des installations optionnelles separees dans le menu d'installation.

`Cleaner helper` est disponible directement depuis le menu principal et aussi dans le menu d'installation. Il analyse les installations des CLI IA laissees dans d'anciennes versions Node gerees par `nvm`, ainsi que les doublons du PATH, puis demande avant de supprimer les npm globaux obsoletes qu'il peut nettoyer sans risque.

`Reset tool configs` ouvre maintenant un second selecteur. Depuis ce menu, vous pouvez reinitialiser seulement `Codex / OMX`, `OpenCode`, `Oh My OpenAgent`, `Oh My OpenCode Slim`, `Claude Code`, `Gemini CLI`, ou `Toutes les configs suivies`.

`OpenCode`, `Oh My OpenAgent` et `Oh My OpenCode Slim` sont maintenant trois voies distinctes :

- `OpenCode` est la CLI de code normale.
- `Oh My OpenAgent` est le plus gros add-on autour d'OpenCode, avec plus d'aides mais aussi plus de setup.
- `Oh My OpenCode Slim` est l'add-on plus leger autour d'OpenCode pour les personnes qui veulent seulement quelques aides en plus.

## Langue

L'interface du lanceur détecte maintenant automatiquement le **français** ou l'**anglais**.

Un forçage manuel est aussi disponible :

```powershell
syta-super-launcher.bat -UiLanguage fr
syta-super-launcher.bat -UiLanguage en
```

Vous pouvez aussi passer par une variable d'environnement :

```powershell
set SYTA_LANGUAGE=fr
```

L'interface du lanceur suit cette préférence. Les sorties des outils tiers ou des installateurs peuvent toutefois rester dans leur langue native.

## Racine Des Projets

Tous les projets sont gérés sous :

```text
C:\.CODEX
```

Si le dossier n’existe pas, le lanceur le crée automatiquement.

Les projets récents sont stockés ici :

```text
C:\.CODEX\.syta-launcher-state.json
```

## Modèle De Runtime

Le lanceur fonctionne sur deux couches distinctes.

### Couche de distribution

Le fichier publié est uniquement :

```text
syta-super-launcher.bat
```

### Couche de runtime

Au moment de l’exécution, le lanceur extrait ses scripts embarqués dans `%TEMP%` et tourne depuis cet emplacement.

Cela permet de garder une distribution ultra-portable tout en conservant :

- une interface interactive riche
- des flux d’installation
- des flux de mise à jour
- un pont WSL
- une couche de diagnostics

## Philosophie D’Installation

Le lanceur est pensé pour des machines réelles, pas pour un environnement parfait de démonstration.

Comportements importants :

- `First install` guide une nouvelle machine a travers WSL Ubuntu, PowerShell 7 en option, puis les CLI IA de base une fois Ubuntu pret. Les voies `Oh My x` restent des extras optionnels.
- `Cleaner helper` reste un raccourci de maintenance depuis le menu principal tout en verifiant les anciennes installations npm des CLI IA dans les versions `nvm` plus vieilles avant nettoyage.
- `Reset tool configs` donne un moyen conservateur d'annuler des chemins config/auth suivis, avec un second menu pour choisir un outil precis ou `Toutes les configs suivies`.
- Les menus utilisent un affichage plus lisible avec un panneau de detail et une progression pendant la preparation des donnees projet ou outil.
- Le lanceur peut verifier si une nouvelle release GitHub est disponible et proposer une mise a jour du lanceur sur place.
- Il privilégie `nvm` pour les CLI basées sur Node.
- Il essaie de préserver la version Node active ou par défaut de l’utilisateur.
- Il tente de réparer `libatomic.so.1` automatiquement sur les systèmes apt si nécessaire.
- Il distingue autant que possible `Installed`, `Configured only` et `Missing`.

## Diagnostics

Avant les lancements et les installations, l’interface peut afficher :

- l’état d’installation
- la version détectée
- des indices d’auth/config
- la source de l’installation, par exemple `nvm`, `system`, `user-local` ou `config-only`

Ces diagnostics sont volontairement pragmatiques. Ils sont utiles pour l’exploitation, mais ne remplacent pas une vérification parfaite de l’auth réelle chez chaque fournisseur.

Quand les diagnostics live prennent un moment, le lanceur affiche maintenant une progression claire au lieu de sembler fige.

## Environnement Recommandé

Meilleure expérience :

- Windows 10 ou Windows 11
- WSL activé
- Ubuntu dans WSL
- Windows Terminal installé

Le modèle cible est :

- lanceur côté Windows
- outils de code côté Linux dans WSL
- installations utilisateur quand c’est pertinent

## Démarrage Rapide

```text
1. Télécharger syta-super-launcher.bat
2. Double-cliquer dessus
3. Utiliser Install -> First install sur une nouvelle machine, ou une autre entree Install si vous n'avez besoin que d'un composant précis
4. Utiliser Code pour créer ou ouvrir un projet puis lancer un outil
```

## Pourquoi Ce Dépôt Reste Minimal

Ce dépôt publie volontairement uniquement le lanceur portable et sa documentation.

Fichiers inclus :

- `syta-super-launcher.bat`
- `README.md`
- `README.fr.md`
- `LICENSE`

Les scripts auxiliaires extraits ne sont pas publiés séparément, car l’objectif du projet est précisément de conserver une distribution en **un seul fichier**.

## Auteur

**Made by Sylvain T.**

## Licence

Projet publié sous **licence MIT**.

Voir [LICENSE](./LICENSE).
