#!/usr/bin/env python3
"""SYTA Super Launcher v2 modernization patch -> v1.12.0.

Adds: Zcode (Z.ai GLM CLI), DSH (DeepSeek harness), Muse Code (Meta),
      Patchright utility. Removes deprecated OMX everywhere.
Bumps nvm 0.40.3 -> 0.40.7. Modernizes OpenCode install/update lanes.
"""
from datetime import datetime, timezone
from pathlib import Path
import re

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = datetime.now(timezone.utc).strftime("SYTA-build-%Y-%m-%d-%H%M%SZ")
RELEASE_TAG = "v1.12.0"

WARNINGS = []


def _to_pattern(old: str) -> bytes:
    return b"\r?\n".join(re.escape(p) for p in old.encode("utf-8").split(b"\n"))


def _find_all(data: bytes, old: str):
    return list(re.compile(_to_pattern(old)).finditer(data))


def replace_once(data: bytes, old: str, new: str, label: str) -> bytes:
    ms = _find_all(data, old)
    if not ms:
        raise SystemExit(f"Pattern not found ({label}):\n{old[:260]}...")
    if len(ms) > 1:
        raise SystemExit(
            f"Expected 1 occurrence for {label}, got {len(ms)}:\n{old[:160]}..."
        )
    m = ms[0]
    matched = m.group(0)
    if b"\r\n" in matched:
        new_bytes = new.replace("\n", "\r\n").encode("utf-8")
    else:
        new_bytes = new.encode("utf-8")
    return data[: m.start()] + new_bytes + data[m.end() :]


def replace_all(
    data: bytes, old: str, new: str, label: str, expected: int | None = None
) -> bytes:
    ms = _find_all(data, old)
    if not ms:
        raise SystemExit(f"Pattern not found ({label}):\n{old[:260]}...")
    if expected is not None and len(ms) != expected:
        raise SystemExit(
            f"Expected {expected} replacements for {label}, got {len(ms)}"
        )
    out = data
    for m in reversed(ms):
        matched = m.group(0)
        if b"\r\n" in matched:
            new_bytes = new.replace("\n", "\r\n").encode("utf-8")
        else:
            new_bytes = new.encode("utf-8")
        out = out[: m.start()] + new_bytes + out[m.end() :]
    return out


def replace_optional(data: bytes, old: str, new: str, label: str) -> bytes:
    ms = _find_all(data, old)
    if not ms:
        WARNINGS.append(f"optional pattern missing (skipped): {label}")
        return data
    if len(ms) > 1:
        WARNINGS.append(f"optional pattern ambiguous (skipped): {label}")
        return data
    return replace_once(data, old, new, label)


def delete_once(data: bytes, old: str, label: str) -> bytes:
    return replace_once(data, old, "", label)


