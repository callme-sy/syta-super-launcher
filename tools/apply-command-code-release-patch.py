#!/usr/bin/env python3
from datetime import datetime, timezone
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = datetime.now(timezone.utc).strftime("SYTA-build-%Y-%m-%d-%H%M%SZ")
RELEASE_TAG = "v1.10.8"


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes in data:
            new_bytes = new.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in old_bytes else new.encode("utf-8")
            return data.replace(old_bytes, new_bytes, 1)
    raise SystemExit(f"Pattern not found ({label}):\n{old[:200]}...")


def replace_all(data: bytes, old: str, new: str, label: str, expected: int | None = None) -> bytes:
    count = 0
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes not in data:
            continue
        new_bytes = new.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in old_bytes else new.encode("utf-8")
        occurrences = data.count(old_bytes)
        data = data.replace(old_bytes, new_bytes)
        count += occurrences
        break
    if count == 0:
        raise SystemExit(f"Pattern not found ({label}):\n{old[:200]}...")
    if expected is not None and count != expected:
        raise SystemExit(f"Expected {expected} replacements for {label}, got {count}")
    return data


def main() -> None:
    data = BAT.read_bytes()
    if b"command-code" in data and b"Key = 'command-code'" in data:
        raise SystemExit("command-code already present in bat")

    # Version bump
    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-06-08-231500Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-06-08-231500Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.10.7'",
        f":: $script:ReleaseTag = '{RELEASE_TAG}'",
        "ReleaseTag",
    )

    # ValidateSet params
    data = replace_once(
        data,
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli')]",
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code')]",
        "Agent ValidateSet",
    )
    data = replace_once(
        data,
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "Install ValidateSet",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'all')]",
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'all')]",
        "Reset ValidateSet",
    )

    # Light update copy EN/ZH/FR
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI。'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code。'",
        "zh light update",
    )
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.'",
        "fr light update",
    )
    data = replace_once(
        data,
        "::             'Grok CLI configs' = 'Grok CLI 配置'\n::             'Remove tracked Grok CLI auth and config files.' = '删除已跟踪的 Grok CLI 认证和配置文件。'",
        "::             'Grok CLI configs' = 'Grok CLI 配置'\n::             'Remove tracked Grok CLI auth and config files.' = '删除已跟踪的 Grok CLI 认证和配置文件。'\n::             'Command Code configs' = 'Command Code 配置'\n::             'Remove tracked Command Code auth and config files.' = '删除已跟踪的 Command Code 认证和配置文件。'",
        "zh reset labels",
    )
    data = replace_once(
        data,
        "::             'Grok CLI configs' = 'Configs Grok CLI'\n::             'Remove tracked Grok CLI auth and config files.' = 'Supprimer les fichiers auth/config suivis de Grok CLI.'",
        "::             'Grok CLI configs' = 'Configs Grok CLI'\n::             'Remove tracked Grok CLI auth and config files.' = 'Supprimer les fichiers auth/config suivis de Grok CLI.'\n::             'Command Code configs' = 'Configs Command Code'\n::             'Remove tracked Command Code auth and config files.' = 'Supprimer les fichiers auth/config suivis de Command Code.'",
        "fr reset labels",
    )

    # AgentOptions
    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'grok-cli'
