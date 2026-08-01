#!/usr/bin/env python3
from datetime import datetime, timezone
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = datetime.now(timezone.utc).strftime("SYTA-build-%Y-%m-%d-%H%M%SZ")
RELEASE_TAG = "v1.11.0"


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    for old_bytes in (old.replace("\n", "\r\n").encode("utf-8"), old.encode("utf-8")):
        if old_bytes in data:
            new_bytes = new.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in old_bytes else new.encode("utf-8")
            return data.replace(old_bytes, new_bytes, 1)
    raise SystemExit(f"Pattern not found ({label}):\n{old[:220]}...")


def replace_all(data: bytes, old: str, new: str, label: str, expected=None) -> bytes:
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
        raise SystemExit(f"Pattern not found ({label}):\n{old[:220]}...")
    if expected is not None and count != expected:
        raise SystemExit(f"Expected {expected} replacements for {label}, got {count}")
    return data


def main() -> None:
    data = BAT.read_bytes()
    if b"Key = 'pi'" in data and b"Key = 'omp'" in data:
        raise SystemExit("pi/omp already present in bat")

    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-08-01-103722Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-08-01-103722Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.10.9'",
        f":: $script:ReleaseTag = '{RELEASE_TAG}'",
        "ReleaseTag",
    )

    data = replace_once(
        data,
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix')]",
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp')]",
        "Agent ValidateSet",
    )
    data = replace_once(
        data,
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "Install ValidateSet",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'all')]",
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'all')]",
        "Reset ValidateSet",
    )

    # Light update copy + OMX deprecation labels (EN source strings used by Localize-Text)
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code、Reasonix。'",
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).' = '仅更新 AI 编码 CLI：Codex、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code、Reasonix、Pi、OMP（若已安装则仍更新已弃用的 OMX）。'",
        "zh light update",
    )
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.'",
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).' = 'Mettre a jour seulement les CLI IA : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecate si installe).'",
        "fr light update",
    )

    data = replace_once(
        data,
        "::             'Oh My Codex / OMX | advanced optional' = 'Oh My Codex / OMX | 进阶可选'",
        "::             'Oh My Codex / OMX | deprecated' = 'Oh My Codex / OMX | 已弃用'",
        "zh omx title",
    )
    data = replace_once(
        data,
        "::             'Oh My Codex / OMX | advanced optional' = 'Oh My Codex / OMX | option avancee'",
        "::             'Oh My Codex / OMX | deprecated' = 'Oh My Codex / OMX | deprecate'",
        "fr omx title",
    )
    data = replace_once(
        data,
        "::             'Reasonix configs' = 'Reasonix 配置'\n::             'Remove tracked Reasonix auth and config files.' = '删除已跟踪的 Reasonix 认证和配置文件。'",
        "::             'Reasonix configs' = 'Reasonix 配置'\n::             'Remove tracked Reasonix auth and config files.' = '删除已跟踪的 Reasonix 认证和配置文件。'\n::             'Pi configs' = 'Pi 配置'\n::             'Remove tracked Pi auth and config files.' = '删除已跟踪的 Pi 认证和配置文件。'\n::             'OMP configs' = 'OMP 配置'\n::             'Remove tracked OMP auth and config files.' = '删除已跟踪的 OMP 认证和配置文件。'",
        "zh reset labels",
    )
    data = replace_once(
        data,
        "::             'Reasonix configs' = 'Configs Reasonix'\n::             'Remove tracked Reasonix auth and config files.' = 'Supprimer les fichiers auth/config suivis de Reasonix.'",
        "::             'Reasonix configs' = 'Configs Reasonix'\n::             'Remove tracked Reasonix auth and config files.' = 'Supprimer les fichiers auth/config suivis de Reasonix.'\n::             'Pi configs' = 'Configs Pi'\n::             'Remove tracked Pi auth and config files.' = 'Supprimer les fichiers auth/config suivis de Pi.'\n::             'OMP configs' = 'Configs OMP'\n::             'Remove tracked OMP auth and config files.' = 'Supprimer les fichiers auth/config suivis de OMP.'",
        "fr reset labels",
    )

    # Deprecate OMX agent option + add Pi/OMP
    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'omx-madmax-high'