def main() -> None:
    data = BAT.read_bytes()
    if "Key = 'zcode'" in data.decode("utf-8", "replace"):
        raise SystemExit("v2 patch already applied (zcode present)")

    # ---------- version ----------
    data = replace_once(
        data,
        'set "SYTA_BUILD_ID=SYTA-build-2026-08-01-105300Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "SYTA_BUILD_ID",
    )
    data = replace_once(
        data,
        ":: $script:BuildId = 'SYTA-build-2026-08-01-105300Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "BuildId",
    )
    data = replace_once(
        data,
        ":: $script:ReleaseTag = 'v1.11.1'",
        f":: $script:ReleaseTag = '{RELEASE_TAG}'",
        "ReleaseTag",
    )

    # ---------- param ValidateSets ----------
    data = replace_once(
        data,
        "[ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp')]",
        "[ValidateSet('codex-yolo', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'zcode', 'dsh', 'muse-code')]",
        "Agent ValidateSet",
    )
    data = replace_once(
        data,
        "'utilities', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "'utilities', 'codex', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'zcode', 'dsh', 'muse-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk'",
        "Install ValidateSet head",
    )
    data = replace_once(
        data,
        "'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')]",
        "'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad', 'utility-patchright')]",
        "Install ValidateSet tail",
    )
    data = replace_once(
        data,
        "[ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'all')]",
        "[ValidateSet('codex', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'zcode', 'dsh', 'muse-code', 'all')]",
        "Reset ValidateSet",
    )

    # ---------- i18n map: light-update copy (zh + fr) ----------
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).' = '仅更新 AI 编码 CLI：Codex、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code、Reasonix、Pi、OMP（若已安装则仍更新已弃用的 OMX）。'",
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP, Zcode, DSH, Muse Code.' = '仅更新 AI 编码 CLI：Codex、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI、Command Code、Reasonix、Pi、OMP、Zcode、DSH、Muse Code。'",
        "zh light update",
    )
    data = replace_once(
        data,
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).' = 'Mettre a jour seulement les CLI IA : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecate si installe).'",
        "::             'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP, Zcode, DSH, Muse Code.' = 'Mettre a jour seulement les CLI IA : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP, Zcode, DSH, Muse Code.'",
        "fr light update",
    )

    # ---------- i18n map: delete orphaned explanation keys (zh 367-381) ----------
    for old in [
        "::             'Codex: OpenAI coding agent with strong editing and reasoning.' = 'Codex：OpenAI 的编码代理，编辑和推理能力都很强。'",
        "::             'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.' = 'OMX：Codex 上层的进阶封装，适合更强的自动化、规划和重型工作流。'",
        "::             'OpenCode: lightweight coding CLI and usually the easiest first start.' = 'OpenCode：轻量编码 CLI，通常也是最容易上手的起点。'",
        "::             'Claude Code and Gemini CLI: best if you already use those ecosystems.' = 'Claude Code 和 Gemini CLI：如果你已经在用这些生态，更值得装。'",
        "::             'Best beginner path: Install -> First install, then start with OpenCode or Codex.' = '新手最佳路径：安装 -> 首次安装，然后从 OpenCode 或 Codex 开始。'",
        "::             'Oh My OpenAgent is the full OpenCode harness. Oh My OpenCode Slim keeps a lighter preset.' = 'Oh My OpenAgent 是完整的 OpenCode 扩展，Oh My OpenCode Slim 是更轻的预设。'",
        "::             'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.' = 'Codex 是直接的 OpenAI 路线；OMX 在其上增加更有主见的自动化和编排。'",
        "::             'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.' = 'OpenCode 通常最轻量；如果你想要更强的引导执行，Codex 和 OMX 更合适。'",
        "::             'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.' = '只安装你真正会用的 CLI。工具越多，认证、更新和重叠就越多。'",
        "::             'Oh My OpenAgent is the broader OpenCode harness; Slim keeps a lighter OpenCode-focused preset.' = 'Oh My OpenAgent 是更完整的 OpenCode 扩展；Slim 则保留更轻量的 OpenCode 预设。'",
        "::             'Brand-new Windows machine: Install -> First install.' = '全新 Windows 机器：安装 -> 首次安装。'",
        "::             'Lowest-friction start: OpenCode.' = '最低摩擦的起点：OpenCode。'",
        "::             'Best OpenAI-first path: Codex, then OMX if you want deeper automation.' = '最佳 OpenAI 优先路径：先 Codex，如果想要更深的自动化再加 OMX。'",
        "::             'Install Oh My OpenAgent if you want the full harness. Install Slim if you want a lighter preset.' = '想要完整扩展就装 Oh My OpenAgent；想要更轻的预设就装 Slim。'",
        "::             'Skip tools you do not have keys, subscriptions, or a real workflow for.' = '跳过你没有 key、订阅或实际工作流需求的工具。'",
    ]:
        data = delete_once(data, "\n" + old, "del zh orphan")

    # ---------- i18n map: delete orphaned explanation keys (fr 689-703) ----------
    for old in [
        "::             'Codex: OpenAI coding agent with strong editing and reasoning.' = 'Codex : l''outil OpenAI pour coder avec de l''aide. Bon choix si vous voulez un assistant serieux pour lire, modifier et expliquer du code.'",
        "::             'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.' = 'OMX : une couche en plus par-dessus Codex. A utiliser surtout si vous voulez plus d''automatisation, plus de structure, et des workflows plus lourds.'",
        "::             'OpenCode: lightweight coding CLI and usually the easiest first start.' = 'OpenCode : l''outil le plus leger et souvent le plus simple pour commencer.'",
        "::             'Claude Code and Gemini CLI: best if you already use those ecosystems.' = 'Claude Code et Gemini CLI : utiles surtout si vous payez deja ces services ou preferez deja ces ecosystemes.'",
        "::             'Best beginner path: Install -> First install, then start with OpenCode or Codex.' = 'Meilleur parcours debutant : Installation -> Premiere installation, puis commencer avec OpenCode ou Codex.'",
        "::             'Oh My OpenAgent is the full OpenCode harness. Oh My OpenCode Slim keeps a lighter preset.' = 'Oh My OpenAgent ajoute plein d''aides autour d''OpenCode. Oh My OpenCode Slim garde seulement une partie plus legere de ces aides.'",
        "::             'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.' = 'Codex est la voie OpenAI directe. OMX ajoute une facon plus guidee et plus automatique de travailler.'",
        "::             'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.' = 'OpenCode est souvent le plus simple. Codex et surtout OMX sont plus utiles si vous voulez etre davantage guide.'",
        "::             'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.' = 'Installez seulement les CLI que vous utiliserez vraiment. Plus d''outils signifie plus d''authentification, de mises a jour et de chevauchements.'",
        "::             'Oh My OpenAgent is the broader OpenCode harness; Slim keeps a lighter OpenCode-focused preset.' = 'Oh My OpenAgent ajoute beaucoup d''outils autour d''OpenCode ; Slim garde une version plus simple de cette idee.'",
        "::             'Brand-new Windows machine: Install -> First install.' = 'Nouvelle machine Windows : Installation -> Premiere installation.'",
        "::             'Lowest-friction start: OpenCode.' = 'Demarrage le plus simple : OpenCode.'",
        "::             'Best OpenAI-first path: Codex, then OMX if you want deeper automation.' = 'Meilleur parcours si vous voulez surtout OpenAI : Codex d''abord, puis OMX seulement si vous voulez aller plus loin.'",
        "::             'Install Oh My OpenAgent if you want the full harness. Install Slim if you want a lighter preset.' = 'Installez Oh My OpenAgent si vous voulez beaucoup d''aides autour d''OpenCode. Installez Slim si vous voulez une version plus simple.'",
        "::             'Skip tools you do not have keys, subscriptions, or a real workflow for.' = 'Ignorez les outils pour lesquels vous n''avez pas de cle, d''abonnement ou de vrai besoin.'",
    ]:
        data = delete_once(data, "\n" + old, "del fr orphan")

    # ---------- i18n map: remove OMX install title, rename reset entries ----------
    data = delete_once(
        data,
        "\n::             'Oh My Codex / OMX | deprecated' = 'Oh My Codex / OMX | 已弃用'",
        "del zh omx title",
    )
    data = delete_once(
        data,
        "\n::             'Oh My Codex / OMX | deprecated' = 'Oh My Codex / OMX | deprecate'",
        "del fr omx title",
    )
    data = replace_once(
        data,
        "::             'Codex / OMX configs' = 'Codex / OMX 配置'",
        "::             'Codex configs' = 'Codex 配置'",
        "zh reset codex title",
    )
    data = replace_once(
        data,
        "::             'Remove tracked Codex and OMX auth/config files.' = '删除已跟踪的 Codex 和 OMX 认证/配置文件。'",
        "::             'Remove tracked Codex auth/config files.' = '删除已跟踪的 Codex 认证/配置文件。'",
        "zh reset codex subtitle",
    )
    data = replace_once(
        data,
        "::             'Codex / OMX configs' = 'Configs Codex / OMX'",
        "::             'Codex configs' = 'Configs Codex'",
        "fr reset codex title",
    )
    data = replace_once(
        data,
        "::             'Remove tracked Codex and OMX auth/config files.' = 'Supprimer les fichiers config/auth suivis de Codex et OMX.'",
        "::             'Remove tracked Codex auth/config files.' = 'Supprimer les fichiers config/auth suivis de Codex.'",
        "fr reset codex subtitle",
    )
    data = replace_once(
        data,
        "::             'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs' = 'Note    : Oh My Codex / OMX 和 Oh My OpenCode 系列仍为可选安装'",
        "::             'Note    : The Oh My OpenCode variants stay optional installs' = 'Note    : Oh My OpenCode 系列仍为可选安装'",
        "zh first-install note",
    )
    data = replace_once(
        data,
        "::             'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs' = 'Note    : Oh My Codex / OMX et les variantes Oh My OpenCode restent optionnels'",
        "::             'Note    : The Oh My OpenCode variants stay optional installs' = 'Note    : Les variantes Oh My OpenCode restent optionnelles'",
        "fr first-install note",
    )

    # ---------- i18n map: utility subtitle + new reset entries ----------
    data = replace_once(
        data,
        "::             'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, and BMAD.' = '安装 rtk、ccusage、codex-auth、superpowers、OpenSpec、Claw Code 和 BMAD。'",
        "::             'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, and Patchright.' = '安装 rtk、ccusage、codex-auth、superpowers、OpenSpec、Claw Code、BMAD 和 Patchright。'",
        "zh utility subtitle",
    )
    data = replace_once(
        data,
        "::             'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, and BMAD.' = 'Installer rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code et BMAD.'",
        "::             'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, and Patchright.' = 'Installer rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD et Patchright.'",
        "fr utility subtitle",
    )
    data = replace_once(
        data,
        "::             'OMP configs' = 'OMP 配置'\n::             'Remove tracked OMP auth and config files.' = '删除已跟踪的 OMP 认证和配置文件。'",
        "::             'OMP configs' = 'OMP 配置'\n::             'Remove tracked OMP auth and config files.' = '删除已跟踪的 OMP 认证和配置文件。'\n::             'Zcode configs' = 'Zcode 配置'\n::             'Remove tracked Z.ai CLI auth and config files.' = '删除已跟踪的 Z.ai CLI 认证和配置文件。'\n::             'DSH configs' = 'DSH 配置'\n::             'Remove tracked DeepSeek harness auth and config files.' = '删除已跟踪的 DeepSeek harness 认证和配置文件。'\n::             'Muse Code configs' = 'Muse Code 配置'\n::             'Remove tracked Muse Code auth and config files.' = '删除已跟踪的 Muse Code 认证和配置文件。'",
        "zh reset new tools",
    )
    data = replace_once(
        data,
        "::             'OMP configs' = 'Configs OMP'\n::             'Remove tracked OMP auth and config files.' = 'Supprimer les fichiers auth/config suivis de OMP.'",
        "::             'OMP configs' = 'Configs OMP'\n::             'Remove tracked OMP auth and config files.' = 'Supprimer les fichiers auth/config suivis de OMP.'\n::             'Zcode configs' = 'Configs Zcode'\n::             'Remove tracked Z.ai CLI auth and config files.' = 'Supprimer les fichiers auth/config suivis de Z.ai CLI.'\n::             'DSH configs' = 'Configs DSH'\n::             'Remove tracked DeepSeek harness auth and config files.' = 'Supprimer les fichiers auth/config suivis du harness DeepSeek.'\n::             'Muse Code configs' = 'Configs Muse Code'\n::             'Remove tracked Muse Code auth and config files.' = 'Supprimer les fichiers auth/config suivis de Muse Code.'",
        "fr reset new tools",
    )

    # ---------- AgentOptions: drop OMX, add zcode/dsh/muse-code ----------
    data = delete_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'omx-madmax-high'
