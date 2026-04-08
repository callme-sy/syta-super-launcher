# SYTA Super Launcher

Single-file Windows launcher for a WSL-first AI coding setup.

`syta-super-launcher.bat` gives you one interactive command deck for creating projects, launching coding agents, installing missing tools, and running update flows from a consistent Windows + WSL workflow.

## Highlights

- Single-file distribution: one `.bat`, no helper files to ship
- WSL-first workflow: projects live under `C:\.CODEX`
- Interactive launcher UI with diagnostics and recent projects
- Built-in install flows for major AI coding CLIs
- Light and full update modes
- Portable runtime: embedded helpers extract to `%TEMP%` at launch time

## Included Modes

| Mode | Purpose |
| --- | --- |
| `Code` | Create/open a project and launch a coding CLI in WSL |
| `Install` | Install or repair WSL, PowerShell, and supported AI tools |
| `Light update` | Update AI coding CLIs only |
| `Update all` | Run a broader toolchain update pass |

## Supported Coding Tools

From the `Code` menu, the launcher can start:

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

From the `Install` menu, the launcher supports:

- `WSL Ubuntu`
- `PowerShell 7`
- `Install all AI CLI tools`
- `Codex CLI`
- `OpenCode`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `Oh My OpenCode Slim`

## Project Root

The launcher always uses:

```text
C:\.CODEX
```

If it does not exist, it is created automatically.

Recent projects are stored in:

```text
C:\.CODEX\.syta-launcher-state.json
```

## How It Works

`syta-super-launcher.bat` embeds its runtime inside the batch file itself.

At launch it extracts helper scripts to a unique temporary runtime directory and runs from there. That temporary runtime is only for the launcher internals.

Actual tool installs happen in the user environment:

- Windows-side tools in Windows
- Linux-side tools in WSL
- Node-based CLIs typically under `nvm` in the WSL home directory

## Installation Philosophy

The launcher is designed to be practical on real machines, not just clean on paper.

Notable behavior:

- It prefers `nvm` for Node-based CLI installs.
- It tries to preserve the user’s existing/default Node version instead of blindly switching to a new one.
- It attempts to repair `libatomic.so.1` on apt-based systems when required for Node runtimes.
- It distinguishes between `Installed`, `Configured only`, and `Missing` where possible.

## Diagnostics

The UI surfaces preflight diagnostics before launch and install actions.

These diagnostics try to show:

- install state
- version detection
- auth/config hints
- install source, such as `nvm`, `system`, `user-local`, or `config-only`

These checks are heuristic by design. They are intended to be helpful and operationally useful, not a perfect provider-auth verification layer.

## Requirements

Recommended setup:

- Windows 10 or Windows 11
- WSL available
- Ubuntu in WSL
- Windows Terminal recommended

The launcher can repair some missing pieces, but the intended target environment is:

- Windows launcher on the host
- Linux-side coding tools inside WSL
- user-scoped installs where possible

## Quick Start

1. Download `syta-super-launcher.bat`.
2. Double-click it.
3. Choose `Install` first if your environment is incomplete.
4. Choose `Code` to create or open a project and launch a tool.

## Repository Scope

This repository intentionally stays minimal.

Published files:

- `syta-super-launcher.bat`
- `README.md`
- `README.fr.md`
- `LICENSE`

It does not publish the extracted helper scripts separately because the whole point is to keep distribution to a single launcher file.

## Author

Made by Sylvain T.

## License

MIT. See [LICENSE](./LICENSE).
