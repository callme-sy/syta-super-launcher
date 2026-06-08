#!/usr/bin/env python3
"""Apply P0-P2 SYTA launcher improvements for v1.10.7."""
from pathlib import Path

BAT = Path(__file__).resolve().parents[1] / "syta-super-launcher.bat"
BUILD_ID = "SYTA-build-2026-06-08-230000Z"
RELEASE = "v1.10.7"

NVM_PREFERRED_FN = """:: nvm_preferred_target() {
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   [ -s "$NVM_DIR/nvm.sh" ] || return 1
::   # shellcheck source=/dev/null
::   . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || return 1
::
::   local def cur latest
::   def="$(nvm version default 2>/dev/null || true)"
::   case "$def" in ''|N/A|system) def='' ;; esac
::   if [ -n "$def" ]; then
::     printf '%s
:: ' "$def"
::     return 0
::   fi
::
::   cur="$(nvm current 2>/dev/null || true)"
::   case "$cur" in ''|none|system) cur='' ;; esac
::   if [ -n "$cur" ]; then
::     printf '%s
:: ' "$cur"
::     return 0
::   fi
::
::   latest="$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -type d -printf '%f
:: ' 2>/dev/null | sort -V | tail -n 1)"
::   if [ -n "$latest" ]; then
::     printf '%s
:: ' "$latest"
::     return 0
::   fi
::
::   return 1
:: }
::
"""

NVM_LOAD_USER_ENV = """:: load_user_env() {
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
:: }
"""


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Pattern not found ({label})")
    return text.replace(old, new, 1)