::         Title = 'OMX | deprecated'
::         Subtitle = 'Deprecated Codex wrapper. Prefer Codex, Pi, or OMP. Still launches when present.'
::         Accent = 'DarkGray'
::         WindowTitle = 'OMX MADMAX HIGH'
::     }
""",
        "AgentOptions remove omx",
    )
    data = replace_once(
        data,
        """::     [pscustomobject]@{
::         Key = 'omp'
::         Title = 'OMP | optional'
::         Subtitle = 'Oh My Pi batteries-included coding agent from omp.sh.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMP'
::     }
:: )""",
        """::     [pscustomobject]@{
::         Key = 'omp'
::         Title = 'OMP | optional'
::         Subtitle = 'Oh My Pi batteries-included coding agent from omp.sh.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMP'
::     }
::     [pscustomobject]@{
::         Key = 'zcode'
::         Title = 'Zcode | GLM toolkit'
::         Subtitle = 'Z.ai GLM coding toolkit: chat, search, media, and doc parsing.'
::         Accent = 'Blue'
::         WindowTitle = 'Zcode'
::     }
::     [pscustomobject]@{
::         Key = 'dsh'
::         Title = 'DSH | DeepSeek harness'
::         Subtitle = 'DeepSeek plugin harness; boots profiles like web, headless, and ACP.'
::         Accent = 'DarkCyan'
::         WindowTitle = 'DSH'
::     }
::     [pscustomobject]@{
::         Key = 'muse-code'
::         Title = 'Muse Code | Meta'
::         Subtitle = 'Meta Muse terminal agent with approvals and OS sandbox.'
::         Accent = 'Blue'
::         WindowTitle = 'Muse Code'
::     }
:: )""",
        "AgentOptions add new",
    )

    # ---------- ToolSpecs: drop omx, add zcode/dsh/muse-code + utility-patchright ----------
    data = delete_once(
        data,
        """::     'omx' = [pscustomobject]@{
::         Command = 'omx'
::         VersionScript = 'omx --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.codex/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Deprecated. Prefer Codex, Pi, or OMP. Install from Install -> Oh My Codex / OMX | deprecated.'
::     }
""",
        "ToolSpecs remove omx",
    )
    data = replace_once(
        data,
        """::     'omp' = [pscustomobject]@{
::         Command = 'omp'
::         VersionScript = 'omp --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> OMP.'
::     }""",
        """::     'omp' = [pscustomobject]@{
::         Command = 'omp'
::         VersionScript = 'omp --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> OMP.'
::     }
::     'zcode' = [pscustomobject]@{
::         Command = 'zai-cli'
::         VersionScript = 'zai-cli --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ZAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.zai/zai-cli/config.json" ] || [ -d "$HOME/.zai/zai-cli" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Zcode.'
::     }
::     'dsh' = [pscustomobject]@{
::         Command = 'dsh'
::         VersionScript = 'dsh --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${DEEPSEEK_API_KEY:-}" ]; then echo env-key; elif [ -d "${DSH_HOME:-$HOME/.dsh}" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> DSH.'
::     }
::     'muse-code' = [pscustomobject]@{
::         Command = 'muse'
::         VersionScript = 'muse --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${META_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.config/muse/settings.json" ] || [ -d "$HOME/.config/muse" ] || [ -d "$HOME/.muse" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Muse Code.'
::     }""",
        "ToolSpecs add agents",
    )
    data = replace_once(
        data,
        """::     'utility-bmad' = [pscustomobject]@{
::         Command = ''
::         VersionScript = ''
::         DetectScript = 'projects_root="${SYTA_PROJECTS_ROOT_WSL:-/mnt/c/.CODEX}"; if [ -d "$projects_root" ]; then first="$(find "$projects_root" -mindepth 2 -maxdepth 2 -type d -name _bmad 2>/dev/null | sort | head -n 1)"; if [ -n "$first" ]; then echo "$first"; fi; fi'
::         AuthScript = 'echo project-scoped'
::         InstallHint = 'Install from Install -> Utilities -> BMAD.'
::     }
:: }""",
        """::     'utility-bmad' = [pscustomobject]@{
::         Command = ''
::         VersionScript = ''
::         DetectScript = 'projects_root="${SYTA_PROJECTS_ROOT_WSL:-/mnt/c/.CODEX}"; if [ -d "$projects_root" ]; then first="$(find "$projects_root" -mindepth 2 -maxdepth 2 -type d -name _bmad 2>/dev/null | sort | head -n 1)"; if [ -n "$first" ]; then echo "$first"; fi; fi'
::         AuthScript = 'echo project-scoped'
::         InstallHint = 'Install from Install -> Utilities -> BMAD.'
::     }
::     'utility-patchright' = [pscustomobject]@{
::         Command = 'patchright'
::         VersionScript = 'patchright --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'echo not-installed'
::         InstallHint = 'Install from Install -> Utilities -> Patchright.'
::     }
:: }""",
        "ToolSpecs add patchright",
    )
    data = delete_once(
        data,
        "::         'omx-madmax-high' { return 'omx' }\n",
        "Resolve-ToolKey omx",
    )

    # ---------- Get-InstallItems ----------
    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('codex', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'zcode', 'dsh', 'muse-code', 'oh-my-openagent', 'oh-my-opencode-slim') -Fast",
        "Install warm keys",
    )
    data = replace_once(
        data,
        """::         $codexDiag = Get-ToolDiagnostics -Key 'codex'
