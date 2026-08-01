## Summary

- **Reasonix**: add the DeepSeek-native coding agent from [DeepSeek-Reasonix](https://github.com/esengine/DeepSeek-Reasonix) across Code, Install, Light update, Cleaner, and Reset tool configs.
- **Install**: `npm install -g reasonix@latest` in WSL (nvm-aware).
- **Launch**: `reasonix` with fallback to the official `dsnix` alias.
- **Auth/config tracking**: `DEEPSEEK_API_KEY`, `~/.reasonix/config.json`, `~/.reasonix/config.toml`, and `~/.reasonix`.
- Docs updated in EN / FR / ZH.

## Test plan

- [x] `tests/launcher-settings-smoke.ps1`
- [x] Parent `super.bat` synced to `syta-super-launcher.bat`