::         Title = 'OMX | advanced'
::         Subtitle = 'More automation and more structure on top of Codex. Better after you already understand the basics.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMX MADMAX HIGH'
::     }
::     [pscustomobject]@{
::         Key = 'opencode'""",
        """::     [pscustomobject]@{
::         Key = 'omx-madmax-high'
::         Title = 'OMX | deprecated'
::         Subtitle = 'Deprecated Codex wrapper. Prefer Codex, Pi, or OMP. Still launches when present.'
::         Accent = 'DarkGray'
::         WindowTitle = 'OMX MADMAX HIGH'
::     }
::     [pscustomobject]@{
::         Key = 'opencode'""",
        "AgentOptions omx deprecate",
    )
    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'reasonix'
::         Title = 'Reasonix | optional'
::         Subtitle = 'DeepSeek-native cache-first coding agent for the terminal.'
::         Accent = 'DarkYellow'
::         WindowTitle = 'Reasonix'
::     }
:: )
:: $script:ToolSpecs = @{""",
        """::     [pscustomobject]@{
::         Key = 'reasonix'
::         Title = 'Reasonix | optional'
::         Subtitle = 'DeepSeek-native cache-first coding agent for the terminal.'
::         Accent = 'DarkYellow'
::         WindowTitle = 'Reasonix'
::     }
::     [pscustomobject]@{
::         Key = 'pi'
::         Title = 'Pi | optional'
::         Subtitle = 'Minimal extensible coding agent from pi.dev.'
::         Accent = 'Cyan'
::         WindowTitle = 'Pi'
::     }
::     [pscustomobject]@{
::         Key = 'omp'
::         Title = 'OMP | optional'
::         Subtitle = 'Oh My Pi batteries-included coding agent from omp.sh.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMP'
::     }
:: )
:: $script:ToolSpecs = @{""",
        "AgentOptions pi omp",
    )

    data = replace_once(
        data,
        """::     'omx' = [pscustomobject]@{
::         Command = 'omx'
::         VersionScript = 'omx --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.codex/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Oh My Codex / OMX.'
::     }""",
        """::     'omx' = [pscustomobject]@{
::         Command = 'omx'
::         VersionScript = 'omx --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.codex/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Deprecated. Prefer Codex, Pi, or OMP. Install from Install -> Oh My Codex / OMX | deprecated.'
::     }""",
        "ToolSpecs omx hint",
    )
    data = replace_once(
        data,
        """::     'reasonix' = [pscustomobject]@{
::         Command = 'reasonix'
::         VersionScript = 'if command -v reasonix >/dev/null 2>&1; then reasonix --version 2>/dev/null | head -n 1; elif command -v dsnix >/dev/null 2>&1; then dsnix --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${DEEPSEEK_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.reasonix/config.json" ] || [ -f "$HOME/.reasonix/config.toml" ] || [ -d "$HOME/.reasonix" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Reasonix.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        """::     'reasonix' = [pscustomobject]@{
::         Command = 'reasonix'
::         VersionScript = 'if command -v reasonix >/dev/null 2>&1; then reasonix --version 2>/dev/null | head -n 1; elif command -v dsnix >/dev/null 2>&1; then dsnix --version 2>/dev/null | head -n 1; fi'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${DEEPSEEK_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.reasonix/config.json" ] || [ -f "$HOME/.reasonix/config.toml" ] || [ -d "$HOME/.reasonix" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Reasonix.'
::     }
::     'pi' = [pscustomobject]@{
::         Command = 'pi'
::         VersionScript = 'pi --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.pi/agent" ] || [ -f "$HOME/.pi/agent/settings.json" ] || [ -d "$HOME/.pi" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Pi.'
::     }
::     'omp' = [pscustomobject]@{
::         Command = 'omp'
::         VersionScript = 'omp --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> OMP.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{""",
        "ToolSpecs pi omp",
    )

    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).'; Accent = 'Green'; Key = 'UpdateLight' }",
        "Update menu light",
    )

    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "Warm diagnostics",
    )
    data = replace_once(
        data,
        "::         $reasonixDiag = Get-ToolDiagnostics -Key 'reasonix'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "::         $reasonixDiag = Get-ToolDiagnostics -Key 'reasonix'\n::         $piDiag = Get-ToolDiagnostics -Key 'pi'\n::         $ompDiag = Get-ToolDiagnostics -Key 'omp'\n::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'",
        "Get pi/omp diag",
    )
    data = replace_once(
        data,
        "::         $reasonixDiag = New-WslMissingToolDiagnostics -Key 'reasonix' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "::         $reasonixDiag = New-WslMissingToolDiagnostics -Key 'reasonix' -SetupIncomplete:$setupIncomplete\n::         $piDiag = New-WslMissingToolDiagnostics -Key 'pi' -SetupIncomplete:$setupIncomplete\n::         $ompDiag = New-WslMissingToolDiagnostics -Key 'omp' -SetupIncomplete:$setupIncomplete\n::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete",
        "New pi/omp diag",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Oh My Codex / OMX | advanced optional'; Subtitle = $omxDiag.MenuText; Accent = if ($omxDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omx'; DiagnosticMode = $omxDiag.DiagnosticMode }",
        "::         [pscustomobject]@{ Title = 'Oh My Codex / OMX | deprecated'; Subtitle = $omxDiag.MenuText; Accent = if ($omxDiag.Installed) { 'DarkGray' } else { 'DarkGray' }; Key = 'omx'; DiagnosticMode = $omxDiag.DiagnosticMode }",
        "Install menu omx deprecate",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = $reasonixDiag.MenuText; Accent = if ($reasonixDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'reasonix'; DiagnosticMode = $reasonixDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "::         [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = $reasonixDiag.MenuText; Accent = if ($reasonixDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'reasonix'; DiagnosticMode = $reasonixDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Pi | optional'; Subtitle = $piDiag.MenuText; Accent = if ($piDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'pi'; DiagnosticMode = $piDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = $ompDiag.MenuText; Accent = if ($ompDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omp'; DiagnosticMode = $ompDiag.DiagnosticMode }\n::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim'; DiagnosticMode = $omoDiag.DiagnosticMode }",
        "Install menu pi omp",
    )
    data = replace_once(
        data,
        "::         'omx' = [pscustomobject]@{ Title = 'Oh My Codex / OMX | advanced optional'; Subtitle = 'Install or repair OMX.'; Accent = 'Cyan'; Key = 'omx' }",
        "::         'omx' = [pscustomobject]@{ Title = 'Oh My Codex / OMX | deprecated'; Subtitle = 'Deprecated. Install or repair OMX only if you still need it.'; Accent = 'DarkGray'; Key = 'omx' }",
        "Resolve install omx",
    )
    data = replace_once(
        data,
        "::         'reasonix' = [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = 'Install or repair Reasonix.'; Accent = 'Cyan'; Key = 'reasonix' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "::         'reasonix' = [pscustomobject]@{ Title = 'Reasonix | optional'; Subtitle = 'Install or repair Reasonix.'; Accent = 'Cyan'; Key = 'reasonix' }\n::         'pi' = [pscustomobject]@{ Title = 'Pi | optional'; Subtitle = 'Install or repair Pi.'; Accent = 'Cyan'; Key = 'pi' }\n::         'omp' = [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = 'Install or repair OMP (Oh My Pi).'; Accent = 'Cyan'; Key = 'omp' }\n::         'oh-my-openagent' = [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = 'Install or repair the OpenCode add-on.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }",
        "Resolve install pi omp",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'OMX'; Key = 'omx' }",
        "::         [pscustomobject]@{ Label = 'OMX*'; Key = 'omx' }",
        "Coding summary omx",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'Reasonix'; Key = 'reasonix' }\n::     )",
        "::         [pscustomobject]@{ Label = 'Reasonix'; Key = 'reasonix' }\n::         [pscustomobject]@{ Label = 'Pi'; Key = 'pi' }\n::         [pscustomobject]@{ Label = 'OMP'; Key = 'omp' }\n::     )",
        "Coding summary pi omp",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Reasonix configs'; Subtitle = 'Remove tracked Reasonix auth and config files.'; Accent = 'DarkYellow'; Key = 'reasonix' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "::         [pscustomobject]@{ Title = 'Reasonix configs'; Subtitle = 'Remove tracked Reasonix auth and config files.'; Accent = 'DarkYellow'; Key = 'reasonix' }\n::         [pscustomobject]@{ Title = 'Pi configs'; Subtitle = 'Remove tracked Pi auth and config files.'; Accent = 'Cyan'; Key = 'pi' }\n::         [pscustomobject]@{ Title = 'OMP configs'; Subtitle = 'Remove tracked OMP auth and config files.'; Accent = 'Yellow'; Key = 'omp' }\n::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }",
        "Reset menu items",
    )
    data = replace_once(
        data,
        "::         'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix',",
        "::         'Scope   : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed)',",
        "Light update scope",
    )
    data = replace_once(
        data,
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "wslRequiredKeys",
    )

    data = replace_once(
        data,
        """::     reasonix)
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
        """::     reasonix)
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
::     pi)
::       command_name='pi'
::       { [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.pi/agent" ] || [ -f "$HOME/.pi/agent/settings.json" ] || [ -d "$HOME/.pi" ]; } && auth='config-present'
::       ;;
::     omp)
::       command_name='omp'
::       { [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; } && auth='config-present'
::       ;;
::     utility-rtk)""",
        "diagnostics pi omp",
    )

    for old, new, label in [
        (
            "::         reasonix_missing) printf 'reasonix n''est pas disponible dans le PATH.\\n' ;;",
            "::         reasonix_missing) printf 'reasonix n''est pas disponible dans le PATH.\\n' ;;\n::         pi_missing) printf 'pi n''est pas disponible dans le PATH.\\n' ;;\n::         omp_missing) printf 'omp n''est pas disponible dans le PATH.\\n' ;;",
            "fr missing",
        ),
        (
            "::         launch_reasonix) printf 'Lancement de Reasonix...\\n\\n' ;;",
            "::         launch_reasonix) printf 'Lancement de Reasonix...\\n\\n' ;;\n::         launch_pi) printf 'Lancement de Pi...\\n\\n' ;;\n::         launch_omp) printf 'Lancement de OMP...\\n\\n' ;;",
            "fr launch",
        ),
        (
            "::         reasonix_missing) printf 'PATH 中没有 reasonix。\\n' ;;",
            "::         reasonix_missing) printf 'PATH 中没有 reasonix。\\n' ;;\n::         pi_missing) printf 'PATH 中没有 pi。\\n' ;;\n::         omp_missing) printf 'PATH 中没有 omp。\\n' ;;",
            "zh missing",
        ),
        (
            "::         launch_reasonix) printf '正在启动 Reasonix...\\n\\n' ;;",
            "::         launch_reasonix) printf '正在启动 Reasonix...\\n\\n' ;;\n::         launch_pi) printf '正在启动 Pi...\\n\\n' ;;\n::         launch_omp) printf '正在启动 OMP...\\n\\n' ;;",
            "zh launch",
        ),
        (
            "::         reasonix_missing) printf 'reasonix is not available in PATH.\\n' ;;",
            "::         reasonix_missing) printf 'reasonix is not available in PATH.\\n' ;;\n::         pi_missing) printf 'pi is not available in PATH.\\n' ;;\n::         omp_missing) printf 'omp is not available in PATH.\\n' ;;",
            "en missing",
        ),
        (
            "::         launch_reasonix) printf 'Launching Reasonix...\\n\\n' ;;",
            "::         launch_reasonix) printf 'Launching Reasonix...\\n\\n' ;;\n::         launch_pi) printf 'Launching Pi...\\n\\n' ;;\n::         launch_omp) printf 'Launching OMP...\\n\\n' ;;",
            "en launch",
        ),
    ]:
        data = replace_once(data, old, new, label)

    data = replace_once(
        data,
        """::     reasonix)