::         $omxDiag = Get-ToolDiagnostics -Key 'omx'
::         $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'""",
        """::         $codexDiag = Get-ToolDiagnostics -Key 'codex'
::         $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'""",
        "Install diags remove omx",
    )
    data = replace_once(
        data,
        """::         $piDiag = Get-ToolDiagnostics -Key 'pi'
::         $ompDiag = Get-ToolDiagnostics -Key 'omp'
::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'""",
        """::         $piDiag = Get-ToolDiagnostics -Key 'pi'
::         $ompDiag = Get-ToolDiagnostics -Key 'omp'
::         $zcodeDiag = Get-ToolDiagnostics -Key 'zcode'
::         $dshDiag = Get-ToolDiagnostics -Key 'dsh'
::         $museDiag = Get-ToolDiagnostics -Key 'muse-code'
::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'""",
        "Install diags add new",
    )
    data = replace_once(
        data,
        """::         $codexDiag = New-WslMissingToolDiagnostics -Key 'codex' -SetupIncomplete:$setupIncomplete
::         $omxDiag = New-WslMissingToolDiagnostics -Key 'omx' -SetupIncomplete:$setupIncomplete
::         $opencodeDiag = New-WslMissingToolDiagnostics -Key 'opencode' -SetupIncomplete:$setupIncomplete""",
        """::         $codexDiag = New-WslMissingToolDiagnostics -Key 'codex' -SetupIncomplete:$setupIncomplete
::         $opencodeDiag = New-WslMissingToolDiagnostics -Key 'opencode' -SetupIncomplete:$setupIncomplete""",
        "Install missing remove omx",
    )
    data = replace_once(
        data,
        """::         $piDiag = New-WslMissingToolDiagnostics -Key 'pi' -SetupIncomplete:$setupIncomplete
::         $ompDiag = New-WslMissingToolDiagnostics -Key 'omp' -SetupIncomplete:$setupIncomplete
::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete""",
        """::         $piDiag = New-WslMissingToolDiagnostics -Key 'pi' -SetupIncomplete:$setupIncomplete
::         $ompDiag = New-WslMissingToolDiagnostics -Key 'omp' -SetupIncomplete:$setupIncomplete
::         $zcodeDiag = New-WslMissingToolDiagnostics -Key 'zcode' -SetupIncomplete:$setupIncomplete
::         $dshDiag = New-WslMissingToolDiagnostics -Key 'dsh' -SetupIncomplete:$setupIncomplete
::         $museDiag = New-WslMissingToolDiagnostics -Key 'muse-code' -SetupIncomplete:$setupIncomplete
::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete""",
        "Install missing add new",
    )
    data = delete_once(
        data,
        "::         [pscustomobject]@{ Title = 'Oh My Codex / OMX | deprecated'; Subtitle = $omxDiag.MenuText; Accent = if ($omxDiag.Installed) { 'DarkGray' } else { 'DarkGray' }; Key = 'omx'; DiagnosticMode = $omxDiag.DiagnosticMode }\n",
        "Install menu remove omx",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = $ompDiag.MenuText; Accent = if ($ompDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omp'; DiagnosticMode = $ompDiag.DiagnosticMode }",
        """::         [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = $ompDiag.MenuText; Accent = if ($ompDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omp'; DiagnosticMode = $ompDiag.DiagnosticMode }
::         [pscustomobject]@{ Title = 'Zcode | GLM toolkit'; Subtitle = $zcodeDiag.MenuText; Accent = if ($zcodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'zcode'; DiagnosticMode = $zcodeDiag.DiagnosticMode }
::         [pscustomobject]@{ Title = 'DSH | DeepSeek harness'; Subtitle = $dshDiag.MenuText; Accent = if ($dshDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'dsh'; DiagnosticMode = $dshDiag.DiagnosticMode }
::         [pscustomobject]@{ Title = 'Muse Code | Meta'; Subtitle = $museDiag.MenuText; Accent = if ($museDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'muse-code'; DiagnosticMode = $museDiag.DiagnosticMode }""",
        "Install menu add new",
    )

    # ---------- Resolve-InstallTargetSelection ----------
    data = delete_once(
        data,
        "::         'omx' = [pscustomobject]@{ Title = 'Oh My Codex / OMX | deprecated'; Subtitle = 'Deprecated. Install or repair OMX only if you still need it.'; Accent = 'DarkGray'; Key = 'omx' }\n",
        "ResolveTarget remove omx",
    )
    data = replace_once(
        data,
        "::         'omp' = [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = 'Install or repair OMP (Oh My Pi).'; Accent = 'Cyan'; Key = 'omp' }",
        """::         'omp' = [pscustomobject]@{ Title = 'OMP | optional'; Subtitle = 'Install or repair OMP (Oh My Pi).'; Accent = 'Cyan'; Key = 'omp' }
::         'zcode' = [pscustomobject]@{ Title = 'Zcode | GLM toolkit'; Subtitle = 'Install or repair Zcode (Z.ai GLM CLI).'; Accent = 'Cyan'; Key = 'zcode' }
::         'dsh' = [pscustomobject]@{ Title = 'DSH | DeepSeek harness'; Subtitle = 'Install or repair DSH (DeepSeek harness).'; Accent = 'Cyan'; Key = 'dsh' }
::         'muse-code' = [pscustomobject]@{ Title = 'Muse Code | Meta'; Subtitle = 'Install or repair Muse Code (Meta).'; Accent = 'Cyan'; Key = 'muse-code' }""",
        "ResolveTarget add agents",
    )
    data = replace_once(
        data,
        "::         'utility-bmad' = [pscustomobject]@{ Title = 'BMAD | project framework'; Subtitle = 'Install BMAD into a selected project.'; Accent = 'Cyan'; Key = 'utility-bmad' }",
        """::         'utility-bmad' = [pscustomobject]@{ Title = 'BMAD | project framework'; Subtitle = 'Install BMAD into a selected project.'; Accent = 'Cyan'; Key = 'utility-bmad' }
::         'utility-patchright' = [pscustomobject]@{ Title = 'Patchright | stealth browser'; Subtitle = 'Install or repair Patchright.'; Accent = 'Cyan'; Key = 'utility-patchright' }""",
        "ResolveTarget add patchright",
    )

    # ---------- summaries ----------
    data = delete_once(
        data,
        "::         [pscustomobject]@{ Label = 'OMX*'; Key = 'omx' }\n",
        "Summary remove omx",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'OMP'; Key = 'omp' }",
        """::         [pscustomobject]@{ Label = 'OMP'; Key = 'omp' }
::         [pscustomobject]@{ Label = 'Zcode'; Key = 'zcode' }
::         [pscustomobject]@{ Label = 'DSH'; Key = 'dsh' }
::         [pscustomobject]@{ Label = 'Muse'; Key = 'muse-code' }""",
        "Summary add agents",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Label = 'BMAD'; Key = 'utility-bmad' }",
        """::         [pscustomobject]@{ Label = 'BMAD'; Key = 'utility-bmad' }
::         [pscustomobject]@{ Label = 'Patchright'; Key = 'utility-patchright' }""",
        "Summary add patchright",
    )

    # ---------- reset menu + legacy alias ----------
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Codex / OMX configs'; Subtitle = 'Remove tracked Codex and OMX auth/config files.'; Accent = 'Cyan'; Key = 'codex-omx' }",
        "::         [pscustomobject]@{ Title = 'Codex configs'; Subtitle = 'Remove tracked Codex auth/config files.'; Accent = 'Cyan'; Key = 'codex' }",
        "Reset menu codex",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'OMP configs'; Subtitle = 'Remove tracked OMP auth and config files.'; Accent = 'Yellow'; Key = 'omp' }",
        """::         [pscustomobject]@{ Title = 'OMP configs'; Subtitle = 'Remove tracked OMP auth and config files.'; Accent = 'Yellow'; Key = 'omp' }
::         [pscustomobject]@{ Title = 'Zcode configs'; Subtitle = 'Remove tracked Z.ai CLI auth and config files.'; Accent = 'Blue'; Key = 'zcode' }
::         [pscustomobject]@{ Title = 'DSH configs'; Subtitle = 'Remove tracked DeepSeek harness auth and config files.'; Accent = 'DarkCyan'; Key = 'dsh' }
::         [pscustomobject]@{ Title = 'Muse Code configs'; Subtitle = 'Remove tracked Muse Code auth and config files.'; Accent = 'Blue'; Key = 'muse-code' }""",
        "Reset menu new tools",
    )
    data = replace_once(
        data,
        """:: function Select-ResetConfigTarget {
::     if ($ResetTarget) {
::         return $ResetTarget
::     }""",
        """:: function Select-ResetConfigTarget {
::     if ($ResetTarget) {
::         if ($ResetTarget -eq 'codex-omx') {
::             return 'codex'
::         }
::         return $ResetTarget
::     }""",
        "Reset legacy alias",
    )

    # ---------- wslRequiredKeys ----------
    data = replace_once(
        data,
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad')",
        "::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'kilocode-cli', 'claude-code', 'gemini-cli', 'droid-cli', 'grok-cli', 'command-code', 'reasonix', 'pi', 'omp', 'zcode', 'dsh', 'muse-code', 'oh-my-openagent', 'oh-my-opencode-slim', 'utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad', 'utility-patchright')",
        "wslRequiredKeys",
    )

    # ---------- Update menu + light scope + first-install note ----------
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed).'; Accent = 'Green'; Key = 'UpdateLight' }",
        "::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP, Zcode, DSH, Muse Code.'; Accent = 'Green'; Key = 'UpdateLight' }",
        "Update menu light",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Update utilities add-ons'; Subtitle = 'Update installed utility add-ons only: RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD.'; Accent = 'Cyan'; Key = 'UpdateUtilities' }",
        "::         [pscustomobject]@{ Title = 'Update utilities add-ons'; Subtitle = 'Update installed utility add-ons only: RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, Patchright.'; Accent = 'Cyan'; Key = 'UpdateUtilities' }",
        "Update menu utilities",
    )
    data = replace_once(
        data,
        "::         'Scope   : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP (OMX deprecated if installed)',",
        "::         'Scope   : Codex, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI, Command Code, Reasonix, Pi, OMP, Zcode, DSH, Muse Code',",
        "Light update scope",
    )
    data = replace_once(
        data,
        "::         'Scope   : RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD',",
        "::         'Scope   : RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, Patchright',",
        "Utilities update scope",
    )
    data = replace_once(
        data,
        "::         'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs'",
        "::         'Note    : The Oh My OpenCode variants stay optional installs'",
        "First-install note",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'Utilities | add-ons'; Subtitle = if ($distroReady) { 'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, and BMAD.' } else { $blockedText }; Accent = if ($distroReady) { 'Blue' } else { 'Yellow' }; Key = 'utilities' }",
        "::         [pscustomobject]@{ Title = 'Utilities | add-ons'; Subtitle = if ($distroReady) { 'Install rtk, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, and Patchright.' } else { $blockedText }; Accent = if ($distroReady) { 'Blue' } else { 'Yellow' }; Key = 'utilities' }",
        "Extra utilities subtitle",
    )

    # ---------- Get-UtilityInstallItems ----------
    data = replace_once(
        data,
        "::         Warm-ToolDiagnosticsCache -Keys @('utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad') -Fast",
        "::         Warm-ToolDiagnosticsCache -Keys @('utility-rtk', 'utility-ccusage', 'utility-codex-auth', 'utility-superpowers', 'utility-openspec', 'utility-claw-code', 'utility-bmad', 'utility-patchright') -Fast",
        "Utility warm keys",
    )
    data = replace_once(
        data,
        """::         $clawCodeDiag = Get-ToolDiagnostics -Key 'utility-claw-code'
::         $bmadDiag = Get-ToolDiagnostics -Key 'utility-bmad'""",
        """::         $clawCodeDiag = Get-ToolDiagnostics -Key 'utility-claw-code'
::         $bmadDiag = Get-ToolDiagnostics -Key 'utility-bmad'
::         $patchrightDiag = Get-ToolDiagnostics -Key 'utility-patchright'""",
        "Utility diags add",
    )
    data = replace_once(
        data,
        """::         $clawCodeDiag = New-WslMissingToolDiagnostics -Key 'utility-claw-code' -SetupIncomplete:$setupIncomplete
::         $bmadDiag = New-WslMissingToolDiagnostics -Key 'utility-bmad' -SetupIncomplete:$setupIncomplete""",
        """::         $clawCodeDiag = New-WslMissingToolDiagnostics -Key 'utility-claw-code' -SetupIncomplete:$setupIncomplete
::         $bmadDiag = New-WslMissingToolDiagnostics -Key 'utility-bmad' -SetupIncomplete:$setupIncomplete
::         $patchrightDiag = New-WslMissingToolDiagnostics -Key 'utility-patchright' -SetupIncomplete:$setupIncomplete""",
        "Utility missing add",
    )
    data = replace_once(
        data,
        "::         [pscustomobject]@{ Title = 'BMAD | project framework'; Subtitle = $bmadDiag.MenuText; Accent = if ($bmadDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'utility-bmad'; DiagnosticMode = $bmadDiag.DiagnosticMode }",
        """::         [pscustomobject]@{ Title = 'BMAD | project framework'; Subtitle = $bmadDiag.MenuText; Accent = if ($bmadDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'utility-bmad'; DiagnosticMode = $bmadDiag.DiagnosticMode }
::         [pscustomobject]@{ Title = 'Patchright | stealth browser'; Subtitle = $patchrightDiag.MenuText; Accent = if ($patchrightDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'utility-patchright'; DiagnosticMode = $patchrightDiag.DiagnosticMode }""",
        "Utility menu add patchright",
    )

    # ---------- preflight extras (both identical utility switches) ----------
    data = replace_all(
        data,
        """::             'utility-bmad' { @(
::                 'BMAD installs into a selected project instead of your global shell profile.',
::                 'SYTA will ask you to choose a project folder before launching the BMAD installer.',
::                 "Use Update -> Update utilities add-ons later to quick-update BMAD installs already found under $script:ProjectsRoot."
::             ) }""",
        """::             'utility-bmad' { @(
::                 'BMAD installs into a selected project instead of your global shell profile.',
::                 'SYTA will ask you to choose a project folder before launching the BMAD installer.',
::                 "Use Update -> Update utilities add-ons later to quick-update BMAD installs already found under $script:ProjectsRoot."
::             ) }
::             'utility-patchright' { @(
::                 'Patchright is the undetected Playwright drop-in for browser automation and scraping.',
::                 'SYTA installs the npm package plus the Chromium driver (patchright install chromium).',
::                 'Handy when plain fetching gets blocked; it often fixes stubborn 404s.'
::             ) }""",
        "utility patchright extras",
        expected=2,
    )

    # ---------- InstallMode generic else: per-agent extra lines ----------
    data = replace_once(
        data,
        """::     } else {
::         $diag = Get-ToolDiagnostics -Key $selection.Key -Refresh
::         Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::             "Target  : $($selection.Title)",
::             "Current : $($diag.InstallText)",
::             "Version : $($diag.VersionText)",
::             "Auth    : $($diag.AuthText)",
::             "Path    : $($diag.PathText)"
::         )
::     }""",
        """::     } else {
::         $diag = Get-ToolDiagnostics -Key $selection.Key -Refresh
::         $extraLines = switch ($selection.Key) {
::             'zcode' { @(
::                 'Zcode runs on the Z.ai GLM platform; bring a Z.ai API key (global or china region).',
::                 'Set it with: zai-cli auth set "your-key" --region global'
::             ) }
::             'dsh' { @(
::                 'DSH boots plugin-profile stacks (web, headless, sdk, acp) from $DSH_HOME (~/.dsh).',
::                 'Profiles auto-initialize on first use; plugin management uses pnpm.'
::             ) }
::             'muse-code' { @(
::                 'Muse Code installs a native binary via the official Meta installer.',
::                 'Authenticate with: muse login (browser) or export META_API_KEY.'
::             ) }
::             default { @() }
::         }
::         Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines (@(
::             "Target  : $($selection.Title)",
::             "Current : $($diag.InstallText)",
::             "Version : $($diag.VersionText)",
::             "Auth    : $($diag.AuthText)",
::             "Path    : $($diag.PathText)"
::         ) + $extraLines)
::     }""",
        "InstallMode agent extras",
    )

    # ---------- Explanations menu titles ----------
    data = replace_once(
        data,
        "::                     [pscustomobject]@{ Title = 'Parcours OpenAI | Codex et OMX'; Subtitle = 'Quand rester sur Codex seul, et quand OMX ajoute une vraie valeur.'; Accent = 'Green'; Key = 'openai' }",
        "::                     [pscustomobject]@{ Title = 'Parcours OpenAI | Codex'; Subtitle = 'Quand rester sur Codex seul, et quand OMP ou Pi ajoutent une vraie valeur.'; Accent = 'Green'; Key = 'openai' }",
        "FR openai menu",
    )
    data = replace_once(
        data,
        "::                     [pscustomobject]@{ Title = 'OpenAI 路线 | Codex 和 OMX'; Subtitle = '什么时候只用 Codex，什么时候 OMX 才真的有价值。'; Accent = 'Green'; Key = 'openai' }",
        "::                     [pscustomobject]@{ Title = 'OpenAI 路线 | Codex'; Subtitle = '什么时候只用 Codex，什么时候 OMP 或 Pi 才真的有价值。'; Accent = 'Green'; Key = 'openai' }",
        "ZH openai menu",
    )
    data = replace_once(
        data,
        "::                     [pscustomobject]@{ Title = 'OpenAI path | Codex and OMX'; Subtitle = 'When Codex alone is enough, and when OMX actually adds value.'; Accent = 'Green'; Key = 'openai' }",
        "::                     [pscustomobject]@{ Title = 'OpenAI path | Codex'; Subtitle = 'When Codex alone is enough, and when OMP or Pi add value.'; Accent = 'Green'; Key = 'openai' }",
        "EN openai menu",
    )
    # (menu subtitle replaces below use full lines)
    data = replace_once(
        data,
        "Subtitle = 'RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD et les extras similaires.'",
        "Subtitle = 'RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, Patchright et les extras similaires.'",
        "FR utilities menu subtitle",
    )
    data = replace_once(
        data,
        "Subtitle = 'RTK、ccusage、codex-auth、superpowers、OpenSpec、Claw Code、BMAD 这类附加工具。'",
        "Subtitle = 'RTK、ccusage、codex-auth、superpowers、OpenSpec、Claw Code、BMAD、Patchright 这类附加工具。'",
        "ZH utilities menu subtitle",
    )
    data = replace_once(
        data,
        "Subtitle = 'RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, and similar extras.'",
        "Subtitle = 'RTK, ccusage, codex-auth, superpowers, OpenSpec, Claw Code, BMAD, Patchright, and similar extras.'",
        "EN utilities menu subtitle",
    )

    # ---------- Explanations content: FR ----------
    for old, new, label in [
        (
            "::                     'OMX est une couche plus lourde par-dessus Codex. C''est utile surtout si vous voulez plus de structure et d''automatisation.',",
            "::                     'OMP et Pi sont les voies maintenues si vous voulez plus de structure que Codex. Zcode (Z.ai GLM), DSH (harness DeepSeek) et Muse Code (Meta) sont les nouveautes a connaitre.',",
            "FR beginner omx",
        ),
        (
            "::                     'OMX convient si vous voulez plus de workflows guides, de planification et d''orchestration.',",
            "::                     'OMP ou Pi conviennent si vous voulez plus de workflows guides, de planification et d''orchestration. Zcode, DSH et Muse Code valent le detour si vous vivez dans ces ecosystemes.',",
            "FR chooser omx",
        ),
        (
            "::                     'Ajoutez OMX seulement quand vous ressentez un vrai besoin de structure, de planification ou d''automatisation plus lourde.',",
            "::                     'Ajoutez OMP ou Pi seulement quand vous ressentez un vrai besoin de structure, de planification ou d''automatisation plus lourde.',",
            "FR openai add",
        ),
        (
            "::                     'Pour beaucoup d''utilisateurs, Codex d''abord puis OMX plus tard est plus sain que l''inverse.',",
            "::                     'Pour beaucoup d''utilisateurs, Codex d''abord puis OMP ou Pi plus tard est plus sain que l''inverse.'",
            "FR openai later",
        ),
        (
            "::                     'Commencer directement par OMX peut sembler puissant, mais aussi plus lourd a comprendre et a maintenir.',",
            "::                     'Commencer directement par un harness plus lourd peut sembler puissant, mais aussi plus lourd a comprendre et a maintenir.'",
            "FR openai start",
        ),
        (
            "::                     'Si vous voulez surtout OpenAI: commencez par Codex, puis ajoutez OMX plus tard si vous manquez de structure.',",
            "::                     'Si vous voulez surtout OpenAI: commencez par Codex, puis ajoutez OMP ou Pi plus tard si vous manquez de structure.',",
            "FR recommend openai",
        ),
    ]:
        data = replace_once(data, old, new, label)

    # ---------- Explanations content: ZH ----------
    for old, new, label in [
        (
            "::                     'OMX 是叠在 Codex 上面的更重一层，适合想要更多结构、规划和自动化的人。',",
            "::                     '如果你想要比 Codex 更强的编排，OMP 和 Pi 是目前仍在维护的路线。Zcode（Z.ai GLM）、DSH（DeepSeek harness）和 Muse Code（Meta）是值得了解的新选择。',",
            "ZH beginner omx",
        ),
        (
            "::                     '如果你想要更强的工作流、规划和编排，OMX 才值得加上去。',",
            "::                     '如果你想要更强的工作流、规划和编排，OMP 或 Pi 更合适。如果你本来就在这些生态里，Zcode、DSH 和 Muse Code 也值得一看。',",
            "ZH chooser omx",
        ),
        (
            "::                     '只有当你真的需要更多结构、规划或更重的自动化时，再加 OMX。',",
            "::                     '只有当你真的需要更多结构、规划或更重的自动化时，再加 OMP 或 Pi。',",
            "ZH openai add",
        ),
        (
            "::                     '对大多数人来说，先用 Codex 做真实工作，再决定要不要加 OMX，更健康。',",
            "::                     '对大多数人来说，先用 Codex 做真实工作，再决定要不要加 OMP 或 Pi，更健康。'",
            "ZH openai later",
        ),
        (
            "::                     '一开始就直接上 OMX 看起来更强，但理解和维护成本也更高。',",
            "::                     '一开始就直接上重型 harness 看起来更强，但理解和维护成本也更高。'",
            "ZH openai start",
        ),
        (
            "::                     '如果你更想走 OpenAI 路线，就先选 Codex；只有后面真的缺结构时再加 OMX。',",
            "::                     '如果你更想走 OpenAI 路线，就先选 Codex；只有后面真的缺结构时再加 OMP 或 Pi。'",
            "ZH recommend openai",
        ),
    ]:
        data = replace_once(data, old, new, label)

    # ---------- Explanations content: EN ----------
    for old, new, label in [
        (
            "::                     'OMX is a heavier layer on top of Codex for people who want more structure, planning, and automation.',",
            "::                     'If you want heavier orchestration than Codex, OMP and Pi are the maintained lanes. Zcode (Z.ai GLM), DSH (the DeepSeek harness), and Muse Code (Meta) are the newer options worth knowing.',",
            "EN beginner omx",
        ),
        (
            "::                     'OMX fits best when you want more guided workflows, planning surfaces, and orchestration.',",
            "::                     'OMP or Pi fit best when you want more guided workflows, planning surfaces, and orchestration. Zcode, DSH, and Muse Code are worth a look if you live in those ecosystems.',",
            "EN chooser omx",
        ),
        (
            "::                     'Add OMX only when you feel a real need for more structure, planning, or heavier automation.',",
            "::                     'Add OMP or Pi only when you feel a real need for more structure, planning, or heavier automation.',",
            "EN openai add",
        ),
        (
            "::                     'For many users, Codex first and OMX later is healthier than starting with the heavier layer.',",
            "::                     'For many users, Codex first and OMP or Pi later is healthier than starting with the heavier layer.',",
            "EN openai later",
        ),
        (
            "::                     'Starting directly on OMX can look powerful, but it is also more to learn and maintain.',",
            "::                     'Starting directly on a heavier harness can look powerful, but it is also more to learn and maintain.',",
            "EN openai start",
        ),
        (
            "::                     'If you want the OpenAI path: Codex first, then OMX later only if you actually need more structure.',",
            "::                     'If you want the OpenAI path: Codex first, then OMP or Pi later only if you actually need more structure.',",
            "EN recommend openai",
        ),
    ]:
        data = replace_once(data, old, new, label)

    # ---------- Explanations: add budget/ecosystem line + Patchright utility lines ----------
    data = replace_once(
        data,
        """::                     'Si vous payez deja surtout Claude ou Gemini, installez seulement cette voie au lieu de tout empiler.',""",
        """::                     'Si vous payez deja surtout Claude ou Gemini, installez seulement cette voie au lieu de tout empiler.',
::                     'Avec un petit budget, Zcode utilise les plans GLM de Z.ai ; les utilisateurs DeepSeek ont DSH ; les utilisateurs Meta ont Muse Code.',""",
        "FR recommend new lanes",
    )
    data = replace_once(
        data,
        """::                     '如果你本来就主要用 Claude 或 Gemini，就只装那条路线，不要什么都堆上去。',""",
        """::                     '如果你本来就主要用 Claude 或 Gemini，就只装那条路线，不要什么都堆上去。',
::                     '如果预算有限，Zcode 可以用价格实惠的 Z.ai GLM 方案；DeepSeek 用户有 DSH；Meta 用户有 Muse Code。',""",
        "ZH recommend new lanes",
    )
    data = replace_once(
        data,
        """::                     'If you already pay for or rely on Claude or Gemini, install that lane instead of stacking everything.',""",
        """::                     'If you already pay for or rely on Claude or Gemini, install that lane instead of stacking everything.',
::                     'On a budget, Zcode rides the cheap Z.ai GLM plans; DeepSeek users get DSH; Meta users get Muse Code.',""",
        "EN recommend new lanes",
    )
    data = replace_once(
        data,
        """::                     'superpowers ajoute une discipline et des skills autour de l''agent, mais c''est une couche avancee, pas une base.',""",
        """::                     'superpowers ajoute une discipline et des skills autour de l''agent, mais c''est une couche avancee, pas une base.',
::                     'Patchright est le remplacant furtif de Playwright pour l''automatisation navigateur et le scraping ; il debloque souvent les 404 qui resistent au telechargement simple.',""",
        "FR utilities patchright",
    )
    data = replace_once(
        data,
        """::                     'superpowers 会给代理增加一整套工作流纪律和技能，但它是高级层，不是基础层。',""",
        """::                     'superpowers 会给代理增加一整套工作流纪律和技能，但它是高级层，不是基础层。',
::                     'Patchright 是隐身版 Playwright，用于浏览器自动化和抓取；当普通抓取遇到顽固 404 时，它常常能解决问题。',""",
        "ZH utilities patchright",
    )
    data = replace_once(
        data,
        """::                     'superpowers adds workflow discipline and skill packs around the agent, but it is an advanced layer, not a base install.',""",
        """::                     'superpowers adds workflow discipline and skill packs around the agent, but it is an advanced layer, not a base install.',
::                     'Patchright is the undetected Playwright drop-in for browser automation and scraping; it often fixes stubborn blocked 404s where plain fetching fails.',""",
        "EN utilities patchright",
    )

    # ================= SH LAYER: diagnostics =================
    data = delete_once(
        data,
        """::     omx)
::       command_name='omx'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/auth.json" ] && auth='config-present'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::       ;;
""",
        "diag remove omx",
    )
    data = replace_once(
        data,
        """::     omp)
::       command_name='omp'
::       { [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; } && auth='config-present'
::       ;;""",
        """::     omp)
::       command_name='omp'
::       { [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.omp/agent" ] || [ -f "$HOME/.omp/agent/config.yml" ] || [ -d "$HOME/.omp" ]; } && auth='config-present'
::       ;;
::     zcode)
::       command_name='zai-cli'
::       [ -n "${ZAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.zai/zai-cli/config.json" ] || [ -d "$HOME/.zai/zai-cli" ]; } && auth='config-present'
::       ;;
::     dsh)
::       command_name='dsh'
::       [ -n "${DEEPSEEK_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -d "${DSH_HOME:-$HOME/.dsh}" ] && auth='config-present'
::       ;;
::     muse-code)
::       command_name='muse'
::       [ -n "${META_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -f "$HOME/.config/muse/settings.json" ] || [ -d "$HOME/.config/muse" ] || [ -d "$HOME/.muse" ]; } && auth='config-present'
::       ;;
::     utility-patchright)
::       command_name='patchright'
::       auth='not-installed'
::       ;;""",
        "diag add new tools",
    )
    data = replace_once(
        data,
        '::       command-code) path="$(resolve_tool_binary command-code cmd 2>/dev/null || true)" ;;',
        '::       command-code) path="$(resolve_tool_binary command-code commandcode cmdc cmd 2>/dev/null || true)" ;;',
        "diag command-code aliases",
    )

    # ================= SH LAYER: run-agent =================
    for old, new, label in [
        (
            "::         omx_missing) printf 'omx n''est pas disponible dans le PATH.\\n' ;;",
            "::         zcode_missing) printf 'zai-cli n''est pas disponible dans le PATH.\\n' ;;\n::         dsh_missing) printf 'dsh n''est pas disponible dans le PATH.\\n' ;;\n::         muse_missing) printf 'muse n''est pas disponible dans le PATH.\\n' ;;",
            "fr agent missing",
        ),
        (
            "::         launch_omx) printf 'Lancement de OMX MADMAX HIGH...\\n\\n' ;;",
            "::         launch_zcode) printf 'Lancement de Zcode (Z.ai GLM)...\\n\\n' ;;\n::         launch_dsh) printf 'Lancement de DSH (web)...\\n\\n' ;;\n::         launch_muse) printf 'Lancement de Muse Code...\\n\\n' ;;",
            "fr agent launch",
        ),
        (
            "::         omx_missing) printf 'PATH 中没有 omx。\\n' ;;",
            "::         zcode_missing) printf 'PATH 中没有 zai-cli。\\n' ;;\n::         dsh_missing) printf 'PATH 中没有 dsh。\\n' ;;\n::         muse_missing) printf 'PATH 中没有 muse。\\n' ;;",
            "zh agent missing",
        ),
        (
            "::         launch_omx) printf '正在启动 OMX MADMAX HIGH...\\n\\n' ;;",
            "::         launch_zcode) printf '正在启动 Zcode（Z.ai GLM）...\\n\\n' ;;\n::         launch_dsh) printf '正在启动 DSH（web）...\\n\\n' ;;\n::         launch_muse) printf '正在启动 Muse Code...\\n\\n' ;;",
            "zh agent launch",
        ),
        (
            "::         omx_missing) printf 'omx is not available in PATH.\\n' ;;",
            "::         zcode_missing) printf 'zai-cli is not available in PATH.\\n' ;;\n::         dsh_missing) printf 'dsh is not available in PATH.\\n' ;;\n::         muse_missing) printf 'muse is not available in PATH.\\n' ;;",
            "en agent missing",
        ),
        (
            "::         launch_omx) printf 'Launching OMX MADMAX HIGH...\\n\\n' ;;",
            "::         launch_zcode) printf 'Launching Zcode (Z.ai GLM)...\\n\\n' ;;\n::         launch_dsh) printf 'Launching DSH (web profile)...\\n\\n' ;;\n::         launch_muse) printf 'Launching Muse Code...\\n\\n' ;;",
            "en agent launch",
        ),
    ]:
        data = replace_once(data, old, new, label)
    data = replace_once(
        data,
        """::     omx-madmax-high)
::       if ! command -v omx >/dev/null 2>&1; then msg omx_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_omx; omx --madmax --high ;;""",
        """::     zcode)
::       if ! command -v zai-cli >/dev/null 2>&1; then msg zcode_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_zcode; zai-cli chat ;;
::     dsh)
::       if ! command -v dsh >/dev/null 2>&1; then msg dsh_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_dsh; dsh web ;;
::     muse-code)
::       if ! command -v muse >/dev/null 2>&1; then msg muse_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_muse; muse ;;""",
        "run_agent new tools",
    )

    # ================= SH LAYER: install-tool =================
    data = replace_once(
        data,
        ':: NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"',
        ':: NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh"',
        "NVM bump",
    )
    data = delete_once(data, ":: omx|oh-my-codex\n", "cleaner remove omx")
    data = replace_once(
        data,
        ":: dsnix|dsnix\n",
        ":: dsnix|dsnix\n:: zai-cli|@z_ai/zai-cli\n:: dsh|@deepseek-ai/dsh\n:: patchright|patchright\n",
        "cleaner add new",
    )
    data = replace_once(
        data,
        """:: codex-omx|Codex / OMX config|file|~/.codex/config.toml
:: codex-omx|Codex / OMX auth|file|~/.codex/auth.json""",
        """:: codex|Codex config|file|~/.codex/config.toml
:: codex|Codex auth|file|~/.codex/auth.json""",
        "reset specs codex",
    )
    data = replace_once(
        data,
        """:: omp|OMP agent config|file|~/.omp/agent/config.yml
:: omp|OMP agent directory|dir|~/.omp/agent
:: omp|OMP config directory|dir|~/.omp""",
        """:: omp|OMP agent config|file|~/.omp/agent/config.yml
:: omp|OMP agent directory|dir|~/.omp/agent
:: omp|OMP config directory|dir|~/.omp
:: zcode|Z.ai CLI config|file|~/.zai/zai-cli/config.json
:: zcode|Z.ai CLI config directory|dir|~/.zai/zai-cli
:: zcode|Z.ai CLI home directory|dir|~/.zai
:: dsh|DSH home directory|dir|~/.dsh
:: muse-code|Muse Code settings|file|~/.config/muse/settings.json
:: muse-code|Muse Code config directory|dir|~/.config/muse
:: muse-code|Muse Code home directory|dir|~/.muse""",
        "reset specs new tools",
    )
    data = replace_once(
        data,
        ":: run_reset_tool_configs() {\n::   local selection=\"${1:-all}\"",
        ":: run_reset_tool_configs() {\n::   local selection=\"${1:-all}\"\n::   if [ \"$selection\" = 'codex-omx' ]; then selection='codex'; fi",
        "reset legacy alias",
    )
    data = delete_once(
        data,
        """:: install_omx() {
::   ensure_node_npm_latest || return 1
::   run_step "Install oh-my-codex" with_nvm npm install -g oh-my-codex || return 1
::   load_user_env
::   if with_nvm command -v omx >/dev/null 2>&1; then
::     run_step "Run omx setup" with_nvm omx setup --force --verbose || return 1
::     with_nvm omx doctor || true
::   else
::     printf 'omx command is still missing after install.
:: '
::     return 1
::   fi
:: }
::
""",
        "install remove omx",
    )
    data = replace_once(
        data,
        """:: install_opencode() {
::   install_opencode_via_npm || return 1
::   load_user_env
::   if command -v opencode >/dev/null 2>&1; then
::     opencode --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'OpenCode install finished but opencode is still not on PATH.
:: '
::   return 1
:: }""",
        """:: install_opencode() {
::   ensure_curl || return 1
::   if bash -lc 'curl -fsSL https://opencode.ai/install | bash'; then
::     load_user_env
::   else
::     printf 'Official OpenCode installer failed, falling back to npm.
:: '
::     install_opencode_via_npm || return 1
::     load_user_env
::   fi
::   if command -v opencode >/dev/null 2>&1; then
::     opencode --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'OpenCode install finished but opencode is still not on PATH.
:: '
::   return 1
:: }""",
        "install opencode official",
    )
    data = replace_once(
        data,
        """::   printf 'OMP install finished but omp is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        """::   printf 'OMP install finished but omp is still not on PATH.
:: '
::   return 1
:: }
::
:: install_zcode() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Zcode (Z.ai GLM CLI)" with_nvm npm install -g @z_ai/zai-cli || return 1
::   load_user_env
::   if command -v zai-cli >/dev/null 2>&1; then
::     with_nvm zai-cli --version 2>/dev/null || true
::     printf 'Authenticate with: zai-cli auth set "your-key" --region global (or china).
:: '
::     return 0
::   fi
::   printf 'Zcode install finished but zai-cli is still not on PATH.
:: '
::   return 1
:: }
::
:: install_dsh() {
::   ensure_node_npm_latest || return 1
::   run_step "Install DSH (DeepSeek harness)" with_nvm npm install -g @deepseek-ai/dsh || return 1
::   load_user_env
::   if command -v dsh >/dev/null 2>&1; then
::     with_nvm dsh --version 2>/dev/null || true
::     printf 'Profiles auto-initialize on first use (web, headless, sdk, acp). Plugin management uses pnpm.
:: '
::     return 0
::   fi
::   printf 'DSH install finished but dsh is still not on PATH.
:: '
::   return 1
:: }
::
:: install_muse_code() {
::   ensure_curl || return 1
::   run_step "Install Muse Code via official installer" bash -lc 'curl -fsSL https://dev.meta.ai/install.sh | bash' || return 1
::   load_user_env
::   export PATH="$HOME/.local/bin:$PATH"
::   if command -v muse >/dev/null 2>&1; then
::     muse --version 2>/dev/null || true
::     printf 'Authenticate with: muse login (browser) or export META_API_KEY.
:: '
::     return 0
::   fi
::   printf 'Muse Code install finished but muse is still not on PATH.
:: '
::   return 1
:: }
::
:: install_patchright() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Patchright" with_nvm npm install -g patchright@latest || return 1
::   load_user_env
::   run_step "Install Patchright Chromium driver" with_nvm patchright install chromium || return 1
::   load_user_env
::   if command -v patchright >/dev/null 2>&1; then
::     patchright --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'Patchright install finished but patchright is still not on PATH.
:: '
::   return 1
:: }
::
:: have_rtk_token_killer() {""",
        "install add new funcs",
    )
    data = replace_once(
        data,
        "::   omx) install_omx || status=$? ;;",
        """::   zcode) install_zcode || status=$? ;;
