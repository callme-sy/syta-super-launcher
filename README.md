<div align="center">

# SYTA Super Launcher

**Single-file Windows launcher for a WSL-first AI coding setup**

<p>
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10/11" />
  <img src="https://img.shields.io/badge/WSL-Ubuntu-0EAD69?style=for-the-badge&logo=ubuntu&logoColor=white" alt="WSL Ubuntu" />
  <img src="https://img.shields.io/badge/Distribution-Single%20File-111111?style=for-the-badge" alt="Single file" />
  <img src="https://img.shields.io/badge/License-MIT-4CAF50?style=for-the-badge" alt="MIT License" />
</p>

<p>
  <img src="https://img.shields.io/badge/Interface-Interactive%20TUI-6A5ACD?style=flat-square" alt="Interactive TUI" />
  <img src="https://img.shields.io/badge/Projects-Configurable-5C6BC0?style=flat-square" alt="Projects root" />
  <img src="https://img.shields.io/badge/Runtime-Portable-455A64?style=flat-square" alt="Portable runtime" />
  <img src="https://img.shields.io/badge/Made%20by-Sylvain%20T.-D81B60?style=flat-square" alt="Made by Sylvain T." />
</p>

</div>

---

## Overview

`syta-super-launcher.bat` is a **portable, single-file command deck** for launching and maintaining an AI coding environment on Windows with WSL.

It gives you one interactive entry point to:

- create and reopen projects under a configurable projects root (default: `C:\.CODEX`)
- search projects with ranked, case-insensitive partial matching
- launch AI coding CLIs inside WSL
- install missing tools
- run the cleaner helper directly from the main menu
- reset tracked tool configs when a setup has become too cluttered
- run light, utility-only, or full update flows
- surface diagnostics before launch

The entire runtime is embedded into the batch file itself. At launch, it extracts helper scripts into a temporary runtime directory, runs the UI from there, and keeps the actual installs in the user environment where they belong.

## At A Glance

| Capability | What it does |
| --- | --- |
| `Code` | Opens a project and launches a coding CLI in WSL |
| `Install` | Installs or repairs the environment and supported tools |
| `Settings` | Changes launcher preferences such as language and projects directory |
| `Extra` | Opens maintenance tools and smaller workflow utilities from the main menu |
| `Check launcher update` | Forces a fresh launcher-release check and offers self-update when needed |
| `Light update` | Updates installed AI coding CLIs only, including Kilo Code CLI and DROID CLI |
| `Update utilities add-ons` | Updates installed utility add-ons only |
| `Update all` | Runs a broader toolchain update pass |
| Diagnostics | Shows install, version, and auth/config hints |
| Responsive menus | Batches diagnostics and shows loading bars during slower menu preparation |
| Update prompt | Can offer a newer launcher release when one is available |
| Portability | Ships as one `.bat` file |
| Language | Auto-detects French/English/Chinese for the launcher UI |

## Supported Tools

### Code Menu

The launcher can start these tools in WSL:

- `Codex`
- `OMX`
- `OpenCode`
- `Kilo Code CLI`
- `Claude Code`
- `Gemini CLI`

### Main Menu

The launcher main menu includes:

- `Code`
- `Install`
- `Settings`
- `Extra`
- `Explanations`
- `Update`

`Settings` is the main-menu lane for launcher preferences such as language and projects directory.

`Extra` is the main-menu lane for maintenance and add-ons.

`Update` now also includes a manual launcher-release checker in case the automatic startup prompt did not surface a newer version.

### Install Menu

The installer currently supports:

- `First install` for guided beginner setup
- `WSL Ubuntu`
- `PowerShell 7`
- `Install core AI CLI tools`
- `Codex CLI`
- `OpenCode`
- `Kilo Code CLI`
- `Oh My OpenAgent`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `DROID CLI`
- `Oh My OpenCode Slim`

`First install` is the beginner lane: it starts WSL Ubuntu when needed, asks whether PowerShell 7 should be installed or repaired, then runs the core AI CLI installer only once Ubuntu is actually ready for user-scoped CLI setup. If Ubuntu still needs a reboot or first-run account setup, SYTA tells the user to finish that step and rerun `First install` afterward.

The core bundle currently installs:

- `Codex`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

`Kilo Code CLI`, `Oh My Codex / OMX`, `Oh My OpenAgent`, `DROID CLI`, and `Oh My OpenCode Slim` remain separate optional installs from the install menu.

`DROID CLI` is Factory AI's CLI. SYTA installs it through Factory AI's official Linux bootstrap command inside WSL.

`Kilo Code CLI` is installed through the official npm package `@kilocode/cli`, then launched in WSL with the `kilo` command.

`Extra` opens a second selector from the main menu for maintenance and smaller workflow add-ons:

- `Cleaner helper`
- `Reset tool configs`
- `Utilities`

`Cleaner helper` scans for tracked AI CLI installs left behind in older `nvm` Node versions, plus duplicate PATH hits, then asks before removing stale npm globals it can safely clean.

`Reset tool configs` opens a second selector. From there you can reset only `Codex / OMX`, `OpenCode`, `Oh My OpenAgent`, `Oh My OpenCode Slim`, `Claude Code`, `Gemini CLI`, or `All tracked configs`.

`Utilities` opens a third selector for smaller workflow add-ons:

- `RTK`
- `ccusage`
- `codex-auth`
- `superpowers`
- `OpenSpec`
- `Claw Code`
- `BMAD`