::       if command -v reasonix >/dev/null 2>&1; then
::         msg launch_reasonix; reasonix
::       elif command -v dsnix >/dev/null 2>&1; then
::         msg launch_reasonix; dsnix
::       else
::         msg reasonix_missing; msg current_path "$PATH"; return 127
::       fi ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        """::     reasonix)
::       if command -v reasonix >/dev/null 2>&1; then
::         msg launch_reasonix; reasonix
::       elif command -v dsnix >/dev/null 2>&1; then
::         msg launch_reasonix; dsnix
::       else
::         msg reasonix_missing; msg current_path "$PATH"; return 127
::       fi ;;
::     pi)
::       if ! command -v pi >/dev/null 2>&1; then msg pi_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_pi; pi ;;
::     omp)
::       if ! command -v omp >/dev/null 2>&1; then msg omp_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_omp; omp ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;""",
        "run_agent pi omp",
    )

    data = replace_once(
        data,
        """:: reasonix|reasonix
:: dsnix|dsnix
:: rtk|rtk
:: EOF""",
        """:: reasonix|reasonix
:: dsnix|dsnix
:: pi|@earendil-works/pi-coding-agent
:: omp|@oh-my-pi/pi-coding-agent
:: rtk|rtk
:: EOF""",
        "cleaner_specs",
    )
    data = replace_once(
        data,
        """:: reasonix|Reasonix config|file|~/.reasonix/config.json
:: reasonix|Reasonix config|file|~/.reasonix/config.toml
:: reasonix|Reasonix config directory|dir|~/.reasonix
:: EOF""",
        """:: reasonix|Reasonix config|file|~/.reasonix/config.json
:: reasonix|Reasonix config|file|~/.reasonix/config.toml
:: reasonix|Reasonix config directory|dir|~/.reasonix
:: pi|Pi agent settings|file|~/.pi/agent/settings.json
:: pi|Pi agent directory|dir|~/.pi/agent
:: pi|Pi config directory|dir|~/.pi
:: omp|OMP agent config|file|~/.omp/agent/config.yml
:: omp|OMP agent directory|dir|~/.omp/agent
:: omp|OMP config directory|dir|~/.omp
:: EOF""",
        "reset_config_specs",
    )

    data = replace_once(
        data,
        """:: install_reasonix() {
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
        """:: install_reasonix() {
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
:: install_pi() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Pi" with_nvm npm install -g --ignore-scripts @earendil-works/pi-coding-agent || return 1
::   load_user_env
::   if command -v pi >/dev/null 2>&1; then
::     with_nvm pi --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'Pi install finished but pi is still not on PATH.
:: '
::   return 1
:: }
::
:: install_omp() {
::   ensure_curl || return 1
::   run_step "Install OMP (Oh My Pi)" bash -lc 'curl -fsSL https://omp.sh/install | sh' || {
::     ensure_node_npm_latest || return 1
::     run_step "Install OMP via npm" with_nvm npm install -g @oh-my-pi/pi-coding-agent || return 1
::   }
::   load_user_env
::   export PATH="$HOME/.local/bin:$HOME/.omp/bin:$PATH"
::   if command -v omp >/dev/null 2>&1; then
::     omp --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'OMP install finished but omp is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        "install_pi_omp",
    )
    data = replace_once(
        data,
        "::   reasonix) install_reasonix || status=$? ;;",
        "::   reasonix) install_reasonix || status=$? ;;\n::   pi) install_pi || status=$? ;;\n::   omp) install_omp || status=$? ;;",
        "install switch",
    )

    data = replace_once(
        data,
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd reasonix dsnix npm npx; do",
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd reasonix dsnix pi omp npm npx; do",
        "update tool list",
    )
    data = replace_once(
        data,
        """::   if have_cmd reasonix || have_cmd dsnix; then
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
        """::   if have_cmd reasonix || have_cmd dsnix; then
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
::   if have_cmd pi; then
::     if have_nvm; then
::       run_step "Update Pi" with_nvm npm install -g --ignore-scripts @earendil-works/pi-coding-agent || true
::     else
::       run_step "Update Pi" npm install -g --ignore-scripts @earendil-works/pi-coding-agent || true
::     fi
::   else
::     echo
::     echo "== Update Pi =="
::     echo SKIPPED
::   fi
::
::   if have_cmd omp; then
::     if command -v omp >/dev/null 2>&1 && omp update --help >/dev/null 2>&1; then
::       run_step "Update OMP" omp update --self || true
::     elif have_nvm; then
::       run_step "Update OMP via npm" with_nvm npm install -g @oh-my-pi/pi-coding-agent || true
::     else
::       run_step "Update OMP via npm" npm install -g @oh-my-pi/pi-coding-agent || true
::     fi
::   else
::     echo
::     echo "== Update OMP =="
::     echo SKIPPED
::   fi
::
::   load_user_env""",
        "update pi omp",
    )

    # Soft-deprecate OMX update label
    data = replace_once(
        data,
        '::       run_step "Update Oh My Codex / OMX" with_nvm npm install -g oh-my-codex || true',
        '::       run_step "Update Oh My Codex / OMX (deprecated)" with_nvm npm install -g oh-my-codex || true',
        "update omx nvm label",
    )
    data = replace_once(
        data,
        '::       run_step "Update Oh My Codex / OMX" npm install -g oh-my-codex || true',
        '::       run_step "Update Oh My Codex / OMX (deprecated)" npm install -g oh-my-codex || true',
        "update omx npm label",
    )
    data = replace_once(
        data,
        '::     echo "== Update Oh My Codex / OMX =="',
        '::     echo "== Update Oh My Codex / OMX (deprecated) =="',
        "update omx skipped label",
    )

    BAT.write_bytes(data)
    print(f"Updated {BAT}")
    print(f"BuildId={BUILD_ID}")
    print(f"ReleaseTag={RELEASE_TAG}")


if __name__ == "__main__":
    main()