::   dsh) install_dsh || status=$? ;;
::   muse-code) install_muse_code || status=$? ;;
::   utility-patchright) install_patchright || status=$? ;;""",
        "install switch new",
    )

    # ================= SH LAYER: update-ai-cli-tools =================
    data = replace_once(
        data,
        ":: for tool in codex omx opencode kilo claude gemini droid grok command-code cmd reasonix dsnix pi omp npm npx; do",
        ":: for tool in codex opencode kilo claude gemini droid grok command-code commandcode cmdc cmd reasonix dsnix pi omp zai-cli dsh muse patchright npm npx; do",
        "update-ai tool list",
    )
    data = replace_once(
        data,
        """::   if have_cmd omx; then
::     if have_nvm; then
::       run_step "Update Oh My Codex / OMX (deprecated)" with_nvm npm install -g oh-my-codex || true
::     else
::       run_step "Update Oh My Codex / OMX (deprecated)" npm install -g oh-my-codex || true
::     fi
::   else
::     echo
::     echo "== Update Oh My Codex / OMX (deprecated) =="
::     echo SKIPPED
::   fi""",
        """::   if have_cmd zai-cli; then
::     if have_nvm; then
::       run_step "Update Zcode (Z.ai GLM CLI)" with_nvm npm install -g @z_ai/zai-cli || true
::     else
::       run_step "Update Zcode (Z.ai GLM CLI)" npm install -g @z_ai/zai-cli || true
::     fi
::   else
::     echo
::     echo "== Update Zcode (Z.ai GLM CLI) =="
::     echo SKIPPED
::   fi
::
::   if have_cmd dsh; then
::     if have_nvm; then
::       run_step "Update DSH (DeepSeek harness)" with_nvm npm install -g @deepseek-ai/dsh || true
::     else
::       run_step "Update DSH (DeepSeek harness)" npm install -g @deepseek-ai/dsh || true
::     fi
::   else
::     echo
::     echo "== Update DSH (DeepSeek harness) =="
::     echo SKIPPED
::   fi
::
::   if have_cmd muse; then
::     run_step "Update Muse Code via official installer" bash -lc 'curl -fsSL https://dev.meta.ai/install.sh | bash' || true
::   else
::     echo
::     echo "== Update Muse Code via official installer =="
::     echo SKIPPED
::   fi""",
        "update-ai new tools",
    )
    data = replace_once(
        data,
        "::   if have_cmd command-code || have_cmd cmd; then",
        "::   if have_cmd command-code || have_cmd commandcode || have_cmd cmdc || have_cmd cmd; then",
        "update-ai command-code aliases",
    )
    data = replace_once(
        data,
        """:: if have_cmd opencode || [ -x "$HOME/.opencode/bin/opencode" ]; then