def replace_all(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count == 0:
        raise SystemExit(f"Pattern not found ({label})")
    return text.replace(old, new)


def main() -> None:
    raw_bytes = BAT.read_bytes()
    text = raw_bytes.decode("utf-8")
    uses_crlf = "\r\n" in text
    if uses_crlf:
        text = text.replace("\r\n", "\n")

    # Version bump
    text = replace_once(
        text,
        'set "SYTA_BUILD_ID=SYTA-build-2026-06-08-121500Z"',
        f'set "SYTA_BUILD_ID={BUILD_ID}"',
        "bat build id",
    )
    text = replace_once(
        text,
        ":: $script:BuildId = 'SYTA-build-2026-06-08-121500Z'",
        f":: $script:BuildId = '{BUILD_ID}'",
        "ps build id",
    )
    text = replace_once(
        text,
        ":: $script:ReleaseTag = 'v1.10.6'",
        f":: $script:ReleaseTag = '{RELEASE}'",
        "release tag",
    )

    # Runtime readiness + prune old builds
    text = replace_once(
        text,
        'if exist "%SYTA_RUNTIME%\\syta-agentic-launcher.ps1" if exist "%SYTA_RUNTIME%\\syta-tool-diagnostics.sh" if exist "%SYTA_RUNTIME%\\syta-wsl-session.sh" if exist "%SYTA_RUNTIME%\\syta-self-update.ps1" set "SYTA_RUNTIME_READY=1"',
        'if exist "%SYTA_RUNTIME%\\syta-agentic-launcher.ps1" if exist "%SYTA_RUNTIME%\\syta-tool-diagnostics.sh" if exist "%SYTA_RUNTIME%\\syta-wsl-session.sh" if exist "%SYTA_RUNTIME%\\syta-self-update.ps1" if exist "%SYTA_RUNTIME%\\syta-install-tool.sh" if exist "%SYTA_RUNTIME%\\syta-run-agent.sh" set "SYTA_RUNTIME_READY=1"',
        "runtime ready gate",
    )
    text = replace_once(
        text,
        '  "if(-not (Test-Path (Join-Path $out \'syta-agentic-launcher.ps1\'))){ throw \'Portable launcher extraction failed.\' }"',
        '  "$currentBuild=(Split-Path -Leaf $out); $base=$env:SYTA_RUNTIME_BASE; if(Test-Path -LiteralPath $base){ Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $currentBuild } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }; if(-not (Test-Path (Join-Path $out \'syta-agentic-launcher.ps1\'))){ throw \'Portable launcher extraction failed.\' }"',
        "runtime prune",
    )

    text = replace_once(
        text,
        ":: $script:WslCliReadyCache = $null\n:: $script:BuildId",
        ":: $script:WslCliReadyCache = $null\n:: $script:LastToolDiagnosticsError = ''\n:: $script:BuildId",
        "last diag error var",
    )

    # P0: stop bypassing release cache when already up to date
    text = replace_once(
        text,
        """::     $latestVersion = Convert-ReleaseTagToVersion $release.Tag
::     if ($currentVersion -and $latestVersion -and $latestVersion -le $currentVersion) {
::         $refreshedRelease = Get-LatestReleaseInfo -ForceRefresh
::         if ($refreshedRelease) {
::             $release = $refreshedRelease
::             $latestVersion = Convert-ReleaseTagToVersion $release.Tag
::         }
::     }
::
::     if (-not $currentVersion -or -not $latestVersion -or $latestVersion -le $currentVersion) {""",
        """::     $latestVersion = Convert-ReleaseTagToVersion $release.Tag
::
::     if (-not $currentVersion -or -not $latestVersion -or $latestVersion -le $currentVersion) {""",
        "update cache bypass",
    )

    # Format-AuthStatus: clearer config label
    text = replace_once(
        text,
        "        'config-present' { return (Localize-Text 'Auth/config detected') }",
        "        'config-present' { return (Localize-Text 'Config found') }\n::         'diag-unavailable' { return (Localize-Text 'Check unavailable') }",
        "format auth status",
    )

    # Invoke-ToolDiagnosticsScript stderr capture
    text = replace_once(
        text,
        """::     try {
::         $output = & wsl.exe -d $distro --cd $wslDir --exec bash $wslScriptPath $Key 2>$null
::     } finally {
::         if ($null -ne $previousProjectsRoot) {
::             $env:SYTA_PROJECTS_ROOT_WSL = $previousProjectsRoot
::         } else {
::             Remove-Item Env:SYTA_PROJECTS_ROOT_WSL -ErrorAction SilentlyContinue
::         }
::     }
::     if ($LASTEXITCODE -ne 0 -or -not $output) {
::         return $null
::     }""",
        """::     $script:LastToolDiagnosticsError = ''
::     $stderrFile = [IO.Path]::GetTempFileName()
::     try {
::         $output = & wsl.exe -d $distro --cd $wslDir --exec bash $wslScriptPath $Key 2> $stderrFile
::         if (Test-Path -LiteralPath $stderrFile) {
::             $stderr = Get-Content -LiteralPath $stderrFile -Raw -ErrorAction SilentlyContinue
::             if ($stderr) { $script:LastToolDiagnosticsError = $stderr.Trim() }
::         }
::     } finally {
::         Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
::         if ($null -ne $previousProjectsRoot) {
::             $env:SYTA_PROJECTS_ROOT_WSL = $previousProjectsRoot
::         } else {
::             Remove-Item Env:SYTA_PROJECTS_ROOT_WSL -ErrorAction SilentlyContinue
::         }
::     }
::     if (-not $output) {
::         return $null
::     }""",
        "single diag stderr",
    )

    # Invoke-ToolDiagnosticsBatchScript stderr + partial parse
    text = replace_once(
        text,
        """::     try {
::         $output = & wsl.exe @wslArgs 2>$null
::     } finally {
::         if ($null -ne $previousProjectsRoot) {
::             $env:SYTA_PROJECTS_ROOT_WSL = $previousProjectsRoot
::         } else {
::             Remove-Item Env:SYTA_PROJECTS_ROOT_WSL -ErrorAction SilentlyContinue
::         }
::     }
::     if ($LASTEXITCODE -ne 0 -or -not $output) {
::         return @{}
::     }""",
        """::     $script:LastToolDiagnosticsError = ''
::     $stderrFile = [IO.Path]::GetTempFileName()
::     try {
::         $output = & wsl.exe @wslArgs 2> $stderrFile
::         if (Test-Path -LiteralPath $stderrFile) {
::             $stderr = Get-Content -LiteralPath $stderrFile -Raw -ErrorAction SilentlyContinue
::             if ($stderr) { $script:LastToolDiagnosticsError = $stderr.Trim() }
::         }
::     } finally {
::         Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
::         if ($null -ne $previousProjectsRoot) {
::             $env:SYTA_PROJECTS_ROOT_WSL = $previousProjectsRoot
::         } else {
::             Remove-Item Env:SYTA_PROJECTS_ROOT_WSL -ErrorAction SilentlyContinue
::         }
::     }
::     if (-not $output) {
::         return @{}
::     }""",
        "batch diag stderr",
    )

    # Get-ToolDiagnostics unavailable when script returns null
    text = replace_once(
        text,
        """::     $raw = Invoke-ToolDiagnosticsScript -Key $resolvedKey
::     $diag = Convert-ToolDiagnosticsRawToObject -ResolvedKey $resolvedKey -Raw $raw
::     $script:ToolDiagCache[$resolvedKey] = $diag
::     return $diag
:: }""",
        """::     $raw = Invoke-ToolDiagnosticsScript -Key $resolvedKey
::     if ($null -eq $raw) {
::         $detail = if ($script:LastToolDiagnosticsError) { $script:LastToolDiagnosticsError } else { $spec.InstallHint }
::         $diag = [pscustomobject]@{
::             Key = $resolvedKey
::             Installed = $false
::             Path = $null
::             PathText = $detail
::             Version = $null
::             DiagnosticMode = 'unavailable'
::             VersionDeferred = $false
::             VersionText = (Localize-Text 'diagnostics unavailable')
::             AuthRaw = 'diag-unavailable'
::             AuthText = (Localize-Text 'Check unavailable')
::             InstallSource = 'unknown'
::             InstallText = (Localize-Text 'Check unavailable')
::             MenuText = (Localize-Text 'Check unavailable')
::         }
::         $script:ToolDiagCache[$resolvedKey] = $diag
::         return $diag
::     }
::     $diag = Convert-ToolDiagnosticsRawToObject -ResolvedKey $resolvedKey -Raw $raw
::     $script:ToolDiagCache[$resolvedKey] = $diag
::     return $diag
:: }""",
        "diag unavailable object",
    )

    # Convert-ToolDiagnosticsRawToObject unavailable handling
    text = replace_once(
        text,
        """::     $statusText = if ($configOnlyPackage) { ('{0} ({1})' -f (Localize-Text 'Installed'), (Localize-Text 'config-only')) } elseif ($configuredOnly) { Localize-Text 'Configured only' } elseif ($installed) { ('{0} ({1})' -f (Localize-Text 'Installed'), $sourceLabel) } else { Localize-Text 'Missing' }""",
        """::     $statusText = if ($diagnosticMode -eq 'unavailable') { Localize-Text 'Check unavailable' } elseif ($configOnlyPackage) { ('{0} ({1})' -f (Localize-Text 'Installed'), (Localize-Text 'config-only')) } elseif ($configuredOnly) { Localize-Text 'Configured only' } elseif ($installed) { ('{0} ({1})' -f (Localize-Text 'Installed'), $sourceLabel) } else { Localize-Text 'Missing' }""",
        "convert status unavailable",
    )
    text = replace_once(
        text,
        """::         VersionText = if ($configOnlyPackage) { (Localize-Text 'config-only add-on') } elseif ($configuredOnly) { (Localize-Text 'binary not found on PATH') } elseif ($installed) { if ($version) { $version } elseif ($versionDeferred) { (Localize-Text 'checked during action') } else { (Localize-Text 'version not detected') } } else { (Localize-Text 'not installed') }""",
        """::         VersionText = if ($diagnosticMode -eq 'unavailable') { (Localize-Text 'diagnostics unavailable') } elseif ($configOnlyPackage) { (Localize-Text 'config-only add-on') } elseif ($configuredOnly) { (Localize-Text 'binary not found on PATH') } elseif ($installed) { if ($version) { $version } elseif ($versionDeferred) { (Localize-Text 'checked during action') } else { (Localize-Text 'version not detected') } } else { (Localize-Text 'not installed') }""",
        "convert version unavailable",
    )

    # Warm-ToolDiagnosticsCache fast miss -> unavailable not missing
    text = replace_once(
        text,
        """::         } elseif ($Fast) {
::             $script:ToolDiagCache[$key] = Convert-ToolDiagnosticsRawToObject -ResolvedKey $key -Raw @{
::                 key = $key
::                 installed = '0'
::                 path = ''
::                 version = ''
::                 auth = 'not-detected'
::                 config = ''
::                 install_source = 'unknown'
::                 diagnostic_mode = 'fast'
::                 version_deferred = '1'
::             }""",
        """::         } elseif ($Fast) {
::             $script:ToolDiagCache[$key] = Convert-ToolDiagnosticsRawToObject -ResolvedKey $key -Raw @{
::                 key = $key
::                 installed = '0'
::                 path = ''
::                 version = ''
::                 auth = 'diag-unavailable'
::                 config = ''
::                 install_source = 'unknown'
::                 diagnostic_mode = 'unavailable'
::                 version_deferred = '0'
::             }""",
        "warm fast unavailable",
    )

    # WSL probe refresh on install menu build
    text = replace_once(
        text,
        ":: function Get-InstallItems {\n::     $distroInstalled = Test-WslUserDistroInstalled",
        ":: function Get-InstallItems {\n::     Clear-WslProbeCache\n::     $distroInstalled = Test-WslUserDistroInstalled",
        "install wsl cache refresh",
    )

    # Launch-InstallMode catch includes stderr hint
    text = replace_once(
        text,
        """::         } catch {
::             Show-InfoBox -Title 'Installer' -Accent Yellow -Hint 'Back' -Lines @(
::                 'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.',
::                 'You can still install WSL Ubuntu or PowerShell 7 from here.',
::                 'You can still use First install from here for the guided beginner path.'
::             )""",
        """::         } catch {
::             $diagHint = if ($script:LastToolDiagnosticsError) { "Detail  : $($script:LastToolDiagnosticsError)" } else { $null }
::             Show-InfoBox -Title 'Installer' -Accent Yellow -Hint 'Back' -Lines @(
::                 'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.',
::                 'You can still install WSL Ubuntu or PowerShell 7 from here.',
::                 'You can still use First install from here for the guided beginner path.'
::             ) + @($diagHint) | Where-Object { $_ }""",
        "install catch stderr",
    )

    # Launch-CodeMode preflight gate
    text = replace_once(
        text,
        """::     Show-InfoBox -Title 'Launch Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::         "Project : $projectDir",
::         "Tool    : $($agent.Title)",
::         "Install : $($diag.InstallText)",
::         "Version : $($diag.VersionText)",
::         "Auth    : $($diag.AuthText)",
::         "Path    : $($diag.PathText)"
::     )
::
::     $result = Open-WslWindow """,
        """::     Show-InfoBox -Title 'Launch Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::         "Project : $projectDir",
::         "Tool    : $($agent.Title)",
::         "Install : $($diag.InstallText)",
::         "Version : $($diag.VersionText)",
::         "Auth    : $($diag.AuthText)",
::         "Path    : $($diag.PathText)"
::     )
::
::     if (-not $diag.Installed) {
::         if ($diag.DiagnosticMode -eq 'unavailable') {
::             $unavailableLines = @(
::                 (Localize-Text 'Tool diagnostics could not be confirmed right now.'),
::                 (Localize-Text 'Install from the Installer menu, or try again later.')
::             )
::             if ($script:LastToolDiagnosticsError) {
::                 $unavailableLines += "Detail  : $($script:LastToolDiagnosticsError)"
::             }
::             Show-InfoBox -Title (Localize-Text 'Diagnostics unavailable') -Accent Yellow -Hint (Localize-Text 'Back') -Lines $unavailableLines
::             Start-Sleep -Milliseconds 1500
::             return
::         }
::
::         if (-not $DryRun) {
::             $recovery = Read-Menu -Title (Localize-Text 'Tool not installed') -Subtitle (Localize-Text 'Install from the Installer menu, or try again later.') -Items @(
::                 [pscustomobject]@{ Title = (Localize-Text 'Install this tool'); Subtitle = (Localize-Text 'Open the guided installer for this CLI.'); Accent = 'Green'; Key = 'install' }
::                 [pscustomobject]@{ Title = (Localize-Text 'Choose another agent'); Subtitle = (Localize-Text 'Return to the agent selector.'); Accent = 'Cyan'; Key = 'back' }
::                 [pscustomobject]@{ Title = (Localize-Text 'Launch anyway'); Subtitle = (Localize-Text 'Open WSL even though this tool looks missing.'); Accent = 'Yellow'; Key = 'launch-anyway' }
::             )
::             if (-not $recovery -or $recovery.Key -eq 'back') {
::                 return
::             }
::             if ($recovery.Key -eq 'install') {
::                 $savedInstallTarget = $InstallTarget
::                 $InstallTarget = Resolve-ToolKey $agent.Key
::                 try {
::                     Launch-InstallMode
::                 } finally {
::                     $InstallTarget = $savedInstallTarget
::                 }
::                 return
::             }
::         }
::     }
::
::     $result = Open-WslWindow """,
        "code preflight gate",
    )

    # Light update scope includes Grok
    text = replace_all(
        text,
        "'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI'",
        "'Scope   : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI'",
        "light update scope",
    )
    text = replace_all(
        text,
        "'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI.'",
        "'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.'",
        "light update subtitle",
    )

    # Codex/OMX auth.json detection
    text = replace_once(
        text,
        """::     codex)
::       command_name='codex'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::       ;;
::     omx)
::       command_name='omx'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'""",
        """::     codex)
::       command_name='codex'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/auth.json" ] && auth='config-present'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::       ;;
::     omx)
::       command_name='omx'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/auth.json" ] && auth='config-present'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'""",
        "codex auth.json",
    )

    # cleaner_specs PATH duplicates for non-npm CLIs
    text = replace_once(
        text,
        """:: comment-checker|@code-yeongyu/comment-checker
:: EOF
:: }""",
        """:: comment-checker|@code-yeongyu/comment-checker
:: droid|droid
:: grok|grok
:: rtk|rtk
:: EOF
:: }""",
        "cleaner specs",
    )

    # syta-run-agent.sh: nvm-aware env
    text = replace_once(
        text,
        """:: lang="$(normalize_lang "$lang")"
::
:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   hash -r 2>/dev/null || true
:: }
::
:: msg() {""",
        f""":: lang="$(normalize_lang "$lang")"
::
{NVM_PREFERRED_FN}{NVM_LOAD_USER_ENV}
::
:: msg() {{""",
        "run-agent env",
    )

    # update scripts: nvm_preferred_target in load_user_env
    old_update_load = """:: load_user_env() {
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

    new_update_load = NVM_PREFERRED_FN + NVM_LOAD_USER_ENV
    text = replace_all(text, old_update_load, new_update_load, "update load_user_env")

  # update-wsl-coding-tools inline nvm use default
    text = replace_once(
        text,
        "  run_step \"Refresh npm to latest\" bash -lc 'export NVM_DIR=\"${NVM_DIR:-$HOME/.nvm}\"; . \"$NVM_DIR/nvm.sh\"; nvm use default >/dev/null 2>&1 || nvm install node >/dev/null; npm install -g npm@latest' || true",
        "  run_step \"Refresh npm to latest\" bash -lc 'export NVM_DIR=\"${NVM_DIR:-$HOME/.nvm}\"; . \"$NVM_DIR/nvm.sh\"; target=\"$(nvm version default 2>/dev/null || true)\"; case \"$target\" in \"\"|N/A|system) target=\"$(nvm current 2>/dev/null || true)\" ;; esac; case \"$target\" in \"\"|none|system) target=\"\" ;; esac; if [ -z \"$target\" ]; then nvm install node >/dev/null; else nvm use \"$target\" >/dev/null 2>&1 || nvm install node >/dev/null; fi; npm install -g npm@latest' || true",
        "wsl update npm refresh",
    )

    # Localization (zh)
    text = replace_once(
        text,
        "::             'Auth/config detected' = '已检测到认证/配置'",
        "            'Auth/config detected' = '已检测到认证/配置'\n::             'Config found' = '已找到配置'\n::             'Check unavailable' = '检查不可用'\n::             'diagnostics unavailable' = '诊断不可用'\n::             'Tool not installed' = '工具未安装'\n::             'Install this tool' = '安装此工具'\n::             'Open the guided installer for this CLI.' = '打开此 CLI 的引导安装器。'\n::             'Choose another agent' = '选择其他代理'\n::             'Return to the agent selector.' = '返回代理选择器。'\n::             'Launch anyway' = '仍然启动'\n::             'Open WSL even though this tool looks missing.' = '即使此工具看起来缺失也打开 WSL。'\n::             'Diagnostics unavailable' = '诊断不可用'\n::             'Tool diagnostics could not be confirmed right now.' = '当前无法确认工具诊断结果。'\n::             'Install from the Installer menu, or try again later.' = '请从安装菜单安装，或稍后重试。'",
        "zh localization",
    )
    text = replace_once(
        text,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI。'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Kilo Code CLI、Claude Code、Gemini CLI、DROID CLI、Grok CLI。'",
        "zh light update grok value",
    )

    # Localization (fr)
    text = replace_once(
        text,
        "::             'Auth/config detected' = 'Auth/config detectee'",
        "            'Auth/config detected' = 'Auth/config detectee'\n::             'Config found' = 'Config detectee'\n::             'Check unavailable' = 'Verification indisponible'\n::             'diagnostics unavailable' = 'diagnostics indisponibles'\n::             'Tool not installed' = 'Outil non installe'\n::             'Install this tool' = 'Installer cet outil'\n::             'Open the guided installer for this CLI.' = 'Ouvrir l''installateur guide pour ce CLI.'\n::             'Choose another agent' = 'Choisir un autre agent'\n::             'Return to the agent selector.' = 'Revenir au selecteur d''agent.'\n::             'Launch anyway' = 'Lancer quand meme'\n::             'Open WSL even though this tool looks missing.' = 'Ouvrir WSL meme si cet outil semble absent.'\n::             'Diagnostics unavailable' = 'Diagnostics indisponibles'\n::             'Tool diagnostics could not be confirmed right now.' = 'Les diagnostics de l''outil n''ont pas pu etre confirmes pour le moment.'\n::             'Install from the Installer menu, or try again later.' = 'Installez depuis le menu Installer, ou reessayez plus tard.'",
        "fr localization",
    )
    text = replace_once(
        text,
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI.'",
        "::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Kilo Code CLI, Claude Code, Gemini CLI, DROID CLI, Grok CLI.'",
        "fr light update grok value",
    )

    if uses_crlf:
        text = text.replace("\n", "\r\n")
    BAT.write_bytes(text.encode("utf-8"))
    print(f"Patched {BAT.name} -> {RELEASE} ({BUILD_ID})")


if __name__ == "__main__":
    main()
