# SYTA Super Launcher

`syta-super-launcher.bat` is a single-file Windows launcher for an opinionated AI coding workspace setup.

It opens a terminal-based interactive UI, manages project folders under `C:\.CODEX`, and launches AI coding tools inside WSL with a consistent workflow.

## What It Is

This repository publishes one portable launcher file:

- `syta-super-launcher.bat`

That file embeds its own runtime helpers and extracts them to a temporary folder at launch time. The extracted files are only runtime helpers. The real tools are installed in the user's Windows or WSL environment, not in the temporary extraction folder.

## Main Goals

The launcher is built to make a WSL-based AI coding setup easier to use.

It can:

- create and open project folders under `C:\.CODEX`
- launch multiple AI coding CLIs from a unified menu
- install missing tools
- run light or full update flows
- keep recent projects
- surface diagnostic hints before launch

## Main Modes

### Code

Creates or opens a project folder in `C:\.CODEX`, then launches one of these tools inside WSL:

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

Before launching, the UI shows a preflight panel with:

- project path
- detected install state
- version detection
- auth/config hint
- resolved binary or config path

### Install

Installs or repairs the environment.

Current install targets include:

- `WSL Ubuntu`
- `PowerShell 7`
- `Install all AI CLI tools`
- `Codex CLI`
- `OpenCode`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `Oh My OpenCode Slim`

For Node-based tooling, the installer prefers `nvm` and tries to preserve an existing Node version instead of blindly switching users to a fresh version that would hide previously installed global CLIs.

The installer also tries to repair a common Linux runtime dependency issue by installing `libatomic1` on apt-based systems when required.

### Light Update

Updates AI coding CLIs only:

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

### Update All

Runs a broader toolchain update pass, including:

- `apt`
- `Homebrew`
- `npm`
- `pnpm`
- `pipx`
- `uv`
- `rustup`
- `cargo-install-update`
- `dotnet` global tools

## Project Root

The launcher always uses:

```text
C:\.CODEX
```

If that folder does not exist, it creates it automatically.

Recent projects are stored here:

```text
C:\.CODEX\.syta-launcher-state.json
```

## How It Works

At startup, `syta-super-launcher.bat` extracts embedded helper scripts to a unique temporary runtime folder.

That runtime then powers:

- the interactive UI
- the installer flows
- the updater flows
- the WSL session bridge
- the diagnostics layer

This means the launcher stays portable while still acting like a small application.

## Requirements

Recommended environment:

- Windows 10 or Windows 11
- WSL available
- Ubuntu in WSL
- Windows Terminal recommended

The intended experience is:

- Windows-side launcher
- Linux-side tooling in WSL
- user-level installs inside the WSL home directory

## Installation Behavior

### WSL Tooling

Linux-side tools are installed into the user's WSL environment.

Examples:

- `nvm` under `~/.nvm`
- npm global CLIs inside the active `nvm` Node version
- OpenCode-related config under `~/.config/opencode`

They are not installed into the temporary launcher extraction folder.

### Node and npm

The installer uses `nvm` where possible.

Important detail:

- global npm CLIs are tied to the active Node version
- switching Node versions can make existing CLIs appear to disappear

Because of that, the launcher now tries to preserve and reuse the current/default `nvm` version before installing or updating npm-based tools.

### OpenCode

OpenCode is handled separately because it may be installed through its own installer path or end up configured without a runnable binary on `PATH`.

The launcher tries to detect the difference between:

- `Installed`
- `Configured only`
- `Missing`

## Diagnostics

The UI includes a diagnostics layer that tries to show:

- whether a tool appears installed
- detected version
- auth/config hints
- install source such as `nvm`, `system`, `user-local`, or `config-only`

These diagnostics are heuristic, not perfect provider-auth verification.

They are intended to be useful and practical rather than authoritative.

## PowerShell 7

The launcher includes a Windows-side PowerShell 7 installer path.

That path is intended to:

- install PowerShell 7 through `winget`
- verify `pwsh.exe`
- set Windows Terminal `defaultProfile` to `PowerShell`

## Build Stamp

The launcher exposes a visible build id in the UI and in `SmokeTest`, so users can confirm they are really running the latest file.

## Why Only One File

The point of this repository is portability.

Instead of publishing a folder full of helper scripts, the runtime is embedded into a single launcher file so it can be copied and shared more easily.

## Limitations

Current known limitations:

- diagnostics are still heuristic
- some install/update paths depend on the target system having the expected Windows and WSL components available
- `super.ps1` is not published here because this repo intentionally focuses on the single-file launcher experience

## Usage

1. Download `syta-super-launcher.bat`.
2. Double-click it.
3. Choose a mode.
4. Follow the interactive menus.

## Author

Made by Sylvain T.

## License

No license file is included yet.

If you want to publish this broadly, add an explicit license.