::   if have_nvm || have_cmd npm; then
::     if have_nvm; then
::       run_step "Update OpenCode via npm" with_nvm npm install -g opencode-ai || true
::     else
::       run_step "Update OpenCode via npm" npm install -g opencode-ai || true
::     fi
::   else
::     echo
::     echo "== Update OpenCode via npm =="
::     echo SKIPPED
::   fi
:: else
::   echo
::   echo "== Update OpenCode =="
::   echo SKIPPED
:: fi""",
        """:: if have_cmd opencode || [ -x "$HOME/.opencode/bin/opencode" ]; then
::   _opencode_bin="$(command -v opencode 2>/dev/null || true)"
::   if [ -z "$_opencode_bin" ] && [ -x "$HOME/.opencode/bin/opencode" ]; then _opencode_bin="$HOME/.opencode/bin/opencode"; fi
::   case "$_opencode_bin" in
::     *"/.nvm/"*|*"/.npm-global/"*|*"/.volta/"*|*"/.asdf/"*)
::       if have_nvm; then
::         run_step "Update OpenCode via npm" with_nvm npm install -g opencode-ai || true
::       else
::         run_step "Update OpenCode via npm" npm install -g opencode-ai || true
::       fi
::       ;;
::     *)
::       run_step "Update OpenCode via official installer" bash -lc 'curl -fsSL https://opencode.ai/install | bash' || true
::       ;;
::   esac
:: else
::   echo
::   echo "== Update OpenCode =="
::   echo SKIPPED
:: fi""",
        "update-ai opencode smart",
    )

    # ================= SH LAYER: update-extra-utilities =================
    data = replace_once(
        data,
        ':: if have_cmd ccusage || have_cmd codex-auth || have_cmd openspec || [ "${#bmad_projects[@]}" -gt 0 ]; then',
        ':: if have_cmd ccusage || have_cmd codex-auth || have_cmd openspec || have_cmd patchright || [ "${#bmad_projects[@]}" -gt 0 ]; then',
        "update-extra node_required",
    )
    data = replace_once(
        data,
        """:: else
