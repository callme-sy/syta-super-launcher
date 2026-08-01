## Summary

- **Startup update cache**: no longer force-refreshes GitHub when the launcher is already up to date (respects the 6h release cache).
- **Honest fast diagnostics**: batch misses now show **Check unavailable** instead of falsely reporting tools as Missing.
- **Code preflight gate**: launching an agent that is not installed offers Install / pick another agent / launch anyway instead of blindly opening WSL.
- **Aligned PATH/nvm**: run-agent and all update scripts now use `nvm_preferred_target` like the installer.
- **WSL/diag hygiene**: install menu refreshes WSL readiness probe; diagnostic stderr is captured and surfaced on fallback.
- **Cleaner + auth**: PATH duplicate scan includes droid/grok/rtk; Codex/OMX also detect `~/.codex/auth.json`.
- **Runtime cache**: prunes old extracted build dirs; readiness gate also checks install/run-agent scripts.

## Test plan

- [x] `tests/launcher-settings-smoke.ps1`
- [x] Parent `super.bat` synced to `syta-super-launcher.bat`
