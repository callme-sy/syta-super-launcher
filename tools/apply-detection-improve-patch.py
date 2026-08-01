#!/usr/bin/env python3
from datetime import datetime, timezone
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = datetime.now(timezone.utc).strftime("SYTA-build-%Y-%m-%d-%H%M%SZ")
RELEASE_TAG = "v1.11.1"


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes in data:
            new_bytes = (
                new.replace("\n", "\r\n").encode("utf-8")
                if b"\r\n" in old_bytes
                else new.encode("utf-8")
            )
            return data.replace(old_bytes, new_bytes, 1)
    raise SystemExit(f"Pattern not found ({label}):\n{old[:240]}...")


def main() -> None:
    data = BAT.read_bytes()
    if b"is_linux_cli_path()" in data and b"resolve_tool_binary()" in data:
        raise SystemExit("detection improvements already present")

    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-08-01-104535Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-08-01-104535Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.11.0'",
        f":: $script:ReleaseTag = '{RELEASE_TAG}'",
        "ReleaseTag",
    )

    # Rewrite diagnostics discovery helpers
    data = replace_once(
        data,
        """:: prepend_known_cli_paths() {
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
:: }
::
:: SYTA_NVM_BIN_DIRS_READY=0
:: SYTA_NVM_BIN_DIRS=()
::
:: prepare_nvm_binary_dirs() {
::   [ "$SYTA_NVM_BIN_DIRS_READY" = '1' ] && return 0
::   SYTA_NVM_BIN_DIRS_READY=1
::   local root="${NVM_DIR:-$HOME/.nvm}/versions/node"
::   local version
::   [ -d "$root" ] || return 0
::   while IFS= read -r version; do
::     [ -n "$version" ] && SYTA_NVM_BIN_DIRS+=("$root/$version/bin")
::   done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null | sort -Vr)
:: }
::
:: find_nvm_binary() {
::   local name="$1"
::   local dir
::   prepare_nvm_binary_dirs
::   for dir in "${SYTA_NVM_BIN_DIRS[@]}"; do
::     if [ -x "$dir/$name" ]; then
::       printf '%s\\n' "$dir/$name"
::       return 0
::     fi
::   done
::   return 1
:: }
::
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
:: }""",
        """:: prepend_known_cli_paths() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.omp/bin:$HOME/.pi/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -d "$HOME/.volta/bin" ] && export PATH="$HOME/.volta/bin:$PATH"
::   [ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"
::   [ -d "$HOME/.local/share/fnm" ] && export PATH="$HOME/.local/share/fnm:$PATH"
::   [ -d "$HOME/.npm-global/bin" ] && export PATH="$HOME/.npm-global/bin:$PATH"
::   prepend_nvm_bin_dirs
:: }
::
:: SYTA_NVM_BIN_DIRS_READY=0
:: SYTA_NVM_BIN_DIRS=()
::
:: prepare_nvm_binary_dirs() {
::   [ "$SYTA_NVM_BIN_DIRS_READY" = '1' ] && return 0
::   SYTA_NVM_BIN_DIRS_READY=1
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   local root="$NVM_DIR/versions/node"
::   local version default_alias default_target
::   [ -d "$root" ] || return 0
::   default_alias="$(cat "$NVM_DIR/alias/default" 2>/dev/null || true)"
::   if [ -n "$default_alias" ] && [ -d "$root/$default_alias/bin" ]; then
::     SYTA_NVM_BIN_DIRS+=("$root/$default_alias/bin")
::   elif [ -n "$default_alias" ]; then
::     default_target="$(cat "$NVM_DIR/alias/$default_alias" 2>/dev/null || true)"
::     [ -n "$default_target" ] && [ -d "$root/$default_target/bin" ] && SYTA_NVM_BIN_DIRS+=("$root/$default_target/bin")
::   fi
::   while IFS= read -r version; do
::     [ -n "$version" ] || continue
::     [ -d "$root/$version/bin" ] || continue
::     case " ${SYTA_NVM_BIN_DIRS[*]} " in
::       *" $root/$version/bin "*) continue ;;
::     esac
::     SYTA_NVM_BIN_DIRS+=("$root/$version/bin")
::   done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null | sort -Vr)
:: }
::
:: prepend_nvm_bin_dirs() {
::   local dir count=0
::   prepare_nvm_binary_dirs
::   for dir in "${SYTA_NVM_BIN_DIRS[@]}"; do
::     [ -d "$dir" ] || continue
::     case ":$PATH:" in
::       *":$dir:"*) ;;
::       *) export PATH="$dir:$PATH" ;;
::     esac
::     count=$((count + 1))
::     [ "$count" -ge 4 ] && break
::   done
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
::   prepend_known_cli_paths
::   hash -r 2>/dev/null || true
:: }
::
:: is_linux_cli_path() {
::   local candidate="$1"
::   case "$candidate" in
::     '') return 1 ;;
::     /mnt/[a-zA-Z]/*) return 1 ;;
::     *.exe|*.bat|*.cmd|*.COM|*.EXE|*.BAT|*.CMD) return 1 ;;
::     */Windows/*|*/windows/*|*/System32/*|*/system32/*) return 1 ;;
::   esac
::   [ -x "$candidate" ] || [ -L "$candidate" ] || return 1
::   return 0
:: }
::
:: find_nvm_binary() {
::   local name="$1"
::   local dir
::   prepare_nvm_binary_dirs
::   for dir in "${SYTA_NVM_BIN_DIRS[@]}"; do
::     if [ -x "$dir/$name" ] || [ -L "$dir/$name" ]; then
::       printf '%s\\n' "$dir/$name"
::       return 0
::     fi
::   done
::   return 1
:: }
::
:: resolve_binary_path() {
::   local name="$1"
::   local candidate
::   if command -v "$name" >/dev/null 2>&1; then
::     candidate="$(command -v "$name" 2>/dev/null || true)"
::     if is_linux_cli_path "$candidate"; then
::       printf '%s\\n' "$candidate"
::       return 0
::     fi
::   fi
::   for candidate in \\
::     "$HOME/.omp/bin/$name" \\
::     "$HOME/.pi/bin/$name" \\
::     "$HOME/.grok/bin/$name" \\
::     "$HOME/.opencode/bin/$name" \\
::     "$HOME/.local/bin/$name" \\
::     "$HOME/bin/$name" \\
::     "$HOME/.cargo/bin/$name" \\
::     "$HOME/.volta/bin/$name" \\
::     "$HOME/.asdf/shims/$name" \\
::     "$HOME/.npm-global/bin/$name"; do
::     if is_linux_cli_path "$candidate"; then
::       printf '%s\\n' "$candidate"
::       return 0
::     fi
::   done
::   candidate="$(find_nvm_binary "$name" 2>/dev/null || true)"
::   if is_linux_cli_path "$candidate"; then
::     printf '%s\\n' "$candidate"
::     return 0
::   fi
::   return 1
:: }
::
:: resolve_tool_binary() {
::   local name candidate
::   for name in "$@"; do
::     [ -n "$name" ] || continue
::     candidate="$(resolve_binary_path "$name" 2>/dev/null || true)"
::     if is_linux_cli_path "$candidate"; then
::       printf '%s\\n' "$candidate"
::       return 0
::     fi
::   done
::   return 1
:: }""",
        "diagnostics helpers rewrite",
    )

    # Fix multi-name tools: don't pick Windows cmd via command -v
    data = replace_once(
        data,
        """::     command-code)
::       if command -v command-code >/dev/null 2>&1; then
::         command_name='command-code'
::       elif command -v cmd >/dev/null 2>&1; then
::         command_name='cmd'
::       else
::         command_name='command-code'
::       fi
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.commandcode/auth.json" ] || [ -d "$HOME/.commandcode" ]; } && auth='config-present'
::       ;;
::     reasonix)
::       if command -v reasonix >/dev/null 2>&1; then
::         command_name='reasonix'
::       elif command -v dsnix >/dev/null 2>&1; then
::         command_name='dsnix'
::       else
::         command_name='reasonix'
::       fi
::       [ -n "${DEEPSEEK_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.reasonix/config.json" ] || [ -f "$HOME/.reasonix/config.toml" ] || [ -d "$HOME/.reasonix" ]; } && auth='config-present'
::       ;;""",
        """::     command-code)
::       command_name='command-code'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.commandcode/auth.json" ] || [ -d "$HOME/.commandcode" ]; } && auth='config-present'
::       ;;
::     reasonix)
::       command_name='reasonix'
::       [ -n "${DEEPSEEK_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.reasonix/config.json" ] || [ -f "$HOME/.reasonix/config.toml" ] || [ -d "$HOME/.reasonix" ]; } && auth='config-present'
::       ;;""",
        "command-code reasonix cases",
    )

    # Resolve binaries with multi-name support + reject bad paths + better version scrape
    data = replace_once(
        data,
        """::   if [ -n "$command_name" ]; then
::     path="$(resolve_binary_path "$command_name" 2>/dev/null || true)"
::     [ -n "$path" ] && installed=1
::
::     if [ "$installed" -eq 1 ]; then
::       case "$path" in
::         *"/.nvm/"*) install_source='nvm' ;;
::         *"/.local/"*|*"/bin/"*) install_source='user' ;;
::         /usr/*|/bin/*|/sbin/*) install_source='system' ;;
::         *) install_source='custom' ;;
::       esac
::     fi
::   fi
::
::   if { [ "$key" = 'oh-my-opencode-slim' ] || [ "$key" = 'oh-my-openagent' ] || [ "$key" = 'utility-superpowers' ]; } && [ -n "$config" ]; then
::     installed=1
::     path="$config"
::     install_source='config'
::   fi
::
::   if [ "$installed" -eq 1 ] && [ -n "$command_name" ] && [ -x "$path" ]; then
::     if [ "$diagnostic_mode" = 'fast' ]; then
::       version_deferred=1
::     else
::       version="$($path --version 2>/dev/null | head -n 1)"
::     fi
::   fi""",
        """::   if [ -n "$command_name" ]; then
::     case "$key" in
::       command-code) path="$(resolve_tool_binary command-code cmd 2>/dev/null || true)" ;;
::       reasonix) path="$(resolve_tool_binary reasonix dsnix 2>/dev/null || true)" ;;
::       *) path="$(resolve_binary_path "$command_name" 2>/dev/null || true)" ;;
::     esac
::     if is_linux_cli_path "$path"; then
::       installed=1
::       command_name="$(basename "$path")"
::     else
::       path=''
::       installed=0
::     fi
::
::     if [ "$installed" -eq 1 ]; then
::       case "$path" in
::         *"/.nvm/"*) install_source='nvm' ;;
::         *"/.volta/"*|*"/.asdf/"*|*"/.npm-global/"*) install_source='user' ;;
::         *"/.local/"*|*"/.omp/"*|*"/.pi/"*|*"/bin/"*) install_source='user' ;;
::         /usr/*|/bin/*|/sbin/*) install_source='system' ;;
::         *) install_source='custom' ;;
::       esac
::     fi
::   fi
::
::   if { [ "$key" = 'oh-my-opencode-slim' ] || [ "$key" = 'oh-my-openagent' ] || [ "$key" = 'utility-superpowers' ]; } && [ -n "$config" ]; then
::     installed=1
::     path="$config"
::     install_source='config'
::   fi
::
::   if [ "$installed" -eq 1 ] && [ -n "$command_name" ] && { [ -x "$path" ] || [ -L "$path" ]; }; then
::     if [ "$diagnostic_mode" = 'fast' ]; then
::       version_deferred=1
::     else
::       version="$($path --version 2>/dev/null | head -n 5 | sed -n 's/\\r$//; /^$/d; /[Uu]pdated/d; /→/d; /->/d; p' | head -n 1)"
::       if [ -z "$version" ]; then
::         version="$($path -V 2>/dev/null | head -n 1 | tr -d '\\r')"
::       fi
::       if [ -z "$version" ]; then
::         version="$($path version 2>/dev/null | head -n 1 | tr -d '\\r')"
::       fi
::     fi
::   fi""",
        "resolve + version improve",
    )

    # Align run-agent PATH bootstrap with known CLI dirs + nvm bins before profile
    data = replace_once(
        data,
        """:: load_user_env() {
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
::     fi""",
        """:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.omp/bin:$HOME/.pi/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -d "$HOME/.volta/bin" ] && export PATH="$HOME/.volta/bin:$PATH"
::   [ -d "$HOME/.npm-global/bin" ] && export PATH="$HOME/.npm-global/bin:$PATH"
::   if [ -d "${NVM_DIR:-$HOME/.nvm}/versions/node" ]; then
::     local _syta_nvm_bin
::     _syta_nvm_bin="$(find "${NVM_DIR:-$HOME/.nvm}/versions/node" -mindepth 2 -maxdepth 2 -type d -name bin 2>/dev/null | sort -Vr | head -n 3)"
::     while IFS= read -r _syta_line; do
::       [ -n "$_syta_line" ] && export PATH="$_syta_line:$PATH"
::     done <<< "$_syta_nvm_bin"
::   fi
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
::     fi""",
        "run-agent load_user_env",
    )

    # Fix command-code / reasonix launch to resolve aliases without Windows cmd false hit
    data = replace_once(
        data,
        """::     command-code)
::       if command -v command-code >/dev/null 2>&1; then
::         msg launch_command_code; command-code
::       elif command -v cmd >/dev/null 2>&1; then
::         msg launch_command_code; cmd
::       else
::         msg command_code_missing; msg current_path "$PATH"; return 127
::       fi ;;
::     reasonix)
::       if command -v reasonix >/dev/null 2>&1; then
::         msg launch_reasonix; reasonix
::       elif command -v dsnix >/dev/null 2>&1; then
::         msg launch_reasonix; dsnix
::       else
::         msg reasonix_missing; msg current_path "$PATH"; return 127
::       fi ;;""",
        """::     command-code)
::       if command -v command-code >/dev/null 2>&1; then
::         msg launch_command_code; command-code
::       else
::         _syta_cmd_alias="$(command -v cmd 2>/dev/null || true)"
::         case "${_syta_cmd_alias:-}" in
::           ''|/mnt/[a-zA-Z]/*|*.exe|*/System32/*|*/system32/*) _syta_cmd_alias='' ;;
::         esac
::         if [ -n "${_syta_cmd_alias:-}" ]; then
::           msg launch_command_code; cmd
::         else
::           msg command_code_missing; msg current_path "$PATH"; return 127
::         fi
::       fi ;;
::     reasonix)
::       if command -v reasonix >/dev/null 2>&1; then
::         msg launch_reasonix; reasonix
::       elif command -v dsnix >/dev/null 2>&1; then
::         msg launch_reasonix; dsnix
::       else
::         msg reasonix_missing; msg current_path "$PATH"; return 127
::       fi ;;""",
        "run-agent command-code launch",
    )

    BAT.write_bytes(data)
    print(f"Updated {BAT}")
    print(f"BuildId={BUILD_ID}")
    print(f"ReleaseTag={RELEASE_TAG}")


if __name__ == "__main__":
    main()
