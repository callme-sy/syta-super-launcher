#!/usr/bin/env python3
from datetime import datetime, timezone
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = datetime.now(timezone.utc).strftime("SYTA-build-%Y-%m-%d-%H%M%SZ")
RELEASE_TAG = "v1.10.9"


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes in data:
            new_bytes = new.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in old_bytes else new.encode("utf-8")
            return data.replace(old_bytes, new_bytes, 1)
    raise SystemExit(f"Pattern not found ({label}):\n{old[:200]}...")


def main() -> None:
    data = BAT.read_bytes()
    if b"Key = 'reasonix'" in data or b"'reasonix' = [pscustomobject]" in data:
        raise SystemExit("reasonix already present in bat")

    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-07-24-155346Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-07-24-155346Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.10.8'",
        f":: $script:ReleaseTag = '{RELEASE_TAG}'",
        "ReleaseTag",
    )

    data = replace_once(
        data,
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code')]",
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix')]",
        "Agent ValidateSet",
    )
    data = replace_once(
        data,
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "Install ValidateSet",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'all')]",
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'all')]",
        "Reset ValidateSet",
    )

    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code。'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code、Reasonix。'",
        "zh light update",
    )
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.'",
        "fr light update",
    )
    data = replace_once(
        data,
        "::             'Command Code configs' = 'Command Code 配置'\n::             'Remove tracked Command Code auth and config files.' = '删除已跟踪的 Command Code 认证和配置文件。'",
        "::             'Command Code configs' = 'Command Code 配置'\n::             'Remove tracked Command Code auth and config files.' = '删除已跟踪的 Command Code 认证和配置文件。'\n::             'Reasonix configs' = 'Reasonix 配置'\n::             'Remove tracked Reasonix auth and config files.' = '删除已跟踪的 Reasonix 认证和配置文件。'",
        "zh reset labels",
    )
    data = replace_once(
        data,
        "::             'Command Code configs' = 'Configs Command Code'\n::             'Remove tracked Command Code auth and config files.' = 'Supprimer les fichiers auth/config suivis de Command Code.'",
        "::             'Command Code configs' = 'Configs Command Code'\n::             'Remove tracked Command Code auth and config files.' = 'Supprimer les fichiers auth/config suivis de Command Code.'\n::             'Reasonix configs' = 'Configs Reasonix'\n::             'Remove tracked Reasonix auth and config files.' = 'Supprimer les fichiers auth/config suivis de Reasonix.'",
        "fr reset labels",
    )

    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'command-code'
