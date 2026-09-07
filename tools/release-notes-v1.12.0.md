## Summary

- **New: Zcode (Z.ai GLM toolkit)** — Code/Install/Update + reset support for the official `@z_ai/zai-cli` package (`zai-cli chat` launch, `ZAI_API_KEY` or `~/.zai/zai-cli/config.json` auth detection).
- **New: DSH (DeepSeek harness)** — Code/Install/Update + reset support for the official `@deepseek-ai/dsh` package (`dsh web` launch, `DEEPSEEK_API_KEY` or `~/.dsh` home detection).
- **New: Muse Code (Meta)** — Code/Install/Update + reset support via the verified official installer (`https://dev.meta.ai/install.sh` → `~/.local/bin/muse`, `muse login` or `META_API_KEY` auth, `~/.config/muse` config detection).
- **New utility: Patchright** — undetected Playwright drop-in (`npm i patchright` + `patchright install chromium`), handy when plain fetching gets blocked (e.g. stubborn 404s). Included in the utilities updater (package + driver refresh).
- **Removed: OMX fully retired** — the deprecated `oh-my-codex` lane is gone from Code/Install/Update/cleaner/diagnostics. Reset scope `codex-omx` renamed to `codex` (old name still accepted as an alias).
- **OpenCode goes official-first** — installs via `https://opencode.ai/install | bash` with npm fallback; light update picks the lane matching how OpenCode was installed (npm vs native `~/.opencode/bin`).
- **nvm 0.40.3 → 0.40.7**, Command Code now also resolves the `commandcode`/`cmdc` aliases (v1.50+ ships them).
- **Explanations rewritten** (EN/FR/ZH) — no more OMX; OMP/Pi are the heavier-orchestration lanes, plus Zcode/DSH/Muse Code guidance and a Patchright utilities entry. ~30 dead orphaned i18n strings removed.
- Install preflight now shows per-tool hints for Zcode/DSH/Muse Code (auth setup) and Patchright.

## Test plan

- [x] `bash -n` on all 7 embedded shell scripts (run inside WSL Ubuntu)
- [x] PowerShell parser check on all 4 embedded PS1 files
- [x] Live WSL fast diagnostics for `zcode dsh muse-code utility-patchright command-code` (detected a real `dsh` nvm install + `~/.dsh` config)
- [x] `tests/launcher-settings-smoke.ps1` — PASS (incl. new asserts: zcode/dsh/muse-code in Code menu, no omx-madmax-high, utility-patchright in utilities)
- [x] Parent `super.bat` synced