::         Title = 'Grok CLI | optional'
::         Subtitle = 'Useful if you want xAI Grok in the terminal.'
::         Accent = 'DarkGreen'
::         WindowTitle = 'Grok CLI'
::     }
:: )
:: $script:ToolSpecs = @{""",
        """::     [pscustomobject]@{
::         Key = 'grok-cli'
::         Title = 'Grok CLI | optional'
::         Subtitle = 'Useful if you want xAI Grok in the terminal.'
::         Accent = 'DarkGreen'
::         WindowTitle = 'Grok CLI'
::     }
::     [pscustomobject]@{
::         Key = 'command-code'
::         Title = 'Command Code | optional'
::         Subtitle = 'AI coding agent with taste learning from commandcode.ai.'
::         Accent = 'Magenta'
::         WindowTitle = 'Command Code'
::     }
:: )
:: $script:ToolSpecs = @{""",
        "AgentOptions command-code",
    )

    # ToolSpecs
    data = replace_once(
        data,
        """::     'grok-cli' = [pscustomobject]@{
::         Command = 'grok'
::         VersionScript = 'grok --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Grok CLI.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        """::     'grok-cli' = [pscustomobject]@{
::         Command = 'grok'
::         VersionScript = 'grok --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Grok CLI.'
::     }
::     'command-code' = [pscustomobject]@{
::         Command = 'command-code'
::         VersionScript = 'if command -v command-code >/dev/null 2>&1; then command-code --version 2>/dev/null | head -n 1; elif command -v cmd >/dev/null 2>&1; then cmd --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -f "$HOME/.commandcode/auth.json" ]; then echo config-present; elif [ -d "$HOME/.commandcode" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Command Code.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        "ToolSpecs command-code",
    )

    # Update menu subtitle
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "Update menu light",
    )

    # Install diagnostics + menu
    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "Warm diagnostics",
    )
    data = replace_once(
        data,
        "::         $grokDiag = Get-ToolDiagnostics -Key 'grok-cli'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "::         $grokDiag = Get-ToolDiagnostics -Key 'grok-cli'\n::         $commandCodeDiag = Get-ToolDiagnostics -Key 'command-code'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "Get command-code diag",
    )
    data = replace_once(
        data,
        "::         $grokDiag = New-WslMissingToolDiagnostics -Key 'grok-cli' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "::         $grokDiag = New-WslMissingToolDiagnostics -Key 'grok-cli' -SetupIncomplete:$setupIncomplete\n::         $commandCodeDiag = New-WslMissingToolDiagnostics -Key 'command-code' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "New command-code diag",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = $grokDiag.MenuText; Accent = if ($grokDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'grok-cli'; DiagnosticMode = $grokDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "::         [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = $grokDiag.MenuText; Accent = if ($grokDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'grok-cli'; DiagnosticMode = $grokDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = $commandCodeDiag.MenuText; Accent = if ($commandCodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'command-code'; DiagnosticMode = $commandCodeDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "Install menu command-code",
    )
    data = replace_once(
        data,
        "::         'grok-cli' = [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = 'Install or repair Grok CLI.'; Accent = 'Cyan'; Key = 'grok-cli' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "::         'grok-cli' = [pscustomobject]@{ Title = 'Grok CLI | optional'; Subtitle = 'Install or repair Grok CLI.'; Accent = 'Cyan'; Key = 'grok-cli' }\n::         'command-code' = [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = 'Install or repair Command Code.'; Accent = 'Cyan'; Key = 'command-code' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "Resolve install command-code",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'Grok'; Key = 'grok-cli' }\n::     )",
        "::         [pscustomobject]@{ Label = 'Grok'; Key = 'grok-cli' }\n::         [pscustomobject]@{ Label = 'CmdCode'; Key = 'command-code' }\n::     )",
        "Coding summary command-code",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Grok CLI configs'; Subtitle = 'Remove tracked Grok CLI auth and config files.'; Accent = 'DarkGreen'; Key = 'grok-cli' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "::         [pscustomobject]@{ Title = 'Grok CLI configs'; Subtitle = 'Remove tracked Grok CLI auth and config files.'; Accent = 'DarkGreen'; Key = 'grok-cli' }\n::         [pscustomobject]@{ Title = 'Command Code configs'; Subtitle = 'Remove tracked Command Code auth and config files.'; Accent = 'Magenta'; Key = 'command-code' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "Reset menu items",
    )
    data = replace_once(
        data,
        "::         'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI',",
        "::         'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code',",
        "Light update scope",
    )
    data = replace_once(
        data,
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "wslRequiredKeys",
    )

    # diagnostics case
    data = replace_once(
        data,
        """::     grok-cli)
::       command_name='grok'
::       { [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; } && auth='config-present'
::       ;;
::     utility-rtk)""",
        """::     grok-cli)
::       command_name='grok'
::       { [ -n "${GROK_DEPLOYMENT_KEY:-}" ] || [ -n "${XAI_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.grok/auth.json" ] || [ -f "$HOME/.grok/config.toml" ]; } && auth='config-present'
::       ;;
::     command-code)
::       if command -v command-code >/dev/null 2>&1; then
::         command_name='command-code'
::       elif command -v cmd >/dev/null 2>&1; then
::         command_name='cmd'
::       else
::         command_name='command-code'
::       fi
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.commandcode/auth.json" ] || [ -d "$HOME/.commandcode" ]; } && auth='config-present'
::       ;;
::     utility-rtk)""",
        "diagnostics command-code",
    )

    # launch messages EN/FR/ZH
    for old, new, label in [
        (
            "::         grok_missing) printf 'grok n''est pas disponible dans le PATH.\\n' ;;",
            "::         grok_missing) printf 'grok n''est pas disponible dans le PATH.\\n' ;;\n::         command_code_missing) printf 'command-code n''est pas disponible dans le PATH.\\n' ;;",
            "fr missing",
        ),
        (
            "::         launch_grok) printf 'Lancement de Grok CLI...\\n\\n' ;;",
            "::         launch_grok) printf 'Lancement de Grok CLI...\\n\\n' ;;\n::         launch_command_code) printf 'Lancement de Command Code...\\n\\n' ;;",
            "fr launch",
        ),
        (
            "::         grok_missing) printf 'PATH 中没有 grok。\\n' ;;",
            "::         grok_missing) printf 'PATH 中没有 grok。\\n' ;;\n::         command_code_missing) printf 'PATH 中没有 command-code。\\n' ;;",
            "zh missing",
        ),
        (
            "::         launch_grok) printf '正在启动 Grok CLI...\\n\\n' ;;",
            "::         launch_grok) printf '正在启动 Grok CLI...\\n\\n' ;;\n::         launch_command_code) printf '正在启动 Command Code...\\n\\n' ;;",
            "zh launch",
        ),
        (
            "::         grok_missing) printf 'grok is not available in PATH.\\n' ;;",
            "::         grok_missing) printf 'grok is not available in PATH.\\n' ;;\n::         command_code_missing) printf 'command-code is not available in PATH.\\n' ;;",
            "en missing",
        ),
        (
            "::         launch_grok) printf 'Launching Grok CLI...\\n\\n' ;;",
            "::         launch_grok) printf 'Launching Grok CLI...\\n\\n' ;;\n::         launch_command_code) printf 'Launching Command Code...\\n\\n' ;;",
            "en launch",
        ),
    ]:
        data = replace_once(data, old, new, label)

    # run_agent
    data = replace_once(
        data,
        """::     grok-cli)
::       if ! command -v grok >/dev/null 2>&1; then msg grok_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_grok; grok ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        """::     grok-cli)
::       if ! command -v grok >/dev/null 2>&1; then msg grok_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_grok; grok ;;
::     command-code)
::       if command -v command-code >/dev/null 2>&1; then
::         msg launch_command_code; command-code
::       elif command -v cmd >/dev/null 2>&1; then
::         msg launch_command_code; cmd
::       else
::         msg command_code_missing; msg current_path "$PATH"; return 127
::       fi ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        "run_agent command-code",
    )

    # cleaner + reset specs
    data = replace_once(
        data,
        """:: grok|grok
:: rtk|rtk
:: EOF""",
        """:: grok|grok
:: command-code|command-code
:: rtk|rtk
:: EOF""",
        "cleaner_specs",
    )
    data = replace_once(
        data,
        """:: grok-cli|Grok CLI auth|file|~/.grok/auth.json
:: grok-cli|Grok CLI config|file|~/.grok/config.toml
:: grok-cli|Grok CLI managed config|file|~/.grok/managed_config.toml
:: grok-cli|Grok CLI requirements|file|~/.grok/requirements.toml
:: EOF""",
        """:: grok-cli|Grok CLI auth|file|~/.grok/auth.json
:: grok-cli|Grok CLI config|file|~/.grok/config.toml
:: grok-cli|Grok CLI managed config|file|~/.grok/managed_config.toml
:: grok-cli|Grok CLI requirements|file|~/.grok/requirements.toml
:: command-code|Command Code auth|file|~/.commandcode/auth.json
:: command-code|Command Code config directory|dir|~/.commandcode
:: EOF""",
        "reset_config_specs",
    )

    # install function + switch
    data = replace_once(
        data,
        """:: install_grok_cli() {
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
        """:: install_grok_cli() {
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
:: install_command_code() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Command Code" with_nvm npm install -g command-code@latest || return 1
::   load_user_env
::   if command -v command-code >/dev/null 2>&1; then
::     with_nvm command-code --version 2>/dev/null || true
::     return 0
::   fi
::   if command -v cmd >/dev/null 2>&1; then
::     with_nvm cmd --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'Command Code install finished but command-code is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        "install_command_code",
    )
    data = replace_once(
        data,
        "::   grok-cli) install_grok_cli || status=$? ;;",
        "::   grok-cli) install_grok_cli || status=$? ;;\n::   command-code) install_command_code || status=$? ;;",
        "install switch",
    )

    # light update tool list + update block
    data = replace_once(
        data,
        ":: for tool in codex omx opencode kilo claude gemini droid grok npm npx; do",
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd npm npx; do",
        "update tool list",
    )
    data = replace_once(
        data,
        """::   if have_cmd grok; then
::     run_step "Update Grok CLI" bash -lc 'curl -fsSL https://x.ai/cli/install.sh | bash' || true
::   else
::     echo
::     echo "== Update Grok CLI =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        """::   if have_cmd grok; then
::     run_step "Update Grok CLI" bash -lc 'curl -fsSL https://x.ai/cli/install.sh | bash' || true
::   else
::     echo
::     echo "== Update Grok CLI =="
::     echo SKIPPED
::   fi
::
::   if have_cmd command-code || have_cmd cmd; then
::     if have_nvm; then
::       run_step "Update Command Code" with_nvm npm install -g command-code@latest || true
::     else
::       run_step "Update Command Code" npm install -g command-code@latest || true
::     fi
::   else
::     echo
::     echo "== Update Command Code =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        "update command-code",
    )

    BAT.write_bytes(data)
    print(f"Updated {BAT}")
    print(f"BuildId={BUILD_ID}")
    print(f"ReleaseTag={RELEASE_TAG}")


if __name__ == "__main__":
    main()
