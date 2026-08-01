## Summary

- **Pi**: add the minimal extensible coding agent from [pi.dev](https://pi.dev) across Code, Install, Light update, Cleaner, and Reset tool configs.
- **Install Pi**: `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` in WSL (nvm-aware).
- **OMP**: add Oh My Pi from [omp.sh](https://omp.sh) as a batteries-included Pi fork across the same menus.
- **Install OMP**: official `curl -fsSL https://omp.sh/install | sh` with npm fallback `@oh-my-pi/pi-coding-agent`.
- **OMX deprecated**: keep launch/repair/light-update for existing installs, but mark Code/Install entries as deprecated and steer users to Codex, Pi, or OMP.
- Docs updated in EN / FR / ZH.

## Test plan

- [x] `tests/launcher-settings-smoke.ps1`
- [x] Code dry-run includes `pi` and `omp`; OMX titled deprecated
- [x] Parent `super.bat` synced to `syta-super-launcher.bat`
