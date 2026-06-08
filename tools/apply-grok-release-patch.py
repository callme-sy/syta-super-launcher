#!/usr/bin/env python3
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes in data:
            new_bytes = new.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in old_bytes else new.encode("utf-8")
            return data.replace(old_bytes, new_bytes, 1)
    raise SystemExit(f"Pattern not found ({label}):\n{old[:160]}...")


def main() -> None:
    data = BAT.read_bytes()

    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-05-01-154055Z"',
        'set "SYTA_BUILD_ID=SYTA-build-2026-06-08-112723Z"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-05-01-154055Z'",
        ":: $script:BuildId = 'SYTA-build-2026-06-08-112723Z'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.10.4'",
        ":: $script:ReleaseTag = 'v1.10.5'",
        "ReleaseTag",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli')]",
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli')]",
        "Agent ValidateSet",
    )
    data = replace_once(
        data,
        "'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "Install ValidateSet",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'all')]",
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'all')]",
        "Reset ValidateSet",
    )
    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'droid-cli'
::         Title = 'DROID CLI | optional'
::         Subtitle = 'Useful if you already use DROID.'
::         Accent = 'DarkCyan'
::         WindowTitle = 'DROID CLI'
::     }
:: )
:: $script:ToolSpecs = @{""",
        """::     [pscustomobject]@{
::         Key = 'droid-cli'
::         Title = 'DROID CLI | optional'
::         Subtitle = 'Useful if you already use DROID.'
::         Accent = 'DarkCyan'
::         WindowTitle = 'DROID CLI'
::     }
::     [pscustomobject]@{
::         Key = 'grok-cli'
::         Title = 'Grok CLI | optional'
::         Subtitle = 'Useful if you want xAI Grok in the terminal.'
::         Accent = 'DarkGreen'
::         WindowTitle = 'Grok CLI'
::     }
:: )
:: $script:ToolSpecs = @{""",
        "AgentOptions grok",
    )
    data = replace_once(
        data,
        """::     'droid-cli' = [pscustomobject]@{
::         Command = 'droid'
::         VersionScript = 'droid --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${FACTORY_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.factory" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> DROID CLI.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        """::     'droid-cli' = [pscustomobject]@{
::         Command = 'droid'
::         VersionScript = 'droid --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${FACTORY_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.factory" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> DROID CLI.'
::     }
::     'grok-cli' = [pscustomobject]@{
::         Command = 'grok'
::         VersionScript = 'grok --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${GROK_DEPLOYMENT_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.grok/auth.json" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Grok CLI.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        "ToolSpecs grok",
    )
    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "Warm diagnostics",
    )
    data = replace_once(
        data,
        "::         $droidDiag = Get-ToolDiagnostics -Key 'droid-cli'",
        "::         $droidDiag = Get-ToolDiagnostics -Key 'droid-cli'\n::         $grokDiag = Get-ToolDiagnostics -Key 'grok-cli'",
        "Get droid diag",
    )
    data = replace_once(
        data,
        "::         $droidDiag = New-WslMissingToolDiagnostics -Key 'droid-cli' -SetupIncomplete:$setupIncomplete",
        "::         $droidDiag = New-WslMissingToolDiagnostics -Key 'droid-cli' -SetupIncomplete:$setupIncomplete\n::         $grokDiag = New-WslMissingToolDiagnostics -Key 'grok-cli' -SetupIncomplete:$setupIncomplete",
        "New droid diag",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'DROID CLI | optional'; Subtitle = $droidDiag.MenuText; Accent = if ($droidDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'droid-cli'; DiagnosticMode = $droidDiag.DiagnosticMode }",
        "::         [pscustomobject]@{ Title = 'DROID CLI | optional'; Subtitle = $droidDiag.MenuText; Accent = if ($droidDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'droid-cli'; DiagnosticMode = $droidDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = $grokDiag.MenuText; Accent = if ($grokDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'grok-cli'; DiagnosticMode = $grokDiag.DiagnosticMode }",
        "Install menu grok",
    )
    data = replace_once(
        data,
        "::         'droid-cli' = [pscustomobject]@{ Title = 'DROID CLI | optional'; Subtitle = 'Install or repair DROID CLI.'; Accent = 'Cyan'; Key = 'droid-cli' }",
        "::         'droid-cli' = [pscustomobject]@{ Title = 'DROID CLI | optional'; Subtitle = 'Install or repair DROID CLI.'; Accent = 'Cyan'; Key = 'droid-cli' }\n::         'grok-cli' = [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = 'Install or repair Grok CLI.'; Accent = 'Cyan'; Key = 'grok-cli' }",
        "Resolve install grok",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'DROID'; Key = 'droid-cli' }",
        "::         [pscustomobject]@{ Label = 'DROID'; Key = 'droid-cli' }\n::         [pscustomobject]@{ Label = 'Grok'; Key = 'grok-cli' }",
        "Coding summary grok",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Gemini CLI configs'; Subtitle = 'Remove tracked Gemini and Google AI config folders.'; Accent = 'Blue'; Key = 'gemini-cli' }",
        "::         [pscustomobject]@{ Title = 'Gemini CLI configs'; Subtitle = 'Remove tracked Gemini and Google AI config folders.'; Accent = 'Blue'; Key = 'gemini-cli' }\n::         [pscustomobject]@{ Title = 'DROID CLI configs'; Subtitle = 'Remove tracked DROID CLI config folder.'; Accent = 'DarkCyan'; Key = 'droid-cli' }\n::         [pscustomobject]@{ Title = 'Grok CLI configs'; Subtitle = 'Remove tracked Grok CLI auth and config files.'; Accent = 'DarkGreen'; Key = 'grok-cli' }",
        "Reset menu items",
    )
    data = replace_once(
        data,
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "wslRequiredKeys",
    )
    data = replace_once(
        data,
        "::             'Remove tracked Gemini and Google AI config folders.' = '删除已跟踪的 Gemini 和 Google AI 配置目录。'",
        "::             'Remove tracked Gemini and Google AI config folders.' = '删除已跟踪的 Gemini 和 Google AI 配置目录。'\n::             'DROID CLI configs' = 'DROID CLI 配置'\n::             'Remove tracked DROID CLI config folder.' = '删除已跟踪的 DROID CLI 配置目录。'\n::             'Grok CLI configs' = 'Grok CLI 配置'\n::             'Remove tracked Grok CLI auth and config files.' = '删除已跟踪的 Grok CLI 认证和配置文件。'",
        "zh reset labels",
    )
    data = replace_once(
        data,
        "::             'Remove tracked Gemini and Google AI config folders.' = 'Supprimer les dossiers de config suivis de Gemini et Google AI.'",
        "::             'Remove tracked Gemini and Google AI config folders.' = 'Supprimer les dossiers de config suivis de Gemini et Google AI.'\n::             'DROID CLI configs' = 'Configs DROID CLI'\n::             'Remove tracked DROID CLI config folder.' = 'Supprimer le dossier de config suivi de DROID CLI.'\n::             'Grok CLI configs' = 'Configs Grok CLI'\n::             'Remove tracked Grok CLI auth and config files.' = 'Supprimer les fichiers auth/config suivis de Grok CLI.'",
        "fr reset labels",
    )

    path_line = '::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"'
    path_insert = '::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"\n' + path_line
    if b'[ -d "$HOME/.grok/bin" ]' not in data:
        for _ in range(6):
            data = replace_once(data, path_line, path_insert, "load_user_env grok path")

    data = replace_once(
        data,
        """::     droid-cli)
::       command_name='droid'
::       [ -n "${FACTORY_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -d "$HOME/.factory" ] && auth='config-present'
::       ;;
::     utility-rtk)""",
        """::     droid-cli)
::       command_name='droid'
::       [ -n "${FACTORY_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -d "$HOME/.factory" ] && auth='config-present'
::       ;;
::     grok-cli)
::       command_name='grok'
::       [ -n "${GROK_DEPLOYMENT_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.grok/auth.json" ] && auth='config-present'
::       ;;
::     utility-rtk)""",
        "diagnostics grok-cli",
    )

    for old, new, label in [
        (
            "::         droid_missing) printf 'droid n''est pas disponible dans le PATH.\\n' ;;",
            "::         droid_missing) printf 'droid n''est pas disponible dans le PATH.\\n' ;;\n::         grok_missing) printf 'grok n''est pas disponible dans le PATH.\\n' ;;",
            "fr grok missing",
        ),
        (
            "::         launch_droid) printf 'Lancement de DROID CLI...\\n\\n' ;;",
            "::         launch_droid) printf 'Lancement de DROID CLI...\\n\\n' ;;\n::         launch_grok) printf 'Lancement de Grok CLI...\\n\\n' ;;",
            "fr launch grok",
        ),
        (
            "::         droid_missing) printf 'PATH 中没有 droid。\\n' ;;",
            "::         droid_missing) printf 'PATH 中没有 droid。\\n' ;;\n::         grok_missing) printf 'PATH 中没有 grok。\\n' ;;",
            "zh grok missing",
        ),
        (
            "::         launch_droid) printf '正在启动 DROID CLI...\\n\\n' ;;",
            "::         launch_droid) printf '正在启动 DROID CLI...\\n\\n' ;;\n::         launch_grok) printf '正在启动 Grok CLI...\\n\\n' ;;",
            "zh launch grok",
        ),
        (
            "::         droid_missing) printf 'droid is not available in PATH.\\n' ;;",
            "::         droid_missing) printf 'droid is not available in PATH.\\n' ;;\n::         grok_missing) printf 'grok is not available in PATH.\\n' ;;",
            "en grok missing",
        ),
        (
            "::         launch_droid) printf 'Launching DROID CLI...\\n\\n' ;;",
            "::         launch_droid) printf 'Launching DROID CLI...\\n\\n' ;;\n::         launch_grok) printf 'Launching Grok CLI...\\n\\n' ;;",
            "en launch grok",
        ),
    ]:
        data = replace_once(data, old, new, label)

    data = replace_once(
        data,
        """::     droid-cli)
::       if ! command -v droid >/dev/null 2>&1; then msg droid_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_droid; droid ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        """::     droid-cli)
::       if ! command -v droid >/dev/null 2>&1; then msg droid_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_droid; droid ;;
::     grok-cli)
::       if ! command -v grok >/dev/null 2>&1; then msg grok_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_grok; grok ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        "run_agent grok",
    )
    data = replace_once(
        data,
        """:: gemini-cli|Gemini CLI config directory|dir|~/.config/gemini
:: gemini-cli|Google AI config directory|dir|~/.config/google
:: EOF""",
        """:: gemini-cli|Gemini CLI config directory|dir|~/.config/gemini
:: gemini-cli|Google AI config directory|dir|~/.config/google
:: droid-cli|DROID CLI config directory|dir|~/.factory
:: grok-cli|Grok CLI auth|file|~/.grok/auth.json
:: grok-cli|Grok CLI config|file|~/.grok/config.toml
:: grok-cli|Grok CLI managed config|file|~/.grok/managed_config.toml
:: grok-cli|Grok CLI requirements|file|~/.grok/requirements.toml
:: EOF""",
        "reset_config_specs",
    )
    data = replace_once(
        data,
        """:: install_droid_cli() {
::   ensure_curl || return 1
::   run_step "Install DROID CLI" bash -lc 'curl -fsSL https://app.factory.ai/cli | sh' || return 1
::   load_user_env
::   if command -v droid >/dev/null 2>&1; then
::     droid --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'DROID CLI install finished but droid is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        """:: install_droid_cli() {
::   ensure_curl || return 1
::   run_step "Install DROID CLI" bash -lc 'curl -fsSL https://app.factory.ai/cli | sh' || return 1
::   load_user_env
::   if command -v droid >/dev/null 2>&1; then
::     droid --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'DROID CLI install finished but droid is still not on PATH.
:: '
::   return 1
:: }
::
:: install_grok_cli() {
::   ensure_curl || return 1
::   run_step "Install Grok CLI" bash -lc 'curl -fsSL https://x.ai/cli/install.sh | bash' || return 1
::   load_user_env
::   if command -v grok >/dev/null 2>&1; then
::     grok --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'Grok CLI install finished but grok is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        "install_grok_cli",
    )
    data = replace_once(
        data,
        "::   droid-cli) install_droid_cli || status=$? ;;",
        "::   droid-cli) install_droid_cli || status=$? ;;\n::   grok-cli) install_grok_cli || status=$? ;;",
        "install switch grok",
    )
    data = replace_once(
        data,
        ":: for tool in codex omx opencode kilo claude gemini droid npm npx; do",
        ":: for tool in codex omx opencode kilo claude gemini droid grok npm npx; do",
        "update tool list",
    )
    data = replace_once(
        data,
        """::   if have_cmd droid; then
::     run_step "Update DROID CLI" bash -lc 'curl -fsSL https://app.factory.ai/cli | sh' || true
::   else
::     echo
::     echo "== Update DROID CLI =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        """::   if have_cmd droid; then
::     run_step "Update DROID CLI" bash -lc 'curl -fsSL https://app.factory.ai/cli | sh' || true
::   else
::     echo
::     echo "== Update DROID CLI =="
::     echo SKIPPED
::   fi
::
::   if have_cmd grok; then
::     run_step "Update Grok CLI" bash -lc 'curl -fsSL https://x.ai/cli/install.sh | bash' || true
::   else
::     echo
::     echo "== Update Grok CLI =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        "update grok",
    )

    BAT.write_bytes(data)
    print(f"Updated {BAT}")


if __name__ == "__main__":
    main()