Those utility lanes still use the launcher's WSL-first model. `RTK`, `ccusage`, `codex-auth`, and `OpenSpec` run the upstream install commands in WSL. `superpowers` clones the upstream repo and links its skills into Codex, then prints the optional OpenCode and Gemini follow-up steps. `Claw Code` clones `ultraworkers/claw-code`, builds the `claw` binary in release mode, and links it into `~/.local/bin`. `BMAD` is project-scoped: SYTA asks you to choose a project under the currently configured projects root, then launches the official BMAD installer inside that project.

`Update -> Update utilities add-ons` refreshes only detected installed utilities. It updates the supported user-scoped utility installs, verifies RTK after updating it, rebuilds/relinks managed Claw Code checkouts, and quick-updates BMAD projects already found under the currently configured projects root.

`OpenCode`, `Oh My OpenAgent`, and `Oh My OpenCode Slim` are now separate lanes:

- `OpenCode` is the normal coding CLI.
- `Oh My OpenAgent` is the bigger add-on around OpenCode, with more helper features and more setup. It is not a separate coding CLI.
- `Oh My OpenCode Slim` is the lighter add-on around OpenCode for people who want a smaller set of extras. It is not a separate coding CLI.

## Language

The launcher UI now auto-detects between **French**, **English**, and **Chinese**.

On the first interactive launch, SYTA now also offers a language picker and stores launcher preferences in `%LOCALAPPDATA%\SYTA Super Launcher\launcher-settings.json`. You can change them later from `Settings`.

Manual override is also available:

```powershell
syta-super-launcher.bat -UiLanguage fr
syta-super-launcher.bat -UiLanguage en
syta-super-launcher.bat -UiLanguage zh
```

Environment-variable override is supported too:

```powershell
set SYTA_LANGUAGE=fr
set SYTA_LANGUAGE=zh
```

The launcher UI follows this preference. Third-party installer or CLI output may still appear in its own native language.

## Project Layout

Projects are managed under a configurable Windows folder. The default root is:

```text
C:\.CODEX
```

You can switch that root later from `Settings`, including to another drive such as `D:\`.

If the chosen folder does not exist, the launcher creates it automatically.

Recent projects for the active root are tracked in:

```text
<Selected projects root>\.syta-launcher-state.json
```

Launcher-wide preferences such as language, selected projects root, and update-cache metadata are stored in:

```text
%LOCALAPPDATA%\SYTA Super Launcher\launcher-settings.json
```

## Runtime Model

The launcher works in two distinct layers:

### Distribution layer

The published file is only:

```text
syta-super-launcher.bat
```

### Runtime layer

At execution time, the launcher extracts its embedded helper scripts into `%TEMP%` and runs from there.

This keeps the distribution portable while still allowing:

- a richer interactive UI
- installer flows
- updater flows
- WSL session bridging
- preflight diagnostics

## Installation Philosophy

This launcher is designed for real-world machines, not idealized clean-room setups.

Important behaviors:

- `First install` guides a new machine through WSL Ubuntu, optional PowerShell 7, then the core AI CLI tools when Ubuntu is ready. The `Oh My x` lanes remain optional extras.
- `Cleaner helper` remains reachable quickly through `Extra` and still checks stale npm-based AI CLI installs across older `nvm` versions before cleanup.
- `Reset tool configs` stays under `Extra` and gives users a conservative way to undo tracked tool config/auth paths, with a second menu for tool-specific reset choices or `All tracked configs`.
- `Utilities` now lives under `Extra` so smaller workflow add-ons stay out of the main install list while still getting diagnostics and preflight screens.
- `Update utilities add-ons` gives the launcher a dedicated maintenance lane for installed extras without forcing the broader full update pass.
- Menus use a cleaner focused-detail layout and loading progress when project or tool data takes time to prepare.
- The launcher can check for a newer GitHub release and offer an in-place launcher update.
- It prefers `nvm` for Node-based CLI installs.
- It tries to preserve the user’s active/default Node version instead of blindly switching to a fresh one.
- It attempts to repair `libatomic.so.1` automatically on apt-based systems when required by Node runtimes.
- It distinguishes between `Installed`, `Configured only`, and `Missing` when possible.

## Diagnostics

Before launching or installing, the UI can surface:

- install state
- version detection
- auth/config hints
- install source, such as `nvm`, `system`, `user-local`, or `config-only`

These diagnostics are intentionally pragmatic. They are useful operational signals, not perfect provider-auth verification.

When live diagnostics take a moment, the launcher now shows focused loading progress instead of appearing frozen.

## Recommended Environment

Best experience:

- Windows 10 or Windows 11
- WSL enabled
- Ubuntu in WSL
- Windows Terminal installed

The intended deployment model is:

- Windows-side launcher
- Linux-side coding tools in WSL
- user-scoped installs when possible

## Quick Start

```text
1. Download syta-super-launcher.bat
2. Double-click it
3. Use Install -> First install on a new machine, or another Install entry if you only need a specific component
4. Use Code to create or open a project and launch a tool
```

## Why This Repo Stays Minimal

This repository intentionally publishes only the portable launcher and its documentation.

Included files:

- `syta-super-launcher.bat`
- `README.md`
- `README.fr.md`
- `README.zh.md`
- `LICENSE`

It does not publish the extracted helper scripts separately because the point of the project is to keep distribution down to a **single launcher file**.

## Author

**Made by Sylvain T.**

## License

Released under the **MIT License**.

See [LICENSE](./LICENSE).
