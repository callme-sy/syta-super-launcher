#!/usr/bin/env python3
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = "SYTA-build-2026-06-08-120000Z"
RELEASE = "v1.10.6"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Pattern not found ({label})")
    return text.replace(old, new, 1)


def replace_all(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Pattern not found ({label})")
    return text.replace(old, new)


def main() -> None:
    text = BAT.read_text(encoding="utf-8")

    text = replace_once(
        text,
        'set "SYTA_BUILD_ID=SYTA-build-2026-06-08-112723Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "bat build id",
    )
    text = replace_once(
        text,
        ":: $script:BuildId = 'SYTA-build-2026-06-08-112723Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "ps build id",
    )
    text = replace_once(
        text,
        ":: $script:ReleaseTag = 'v1.10.5'",
        f":: $script:ReleaseTag = '{RELEASE}'",
        "release tag",
    )

    diag_marker = "::BEGIN:syta-tool-diagnostics.sh"
    diag_start = text.index(diag_marker)
    diag_end = text.index("::END:syta-tool-diagnostics.sh", diag_start)
    diag = text[diag_start:diag_end]

    old_diag_load = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     local def cur latest
::     def="$(nvm version default 2>/dev/null || true)"
::     case "$def" in ''|N/A|system) def='' ;; esac
::     cur="$(nvm current 2>/dev/null || true)"
::     case "$cur" in ''|none|system) cur='' ;; esac
::     if [ -n "$def" ]; then
::       nvm use "$def" >/dev/null 2>&1 || true
::     elif [ -n "$cur" ]; then
::       nvm use "$cur" >/dev/null 2>&1 || true
::     else
::       latest="$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -type d -printf '%f
:: ' 2>/dev/null | sort -V | tail -n 1)"
::       [ -n "$latest" ] && nvm use "$latest" >/dev/null 2>&1 || true
::     fi
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    new_diag_load = """:: prepend_known_cli_paths() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
:: }
::
:: load_user_env() {
::   prepend_known_cli_paths
::   if [ "${SYTA_DIAG_FAST:-0}" = '1' ]; then
::     hash -r 2>/dev/null || true
::     return 0
::   fi
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     local def cur latest
::     def="$(nvm version default 2>/dev/null || true)"
::     case "$def" in ''|N/A|system) def='' ;; esac
::     cur="$(nvm current 2>/dev/null || true)"
::     case "$cur" in ''|none|system) cur='' ;; esac
::     if [ -n "$def" ]; then
::       nvm use "$def" >/dev/null 2>&1 || true
::     elif [ -n "$cur" ]; then
::       nvm use "$cur" >/dev/null 2>&1 || true
::     else
::       latest="$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -type d -printf '%f
:: ' 2>/dev/null | sort -V | tail -n 1)"
::       [ -n "$latest" ] && nvm use "$latest" >/dev/null 2>&1 || true
::     fi
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    if old_diag_load not in diag:
        raise SystemExit("Diagnostics load_user_env block not found")
    diag = diag.replace(old_diag_load, new_diag_load, 1)

    resolve_helper = """::
:: resolve_binary_path() {
::   local name="$1"
::   local candidate
::   if command -v "$name" >/dev/null 2>&1; then
::     command -v "$name"
::     return 0
::   fi
::   for candidate in \\
::     "$HOME/.grok/bin/$name" \\
::     "$HOME/.local/bin/$name" \\
::     "$HOME/bin/$name" \\
::     "$HOME/.cargo/bin/$name"; do
::     if [ -x "$candidate" ]; then
::       printf '%s\\n' "$candidate"
::       return 0
::     fi
::   done
::   if [ "${SYTA_DIAG_FAST:-0}" != '1' ]; then
::     candidate="$(find_nvm_binary "$name" 2>/dev/null || true)"
::     if [ -n "$candidate" ]; then
::       printf '%s\\n' "$candidate"
::       return 0
::     fi
::   fi
::   return 1
:: }""".replace("\\n", "\n")

    find_nvm_tail = """::   return 1
:: }
::
:: print_kv() {"""
    if find_nvm_tail not in diag:
        raise SystemExit("find_nvm_binary tail not found")
    diag = diag.replace(find_nvm_tail, """::   return 1
:: }""" + resolve_helper + """
::
:: print_kv() {""", 1)

    diag = replace_once(
        diag,
        """::     grok-cli)
::       command_name='grok'
::       [ -n "${GROK_DEPLOYMENT_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.grok/auth.json" ] && auth='config-present'
::       ;;""",
        """::     grok-cli)
::       command_name='grok'
::       { [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; } && auth='config-present'
::       ;;""",
        "grok auth in diagnostics",
    )

    diag = replace_once(
        diag,
        """::   if [ -n "$command_name" ]; then
::     if command -v "$command_name" >/dev/null 2>&1; then
::       path="$(command -v "$command_name")"
::       installed=1
::     else
::       path="$(find_nvm_binary "$command_name" 2>/dev/null || true)"
::       [ -n "$path" ] && installed=1
::     fi""",
        """::   if [ -n "$command_name" ]; then
::     path="$(resolve_binary_path "$command_name" 2>/dev/null || true)"
::     [ -n "$path" ] && installed=1""",
        "resolve_binary_path usage",
    )

    text = text[:diag_start] + diag + text[diag_end:]

    text = replace_once(
        text,
        """::         AuthScript = 'if [ -n "${GROK_DEPLOYMENT_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.grok/auth.json" ]; then echo config-present; else echo not-detected; fi'""",
        """::         AuthScript = 'if [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; then echo config-present; else echo not-detected; fi'""",
        "grok toolspec auth",
    )

    light_load = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   hash -r 2>/dev/null || true
:: }"""

    light_load_new = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   hash -r 2>/dev/null || true
:: }"""

    run_marker = "::BEGIN:syta-run-agent.sh"
    run_start = text.index(run_marker)
    run_end = text.index("::END:syta-run-agent.sh", run_start)
    run = text[run_start:run_end]
    if light_load not in run:
        raise SystemExit("run-agent load_user_env not found")
    text = text[:run_start] + run.replace(light_load, light_load_new, 1) + text[run_end:]

    install_marker = "::BEGIN:syta-install-tool.sh"
    install_start = text.index(install_marker)
    install_end = text.index("::END:syta-install-tool.sh", install_start)
    install = text[install_start:install_end]

    install_load_old = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     # shellcheck source=/dev/null
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     local target
::     target="$(nvm_preferred_target 2>/dev/null || true)"
::     if [ -n "$target" ]; then
::       nvm use "$target" >/dev/null 2>&1 || true
::     fi
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    install_load_new = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     # shellcheck source=/dev/null
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     local target
::     target="$(nvm_preferred_target 2>/dev/null || true)"
::     if [ -n "$target" ]; then
::       nvm use "$target" >/dev/null 2>&1 || true
::     fi
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    if install_load_old not in install:
        raise SystemExit("install load_user_env not found")
    text = text[:install_start] + install.replace(install_load_old, install_load_new, 1) + text[install_end:]

    update_load_old = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     nvm use default >/dev/null 2>&1 || true
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    update_load_new = """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ -s "$NVM_DIR/nvm.sh" ]; then
::     . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
::     nvm use default >/dev/null 2>&1 || true
::   fi
::   hash -r 2>/dev/null || true
:: }"""

    text = replace_all(text, update_load_old, update_load_new, "update load_user_env")

    BAT.write_text(text, encoding="utf-8", newline="\r\n")
    print(f"Updated {BAT}")


if __name__ == "__main__":
    main()