::   echo
::   echo "== Update OpenSpec =="
::   echo SKIPPED
:: fi
::
:: if [ -d "$HOME/.codex/claw-code/.git" ]; then""",
        """:: else
::   echo
::   echo "== Update OpenSpec =="
::   echo SKIPPED
:: fi
::
:: if have_cmd patchright; then
::   if [ "$node_ready" -eq 1 ]; then
::     run_npm_global_update "Update Patchright" "patchright@latest" || true
::     if have_nvm; then
::       run_step "Refresh Patchright Chromium driver" with_nvm patchright install chromium || true
::     else
::       run_step "Refresh Patchright Chromium driver" patchright install chromium || true
::     fi
::   else
::     echo
::     echo "== Update Patchright =="
::     echo SKIPPED
::   fi
:: else
::   echo
::   echo "== Update Patchright =="
::   echo SKIPPED
:: fi
::
:: if [ -d "$HOME/.codex/claw-code/.git" ]; then""",
        "update-extra patchright",
    )

    # ================= SH LAYER: update-wsl-coding-tools =================
    data = replace_once(
        data,
        ":: for tool in codex omx opencode npm pnpm pipx uv rustup; do",
        ":: for tool in codex opencode kilo claude gemini droid grok command-code reasonix pi omp zai-cli dsh muse patchright npm pnpm pipx uv rustup; do",
        "update-wsl tool list",
    )

    BAT.write_bytes(data)
    print(f"Phase 1+2 OK ({BAT})")
    for w in WARNINGS:
        print("WARN:", w)


if __name__ == "__main__":
    main()
