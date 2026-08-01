## Summary

- **Detection fix**: fast install-menu diagnostics now find nvm-installed CLIs (the main reason Command Code looked "Missing" after a correct install).
- **Smarter PATH scan**: prepends nvm/fnm/volta/asdf/omp/pi/npm-global bins without the slow full `nvm.sh` load in fast mode.
- **False positives blocked**: ignores Windows interop hits like `/mnt/c/Windows/System32/cmd.exe` when resolving Linux CLI aliases.
- **Multi-name tools**: Command Code resolves `command-code` then real `cmd` alias; Reasonix resolves `reasonix` then `dsnix`.
- **Cleaner versions**: filters update banners from `--version` output (e.g. Command Code now reports `1.7.0`).
- Launch PATH bootstrap aligned so agents started from SYTA see the same bins.

## Test plan

- [x] Fast diag: `command-code` → installed=1 via `~/.nvm/.../bin/command-code`
- [x] Full diag version: `1.7.0`
- [x] `tests/launcher-settings-smoke.ps1`
- [x] Parent `super.bat` synced