::         Title = 'Command Code | optional'
::         Subtitle = 'AI coding agent with taste learning from commandcode.ai.'
::         Accent = 'Magenta'
::         WindowTitle = 'Command Code'
::     }
:: )
:: $script:ToolSpecs = @{""",
        """::     [pscustomobject]@{
::         Key = 'command-code'
::         Title = 'Command Code | optional'
::         Subtitle = 'AI coding agent with taste learning from commandcode.ai.'
::         Accent = 'Magenta'
::         WindowTitle = 'Command Code'
::     }
::     [pscustomobject]@{
::         Key = 'reasonix'
::         Title = 'Reasonix | optional'
::         Subtitle = 'DeepSeek-native cache-first coding agent for the terminal.'
::         Accent = 'DarkYellow'
::         WindowTitle = 'Reasonix'
::     }
:: )
:: $script:ToolSpecs = @{""",
        "AgentOptions reasonix",
    )

    data = replace_once(
        data,
        """::     'command-code' = [pscustomobject]@{
::         Command = 'command-code'
::         VersionScript = 'if command -v command-code >/dev/null 2>&1; then command-code --version 2>/dev/null | head -n 1; elif command -v cmd >/dev/null 2>&1; then cmd --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -f "$HOME/.commandcode/auth.json" ]; then echo config-present; elif [ -d "$HOME/.commandcode" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Command Code.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        """::     'command-code' = [pscustomobject]@{
::         Command = 'command-code'
::         VersionScript = 'if command -v command-code >/dev/null 2>&1; then command-code --version 2>/dev/null | head -n 1; elif command -v cmd >/dev/null 2>&1; then cmd --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -f "$HOME/.commandcode/auth.json" ]; then echo config-present; elif [ -d "$HOME/.commandcode" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Command Code.'
::     }
::     'reasonix' = [pscustomobject]@{
::         Command = 'reasonix'
::         VersionScript = 'if command -v reasonix >/dev/null 2>&1; then reasonix --version 2>/dev/null | head -n 1; elif command -v dsnix >/dev/null 2>&1; then dsnix --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${DEEPSEEK_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.reasonix/config.json" ] || [ -f "$HOME/.reasonix/config.toml" ] || [ -d "$HOME/.reasonix" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Reasonix.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        "ToolSpecs reasonix",
    )

    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "Update menu light",
    )

    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "Warm diagnostics",
    )
    data = replace_once(
        data,
        "::         $commandCodeDiag = Get-ToolDiagnostics -Key 'command-code'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "::         $commandCodeDiag = Get-ToolDiagnostics -Key 'command-code'\n::         $reasonixDiag = Get-ToolDiagnostics -Key 'reasonix'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "Get reasonix diag",
    )
    data = replace_once(
        data,
        "::         $commandCodeDiag = New-WslMissingToolDiagnostics -Key 'command-code' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "::         $commandCodeDiag = New-WslMissingToolDiagnostics -Key 'command-code' -SetupIncomplete:$setupIncomplete\n::         $reasonixDiag = New-WslMissingToolDiagnostics -Key 'reasonix' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "New reasonix diag",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = $commandCodeDiag.MenuText; Accent = if ($commandCodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'command-code'; DiagnosticMode = $commandCodeDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "::         [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = $commandCodeDiag.MenuText; Accent = if ($commandCodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'command-code'; DiagnosticMode = $commandCodeDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = $reasonixDiag.MenuText; Accent = if ($reasonixDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'reasonix'; DiagnosticMode = $reasonixDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "Install menu reasonix",
    )
    data = replace_once(
        data,
        "::         'command-code' = [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = 'Install or repair Command Code.'; Accent = 'Cyan'; Key = 'command-code' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "::         'command-code' = [pscustomobject]@{ Title = 'Command Code | optional'; Subtitle = 'Install or repair Command Code.'; Accent = 'Cyan'; Key = 'command-code' }\n::         'reasonix' = [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = 'Install or repair Reasonix.'; Accent = 'Cyan'; Key = 'reasonix' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "Resolve install reasonix",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'CmdCode'; Key = 'command-code' }\n::     )",
        "::         [pscustomobject]@{ Label = 'CmdCode'; Key = 'command-code' }\n::         [pscustomobject]@{ Label = 'Reasonix'; Key = 'reasonix' }\n::     )",
        "Coding summary reasonix",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Command Code configs'; Subtitle = 'Remove tracked Command Code auth and config files.'; Accent = 'Magenta'; Key = 'command-code' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "::         [pscustomobject]@{ Title = 'Command Code configs'; Subtitle = 'Remove tracked Command Code auth and config files.'; Accent = 'Magenta'; Key = 'command-code' }\n::         [pscustomobject]@{ Title = 'Reasonix configs'; Subtitle = 'Remove tracked Reasonix auth and config files.'; Accent = 'DarkYellow'; Key = 'reasonix' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "Reset menu items",
    )
    data = replace_once(
        data,
        "::         'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code',",
        "::         'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix',",
        "Light update scope",
    )
    data = replace_once(
        data,
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "wslRequiredKeys",
    )

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
::     utility-rtk)""",
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
::       ;;
::     utility-rtk)""",
        "diagnostics reasonix",
    )

    for old, new, label in [
        (
            "::         command_code_missing) printf 'command-code n''est pas disponible dans le PATH.\\n' ;;",
            "::         command_code_missing) printf 'command-code n''est pas disponible dans le PATH.\\n' ;;\n::         reasonix_missing) printf 'reasonix n''est pas disponible dans le PATH.\\n' ;;",
            "fr missing",
        ),
        (
            "::         launch_command_code) printf 'Lancement de Command Code...\\n\\n' ;;",
            "::         launch_command_code) printf 'Lancement de Command Code...\\n\\n' ;;\n::         launch_reasonix) printf 'Lancement de Reasonix...\\n\\n' ;;",
            "fr launch",
        ),
        (
            "::         command_code_missing) printf 'PATH 中没有 command-code。\\n' ;;",
            "::         command_code_missing) printf 'PATH 中没有 command-code。\\n' ;;\n::         reasonix_missing) printf 'PATH 中没有 reasonix。\\n' ;;",
            "zh missing",
        ),
        (
            "::         launch_command_code) printf '正在启动 Command Code...\\n\\n' ;;",
            "::         launch_command_code) printf '正在启动 Command Code...\\n\\n' ;;\n::         launch_reasonix) printf '正在启动 Reasonix...\\n\\n' ;;",
            "zh launch",
        ),
        (
            "::         command_code_missing) printf 'command-code is not available in PATH.\\n' ;;",
            "::         command_code_missing) printf 'command-code is not available in PATH.\\n' ;;\n::         reasonix_missing) printf 'reasonix is not available in PATH.\\n' ;;",
            "en missing",
        ),
        (
            "::         launch_command_code) printf 'Launching Command Code...\\n\\n' ;;",
            "::         launch_command_code) printf 'Launching Command Code...\\n\\n' ;;\n::         launch_reasonix) printf 'Launching Reasonix...\\n\\n' ;;",
            "en launch",
        ),
    ]:
        data = replace_once(data, old, new, label)

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
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
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
::       fi ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        "run_agent reasonix",
    )

    data = replace_once(
        data,
        """:: command-code|command-code
:: rtk|rtk
:: EOF""",
        """:: command-code|command-code
:: reasonix|reasonix
:: dsnix|dsnix
:: rtk|rtk
:: EOF""",
        "cleaner_specs",
    )
    data = replace_once(
        data,
        """:: command-code|Command Code auth|file|~/.commandcode/auth.json
:: command-code|Command Code config directory|dir|~/.commandcode
:: EOF""",
        """:: command-code|Command Code auth|file|~/.commandcode/auth.json
:: command-code|Command Code config directory|dir|~/.commandcode
:: reasonix|Reasonix config|file|~/.reasonix/config.json
:: reasonix|Reasonix config|file|~/.reasonix/config.toml
:: reasonix|Reasonix config directory|dir|~/.reasonix
:: EOF""",
        "reset_config_specs",
    )

    data = replace_once(
        data,
        """:: install_command_code() {
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
        """:: install_command_code() {
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
:: install_reasonix() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Reasonix" with_nvm npm install -g reasonix@latest || return 1
::   load_user_env
::   if command -v reasonix >/dev/null 2>&1; then
::     with_nvm reasonix --version 2>/dev/null || true
::     return 0
::   fi
::   if command -v dsnix >/dev/null 2>&1; then
::     with_nvm dsnix --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'Reasonix install finished but reasonix is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        "install_reasonix",
    )
    data = replace_once(
        data,
        "::   command-code) install_command_code || status=$? ;;",
        "::   command-code) install_command_code || status=$? ;;\n::   reasonix) install_reasonix || status=$? ;;",
        "install switch",
    )

    data = replace_once(
        data,
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd npm npx; do",
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd reasonix dsnix npm npx; do",
        "update tool list",
    )
    data = replace_once(
        data,
        """::   if have_cmd command-code || have_cmd cmd; then
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
        """::   if have_cmd command-code || have_cmd cmd; then
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
::   if have_cmd reasonix || have_cmd dsnix; then
::     if have_nvm; then
::       run_step "Update Reasonix" with_nvm npm install -g reasonix@latest || true
::     else
::       run_step "Update Reasonix" npm install -g reasonix@latest || true
::     fi
::   else
::     echo
::     echo "== Update Reasonix =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        "update reasonix",
    )

    BAT.write_bytes(data)
    print(f"Updated {BAT}")
    print(f"BuildId={BUILD_ID}")
    print(f"ReleaseTag={RELEASE_TAG}")


if __name__ == "__main__":
    main()
