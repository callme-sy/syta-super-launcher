@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions DisableDelayedExpansion

set "SYTA_PORTABLE_ROOT=%~dp0"
set "SYTA_SELF=%~f0"
for /f "usebackq delims=" %%I in (`powershell.exe -NoLogo -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "SYTA_RUNTIME=%TEMP%\syta-super-launcher-runtime-%%I"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$self=$env:SYTA_SELF;" ^
  "$out=$env:SYTA_RUNTIME;" ^
  "New-Item -ItemType Directory -Force -Path $out | Out-Null;" ^
  "$lines=Get-Content -LiteralPath $self -Encoding UTF8;" ^
  "$name=$null;" ^
  "$buf=New-Object System.Collections.Generic.List[string];" ^
  "foreach($line in $lines){" ^
  "  if($line -like '::BEGIN:*'){ $name=$line.Substring(8); $buf.Clear(); continue }" ^
  "  if($line -like '::END:*'){ $enc = if($name -like '*.ps1'){ New-Object Text.UTF8Encoding $true } else { New-Object Text.UTF8Encoding $false }; [IO.File]::WriteAllText((Join-Path $out $name), ($buf -join \"`n\"), $enc); $name=$null; continue }" ^
  "  if($null -ne $name){ if($line -eq '::'){ $buf.Add('') } elseif($line.StartsWith(':: ')){ $buf.Add($line.Substring(3)) } }" ^
  "}" ^
  "if(-not (Test-Path (Join-Path $out 'syta-agentic-launcher.ps1'))){ throw 'Portable launcher extraction failed.' }"

if errorlevel 1 (
    echo.
    echo Failed to prepare SYTA portable runtime.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SYTA_RUNTIME%\syta-agentic-launcher.ps1" %*
exit /b %errorlevel%

::BEGIN:syta-agentic-launcher.ps1
:: param(
::     [ValidateSet('Code', 'Install', 'Explanations', 'CleanerHelper', 'Update', 'UpdateAll', 'UpdateLight')]
::     [string]$Mode,
::     [ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'claude-code', 'gemini-cli')]
::     [string]$Agent,
::     [ValidateSet('first-install', 'wsl-ubuntu', 'powershell-7', 'all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim')]
::     [string]$InstallTarget,
::     [ValidateSet('codex-omx', 'opencode', 'oh-my-openagent', 'oh-my-opencode-slim', 'claude-code', 'gemini-cli', 'all')]
::     [string]$ResetTarget,
::     [string]$ProjectName,
::     [switch]$NoAnimation,
::     [switch]$NoMaximize,
::     [switch]$DryRun,
::     [switch]$SmokeTest,
::     [ValidateSet('auto', 'fr', 'en', 'zh')]
::     [Alias('Lang')]
::     [string]$UiLanguage = 'auto'
:: )
::
:: $ErrorActionPreference = 'Stop'
::
:: try {
::     [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
::     [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
::     $OutputEncoding = [Console]::OutputEncoding
:: } catch {
:: }
::
:: $script:ScriptDir = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSCommandPath)).TrimEnd('\')
:: $script:ProjectsRoot = 'C:\.CODEX'
:: if (-not (Test-Path -LiteralPath $script:ProjectsRoot)) {
::     $null = New-Item -ItemType Directory -Path $script:ProjectsRoot -Force
:: }
:: $script:StateFile = Join-Path $script:ProjectsRoot '.syta-launcher-state.json'
:: $script:ToolDiagCache = @{}
:: $script:RecentProjectCountCache = $null
:: $script:BuildId = 'SYTA-build-2026-04-15-014800Z'
:: $script:ReleaseTag = 'v1.6.3'
:: $script:ReleaseApiUrl = 'https://api.github.com/repos/callme-sy/syta-super-launcher/releases/latest'
:: $script:UpdateCheckTtlHours = 6
:: $script:Language = 'en'
::
:: function Resolve-Language {
::     param([string]$Requested = 'auto')
::
::     $candidate = $null
::     if ($Requested -and $Requested -ne 'auto') {
::         $candidate = $Requested
::     } elseif ($env:SYTA_LANGUAGE) {
::         $candidate = $env:SYTA_LANGUAGE
::     } elseif ($env:SYTA_LANG) {
::         $candidate = $env:SYTA_LANG
::     }
::
::     if ($candidate) {
::         $normalized = $candidate.ToLowerInvariant()
::         if ($normalized -match '^fr') { return 'fr' }
::         if ($normalized -match '^zh') { return 'zh' }
::         if ($normalized -match '^en') { return 'en' }
::     }
::
::     try {
::         $culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
::     } catch {
::         $culture = ''
::     }
::
::     if ($culture -match '^fr') { return 'fr' }
::     if ($culture -match '^zh') { return 'zh' }
::     return 'en'
:: }
::
:: function Localize-Text {
::     param([string]$Text)
::
::     if ([string]::IsNullOrEmpty($Text) -or $script:Language -eq 'en') {
::         return $Text
::     }
::
::     $map = if ($script:Language -eq 'zh') {
::         @{
::             'Selector' = '选择器'
::             'Arrows move, Enter selects, Esc goes back' = '方向键移动，Enter 选择，Esc 返回'
::             'Please wait' = '请稍候'
::             'Launching in a new terminal tab' = '正在新终端标签页中启动'
::             'SYTA keeps this selector open while new tabs launch' = 'SYTA 会在新标签页启动时保持此选择器打开'
::             'Boot sequence' = '启动序列'
::             'unpacking portable runtime' = '正在解包便携运行时'
::             'loading command deck' = '正在加载命令面板'
::             'scanning WSL bridge' = '正在扫描 WSL 桥接'
::             'mapping project roots' = '正在映射项目根目录'
::             'arming install matrix' = '正在准备安装矩阵'
::             'warming AI launch lanes' = '正在预热 AI 启动通道'
::             'routing terminal host' = '正在配置终端宿主'
::             'syncing updater engines' = '正在同步更新引擎'
::             'locking flight path' = '正在锁定执行路径'
::             'SYTA ready' = 'SYTA 已就绪'
::             'telemetry: launcher online, diagnostics cache cold, routes ready' = '遥测：启动器已上线，诊断缓存为空，路线已就绪'
::             'Create New Project' = '创建新项目'
::             'Leave blank to cancel' = '留空以取消'
::             'Choose a short Windows-safe folder name.' = '请选择一个简短且兼容 Windows 的文件夹名。'
::             '   Project name' = '   项目名称'
::             'Invalid project name' = '项目名称无效'
::             'Avoid characters Windows cannot use in folder names.' = '避免使用 Windows 不能用于文件夹名的字符。'
::             'Try another name' = '换一个名称'
::             'Back' = '返回'
::             'Exit' = '退出'
::             'Project Selector' = '项目选择'
::             'Recent Projects' = '最近项目'
::             'Existing Projects' = '现有项目'
::             'Search Projects' = '搜索项目'
::             'Search Results' = '搜索结果'
::             'Search scans existing folders under C:\.CODEX.' = '搜索会扫描 C:\.CODEX 下现有的文件夹。'
::             'Search is case-insensitive and matches partial words.' = '搜索不区分大小写，并支持部分词匹配。'
::             '   Search term' = '   搜索词'
::             'No project matches' = '没有匹配的项目'
::             'Try another search' = '换一个搜索词'
::             'Open existing project' = '打开现有项目'
::             'Type a fresh project name and create its folder.' = '输入新项目名并创建其文件夹。'
::             'Filter existing projects by a search term.' = '用搜索词筛选现有项目。'
::             'Choose a recently used project folder.' = '选择最近使用的项目文件夹。'
::             'Choose a project folder to open.' = '选择要打开的项目文件夹。'
::             'Choose the tool to launch in the project workspace.' = '选择要在该项目工作区中启动的工具。'
::             'Agent Selector' = '代理选择'
::             'Mode Selector' = '模式选择'
::             'Explanations' = '说明'
::             'Update' = '更新'
::             'Choose which update lane to run.' = '选择要运行的更新方式。'
::             'Run a lighter AI-tools-only update or the broader full maintenance pass.' = '仅更新 AI 工具，或运行更全面的维护更新。'
::             'Light update' = '轻量更新'
::             'Update all' = '全量更新'
::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Claude Code, Gemini CLI.' = '仅更新 AI 编码 CLI：Codex、OMX、OpenCode、Claude Code、Gemini CLI。'
::             'Run the broader toolchain update pass, including system package managers.' = '运行更全面的工具链更新，包括系统包管理器。'
::             'First install (recommended)' = '首次安装（推荐）'
::             'Best beginner path for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.' = '面向新手的最佳路径：WSL Ubuntu、可选 PowerShell 7，以及核心 AI CLI 工具。'
::             'Recommended path for a new machine or first SYTA setup' = '适用于新机器或首次 SYTA 安装的推荐路径'
::             'CLI     : Ready to launch the core AI CLI tools now' = 'CLI     : 现在即可启动核心 AI CLI 工具'
::             'CLI     : Full core AI CLI install starts after Ubuntu is ready' = 'CLI     : Ubuntu 准备好后再启动完整的核心 AI CLI 安装'
::             'Note    : Recommended path for a new machine or first SYTA setup' = 'Note    : 适用于新机器或首次 SYTA 安装的推荐路径'
::             'Note    : Ubuntu setup may require a reboot before CLI installs continue' = 'Note    : 在 CLI 安装继续前，Ubuntu 设置可能需要重启'
::             'Note    : Ubuntu may also require first-run Linux account creation' = 'Note    : Ubuntu 也可能需要先完成首次 Linux 账户创建'
::             'You can still use First install from here for the guided beginner path.' = '你仍然可以从这里使用“首次安装”这一新手引导路径。'
::             'Learn what the tools are, who they are for, and what SYTA recommends.' = '了解这些工具是什么、适合谁，以及 SYTA 的推荐。'
::             'Learn what the tools are, what SYTA recommends, and how to choose a setup.' = '了解这些工具是什么、SYTA 的推荐，以及如何选择安装方案。'
::             'Beginner guide' = '新手指南'
::             'Beginner guide | simple' = '新手指南 | 简单版'
::             'Ultra-beginner explanation of each tool and the easiest path through SYTA.' = '面向完全新手的工具说明和最简单的 SYTA 路径。'
::             'Very simple explanation of each tool and the easiest place to start.' = '用最简单的方式解释每个工具，以及最容易开始的路径。'
::             'Advanced guide' = '进阶指南'
::             'Advanced guide | more detail' = '进阶指南 | 更多细节'
::             'Higher-level tradeoffs, workflows, and why you might pick one tool over another.' = '更高层次的取舍、工作流，以及为何选择某个工具。'
::             'More detail about the differences between the tools and when to pick each one.' = '更详细地说明这些工具的差异，以及何时选择它们。'
::             'What should I install?' = '我该安装什么？'
::             'What should I install? | short answer' = '我该安装什么？ | 简短答案'
::             'Straight recommendation based on simplicity, budget, and how hands-off you want setup to be.' = '基于简单性、预算和你想要多省心的直接推荐。'
::             'Direct recommendation if you just want the short answer.' = '如果你只想看简短答案，这里给出直接建议。'
::             'Press any key to return.' = '按任意键返回。'
::             'Codex: OpenAI coding agent with strong editing and reasoning.' = 'Codex：OpenAI 的编码代理，编辑和推理能力都很强。'
::             'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.' = 'OMX：Codex 上层的进阶封装，适合更强的自动化、规划和重型工作流。'
::             'OpenCode: lightweight coding CLI and usually the easiest first start.' = 'OpenCode：轻量编码 CLI，通常也是最容易上手的起点。'
::             'Claude Code and Gemini CLI: best if you already use those ecosystems.' = 'Claude Code 和 Gemini CLI：如果你已经在用这些生态，更值得装。'
::             'Best beginner path: Install -> First install, then start with OpenCode or Codex.' = '新手最佳路径：安装 -> 首次安装，然后从 OpenCode 或 Codex 开始。'
::             'Oh My OpenAgent is the full OpenCode harness. Oh My OpenCode Slim keeps a lighter preset.' = 'Oh My OpenAgent 是完整的 OpenCode 扩展，Oh My OpenCode Slim 是更轻的预设。'
::             'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.' = 'Codex 是直接的 OpenAI 路线；OMX 在其上增加更有主见的自动化和编排。'
::             'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.' = 'OpenCode 通常最轻量；如果你想要更强的引导执行，Codex 和 OMX 更合适。'
::             'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.' = '只安装你真正会用的 CLI。工具越多，认证、更新和重叠就越多。'
::             'Oh My OpenAgent is the broader OpenCode harness; Slim keeps a lighter OpenCode-focused preset.' = 'Oh My OpenAgent 是更完整的 OpenCode 扩展；Slim 则保留更轻量的 OpenCode 预设。'
::             'Brand-new Windows machine: Install -> First install.' = '全新 Windows 机器：安装 -> 首次安装。'
::             'Lowest-friction start: OpenCode.' = '最低摩擦的起点：OpenCode。'
::             'Best OpenAI-first path: Codex, then OMX if you want deeper automation.' = '最佳 OpenAI 优先路径：先 Codex，如果想要更深的自动化再加 OMX。'
::             'Install Oh My OpenAgent if you want the full harness. Install Slim if you want a lighter preset.' = '想要完整扩展就装 Oh My OpenAgent；想要更轻的预设就装 Slim。'
::             'Skip tools you do not have keys, subscriptions, or a real workflow for.' = '跳过你没有 key、订阅或实际工作流需求的工具。'
::             'Choose what SYTA should do.' = '选择 SYTA 要执行的操作。'
::             'Launch an agent with project selection, diagnostics, and recent-project support.' = '通过项目选择、诊断和最近项目支持来启动代理。'
::             'Install WSL Ubuntu or supported coding CLIs with preflight diagnostics.' = '通过预检诊断来安装 WSL Ubuntu 或受支持的编码 CLI。'
::             'Close the launcher.' = '关闭启动器。'
::             'Install or repair WSL Ubuntu and supported coding CLIs.' = '安装或修复 WSL Ubuntu 以及受支持的编码 CLI。'
::             'First install' = '首次安装'
::             'First install | recommended' = '首次安装 | 推荐'
::             'WSL Ubuntu | system setup' = 'WSL Ubuntu | 系统设置'
::             'PowerShell 7 | optional' = 'PowerShell 7 | 可选'
::             'Install core AI CLI tools | simple' = '安装核心 AI CLI 工具 | 简单'
::             'Cleaner helper | maintenance' = '清理助手 | 维护'
::             'Reset tool configs | maintenance' = '重置工具配置 | 维护'
::             'Codex CLI | guided' = 'Codex CLI | 引导'
::             'OpenCode | simple' = 'OpenCode | 简单'
::             'Oh My OpenAgent | advanced optional' = 'Oh My OpenAgent | 进阶可选'
::             'Oh My Codex / OMX | advanced optional' = 'Oh My Codex / OMX | 进阶可选'
::             'Claude Code | optional' = 'Claude Code | 可选'
::             'Gemini CLI | optional' = 'Gemini CLI | 可选'
::             'DROID CLI | optional' = 'DROID CLI | 可选'
::             'Oh My OpenCode Slim | optional' = 'Oh My OpenCode Slim | 可选'
::             'Guided setup for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.' = 'WSL Ubuntu、可选 PowerShell 7 和核心 AI CLI 工具的引导安装。'
::             'PowerShell 7 is already installed. Reinstall or repair it now?' = 'PowerShell 7 已安装。现在要重装或修复吗？'
::             'Would you like SYTA to install PowerShell 7 too?' = '你希望 SYTA 一并安装 PowerShell 7 吗？'
::             'Skip PowerShell 7 for now' = '暂时跳过 PowerShell 7'
::             'Continue without changing the Windows Terminal default profile.' = '继续，但不更改 Windows Terminal 默认配置文件。'
::             'Install PowerShell 7 now' = '现在安装 PowerShell 7'
::             'Reinstall or repair PowerShell 7' = '重新安装或修复 PowerShell 7'
::             'Install core AI CLI tools' = '安装核心 AI CLI 工具'
::             'Run Codex, OpenCode, Claude Code, and Gemini CLI in one pass.' = '一次运行 Codex、OpenCode、Claude Code 和 Gemini CLI 的安装。'
::             'WSL Linux setup incomplete | launch Ubuntu once first.' = 'WSL Linux 设置未完成 | 请先启动一次 Ubuntu。'
::             'Cleaner helper' = '清理助手'
::             'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.' = '清理前扫描旧的 nvm/npm AI CLI 安装和重复的 PATH 项。'
::             'Reset tool configs' = '重置工具配置'
::             'Review tracked config/auth paths and remove only the ones you confirm.' = '检查已跟踪的配置/认证路径，只删除你确认的项。'
::             'Choose which tool configs to reset.' = '选择要重置哪些工具配置。'
::             'Pick one tool family, or reset every tracked config path.' = '选择一个工具类别，或重置所有已跟踪的配置路径。'
::             'Codex / OMX configs' = 'Codex / OMX 配置'
::             'Remove tracked Codex and OMX auth/config files.' = '删除已跟踪的 Codex 和 OMX 认证/配置文件。'
::             'OpenCode configs' = 'OpenCode 配置'
::             'Remove tracked OpenCode base config files.' = '删除已跟踪的 OpenCode 基础配置文件。'
::             'Oh My OpenAgent configs' = 'Oh My OpenAgent 配置'
::             'Remove tracked Oh My OpenAgent compatibility config files.' = '删除已跟踪的 Oh My OpenAgent 兼容配置文件。'
::             'Oh My OpenCode Slim configs' = 'Oh My OpenCode Slim 配置'
::             'Remove tracked Oh My OpenCode Slim config files.' = '删除已跟踪的 Oh My OpenCode Slim 配置文件。'
::             'Claude Code configs' = 'Claude Code 配置'
::             'Remove tracked Claude Code config files.' = '删除已跟踪的 Claude Code 配置文件。'
::             'Gemini CLI configs' = 'Gemini CLI 配置'
::             'Remove tracked Gemini and Google AI config folders.' = '删除已跟踪的 Gemini 和 Google AI 配置目录。'
::             'All tracked configs' = '所有已跟踪的配置'
::             'Remove every tracked config/auth path shown by SYTA.' = '删除 SYTA 显示的所有已跟踪配置/认证路径。'
::             'SYTA Install - Config Reset Helper' = 'SYTA 安装 - 配置重置助手'
::             'Target  : Reset tool configs' = '目标   : 重置工具配置'
::             'Action  : Review tracked config/auth paths and confirm which ones to remove' = '操作   : 检查已跟踪的配置/认证路径并确认要删除的项'
::             'Scope   : Selected tracked config/auth paths, or all tracked config/auth paths' = '范围   : 选定的配置/认证路径，或所有已跟踪的配置/认证路径'
::             'Selection : ' = '选择   : '
::             'SYTA Install - Cleaner Helper' = 'SYTA 安装 - 清理助手'
::             'Target  : Cleaner helper' = '目标   : 清理助手'
::             'Action  : Scan stale AI CLI installs and ask before removing old npm globals' = '操作   : 扫描过时的 AI CLI 安装，并在删除旧 npm 全局包前询问'
::             'Scope   : Older nvm Node versions, duplicate PATH entries, user-scoped npm installs' = '范围   : 较旧的 nvm Node 版本、重复 PATH 条目、用户级 npm 安装'
::             'Oh My OpenAgent' = 'Oh My OpenAgent'
::             'OpenCode + the full Oh My OpenAgent harness with its interactive installer.' = 'OpenCode + 完整的 Oh My OpenAgent 扩展及其交互式安装器。'
::             'This is an OpenCode add-on, not a separate coding CLI.' = '这是 OpenCode 的附加组件，不是单独的编码 CLI。'
::             'OpenCode should be installed first. SYTA will install it automatically if needed.' = '应先安装 OpenCode。必要时 SYTA 会自动安装它。'
::             'Best if you already use OpenCode and want more helper features around it.' = '如果你已经在用 OpenCode 并想要更多辅助功能，这最合适。'
::             'Best if you want a lighter OpenCode add-on instead of the bigger OpenAgent setup.' = '如果你想要比 OpenAgent 更轻的 OpenCode 附加组件，这最合适。'
::             'OpenCode : ' = 'OpenCode：'
::             'Loading live tool diagnostics' = '正在加载实时工具诊断'
::             'Checking Windows prerequisites' = '正在检查 Windows 前置条件'
::             'Loading WSL tool diagnostics' = '正在加载 WSL 工具诊断'
::             'Preparing install options' = '正在准备安装选项'
::             'No WSL Linux distro is ready yet, so SYTA will show safe setup choices only.' = '当前还没有可用的 WSL Linux 发行版，因此 SYTA 只会显示安全的安装选项。'
::             'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.' = '实时诊断不可用，因此 SYTA 已切换到安全的回退安装菜单。'
::             'You can still install WSL Ubuntu or PowerShell 7 from here.' = '你仍然可以从这里安装 WSL Ubuntu 或 PowerShell 7。'
::             'Loading recent projects' = '正在加载最近项目'
::             'Scanning project folders' = '正在扫描项目文件夹'
::             'Selected item' = '当前选中项'
::             'Press Enter to choose the focused item.' = '按 Enter 选择当前聚焦项。'
::             'Launcher Update Available' = '有可用的启动器更新'
::             'Update now' = '立即更新'
::             'Later' = '稍后'
::             'Skip this version' = '跳过此版本'
::             'Download the latest portable batch and replace the current launcher.' = '下载最新便携 batch 并替换当前启动器。'
::             'Keep using this version and check again later.' = '继续使用当前版本，稍后再检查。'
::             'Do not prompt again for' = '不再提示'
::             'Download' = '下载'
::             'Verify download' = '验证下载'
::             'Replace launcher' = '替换启动器'
::             'Relaunch updated launcher' = '重新启动已更新的启动器'
::             'SYTA was updated to' = 'SYTA 已更新为'
::             'Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell' = '使用 winget 安装 PowerShell 7 并将 Windows Terminal 默认配置文件设为 PowerShell'
::             'Install via winget and set Windows Terminal default profile to PowerShell.' = '通过 winget 安装并将 Windows Terminal 默认配置文件设为 PowerShell。'
::             'Return to the main menu.' = '返回主菜单。'
::             'Return to the previous menu.' = '返回上一级菜单。'
::             'Launch Preflight' = '启动前检查'
::             'Full Update Preflight' = '全量更新前检查'
::             'Light Update Preflight' = '轻量更新前检查'
::             'Install Preflight' = '安装前检查'
::             'A new terminal tab opens immediately after this screen' = '此界面后会立即打开一个新的终端标签页'
::             'A PowerShell window opens immediately after this screen' = '此界面后会立即打开一个 PowerShell 窗口'
::             'SYTA WSL Ubuntu Install' = 'SYTA WSL Ubuntu 安装'
::             'SYTA PowerShell 7 Install' = 'SYTA PowerShell 7 安装'
::             'SYTA Install - Core AI CLI Tools' = 'SYTA 安装 - 核心 AI CLI 工具'
::             'SYTA Light Updater' = 'SYTA 轻量更新'
::             'SYTA Updater' = 'SYTA 更新器'
::             'Continue later' = '稍后继续'
::             'Target  : First install' = '目标   : 首次安装'
::             'WSL     : Linux distro already installed' = 'WSL     : Linux 发行版已安装'
::             'WSL     : Will run wsl --install -d Ubuntu' = 'WSL     : 将运行 wsl --install -d Ubuntu'
::             'Power   : SYTA will ask whether to install PowerShell 7' = 'Power   : SYTA 将询问是否安装 PowerShell 7'
::             'Power   : PowerShell 7 already installed; SYTA can repair it if needed' = 'Power   : PowerShell 7 已安装；如有需要，SYTA 可进行修复'
::             'CLI     : Install the core AI CLI tools once a Linux distro is ready' = 'CLI     : Linux 发行版就绪后安装核心 AI CLI 工具'
::             'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs' = 'Note    : Oh My Codex / OMX 和 Oh My OpenCode 系列仍为可选安装'
::             'WSL     : Linux distro ready for CLI installs' = 'WSL     : Linux 发行版已就绪，可安装 CLI'
::             'WSL     : Ubuntu is installed but first Linux-user setup is still required' = 'WSL     : Ubuntu 已安装，但仍需完成首次 Linux 用户设置'
::             'Note    : Launch Ubuntu once and finish Linux user creation before installing CLI tools' = 'Note    : 先启动一次 Ubuntu 并完成 Linux 用户创建，再安装 CLI 工具'
::             'Ubuntu is installed, but its first Linux-user setup is not finished yet.' = 'Ubuntu 已安装，但其首次 Linux 用户设置尚未完成。'
::             'Launch Ubuntu once and finish Linux user creation before installing CLI tools.' = '先启动一次 Ubuntu 并完成 Linux 用户创建，再安装 CLI 工具。'
::             'After that, rerun First install or this install action.' = '完成后重新运行“首次安装”或当前安装操作。'
::             'WSL Ubuntu is not ready yet.' = 'WSL Ubuntu 还未就绪。'
::             'Run First install or WSL Ubuntu first.' = '请先运行“首次安装”或 WSL Ubuntu。'
::             'Then come back here once Ubuntu setup is complete.' = '完成 Ubuntu 设置后再回到这里。'
::             'Note    : Ubuntu setup may require a reboot or first-run Linux account creation before CLI installs can continue' = 'Note    : Ubuntu 安装可能需要重启或首次 Linux 用户创建，然后 CLI 安装才能继续'
::             'Ubuntu setup was started in a separate PowerShell window.' = 'Ubuntu 安装已在单独的 PowerShell 窗口中启动。'
::             'After Ubuntu finishes installing, rerun First install to continue with the core AI CLI tools.' = 'Ubuntu 安装完成后，请重新运行“首次安装”以继续安装核心 AI CLI 工具。'
::             'If Windows asks for a reboot, restart Windows first.' = '如果 Windows 要求重启，请先重启 Windows。'
::             'If Ubuntu asks you to create your Linux user, finish that step first.' = '如果 Ubuntu 要求你创建 Linux 用户，请先完成该步骤。'
::             'You can also use Install core AI CLI tools later if Ubuntu is already ready.' = '如果 Ubuntu 已就绪，你也可以稍后使用“安装核心 AI CLI 工具”。'
::             'Unknown tool' = '未知工具'
::             'Auth via env key' = '通过环境变量 key 认证'
::             'Auth/config detected' = '已检测到认证/配置'
::             'Auth n/a' = '无需认证'
::             'WSL Linux distro missing' = '缺少 WSL Linux 发行版'
::             'WSL Linux setup incomplete' = 'WSL Linux 设置未完成'
::             'Auth not detected' = '未检测到认证'
::             'Auth unknown' = '认证状态未知'
::             'Installed' = '已安装'
::             'Configured only' = '仅检测到配置'
::             'Missing' = '缺失'
::             'version not detected' = '未检测到版本'
::             'binary not found on PATH' = 'PATH 中未找到可执行文件'
::             'not installed' = '未安装'
::             'via nvm' = '通过 nvm'
::             'user-local' = '用户本地'
::             'system-wide' = '系统级'
::             'config-only' = '仅配置'
::             'custom path' = '自定义路径'
::             'unknown source' = '未知来源'
::         }
::     } else {
::         @{
::             'Selector' = 'Selection'
::             'Arrows move, Enter selects, Esc goes back' = 'Fleches pour naviguer, Entree pour valider, Echap pour revenir'
::             'Please wait' = 'Veuillez patienter'
::             'Launching in a new terminal tab' = 'Ouverture immediate dans un nouvel onglet du terminal'
::             'SYTA keeps this selector open while new tabs launch' = 'SYTA garde ce selecteur ouvert pendant l''ouverture des nouveaux onglets'
::             'Boot sequence' = 'Demarrage'
::             'unpacking portable runtime' = 'extraction du runtime portable'
::             'loading command deck' = 'chargement du poste de commande'
::             'scanning WSL bridge' = 'analyse du pont WSL'
::             'mapping project roots' = 'cartographie des projets'
::             'arming install matrix' = 'preparation de la matrice d''installation'
::             'warming AI launch lanes' = 'prechauffage des voies IA'
::             'routing terminal host' = 'configuration de l''hote terminal'
::             'syncing updater engines' = 'synchronisation des moteurs de mise a jour'
::             'locking flight path' = 'verrouillage de la trajectoire'
::             'SYTA ready' = 'SYTA pret'
::             'telemetry: launcher online, diagnostics cache cold, routes ready' = 'telemetrie : lanceur en ligne, cache de diagnostic vide, routes pretes'
::             'Create New Project' = 'Creer un nouveau projet'
::             'Leave blank to cancel' = 'Laisser vide pour annuler'
::             'Choose a short Windows-safe folder name.' = 'Choisissez un nom de dossier court et compatible Windows.'
::             '   Project name' = '   Nom du projet'
::             'Invalid project name' = 'Nom de projet invalide'
::             'Avoid characters Windows cannot use in folder names.' = 'Evitez les caracteres interdits dans les noms de dossier Windows.'
::             'Try another name' = 'Essayez un autre nom'
::             'Back' = 'Retour'
::             'Exit' = 'Quitter'
::             'Project Selector' = 'Selection du projet'
::             'Recent Projects' = 'Projets recents'
::             'Existing Projects' = 'Projets existants'
::             'Search Projects' = 'Rechercher des projets'
::             'Search Results' = 'Resultats de recherche'
::             'Search scans existing folders under C:\.CODEX.' = 'La recherche parcourt les dossiers existants sous C:\.CODEX.'
::             'Search is case-insensitive and matches partial words.' = 'La recherche ignore la casse et reconnait les mots partiels.'
::             '   Search term' = '   Terme de recherche'
::             'No project matches' = 'Aucun projet correspondant'
::             'Try another search' = 'Essayez une autre recherche'
::             'Open existing project' = 'Ouvrir un projet existant'
::             'Type a fresh project name and create its folder.' = 'Saisissez un nouveau nom de projet et creez son dossier.'
::             'Filter existing projects by a search term.' = 'Filtrer les projets existants par terme de recherche.'
::             'Choose a recently used project folder.' = 'Choisissez un dossier de projet recent.'
::             'Choose a project folder to open.' = 'Choisissez un dossier de projet a ouvrir.'
::             'Choose the tool to launch in the project workspace.' = 'Choisissez l''outil a lancer dans l''espace de travail du projet.'
::             'Agent Selector' = 'Selection de l''agent'
::             'Mode Selector' = 'Selection du mode'
::             'Explanations' = 'Explications'
::             'Update' = 'Mise a jour'
::             'Choose which update lane to run.' = 'Choisissez le type de mise a jour a lancer.'
::             'Run a lighter AI-tools-only update or the broader full maintenance pass.' = 'Lancer soit une mise a jour legere des outils IA, soit la maintenance complete.'
::             'Light update' = 'Mise a jour legere'
::             'Update all' = 'Mise a jour complete'
::             'Update AI coding CLIs only: Codex, OMX, OpenCode, Claude Code, Gemini CLI.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Claude Code, Gemini CLI.'
::             'Run the broader toolchain update pass, including system package managers.' = 'Lancer la maintenance plus large de la chaine d''outils, y compris les gestionnaires systeme.'
::             'First install (recommended)' = 'Premiere installation (recommandee)'
::             'Best beginner path for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.' = 'Meilleur parcours debutant pour WSL Ubuntu, PowerShell 7 en option et les CLI IA de base.'
::             'Recommended path for a new machine or first SYTA setup' = 'Parcours recommande pour une nouvelle machine ou une premiere installation SYTA'
::             'CLI     : Ready to launch the core AI CLI tools now' = 'CLI     : pret a lancer maintenant les CLI IA de base'
::             'CLI     : Full core AI CLI install starts after Ubuntu is ready' = 'CLI     : l''installation complete des CLI IA de base demarre apres qu''Ubuntu soit pret'
::             'Note    : Recommended path for a new machine or first SYTA setup' = 'Note    : parcours recommande pour une nouvelle machine ou une premiere installation SYTA'
::             'Note    : Ubuntu setup may require a reboot before CLI installs continue' = 'Note    : Ubuntu peut demander un redemarrage avant la suite des installations CLI'
::             'Note    : Ubuntu may also require first-run Linux account creation' = 'Note    : Ubuntu peut aussi demander la creation initiale du compte Linux'
::             'You can still use First install from here for the guided beginner path.' = 'Vous pouvez toujours utiliser Premiere installation ici pour le parcours debutant guide.'
::             'Learn what the tools are, who they are for, and what SYTA recommends.' = 'Comprendre simplement a quoi servent les outils et quoi choisir en premier.'
::             'Learn what the tools are, what SYTA recommends, and how to choose a setup.' = 'Comprendre simplement a quoi servent les outils, ce que SYTA recommande et quoi choisir.'
::             'Beginner guide' = 'Guide debutant'
::             'Beginner guide | simple' = 'Guide debutant | simple'
::             'Ultra-beginner explanation of each tool and the easiest path through SYTA.' = 'Explication tres simple de chaque outil et du chemin le plus facile dans SYTA.'
::             'Very simple explanation of each tool and the easiest place to start.' = 'Explication tres simple de chaque outil et du point de depart le plus facile.'
::             'Advanced guide' = 'Guide avance'
::             'Advanced guide | more detail' = 'Guide avance | plus de details'
::             'Higher-level tradeoffs, workflows, and why you might pick one tool over another.' = 'Vue plus detaillee des differences entre les outils et de quand les choisir.'
::             'More detail about the differences between the tools and when to pick each one.' = 'Plus de details sur les differences entre les outils et quand choisir chacun.'
::             'What should I install?' = 'Que dois-je installer ?'
::             'What should I install? | short answer' = 'Que dois-je installer ? | reponse courte'
::             'Straight recommendation based on simplicity, budget, and how hands-off you want setup to be.' = 'Recommandation directe selon ce qui est le plus simple, le moins prise de tete, et vos abonnements.'
::             'Direct recommendation if you just want the short answer.' = 'Recommandation directe si vous voulez seulement la reponse courte.'
::             'Press any key to return.' = 'Appuyez sur une touche pour revenir.'
::             'Codex: OpenAI coding agent with strong editing and reasoning.' = 'Codex : l''outil OpenAI pour coder avec de l''aide. Bon choix si vous voulez un assistant serieux pour lire, modifier et expliquer du code.'
::             'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.' = 'OMX : une couche en plus par-dessus Codex. A utiliser surtout si vous voulez plus d''automatisation, plus de structure, et des workflows plus lourds.'
::             'OpenCode: lightweight coding CLI and usually the easiest first start.' = 'OpenCode : l''outil le plus leger et souvent le plus simple pour commencer.'
::             'Claude Code and Gemini CLI: best if you already use those ecosystems.' = 'Claude Code et Gemini CLI : utiles surtout si vous payez deja ces services ou preferez deja ces ecosystemes.'
::             'Best beginner path: Install -> First install, then start with OpenCode or Codex.' = 'Meilleur parcours debutant : Installation -> Premiere installation, puis commencer avec OpenCode ou Codex.'
::             'Oh My OpenAgent is the full OpenCode harness. Oh My OpenCode Slim keeps a lighter preset.' = 'Oh My OpenAgent ajoute plein d''aides autour d''OpenCode. Oh My OpenCode Slim garde seulement une partie plus legere de ces aides.'
::             'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.' = 'Codex est la voie OpenAI directe. OMX ajoute une facon plus guidee et plus automatique de travailler.'
::             'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.' = 'OpenCode est souvent le plus simple. Codex et surtout OMX sont plus utiles si vous voulez etre davantage guide.'
::             'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.' = 'Installez seulement les CLI que vous utiliserez vraiment. Plus d''outils signifie plus d''authentification, de mises a jour et de chevauchements.'
::             'Oh My OpenAgent is the broader OpenCode harness; Slim keeps a lighter OpenCode-focused preset.' = 'Oh My OpenAgent ajoute beaucoup d''outils autour d''OpenCode ; Slim garde une version plus simple de cette idee.'
::             'Brand-new Windows machine: Install -> First install.' = 'Nouvelle machine Windows : Installation -> Premiere installation.'
::             'Lowest-friction start: OpenCode.' = 'Demarrage le plus simple : OpenCode.'
::             'Best OpenAI-first path: Codex, then OMX if you want deeper automation.' = 'Meilleur parcours si vous voulez surtout OpenAI : Codex d''abord, puis OMX seulement si vous voulez aller plus loin.'
::             'Install Oh My OpenAgent if you want the full harness. Install Slim if you want a lighter preset.' = 'Installez Oh My OpenAgent si vous voulez beaucoup d''aides autour d''OpenCode. Installez Slim si vous voulez une version plus simple.'
::             'Skip tools you do not have keys, subscriptions, or a real workflow for.' = 'Ignorez les outils pour lesquels vous n''avez pas de cle, d''abonnement ou de vrai besoin.'
::             'Choose what SYTA should do.' = 'Choisissez ce que SYTA doit faire.'
::             'Launch an agent with project selection, diagnostics, and recent-project support.' = 'Lancer un agent avec selection de projet, diagnostics et prise en charge des projets recents.'
::             'Install WSL Ubuntu or supported coding CLIs with preflight diagnostics.' = 'Installer WSL Ubuntu ou les CLI de code prises en charge avec diagnostics prealables.'
::             'Close the launcher.' = 'Fermer le lanceur.'
::             'Install or repair WSL Ubuntu and supported coding CLIs.' = 'Installer ou reparer WSL Ubuntu et les CLI de codage prises en charge.'
::             'First install' = 'Premiere installation'
::             'First install | recommended' = 'Premiere installation | recommandee'
::             'WSL Ubuntu | system setup' = 'WSL Ubuntu | configuration systeme'
::             'PowerShell 7 | optional' = 'PowerShell 7 | optionnel'
::             'Install core AI CLI tools | simple' = 'Installer les CLI IA de base | simple'
::             'Cleaner helper | maintenance' = 'Assistant de nettoyage | maintenance'
::             'Reset tool configs | maintenance' = 'Reinitialiser les configs des outils | maintenance'
::             'Codex CLI | guided' = 'Codex CLI | guide'
::             'OpenCode | simple' = 'OpenCode | simple'
::             'Oh My OpenAgent | advanced optional' = 'Oh My OpenAgent | option avancee'
::             'Oh My Codex / OMX | advanced optional' = 'Oh My Codex / OMX | option avancee'
::             'Claude Code | optional' = 'Claude Code | optionnel'
::             'Gemini CLI | optional' = 'Gemini CLI | optionnel'
::             'DROID CLI | optional' = 'DROID CLI | optionnel'
::             'Oh My OpenCode Slim | optional' = 'Oh My OpenCode Slim | optionnel'
::             'Guided setup for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.' = 'Parcours guide pour WSL Ubuntu, PowerShell 7 en option, et les CLI IA de base.'
::             'PowerShell 7 is already installed. Reinstall or repair it now?' = 'PowerShell 7 est deja installe. Le reinstaller ou le reparer maintenant ?'
::             'Would you like SYTA to install PowerShell 7 too?' = 'Voulez-vous aussi que SYTA installe PowerShell 7 ?'
::             'Skip PowerShell 7 for now' = 'Ignorer PowerShell 7 pour le moment'
::             'Continue without changing the Windows Terminal default profile.' = 'Continuer sans modifier le profil par defaut de Windows Terminal.'
::             'Install PowerShell 7 now' = 'Installer PowerShell 7 maintenant'
::             'Reinstall or repair PowerShell 7' = 'Reinstaller ou reparer PowerShell 7'
::             'Install core AI CLI tools' = 'Installer les CLI IA de base'
::             'Run Codex, OpenCode, Claude Code, and Gemini CLI in one pass.' = 'Lancer Codex, OpenCode, Claude Code et Gemini CLI en une seule passe.'
::             'WSL Linux setup incomplete | launch Ubuntu once first.' = 'Configuration Linux WSL incomplete | lancez Ubuntu une fois d''abord.'
::             'Cleaner helper' = 'Assistant de nettoyage'
::             'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.' = 'Analyser les anciennes installations nvm/npm des CLI IA et les doublons du PATH avant nettoyage.'
::             'Reset tool configs' = 'Reinitialiser les configs des outils'
::             'Review tracked config/auth paths and remove only the ones you confirm.' = 'Examiner les chemins config/auth suivis et supprimer seulement ceux que vous confirmez.'
::             'Choose which tool configs to reset.' = 'Choisissez quelles configs d''outils reinitialiser.'
::             'Pick one tool family, or reset every tracked config path.' = 'Choisissez une famille d''outils, ou reinitialisez tous les chemins config suivis.'
::             'Codex / OMX configs' = 'Configs Codex / OMX'
::             'Remove tracked Codex and OMX auth/config files.' = 'Supprimer les fichiers config/auth suivis de Codex et OMX.'
::             'OpenCode configs' = 'Configs OpenCode'
::             'Remove tracked OpenCode base config files.' = 'Supprimer les fichiers de config principaux suivis d''OpenCode.'
::             'Oh My OpenAgent configs' = 'Configs Oh My OpenAgent'
::             'Remove tracked Oh My OpenAgent compatibility config files.' = 'Supprimer les fichiers de config de compatibilite suivis d''Oh My OpenAgent.'
::             'Oh My OpenCode Slim configs' = 'Configs Oh My OpenCode Slim'
::             'Remove tracked Oh My OpenCode Slim config files.' = 'Supprimer les fichiers de config suivis d''Oh My OpenCode Slim.'
::             'Claude Code configs' = 'Configs Claude Code'
::             'Remove tracked Claude Code config files.' = 'Supprimer les fichiers de config suivis de Claude Code.'
::             'Gemini CLI configs' = 'Configs Gemini CLI'
::             'Remove tracked Gemini and Google AI config folders.' = 'Supprimer les dossiers de config suivis de Gemini et Google AI.'
::             'All tracked configs' = 'Toutes les configs suivies'
::             'Remove every tracked config/auth path shown by SYTA.' = 'Supprimer tous les chemins config/auth suivis affiches par SYTA.'
::             'SYTA Install - Config Reset Helper' = 'SYTA Installation - Assistant de reinitialisation des configs'
::             'Target  : Reset tool configs' = 'Cible   : Reinitialiser les configs des outils'
::             'Action  : Review tracked config/auth paths and confirm which ones to remove' = 'Action  : examiner les chemins config/auth suivis et confirmer ceux a supprimer'
::             'Scope   : Selected tracked config/auth paths, or all tracked config/auth paths' = 'Portee  : chemins config/auth suivis selectionnes, ou tous les chemins config/auth suivis'
::             'Selection : ' = 'Selection : '
::             'SYTA Install - Cleaner Helper' = 'SYTA Installation - Assistant de nettoyage'
::             'Target  : Cleaner helper' = 'Cible   : Assistant de nettoyage'
::             'Action  : Scan stale AI CLI installs and ask before removing old npm globals' = 'Action  : analyser les CLI IA obsoletes et demander avant de supprimer les npm globaux anciens'
::             'Scope   : Older nvm Node versions, duplicate PATH entries, user-scoped npm installs' = 'Portee  : anciennes versions Node nvm, doublons du PATH, installations npm utilisateur'
::             'Oh My OpenAgent' = 'Oh My OpenAgent'
::             'OpenCode + the full Oh My OpenAgent harness with its interactive installer.' = 'OpenCode + le harnais complet Oh My OpenAgent avec son installateur interactif.'
::             'This is an OpenCode add-on, not a separate coding CLI.' = 'Ceci est un add-on pour OpenCode, pas une CLI de code separee.'
::             'OpenCode should be installed first. SYTA will install it automatically if needed.' = 'OpenCode doit etre installe d''abord. SYTA l''installera automatiquement si besoin.'
::             'Best if you already use OpenCode and want more helper features around it.' = 'A conseiller surtout si vous utilisez deja OpenCode et voulez plus d''aides autour.'
::             'Best if you want a lighter OpenCode add-on instead of the bigger OpenAgent setup.' = 'A conseiller si vous voulez un add-on OpenCode plus leger que le gros setup OpenAgent.'
::             'OpenCode : ' = 'OpenCode : '
::             'Loading live tool diagnostics' = 'Chargement des diagnostics des outils'
::             'Checking Windows prerequisites' = 'Verification des prerequis Windows'
::             'Loading WSL tool diagnostics' = 'Chargement des diagnostics WSL'
::             'Preparing install options' = 'Preparation des options d''installation'
::             'No WSL Linux distro is ready yet, so SYTA will show safe setup choices only.' = 'Aucune distribution Linux WSL n''est encore prete, SYTA affiche donc uniquement des options d''installation sures.'
::             'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.' = 'Les diagnostics live etaient indisponibles, SYTA a bascule vers un menu d''installation de secours.'
::             'You can still install WSL Ubuntu or PowerShell 7 from here.' = 'Vous pouvez toujours installer WSL Ubuntu ou PowerShell 7 depuis ici.'
::             'Loading recent projects' = 'Chargement des projets recents'
::             'Scanning project folders' = 'Analyse des dossiers projet'
::             'Selected item' = 'Element selectionne'
::             'Press Enter to choose the focused item.' = 'Appuyez sur Entree pour choisir l''element selectionne.'
::             'Launcher Update Available' = 'Mise a jour du lanceur disponible'
::             'Update now' = 'Mettre a jour maintenant'
::             'Later' = 'Plus tard'
::             'Skip this version' = 'Ignorer cette version'
::             'Download the latest portable batch and replace the current launcher.' = 'Telecharger le dernier batch portable et remplacer le lanceur actuel.'
::             'Keep using this version and check again later.' = 'Continuer avec cette version et reverifier plus tard.'
::             'Do not prompt again for' = 'Ne plus proposer pour'
::             'Download' = 'Telechargement'
::             'Verify download' = 'Verification du telechargement'
::             'Replace launcher' = 'Remplacement du lanceur'
::             'Relaunch updated launcher' = 'Relance du lanceur mis a jour'
::             'SYTA was updated to' = 'SYTA a ete mis a jour vers'
::             'Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell' = 'Installer PowerShell 7 avec winget et definir PowerShell comme profil par defaut de Windows Terminal'
::             'Install via winget and set Windows Terminal default profile to PowerShell.' = 'Installer via winget et definir PowerShell comme profil par defaut de Windows Terminal.'
::             'Return to the main menu.' = 'Revenir au menu principal.'
::             'Return to the previous menu.' = 'Revenir au menu precedent.'
::             'Launch Preflight' = 'Pre-verification avant lancement'
::             'Full Update Preflight' = 'Pre-verification avant mise a jour complete'
::             'Light Update Preflight' = 'Pre-verification avant mise a jour legere'
::             'Install Preflight' = 'Pre-verification avant installation'
::             'A new terminal tab opens immediately after this screen' = 'Un nouvel onglet du terminal s''ouvre juste apres cet ecran'
::             'A PowerShell window opens immediately after this screen' = 'Une fenetre PowerShell s''ouvre juste apres cet ecran'
::             'SYTA WSL Ubuntu Install' = 'SYTA Installation WSL Ubuntu'
::             'SYTA PowerShell 7 Install' = 'SYTA Installation PowerShell 7'
::             'SYTA Install - Core AI CLI Tools' = 'SYTA Installation - CLI IA de base'
::             'SYTA Light Updater' = 'SYTA Mise a jour legere'
::             'SYTA Updater' = 'SYTA Mise a jour complete'
::             'Continue later' = 'Continuer plus tard'
::             'Target  : First install' = 'Cible   : Premiere installation'
::             'WSL     : Linux distro already installed' = 'WSL     : distribution Linux deja installee'
::             'WSL     : Will run wsl --install -d Ubuntu' = 'WSL     : executera wsl --install -d Ubuntu'
::             'Power   : SYTA will ask whether to install PowerShell 7' = 'Power   : SYTA demandera s''il faut installer PowerShell 7'
::             'Power   : PowerShell 7 already installed; SYTA can repair it if needed' = 'Power   : PowerShell 7 deja installe ; SYTA peut le reparer si besoin'
::             'CLI     : Install the core AI CLI tools once a Linux distro is ready' = 'CLI     : installer les CLI IA de base une fois une distribution Linux prete'
::             'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs' = 'Note    : Oh My Codex / OMX et les variantes Oh My OpenCode restent optionnels'
::             'WSL     : Linux distro ready for CLI installs' = 'WSL     : distribution Linux prete pour les installations CLI'
::             'WSL     : Ubuntu is installed but first Linux-user setup is still required' = 'WSL     : Ubuntu est installe mais la creation initiale de l''utilisateur Linux reste a faire'
::             'Note    : Launch Ubuntu once and finish Linux user creation before installing CLI tools' = 'Note    : lancez Ubuntu une fois et terminez la creation de l''utilisateur Linux avant d''installer les CLI'
::             'Ubuntu is installed, but its first Linux-user setup is not finished yet.' = 'Ubuntu est installe, mais sa configuration initiale de l''utilisateur Linux n''est pas encore terminee.'
::             'Launch Ubuntu once and finish Linux user creation before installing CLI tools.' = 'Lancez Ubuntu une fois et terminez la creation de l''utilisateur Linux avant d''installer les CLI.'
::             'After that, rerun First install or this install action.' = 'Ensuite, relancez Premiere installation ou cette action d''installation.'
::             'WSL Ubuntu is not ready yet.' = 'WSL Ubuntu n''est pas encore pret.'
::             'Run First install or WSL Ubuntu first.' = 'Lancez d''abord Premiere installation ou WSL Ubuntu.'
::             'Then come back here once Ubuntu setup is complete.' = 'Revenez ici une fois la configuration d''Ubuntu terminee.'
::             'Note    : Ubuntu setup may require a reboot or first-run Linux account creation before CLI installs can continue' = 'Note    : l''installation d''Ubuntu peut necessiter un redemarrage ou la creation initiale du compte Linux avant de poursuivre les CLI'
::             'Ubuntu setup was started in a separate PowerShell window.' = 'L''installation d''Ubuntu a ete lancee dans une fenetre PowerShell separee.'
::             'After Ubuntu finishes installing, rerun First install to continue with the core AI CLI tools.' = 'Une fois Ubuntu installe, relancez Premiere installation pour continuer avec les CLI IA de base.'
::             'If Windows asks for a reboot, restart Windows first.' = 'Si Windows demande un redemarrage, redemarrez Windows d''abord.'
::             'If Ubuntu asks you to create your Linux user, finish that step first.' = 'Si Ubuntu demande de creer votre utilisateur Linux, terminez d''abord cette etape.'
::             'You can also use Install core AI CLI tools later if Ubuntu is already ready.' = 'Vous pourrez aussi utiliser Installer les CLI IA de base plus tard si Ubuntu est deja pret.'
::             'Unknown tool' = 'Outil inconnu'
::             'Auth via env key' = 'Auth via cle d''environnement'
::             'Auth/config detected' = 'Auth/config detectee'
::             'Auth n/a' = 'Auth n/a'
::             'WSL Linux distro missing' = 'Aucune distribution Linux WSL prete'
::             'WSL Linux setup incomplete' = 'Configuration Linux WSL incomplete'
::             'Auth not detected' = 'Auth non detectee'
::             'Auth unknown' = 'Auth inconnue'
::             'Installed' = 'Installe'
::             'Configured only' = 'Configuration detectee seulement'
::             'Missing' = 'Absent'
::             'version not detected' = 'version non detectee'
::             'binary not found on PATH' = 'binaire introuvable dans le PATH'
::             'not installed' = 'non installe'
::             'via nvm' = 'via nvm'
::             'user-local' = 'utilisateur local'
::             'system-wide' = 'systeme'
::             'config-only' = 'config seulement'
::             'custom path' = 'chemin personnalise'
::             'unknown source' = 'source inconnue'
::         }
::     }
::
::     if ($map.ContainsKey($Text)) { return $map[$Text] }
::
::     if ($script:Language -eq 'zh') {
::         if ($Text -match '^Projects root: (.+)$') { return "项目根目录：$($Matches[1])" }
::         if ($Text -match '^Build: (.+)$') { return "构建：$($Matches[1])" }
::         if ($Text -match '^Recent projects tracked: (.+)$') { return "已跟踪最近项目数：$($Matches[1])" }
::         if ($Text -match '^Hint: (.+)$') { return "提示：$(Localize-Text $Matches[1])" }
::         if ($Text -match '^Folder root: (.+)$') { return "文件夹根目录：$($Matches[1])" }
::         if ($Text -match '^Recent project in (.+)$') { return "$($Matches[1]) 中的最近项目" }
::         if ($Text -match '^Recent project folder in (.+)$') { return "$($Matches[1]) 中的最近项目文件夹" }
::         if ($Text -match '^Project folder at (.+)$') { return "项目文件夹位于 $($Matches[1])" }
::         if ($Text -match '^Project folder in (.+)$') { return "项目文件夹位于 $($Matches[1])" }
::         if ($Text -match '^Choose how to work inside (.+)\.$') { return "选择如何在 $($Matches[1]) 中工作。" }
::         if ($Text -match '^Jump into one of (.+) recently used project\(s\)\.$') { return "打开 $($Matches[1]) 个最近使用的项目之一。" }
::         if ($Text -match '^Browse (.+) existing project folder\(s\)\.$') { return "浏览 $($Matches[1]) 个现有项目文件夹。" }
::         if ($Text -match '^No existing project matched ''(.+)''\.$') { return "没有现有项目匹配 '$($Matches[1])'。" }
::         if ($Text -match '^Projects matching ''(.+)''\.$') { return "与 '$($Matches[1])' 匹配的项目。" }
::         if ($Text -match '^Project : (.+)$') { return "项目   : $($Matches[1])" }
::         if ($Text -match '^Tool    : (.+)$') { return "工具   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Install : (.+)$') { return "安装   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Version : (.+)$') { return "版本   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Auth    : (.+)$') { return "认证   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Path    : (.+)$') { return "路径   : $($Matches[1])" }
::         if ($Text -match '^Scope   : (.+)$') { return "范围   : $($Matches[1])" }
::         if ($Text -match '^Folder  : (.+)$') { return "文件夹 : $($Matches[1])" }
::         if ($Text -match '^Target  : (.+)$') { return "目标   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Current : (.+)$') { return "当前   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Action  : (.+)$') { return "操作   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Impact  : (.+)$') { return "影响   : $(Localize-Text $Matches[1])" }
::         if ($Text -match '^Step (\d+)/(\d+)$') { return "步骤 $($Matches[1])/$($Matches[2])" }
::         if ($Text -match '^Items: (\d+) \| Selected: (\d+)/(\d+)$') { return "条目：$($Matches[1]) | 选中：$($Matches[2])/$($Matches[3])" }
::         if ($Text -match '^Items: (\d+) \| Selected: (\d+)/(\d+) \| Showing: (\d+)-(\d+)$') { return "条目：$($Matches[1]) | 选中：$($Matches[2])/$($Matches[3]) | 显示：$($Matches[4])-$($Matches[5])" }
::         if ($Text -match '^Installed \((.+)\)$') { return "已安装（$($Matches[1])）" }
::         return $Text
::     }
::
::     if ($Text -match '^Projects root: (.+)$') { return "Racine des projets : $($Matches[1])" }
::     if ($Text -match '^Build: (.+)$') { return "Build : $($Matches[1])" }
::     if ($Text -match '^Recent projects tracked: (.+)$') { return "Projets recents suivis : $($Matches[1])" }
::     if ($Text -match '^Hint: (.+)$') { return "Astuce : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Folder root: (.+)$') { return "Racine du dossier : $($Matches[1])" }
::     if ($Text -match '^Recent project in (.+)$') { return "Projet recent dans $($Matches[1])" }
::     if ($Text -match '^Recent project folder in (.+)$') { return "Dossier recent du projet dans $($Matches[1])" }
::     if ($Text -match '^Project folder at (.+)$') { return "Dossier du projet dans $($Matches[1])" }
::     if ($Text -match '^Project folder in (.+)$') { return "Dossier du projet dans $($Matches[1])" }
::     if ($Text -match '^Choose how to work inside (.+)\.$') { return "Choisissez comment travailler dans $($Matches[1])." }
::     if ($Text -match '^Jump into one of (.+) recently used project\(s\)\.$') { return "Ouvrir l''un des $($Matches[1]) projet(s) recemment utilises." }
::     if ($Text -match '^Browse (.+) existing project folder\(s\)\.$') { return "Parcourir $($Matches[1]) dossier(s) de projet existant(s)." }
::     if ($Text -match '^No existing project matched ''(.+)''\.$') { return "Aucun projet existant ne correspond a ''$($Matches[1])''." }
::     if ($Text -match '^Projects matching ''(.+)''\.$') { return "Projets correspondant a ''$($Matches[1])''." }
::     if ($Text -match '^Project : (.+)$') { return "Projet  : $($Matches[1])" }
::     if ($Text -match '^Tool    : (.+)$') { return "Outil   : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Install : (.+)$') { return "Install : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Version : (.+)$') { return "Version : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Auth    : (.+)$') { return "Auth    : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Path    : (.+)$') { return "Chemin  : $($Matches[1])" }
::     if ($Text -match '^Scope   : (.+)$') { return "Portee  : $($Matches[1])" }
::     if ($Text -match '^Folder  : (.+)$') { return "Dossier : $($Matches[1])" }
::     if ($Text -match '^Target  : (.+)$') { return "Cible   : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Current : (.+)$') { return "Actuel  : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Action  : (.+)$') { return "Action  : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Impact  : (.+)$') { return "Impact  : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Step (\d+)/(\d+)$') { return "Etape $($Matches[1])/$($Matches[2])" }
::     if ($Text -match '^Items: (\d+) \| Selected: (\d+)/(\d+)$') { return "Elements : $($Matches[1]) | Selection : $($Matches[2])/$($Matches[3])" }
::     if ($Text -match '^Items: (\d+) \| Selected: (\d+)/(\d+) \| Showing: (\d+)-(\d+)$') { return "Elements : $($Matches[1]) | Selection : $($Matches[2])/$($Matches[3]) | Affichage : $($Matches[4])-$($Matches[5])" }
::     if ($Text -match '^Installed \((.+)\)$') { return "Installe ($($Matches[1]))" }
::     return $Text
:: }
::
:: $script:Language = Resolve-Language -Requested $UiLanguage
:: function Ensure-MaximizedWindow {
::     if ($NoMaximize) {
::         return
::     }
::
::     try {
::         Add-Type -Namespace SYTA -Name NativeWin -MemberDefinition @"
:: using System;
:: using System.Runtime.InteropServices;
:: public static class NativeWin {
::     [DllImport("user32.dll")]
::     public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
:: }
:: "@ -ErrorAction SilentlyContinue | Out-Null
::
::         $hwnd = (Get-Process -Id $PID).MainWindowHandle
::         if ($hwnd -ne 0) {
::             [SYTA.NativeWin]::ShowWindowAsync($hwnd, 3) | Out-Null
::         }
::     } catch {
::         # Best effort only.
::     }
:: }
::
:: $script:AgentOptions = @(
::     [pscustomobject]@{
::         Key = 'codex-yolo'
::         Title = 'Codex | guided'
::         Subtitle = 'Strong all-around coding help. Good default if you want the OpenAI path.'
::         Accent = 'Cyan'
::         WindowTitle = 'Codex YOLO'
::     }
::     [pscustomobject]@{
::         Key = 'omx-madmax-high'
::         Title = 'OMX | advanced'
::         Subtitle = 'More automation and more structure on top of Codex. Better after you already understand the basics.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMX MADMAX HIGH'
::     }
::     [pscustomobject]@{
::         Key = 'opencode'
::         Title = 'OpenCode | simple'
::         Subtitle = 'Usually the easiest and lightest place to start.'
::         Accent = 'Green'
::         WindowTitle = 'OpenCode'
::     }
::     [pscustomobject]@{
::         Key = 'claude-code'
::         Title = 'Claude Code | optional'
::         Subtitle = 'Useful if you already use Claude.'
::         Accent = 'Magenta'
::         WindowTitle = 'Claude Code'
::     }
::     [pscustomobject]@{
::         Key = 'gemini-cli'
::         Title = 'Gemini CLI | optional'
::         Subtitle = 'Useful if you already use Gemini.'
::         Accent = 'Blue'
::         WindowTitle = 'Gemini CLI'
::     }
:: )
:: $script:ToolSpecs = @{
::     'codex' = [pscustomobject]@{
::         Command = 'codex'
::         VersionScript = 'codex --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.codex/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Codex CLI.'
::     }
::     'omx' = [pscustomobject]@{
::         Command = 'omx'
::         VersionScript = 'omx --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; elif [ -f "$HOME/.codex/config.toml" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Oh My Codex / OMX.'
::     }
::     'opencode' = [pscustomobject]@{
::         Command = 'opencode'
::         VersionScript = 'opencode --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -f "$HOME/.config/opencode/opencode.json" ]; then echo config-present; elif [ -n "${OPENAI_API_KEY:-}" ]; then echo env-key; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> OpenCode.'
::     }
::     'oh-my-openagent' = [pscustomobject]@{
::         Command = ''
::         VersionScript = ''
::         DetectScript = 'if [ -f "$HOME/.config/opencode/oh-my-openagent.jsonc" ]; then echo "$HOME/.config/opencode/oh-my-openagent.jsonc"; elif [ -f "$HOME/.config/opencode/oh-my-openagent.json" ]; then echo "$HOME/.config/opencode/oh-my-openagent.json"; elif [ -f "$HOME/.config/opencode/oh-my-opencode.jsonc" ]; then echo "$HOME/.config/opencode/oh-my-opencode.jsonc"; elif [ -f "$HOME/.config/opencode/oh-my-opencode.json" ]; then echo "$HOME/.config/opencode/oh-my-opencode.json"; elif [ -f "$HOME/.config/opencode/opencode.json" ] && grep -Eq "\"oh-my-openagent\"|\"oh-my-opencode\"" "$HOME/.config/opencode/opencode.json"; then echo "$HOME/.config/opencode/opencode.json"; elif [ -f "$HOME/.config/opencode/opencode.jsonc" ] && grep -Eq "\"oh-my-openagent\"|\"oh-my-opencode\"" "$HOME/.config/opencode/opencode.jsonc"; then echo "$HOME/.config/opencode/opencode.jsonc"; fi'
::         AuthScript = 'if [ -f "$HOME/.config/opencode/oh-my-openagent.jsonc" ] || [ -f "$HOME/.config/opencode/oh-my-openagent.json" ] || [ -f "$HOME/.config/opencode/oh-my-opencode.jsonc" ] || [ -f "$HOME/.config/opencode/oh-my-opencode.json" ] || { [ -f "$HOME/.config/opencode/opencode.json" ] && grep -Eq "\"oh-my-openagent\"|\"oh-my-opencode\"" "$HOME/.config/opencode/opencode.json"; } || { [ -f "$HOME/.config/opencode/opencode.jsonc" ] && grep -Eq "\"oh-my-openagent\"|\"oh-my-opencode\"" "$HOME/.config/opencode/opencode.jsonc"; }; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Oh My OpenAgent.'
::     }
::     'claude-code' = [pscustomobject]@{
::         Command = 'claude'
::         VersionScript = 'claude --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${ANTHROPIC_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.config/claude" ] || [ -f "$HOME/.claude.json" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Claude Code.'
::     }
::     'gemini-cli' = [pscustomobject]@{
::         Command = 'gemini'
::         VersionScript = 'gemini --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.config/gemini" ] || [ -d "$HOME/.config/google" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Gemini CLI.'
::     }
::     'droid-cli' = [pscustomobject]@{
::         Command = 'droid'
::         VersionScript = 'droid --version 2>/dev/null | head -n 1'
::         DetectScript = $null
::         AuthScript = 'if [ -n "${FACTORY_API_KEY:-}" ]; then echo env-key; elif [ -d "$HOME/.factory" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> DROID CLI.'
::     }
::     'oh-my-opencode-slim' = [pscustomobject]@{
::         Command = ''
::         VersionScript = ''
::         DetectScript = 'if [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ]; then echo "$HOME/.config/opencode/oh-my-opencode-slim.json"; fi'
::         AuthScript = 'if [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ]; then echo config-present; else echo not-detected; fi'
::         InstallHint = 'Install from Install -> Oh My OpenCode Slim.'
::     }
:: }
::
:: function Resolve-ToolKey {
::     param([string]$Key)
::
::     switch ($Key) {
::         'codex-yolo' { return 'codex' }
::         'omx-madmax-high' { return 'omx' }
::         default { return $Key }
::     }
:: }
::
:: function Test-WslAvailable {
::     return [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
:: }
::
:: function Get-WslDistros {
::     if (-not (Test-WslAvailable)) {
::         return @()
::     }
::
::     $raw = & wsl.exe -l -q 2>$null
::     if ($LASTEXITCODE -ne 0 -or -not $raw) {
::         return @()
::     }
::
::     return @($raw | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
:: }
::
:: function Get-WslUserDistros {
::     return @(Get-WslDistros | Where-Object {
::         $_ -and $_ -notmatch '^(docker-desktop|docker-desktop-data|rancher-desktop|podman-machine-default|podman-machine-default-rootful)$'
::     })
:: }
::
:: function Get-PreferredWslDistro {
::     $userDistros = @(Get-WslUserDistros)
::     if ($userDistros.Count -eq 0) {
::         return $null
::     }
::
::     $ubuntu = @($userDistros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1)
::     if ($ubuntu.Count -gt 0) {
::         return $ubuntu[0]
::     }
::
::     return $userDistros[0]
:: }
::
:: function Test-WslUserDistroInstalled {
::     return @(Get-WslUserDistros).Count -gt 0
:: }
::
:: function Test-WslPreferredDistroReadyForCli {
::     $distro = Get-PreferredWslDistro
::     if (-not $distro) {
::         return $false
::     }
::
::     & wsl.exe -d $distro --exec sh -lc "grep -Ev '^nobody:' /etc/passwd | grep -Eq '^[^:]+:[^:]*:[1-9][0-9]{3,}:'" 2>$null
::     return ($LASTEXITCODE -eq 0)
:: }
::
:: function Test-UbuntuInstalled {
::     return @(Get-WslDistros | Where-Object { $_ -match '^Ubuntu' }).Count -gt 0
:: }
::
:: function Get-PwshInfo {
::     $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
::     if (-not $cmd) {
::         return [pscustomobject]@{
::             Installed = $false
::             Path = $null
::             Version = 'not installed'
::             MenuText = 'Missing | install via winget and set as Windows Terminal default.'
::         }
::     }
::
::     $version = try {
::         (& $cmd.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null | Out-String).Trim()
::     } catch {
::         'version not detected'
::     }
::
::     return [pscustomobject]@{
::         Installed = $true
::         Path = $cmd.Source
::         Version = if ($version) { $version } else { 'version not detected' }
::         MenuText = Shorten-Text -Text ("Installed | version $version | can be set as Windows Terminal default")
::     }
:: }
::
:: function Invoke-WslCapture {
::     param([Parameter(Mandatory = $true)][string]$Script)
::
::     $distro = Get-PreferredWslDistro
::     if (-not $distro) {
::         return $null
::     }
::
::     $result = & wsl.exe -d $distro --exec sh -lc $Script 2>$null
::     if ($LASTEXITCODE -ne 0 -or -not $result) {
::         return $null
::     }
::
::     return ($result | Out-String).Trim()
:: }
::
:: function Get-WslPath {
::     param([Parameter(Mandatory = $true)][string]$WindowsPath)
::
::     $resolved = [System.IO.Path]::GetFullPath($WindowsPath)
::     if ($resolved -match '^(?<Drive>[A-Za-z]):\\(?<Rest>.*)$') {
::         $drive = $Matches.Drive.ToLowerInvariant()
::         $rest = ($Matches.Rest -replace '\\', '/').TrimEnd('/')
::         if ([string]::IsNullOrEmpty($rest)) {
::             return "/mnt/$drive"
::         }
::         return "/mnt/$drive/$rest"
::     }
::
::     throw "Unsupported path for WSL conversion: $resolved"
:: }
::
:: function Invoke-ToolDiagnosticsScript {
::     param([Parameter(Mandatory = $true)][string]$Key)
::
::     if (-not (Test-WslPreferredDistroReadyForCli)) {
::         return $null
::     }
::
::     $distro = Get-PreferredWslDistro
::     if (-not $distro) {
::         return $null
::     }
::
::     $scriptPath = Join-Path $script:ScriptDir 'syta-tool-diagnostics.sh'
::     $wslScriptPath = Get-WslPath -WindowsPath $scriptPath
::     $wslDir = Get-WslPath -WindowsPath $script:ScriptDir
::     $output = & wsl.exe -d $distro --cd $wslDir --exec bash $wslScriptPath $Key 2>$null
::     if ($LASTEXITCODE -ne 0 -or -not $output) {
::         return $null
::     }
::
::     $map = @{}
::     foreach ($line in $output) {
::         if ($line -match '^(?<Name>[^=]+)=(?<Value>.*)$') {
::             $map[$Matches.Name] = $Matches.Value
::         }
::     }
::     return $map
:: }
::
:: function Invoke-ToolDiagnosticsBatchScript {
::     param([string[]]$Keys)
::
::     if (-not (Test-WslPreferredDistroReadyForCli) -or -not $Keys -or $Keys.Count -eq 0) {
::         return @{}
::     }
::
::     $distro = Get-PreferredWslDistro
::     if (-not $distro) {
::         return @{}
::     }
::
::     $scriptPath = Join-Path $script:ScriptDir 'syta-tool-diagnostics.sh'
::     $wslScriptPath = Get-WslPath -WindowsPath $scriptPath
::     $wslDir = Get-WslPath -WindowsPath $script:ScriptDir
::     $output = & wsl.exe -d $distro --cd $wslDir --exec bash $wslScriptPath @Keys 2>$null
::     if ($LASTEXITCODE -ne 0 -or -not $output) {
::         return @{}
::     }
::
::     $records = @{}
::     $current = @{}
::     $currentKey = $null
::     foreach ($line in $output) {
::         if ($line -match '^__SYTA_DIAG_BEGIN__=(.+)$') {
::             $current = @{}
::             $currentKey = $Matches[1]
::             continue
::         }
::
::         if ($line -match '^__SYTA_DIAG_END__=(.+)$') {
::             if ($currentKey) {
::                 $records[$currentKey] = $current
::             }
::             $current = @{}
::             $currentKey = $null
::             continue
::         }
::
::         if ($line -match '^(?<Name>[^=]+)=(?<Value>.*)$') {
::             $current[$Matches.Name] = $Matches.Value
::         }
::     }
::
::     return $records
:: }
::
:: function Get-RecentProjectCount {
::     if ($null -eq $script:RecentProjectCountCache) {
::         $script:RecentProjectCountCache = @(Get-RecentProjects).Count
::     }
::
::     return [int]$script:RecentProjectCountCache
:: }
::
:: function Show-LoadProgress {
::     param(
::         [string]$Title,
::         [string]$Status,
::         [string]$Detail = '',
::         [int]$Current = 1,
::         [int]$Total = 1,
::         [ConsoleColor]$Accent = [ConsoleColor]::Cyan
::     )
::
::     $safeTotal = [Math]::Max(1, $Total)
::     $safeCurrent = [Math]::Min($safeTotal, [Math]::Max(0, $Current))
::     $filled = [Math]::Floor(($safeCurrent / $safeTotal) * 24)
::     if ($filled -le 0) {
::         $barCore = '>' + ('.' * 23)
::     } elseif ($filled -ge 24) {
::         $barCore = '=' * 24
::     } else {
::         $barCore = ('=' * ($filled - 1)) + '>' + ('.' * (24 - $filled))
::     }
::     $bar = '[' + $barCore + ']'
::
::     Clear-Host
::     Write-Banner -Tagline $Title -Hint 'Please wait'
::     Write-UiBorderLine -Color DarkGray
::     Write-BoxLine -Content $Status -Color $Accent
::     if ($Detail) {
::         Write-BoxLine -Content $Detail -Color DarkGray
::     }
::     Write-BoxLine -Content ("Step {0}/{1}" -f $safeCurrent, $safeTotal) -Color DarkGray
::     Write-BoxLine -Content $bar -Color $Accent
::     Write-UiBorderLine -Color DarkGray
::     Write-Host ''
:: }
::
:: function Shorten-Text {
::     param(
::         [string]$Text,
::         [int]$Max = 68
::     )
::
::     if ($null -eq $Text) {
::         return ''
::     }
::
::     if ($Text.Length -le $Max) {
::         return $Text
::     }
::
::     return ($Text.Substring(0, [Math]::Max(0, $Max - 3)) + '...')
:: }
::
:: function Get-UiContentWidth {
::     param(
::         [int]$Minimum = 44,
::         [int]$Maximum = 88,
::         [int]$Fallback = 72
::     )
::
::     try {
::         $windowWidth = [Console]::WindowWidth
::     } catch {
::         $windowWidth = 0
::     }
::
::     if ($windowWidth -le 0) {
::         return $Fallback
::     }
::
::     return [Math]::Max($Minimum, [Math]::Min($Maximum, ($windowWidth - 8)))
:: }
::
:: function Write-UiBorderLine {
::     param([ConsoleColor]$Color = [ConsoleColor]::DarkGray)
::
::     $width = Get-UiContentWidth
::     Write-Host ('  +' + ('-' * ($width + 2)) + '+') -ForegroundColor $Color
:: }
::
:: function Get-MenuViewport {
::     param(
::         [int]$ItemCount,
::         [int]$SelectedIndex,
::         [int]$ItemRowCost = 1
::     )
::
::     if ($ItemCount -le 0) {
::         return [pscustomobject]@{ Start = 0; End = -1; Visible = 0 }
::     }
::
::     try {
::         $windowHeight = [Console]::WindowHeight
::     } catch {
::         $windowHeight = 0
::     }
::
::     $rowCost = [Math]::Max(1, $ItemRowCost)
::
::     $visible = if ($windowHeight -gt 0) {
::         [Math]::Max(3, [Math]::Min($ItemCount, [Math]::Floor(($windowHeight - 18) / $rowCost)))
::     } else {
::         [Math]::Min($ItemCount, 5)
::     }
::
::     $start = [Math]::Max(0, [Math]::Min(($SelectedIndex - [Math]::Floor($visible / 2)), ($ItemCount - $visible)))
::     $end = [Math]::Min(($ItemCount - 1), ($start + $visible - 1))
::     return [pscustomobject]@{ Start = $start; End = $end; Visible = $visible }
:: }
::
:: function Clear-ToolDiagnosticsCache {
::     $script:ToolDiagCache = @{}
:: }
::
:: function Get-StateObject {
::     if (-not (Test-Path -LiteralPath $script:StateFile)) {
::         return [pscustomobject]@{ recentProjects = @() }
::     }
::
::     try {
::         $raw = Get-Content -LiteralPath $script:StateFile -Raw -ErrorAction Stop
::         $state = $raw | ConvertFrom-Json
::     } catch {
::         return [pscustomobject]@{ recentProjects = @() }
::     }
::
::     if (-not $state) {
::         return [pscustomobject]@{ recentProjects = @() }
::     }
::
::     if (-not $state.PSObject.Properties.Match('recentProjects').Count) {
::         $state | Add-Member -NotePropertyName recentProjects -NotePropertyValue @()
::     }
::
::     return $state
:: }
::
:: function Save-StateObject {
::     param([Parameter(Mandatory = $true)]$State)
::
::     $State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:StateFile -Encoding utf8
:: }
::
:: function Update-StateFields {
::     param([hashtable]$Fields)
::
::     $state = Get-StateObject
::     foreach ($key in $Fields.Keys) {
::         if ($state.PSObject.Properties.Match($key).Count) {
::             $state.$key = $Fields[$key]
::         } else {
::             $state | Add-Member -NotePropertyName $key -NotePropertyValue $Fields[$key]
::         }
::     }
::     Save-StateObject $state
::     return $state
:: }
::
:: function Get-RecentProjects {
::     $state = Get-StateObject
::     $projects = @()
::     foreach ($name in @($state.recentProjects)) {
::         if (-not [string]::IsNullOrWhiteSpace("$name")) {
::             $path = Join-Path $script:ProjectsRoot "$name"
::             if (Test-Path -LiteralPath $path -PathType Container) {
::                 $projects += [pscustomobject]@{
::                     Title = "$name"
::                     Subtitle = "Recent project in $script:ProjectsRoot"
::                     Accent = 'Cyan'
::                     Name = "$name"
::                     Existing = $true
::                 }
::             }
::         }
::     }
::     $script:RecentProjectCountCache = $projects.Count
::     return $projects
:: }
::
:: function Add-RecentProject {
::     param([Parameter(Mandatory = $true)][string]$Name)
::
::     $state = Get-StateObject
::     $current = @($state.recentProjects | ForEach-Object { "$_" } | Where-Object { $_ -and $_ -ne $Name })
::     $updated = @($Name) + $current
::     if ($updated.Count -gt 12) {
::         $updated = $updated[0..11]
::     }
::
::     if ($state.PSObject.Properties.Match('recentProjects').Count) {
::         $state.recentProjects = $updated
::     } else {
::         $state | Add-Member -NotePropertyName recentProjects -NotePropertyValue $updated
::     }
::     Save-StateObject $state
::     $script:RecentProjectCountCache = $updated.Count
:: }
::
:: function Update-StateFields {
::     param([hashtable]$Fields)
::
::     $state = Get-StateObject
::     foreach ($key in $Fields.Keys) {
::         if ($state.PSObject.Properties.Match($key).Count) {
::             $state.$key = $Fields[$key]
::         } else {
::             $state | Add-Member -NotePropertyName $key -NotePropertyValue $Fields[$key]
::         }
::     }
::     Save-StateObject $state
::     return $state
:: }
::
:: function Get-LauncherBatchPath {
::     $candidates = @(
::         $env:SYTA_SELF,
::         (Join-Path $script:ScriptDir 'syta-super-launcher.bat'),
::         (Join-Path $script:ScriptDir 'super.bat')
::     ) | Where-Object { $_ }
::
::     foreach ($candidate in $candidates) {
::         if (Test-Path -LiteralPath $candidate) {
::             return [System.IO.Path]::GetFullPath($candidate)
::         }
::     }
::
::     return $null
:: }
::
:: function Convert-ReleaseTagToVersion {
::     param([string]$Tag)
::
::     if ([string]::IsNullOrWhiteSpace($Tag)) {
::         return $null
::     }
::
::     $normalized = $Tag.Trim()
::     if ($normalized.StartsWith('v')) {
::         $normalized = $normalized.Substring(1)
::     }
::
::     try {
::         return [version]$normalized
::     } catch {
::         return $null
::     }
:: }
::
:: function Get-LatestReleaseInfoFromRedirect {
::     try {
::         $request = [System.Net.HttpWebRequest]::Create('https://github.com/callme-sy/syta-super-launcher/releases/latest')
::         $request.Method = 'HEAD'
::         $request.AllowAutoRedirect = $false
::         $request.UserAgent = 'SYTA Super Launcher'
::
::         try {
::             $response = $request.GetResponse()
::         } catch [System.Net.WebException] {
::             $response = $_.Exception.Response
::         }
::
::         if ($null -eq $response) {
::             return $null
::         }
::
::         $location = "$($response.Headers['Location'])"
::         if ([string]::IsNullOrWhiteSpace($location) -or $location -notmatch '/releases/tag/(?<Tag>v[^/]+)$') {
::             return $null
::         }
::
::         $tag = $Matches.Tag
::         return [pscustomobject]@{
::             Tag = $tag
::             Url = $location
::             AssetUrl = "https://github.com/callme-sy/syta-super-launcher/releases/download/$tag/syta-super-launcher.bat"
::             Digest = ''
::             PublishedAt = ''
::         }
::     } catch {
::         return $null
::     }
:: }
::
:: function Get-LatestReleaseInfo {
::     param([switch]$ForceRefresh)
::
::     $state = Get-StateObject
::     $cachedTag = if ($state.PSObject.Properties.Match('latestReleaseTag').Count) { "$($state.latestReleaseTag)" } else { '' }
::     $cachedUrl = if ($state.PSObject.Properties.Match('latestReleaseUrl').Count) { "$($state.latestReleaseUrl)" } else { '' }
::     $cachedAssetUrl = if ($state.PSObject.Properties.Match('latestReleaseAssetUrl').Count) { "$($state.latestReleaseAssetUrl)" } else { '' }
::     $cachedDigest = if ($state.PSObject.Properties.Match('latestReleaseAssetDigest').Count) { "$($state.latestReleaseAssetDigest)" } else { '' }
::     $cachedPublishedAt = if ($state.PSObject.Properties.Match('latestReleasePublishedAt').Count) { "$($state.latestReleasePublishedAt)" } else { '' }
::     $lastCheckedRaw = if ($state.PSObject.Properties.Match('updateLastCheckedUtc').Count) { "$($state.updateLastCheckedUtc)" } else { '' }
::
::     if (-not $ForceRefresh -and $lastCheckedRaw) {
::         try {
::             $lastChecked = [datetime]::Parse($lastCheckedRaw).ToUniversalTime()
::             if (((Get-Date).ToUniversalTime() - $lastChecked).TotalHours -lt $script:UpdateCheckTtlHours -and $cachedTag -and $cachedAssetUrl) {
::                 return [pscustomobject]@{
::                     Tag = $cachedTag
::                     Url = $cachedUrl
::                     AssetUrl = $cachedAssetUrl
::                     Digest = $cachedDigest
::                     PublishedAt = $cachedPublishedAt
::                 }
::             }
::         } catch {
::         }
::     }
::
::     try {
::         $response = Invoke-RestMethod -Uri $script:ReleaseApiUrl -Headers @{
::             'User-Agent' = 'SYTA Super Launcher'
::             'Accept' = 'application/vnd.github+json'
::         } -Method Get -TimeoutSec 3
::         $asset = @($response.assets | Where-Object { $_.name -eq 'syta-super-launcher.bat' } | Select-Object -First 1)
::         if (-not $asset) {
::             return $null
::         }
::
::         $digest = if ($asset.PSObject.Properties.Match('digest').Count) { "$($asset.digest)" } else { '' }
::         $info = [pscustomobject]@{
::             Tag = "$($response.tag_name)"
::             Url = "$($response.html_url)"
::             AssetUrl = "$($asset.browser_download_url)"
::             Digest = $digest
::             PublishedAt = "$($response.published_at)"
::         }
::
::         Update-StateFields @{
::             updateLastCheckedUtc = (Get-Date).ToUniversalTime().ToString('o')
::             latestReleaseTag = $info.Tag
::             latestReleaseUrl = $info.Url
::             latestReleaseAssetUrl = $info.AssetUrl
::             latestReleaseAssetDigest = $info.Digest
::             latestReleasePublishedAt = $info.PublishedAt
::         } | Out-Null
::
::         return $info
::     } catch {
::         $redirectInfo = Get-LatestReleaseInfoFromRedirect
::         if ($redirectInfo) {
::             Update-StateFields @{
::                 updateLastCheckedUtc = (Get-Date).ToUniversalTime().ToString('o')
::                 latestReleaseTag = $redirectInfo.Tag
::                 latestReleaseUrl = $redirectInfo.Url
::                 latestReleaseAssetUrl = $redirectInfo.AssetUrl
::                 latestReleaseAssetDigest = $redirectInfo.Digest
::                 latestReleasePublishedAt = $redirectInfo.PublishedAt
::             } | Out-Null
::
::             return $redirectInfo
::         }
::
::         if ($cachedTag -and $cachedAssetUrl) {
::             return [pscustomobject]@{
::                 Tag = $cachedTag
::                 Url = $cachedUrl
::                 AssetUrl = $cachedAssetUrl
::                 Digest = $cachedDigest
::                 PublishedAt = $cachedPublishedAt
::             }
::         }
::         return $null
::     }
:: }
::
:: function Get-AvailableLauncherUpdate {
::     $launcherPath = Get-LauncherBatchPath
::     if (-not $launcherPath) {
::         return $null
::     }
::
::     $currentVersion = Convert-ReleaseTagToVersion $script:ReleaseTag
::     $release = Get-LatestReleaseInfo
::     if (-not $release) {
::         return $null
::     }
::
::     $latestVersion = Convert-ReleaseTagToVersion $release.Tag
::     if ($currentVersion -and $latestVersion -and $latestVersion -le $currentVersion) {
::         $refreshedRelease = Get-LatestReleaseInfo -ForceRefresh
::         if ($refreshedRelease) {
::             $release = $refreshedRelease
::             $latestVersion = Convert-ReleaseTagToVersion $release.Tag
::         }
::     }
::
::     if (-not $currentVersion -or -not $latestVersion -or $latestVersion -le $currentVersion) {
::         return $null
::     }
::
::     $state = Get-StateObject
::     $dismissedTag = if ($state.PSObject.Properties.Match('dismissedReleaseTag').Count) { "$($state.dismissedReleaseTag)" } else { '' }
::     if ($dismissedTag -and $dismissedTag -eq $release.Tag) {
::         return $null
::     }
::
::     return [pscustomobject]@{
::         CurrentTag = $script:ReleaseTag
::         LatestTag = $release.Tag
::         ReleaseUrl = $release.Url
::         AssetUrl = $release.AssetUrl
::         Digest = $release.Digest
::         PublishedAt = $release.PublishedAt
::         LauncherPath = $launcherPath
::     }
:: }
::
:: function Format-AuthStatus {
::     param([string]$Raw)
::
::     switch ($Raw) {
::         'env-key' { return (Localize-Text 'Auth via env key') }
::         'config-present' { return (Localize-Text 'Auth/config detected') }
::         'not-installed' { return (Localize-Text 'Auth n/a') }
::         'wsl-missing' { return (Localize-Text 'WSL Linux distro missing') }
::         'wsl-setup-incomplete' { return (Localize-Text 'WSL Linux setup incomplete') }
::         'not-detected' { return (Localize-Text 'Auth not detected') }
::         default {
::             if ([string]::IsNullOrWhiteSpace($Raw)) { return (Localize-Text 'Auth unknown') }
::             return $Raw
::         }
::     }
:: }
::
:: function Get-ToolDiagnostics {
::     param(
::         [Parameter(Mandatory = $true)][string]$Key,
::         [switch]$Refresh
::     )
::
::     $resolvedKey = Resolve-ToolKey $Key
::     if (-not $Refresh -and $script:ToolDiagCache.ContainsKey($resolvedKey)) {
::         return $script:ToolDiagCache[$resolvedKey]
::     }
::
::     $spec = $script:ToolSpecs[$resolvedKey]
::     if (-not $spec) {
::         $diag = [pscustomobject]@{
::             Key = $resolvedKey
::             Installed = $false
::             Path = $null
::             PathText = (Localize-Text 'Unknown tool')
::             Version = $null
::             VersionText = (Localize-Text 'Unknown tool')
::             AuthRaw = 'not-detected'
::             AuthText = (Localize-Text 'Auth unknown')
::             InstallSource = 'unknown'
::             InstallText = (Localize-Text 'Unknown')
::             MenuText = (Localize-Text 'Unknown tool')
::         }
::         $script:ToolDiagCache[$resolvedKey] = $diag
::         return $diag
::     }
::
::     $distroInstalled = Test-WslUserDistroInstalled
::     $distroReady = Test-WslPreferredDistroReadyForCli
::     if (-not $distroReady) {
::         $setupText = if ($distroInstalled) { (Localize-Text 'WSL Linux setup incomplete') } else { (Localize-Text 'WSL Linux distro missing') }
::         $authRaw = if ($distroInstalled) { 'wsl-setup-incomplete' } else { 'wsl-missing' }
::         $diag = [pscustomobject]@{
::             Key = $resolvedKey
::             Installed = $false
::             Path = $null
::             PathText = $spec.InstallHint
::             Version = $null
::             VersionText = $setupText
::             AuthRaw = $authRaw
::             AuthText = $setupText
::             InstallSource = 'unknown'
::             InstallText = (Localize-Text 'Missing')
::             MenuText = $setupText
::         }
::         $script:ToolDiagCache[$resolvedKey] = $diag
::         return $diag
::     }
::
::     $raw = Invoke-ToolDiagnosticsScript -Key $resolvedKey
::     $diag = Convert-ToolDiagnosticsRawToObject -ResolvedKey $resolvedKey -Raw $raw
::     $script:ToolDiagCache[$resolvedKey] = $diag
::     return $diag
:: }
::
:: function Convert-ToolDiagnosticsRawToObject {
::     param(
::         [Parameter(Mandatory = $true)][string]$ResolvedKey,
::         [Parameter(Mandatory = $true)]$Raw
::     )
::
::     $spec = $script:ToolSpecs[$ResolvedKey]
::     $installed = ($Raw.installed -eq '1')
::     $path = if ($Raw.path) { $Raw.path } else { $null }
::     $version = if ($Raw.version) { $Raw.version } else { $null }
::     $authRaw = if ($Raw.auth) { $Raw.auth } else { 'not-detected' }
::     $installSource = if ($Raw.install_source) { $Raw.install_source } else { 'unknown' }
::
::     $sourceLabel = switch ($installSource) {
::         'nvm' { Localize-Text 'via nvm' }
::         'user' { Localize-Text 'user-local' }
::         'system' { Localize-Text 'system-wide' }
::         'config' { Localize-Text 'config-only' }
::         'custom' { Localize-Text 'custom path' }
::         default { Localize-Text 'unknown source' }
::     }
::
::     $configPath = if ($Raw.config) { $Raw.config } else { $null }
::     $statusText = if ($installSource -eq 'config' -or $configPath) { Localize-Text 'Configured only' } elseif ($installed) { Localize-Text "Installed ($sourceLabel)" } else { Localize-Text 'Missing' }
::
::     $diag = [pscustomobject]@{
::         Key = $ResolvedKey
::         Installed = $installed
::         Path = $path
::         PathText = if ($path) { $path } elseif ($configPath) { $configPath } else { $spec.InstallHint }
::         Version = $version
::         VersionText = if ($installSource -eq 'config' -or $configPath) { (Localize-Text 'binary not found on PATH') } elseif ($installed) { if ($version) { $version } else { (Localize-Text 'version not detected') } } else { (Localize-Text 'not installed') }
::         AuthRaw = $authRaw
::         AuthText = Format-AuthStatus -Raw $authRaw
::         InstallSource = $installSource
::         InstallText = $statusText
::     }
::     $diag | Add-Member -NotePropertyName MenuText -NotePropertyValue (Shorten-Text -Text ("$($diag.InstallText) | $($diag.VersionText) | $($diag.AuthText)"))
::     return $diag
:: }
::
:: function New-WslMissingToolDiagnostics {
::     param(
::         [Parameter(Mandatory = $true)][string]$Key,
::         [switch]$SetupIncomplete
::     )
::
::     $resolvedKey = Resolve-ToolKey $Key
::     $spec = $script:ToolSpecs[$resolvedKey]
::     $statusText = if ($SetupIncomplete) { (Localize-Text 'WSL Linux setup incomplete') } else { (Localize-Text 'WSL Linux distro missing') }
::     $authRaw = if ($SetupIncomplete) { 'wsl-setup-incomplete' } else { 'wsl-missing' }
::     $diag = [pscustomobject]@{
::         Key = $resolvedKey
::         Installed = $false
::         Path = $null
::         PathText = $spec.InstallHint
::         Version = $null
::         VersionText = $statusText
::         AuthRaw = $authRaw
::         AuthText = $statusText
::         InstallSource = 'unknown'
::         InstallText = (Localize-Text 'Missing')
::         MenuText = $statusText
::     }
::     return $diag
:: }
::
:: function Warm-ToolDiagnosticsCache {
::     param([string[]]$Keys)
::
::     $resolvedKeys = @($Keys | ForEach-Object { Resolve-ToolKey $_ } | Select-Object -Unique)
::     if ($resolvedKeys.Count -eq 0) {
::         return
::     }
::
::     if (-not (Test-WslPreferredDistroReadyForCli)) {
::         foreach ($key in $resolvedKeys) {
::             $null = Get-ToolDiagnostics -Key $key
::         }
::         return
::     }
::
::     $rawMap = Invoke-ToolDiagnosticsBatchScript -Keys $resolvedKeys
::     foreach ($key in $resolvedKeys) {
::         if ($script:ToolDiagCache.ContainsKey($key)) {
::             continue
::         }
::
::         if ($rawMap.ContainsKey($key)) {
::             $script:ToolDiagCache[$key] = Convert-ToolDiagnosticsRawToObject -ResolvedKey $key -Raw $rawMap[$key]
::         } else {
::             $null = Get-ToolDiagnostics -Key $key -Refresh
::         }
::     }
:: }
::
:: function Get-AgentMenuItems {
::     Show-LoadProgress -Title 'Agent Selector' -Status 'Loading live tool diagnostics' -Current 1 -Total 1 -Accent Cyan
::     Warm-ToolDiagnosticsCache -Keys @($script:AgentOptions | Select-Object -ExpandProperty Key)
::     return @($script:AgentOptions | ForEach-Object {
::         $diag = Get-ToolDiagnostics -Key $_.Key
::         [pscustomobject]@{
::             Key = $_.Key
::             Title = $_.Title
::             Subtitle = "$($_.Subtitle) | $($diag.MenuText)"
::             Accent = if ($diag.Installed) { $_.Accent } else { 'DarkYellow' }
::             WindowTitle = $_.WindowTitle
::             ToolDiag = $diag
::         }
::     })
:: }
::
:: function Write-BoxLine {
::     param(
::         [string]$Content,
::         [ConsoleColor]$Color = [ConsoleColor]::Gray,
::         [int]$Width = 0
::     )
::
::     if ($Width -le 0) {
::         $Width = Get-UiContentWidth
::     }
::
::     $render = Shorten-Text -Text (Localize-Text $Content) -Max $Width
::     Write-Host ('  | ' + $render.PadRight($Width) + ' |') -ForegroundColor $Color
:: }
::
:: function Write-WrappedBoxText {
::     param(
::         [string]$Content,
::         [ConsoleColor]$Color = [ConsoleColor]::Gray,
::         [int]$Width = 0
::     )
::
::     if ($Width -le 0) {
::         $Width = Get-UiContentWidth
::     }
::
::     $text = Localize-Text $Content
::     if ($null -eq $text) {
::         $text = ''
::     }
::
::     $remaining = $text.Trim()
::     if (-not $remaining) {
::         Write-Host ('  | ' + ''.PadRight($Width) + ' |') -ForegroundColor $Color
::         return
::     }
::
::     while ($remaining.Length -gt $Width) {
::         $slice = $remaining.Substring(0, $Width)
::         $breakAt = $slice.LastIndexOf(' ')
::         if ($breakAt -lt 0 -or $breakAt -lt [Math]::Floor($Width / 3)) {
::             $breakAt = $Width
::         }
::
::         $line = $remaining.Substring(0, $breakAt).Trim()
::         Write-Host ('  | ' + $line.PadRight($Width) + ' |') -ForegroundColor $Color
::         $remaining = $remaining.Substring([Math]::Min($breakAt, $remaining.Length)).TrimStart()
::     }
::
::     Write-Host ('  | ' + $remaining.PadRight($Width) + ' |') -ForegroundColor $Color
:: }
::
:: function Write-Banner {
::     param(
::         [string]$Tagline = 'Selector',
::         [string]$Hint = 'Arrows move, Enter selects, Esc goes back'
::     )
::
::     $recentCount = Get-RecentProjectCount
::     Write-Host ''
::     Write-UiBorderLine -Color DarkCyan
::     Write-BoxLine -Content 'SYTA AGENTIC LAUNCHER' -Color Cyan
::     Write-BoxLine -Content 'Made by Sylvain T.' -Color Magenta
::     Write-BoxLine -Content $Tagline -Color Gray
::     Write-BoxLine -Content "Projects root: $script:ProjectsRoot" -Color White
::     Write-BoxLine -Content "SYTA $script:ReleaseTag" -Color DarkGray
::     Write-BoxLine -Content "Recent projects tracked: $recentCount" -Color DarkGray
::     Write-BoxLine -Content "Hint: $Hint" -Color Gray
::     Write-UiBorderLine -Color DarkCyan
::     Write-Host ''
:: }
::
:: function Show-IntroAnimation {
::     if ($NoAnimation) {
::         return
::     }
::
::     $rocket = @(
::         '      .',
::         '     / \',
::         '    / _ \',
::         "   |.o ''.|",
::         "   |''._.''|",
::         '   |     |',
::         " ,''|  |  |`.",
::         ' /  |  |  |  \',
::         " |,-''--|--''-.|"
::     )
::
::     $frames = @(
::         @{ Offset = 0;  Bar = '[=>                            ]'; Status = 'unpacking portable runtime'; Accent = 'Cyan' },
::         @{ Offset = 2;  Bar = '[====>                         ]'; Status = 'loading command deck'; Accent = 'Cyan' },
::         @{ Offset = 4;  Bar = '[=======>                      ]'; Status = 'scanning WSL bridge'; Accent = 'White' },
::         @{ Offset = 6;  Bar = '[==========>                   ]'; Status = 'mapping project roots'; Accent = 'White' },
::         @{ Offset = 8;  Bar = '[=============>                ]'; Status = 'arming install matrix'; Accent = 'Yellow' },
::         @{ Offset = 10; Bar = '[================>             ]'; Status = 'warming AI launch lanes'; Accent = 'Yellow' },
::         @{ Offset = 12; Bar = '[===================>          ]'; Status = 'routing terminal host'; Accent = 'Green' },
::         @{ Offset = 14; Bar = '[======================>       ]'; Status = 'syncing updater engines'; Accent = 'Green' },
::         @{ Offset = 16; Bar = '[=========================>    ]'; Status = 'locking flight path'; Accent = 'Cyan' },
::         @{ Offset = 18; Bar = '[============================> ]'; Status = 'SYTA ready'; Accent = 'Cyan' }
::     )
::
::     foreach ($frame in $frames) {
::         $pad = ' ' * $frame.Offset
::         Clear-Host
::         Write-Banner -Tagline 'Boot sequence' -Hint 'Please wait'
::         Write-Host '   .--------------------------------------------------------.' -ForegroundColor DarkGray
::         Write-Host '   |                  SYTA Launch Bay                       |' -ForegroundColor DarkGray
::         Write-Host "   '--------------------------------------------------------'" -ForegroundColor DarkGray
::         Write-Host ''
::
::         foreach ($line in $rocket) {
::             Write-Host ($pad + $line) -ForegroundColor White
::         }
::
::         Write-Host ''
::         Write-Host ("   " + $frame.Bar + "  " + (Localize-Text $frame.Status)) -ForegroundColor $frame.Accent
::         Write-Host '   Made by Sylvain T.' -ForegroundColor Magenta
::         Write-Host ('   ' + (Localize-Text 'telemetry: launcher online, diagnostics cache cold, routes ready')) -ForegroundColor DarkGray
::         Start-Sleep -Milliseconds 45
::     }
::
::     Start-Sleep -Milliseconds 100
:: }
::
:: function Show-InfoBox {
::     param(
::         [string]$Title,
::         [string[]]$Lines,
::         [ConsoleColor]$Accent = [ConsoleColor]::Cyan,
::         [string]$Hint = 'Launching in a new terminal tab'
::     )
::
::     Clear-Host
::     Write-Banner -Tagline $Title -Hint $Hint
::     Write-UiBorderLine -Color DarkGray
::     foreach ($line in $Lines) {
::         Write-BoxLine -Content $line -Color $Accent
::     }
::     Write-UiBorderLine -Color DarkGray
::     Write-Host ''
:: }
::
:: function Show-DetailPanel {
::     param(
::         [string]$Label,
::         [string]$Title,
::         [string]$Detail = '',
::         [ConsoleColor]$Accent = [ConsoleColor]::Cyan
::     )
::
::     Write-UiBorderLine -Color DarkGray
::     $localizedLabel = Localize-Text $Label
::     $localizedTitle = Localize-Text $Title
::     Write-BoxLine -Content ("{0}: {1}" -f $localizedLabel, $localizedTitle) -Color $Accent
::     if ($Detail) {
::         Write-BoxLine -Content (Localize-Text $Detail) -Color Gray
::     }
::     Write-UiBorderLine -Color DarkGray
:: }
::
:: function Show-StatusPanel {
::     param(
::         [string]$Title,
::         [string]$Body,
::         [ConsoleColor]$Color = [ConsoleColor]::Cyan
::     )
::
::     Show-InfoBox -Title $Title -Lines @($Body) -Accent $Color -Hint 'SYTA keeps this selector open while new tabs launch'
:: }
::
:: function Open-WindowsPowerShellWindow {
::     param(
::         [Parameter(Mandatory = $true)][string]$Title,
::         [Parameter(Mandatory = $true)][string]$Command,
::         [switch]$UseWindowsTerminal = $true
::     )
::
::     $psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
::     if (-not (Test-Path -LiteralPath $psExe)) {
::         $cmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
::         if ($cmd) {
::             $psExe = $cmd.Source
::         }
::     }
::
::     $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
::     switch ($script:Language) {
::         'fr' {
::             $successMessage = 'Operation terminee. Vous pouvez fermer cette fenetre et revenir a la fenetre principale SYTA.'
::             $failureMessage = 'Operation terminee avec une erreur.'
::             $returnMessage = 'Revenez a la fenetre principale SYTA pour choisir une autre action ou installer l''outil manquant.'
::             $closePrompt = 'Appuyez sur Entree pour fermer cette fenetre'
::         }
::         'zh' {
::             $successMessage = '操作已完成。你可以关闭此窗口并返回 SYTA 主窗口。'
::             $failureMessage = '操作因错误结束。'
::             $returnMessage = '返回主 SYTA 窗口以选择其他操作或安装缺失的工具。'
::             $closePrompt = '按 Enter 关闭此窗口'
::         }
::         default {
::             $successMessage = 'Operation completed. You can close this window and go back to the main SYTA window.'
::             $failureMessage = 'Operation finished with an error.'
::             $returnMessage = 'Go back to the main SYTA window to choose another action or install the missing tool.'
::             $closePrompt = 'Press Enter to close this window'
::         }
::     }
::     $escapedTitle = $Title.Replace("'", "''")
::     $escapedSuccess = $successMessage.Replace("'", "''")
::     $escapedFailure = $failureMessage.Replace("'", "''")
::     $escapedReturn = $returnMessage.Replace("'", "''")
::     $escapedClosePrompt = $closePrompt.Replace("'", "''")
::     $wrappedCommand = @(
::         "`$env:SYTA_LANGUAGE = '$($script:Language)'"
::         "`$Host.UI.RawUI.WindowTitle = '$escapedTitle'"
::         '$ErrorActionPreference = ''Stop'''
::         'try {'
::         "  $Command"
::         "  Write-Host ''"
::         "  Write-Host '$escapedSuccess' -ForegroundColor Green"
::         '} catch {'
::         "  Write-Host ''"
::         "  Write-Host '$escapedFailure' -ForegroundColor Red"
::         '  Write-Host $_.Exception.Message -ForegroundColor Yellow'
::         "  Write-Host '$escapedReturn' -ForegroundColor Cyan"
::         '} finally {'
::         "  Write-Host ''"
::         "  Read-Host '$escapedClosePrompt' | Out-Null"
::         '}'
::     ) -join '; '
::     $psArgs = @(
::         '-NoLogo',
::         '-NoProfile',
::         '-ExecutionPolicy', 'Bypass',
::         '-Command', $wrappedCommand
::     )
::
::     if ($DryRun) {
::         return [pscustomobject]@{
::             Title = $Title
::             Command = $wrappedCommand
::             FilePath = $psExe
::             UsesWindowsTerminal = ([bool]$wt -and $UseWindowsTerminal)
::         }
::     }
::
::     if ($wt -and $UseWindowsTerminal) {
::         $wtArgs = @('new-tab', '--title', $Title, $psExe) + $psArgs
::         & $wt.Source @wtArgs | Out-Null
::         return
::     }
::
::     Start-Process -FilePath $psExe -ArgumentList $psArgs | Out-Null
:: }
::
:: function Read-Menu {
::     param(
::         [Parameter(Mandatory = $true)][string]$Title,
::         [Parameter(Mandatory = $true)][string]$Subtitle,
::         [Parameter(Mandatory = $true)][array]$Items
::     )
::
::     $index = 0
::     while ($true) {
::         Clear-Host
::         Write-Banner -Tagline $Title
::         Write-UiBorderLine -Color DarkGray
::         Write-BoxLine -Content $Subtitle -Color Gray
::         Write-UiBorderLine -Color DarkGray
::         Write-Host ''
::
::         $viewport = Get-MenuViewport -ItemCount $Items.Count -SelectedIndex $index -ItemRowCost 2
::         $labelMax = [Math]::Max(24, (Get-UiContentWidth) - 6)
::         $detailMax = [Math]::Max(24, (Get-UiContentWidth) - 8)
::
::         if ($viewport.Start -gt 0) {
::             Write-Host '  ...' -ForegroundColor DarkGray
::         }
::
::         for ($i = $viewport.Start; $i -le $viewport.End; $i++) {
::             $item = $Items[$i]
::             $selected = $i -eq $index
::             $titleColor = if ($selected) {
::                 if ($item.PSObject.Properties.Match('Accent').Count) { $item.Accent } else { 'Cyan' }
::             } else {
::                 'Gray'
::             }
::             $detailColor = if ($selected) { 'White' } else { 'DarkGray' }
::             $prefix = if ($selected) { '> ' } else { '  ' }
::             $label = if ($item.PSObject.Properties.Match('Title').Count) { $item.Title } else { [string]$item }
::             $detail = if ($item.PSObject.Properties.Match('Subtitle').Count) { $item.Subtitle } else { '' }
::
::             $label = Localize-Text $label
::             $detail = Localize-Text $detail
::             Write-Host ('  ' + $prefix + (Shorten-Text -Text $label -Max $labelMax)) -ForegroundColor $titleColor
::             if ($detail) {
::                 Write-Host ('     ' + (Shorten-Text -Text $detail -Max $detailMax)) -ForegroundColor $detailColor
::             }
::         }
::
::         if ($viewport.End -lt ($Items.Count - 1)) {
::             Write-Host '  ...' -ForegroundColor DarkGray
::         }
::         Write-Host ''
::
::         $selectedItem = $Items[$index]
::         $selectedLabel = if ($selectedItem.PSObject.Properties.Match('Title').Count) { $selectedItem.Title } else { [string]$selectedItem }
::         $selectedDetail = if ($selectedItem.PSObject.Properties.Match('Subtitle').Count) { $selectedItem.Subtitle } else { '' }
::         $selectedAccent = if ($selectedItem.PSObject.Properties.Match('Accent').Count) { $selectedItem.Accent } else { 'Cyan' }
::         Show-DetailPanel -Label 'Selected item' -Title $selectedLabel -Detail $selectedDetail -Accent $selectedAccent
::
::         Write-UiBorderLine -Color DarkGray
::         Write-BoxLine -Content 'Press Enter to choose the focused item.' -Color Gray
::         Write-BoxLine -Content 'Keys: Up/Down move | Enter select | Esc back' -Color DarkGray
::         Write-BoxLine -Content ("Items: {0} | Selected: {1}/{2} | Showing: {3}-{4}" -f $Items.Count, ($index + 1), $Items.Count, ($viewport.Start + 1), ($viewport.End + 1)) -Color DarkGray
::         Write-UiBorderLine -Color DarkGray
::
::         $key = [Console]::ReadKey($true)
::         switch ($key.Key) {
::             'UpArrow' { $index = ($index - 1 + $Items.Count) % $Items.Count }
::             'DownArrow' { $index = ($index + 1) % $Items.Count }
::             'Enter' { return $Items[$index] }
::             'Escape' { return $null }
::         }
::     }
:: }
::
:: function Prompt-PowerShell7Choice {
::     param([bool]$Installed)
::
::     $selection = Read-Menu -Title 'First Install' -Subtitle (
::         if ($Installed) {
::             'PowerShell 7 is already installed. Reinstall or repair it now?'
::         } else {
::             'Would you like SYTA to install PowerShell 7 too?'
::         }
::     ) -Items @(
::         [pscustomobject]@{
::             Title = 'Skip PowerShell 7 for now'
::             Subtitle = 'Continue without changing the Windows Terminal default profile.'
::             Accent = 'DarkGray'
::             Key = 'skip'
::         }
::         [pscustomobject]@{
::             Title = if ($Installed) { 'Reinstall or repair PowerShell 7' } else { 'Install PowerShell 7 now' }
::             Subtitle = 'Install via winget and set Windows Terminal default profile to PowerShell.'
::             Accent = 'Yellow'
::             Key = 'install'
::         }
::     )
::
::     return ($selection -and $selection.Key -eq 'install')
:: }
::
:: function Prompt-LauncherUpdateChoice {
::     param([Parameter(Mandatory = $true)]$Update)
::
::     $selection = Read-Menu -Title 'Launcher Update Available' -Subtitle "SYTA $($Update.LatestTag) is available. Current version: $($Update.CurrentTag)." -Items @(
::         [pscustomobject]@{ Title = 'Update now'; Subtitle = 'Download the latest portable batch and replace the current launcher.'; Accent = 'Green'; Key = 'update' }
::         [pscustomobject]@{ Title = 'Later'; Subtitle = 'Keep using this version and check again later.'; Accent = 'Yellow'; Key = 'later' }
::         [pscustomobject]@{ Title = 'Skip this version'; Subtitle = "Do not prompt again for $($Update.LatestTag)."; Accent = 'DarkGray'; Key = 'skip' }
::     )
::
::     if (-not $selection) {
::         return 'later'
::     }
::
::     return $selection.Key
:: }
::
:: function Show-ExplanationPanel {
::     param(
::         [Parameter(Mandatory = $true)][string]$Title,
::         [Parameter(Mandatory = $true)][string[]]$Lines
::     )
::
::     Clear-Host
::     Write-Banner -Tagline $Title -Hint 'Back'
::     Write-UiBorderLine -Color DarkGray
::     foreach ($line in $Lines) {
::         Write-WrappedBoxText -Content $line -Color Cyan
::     }
::     Write-UiBorderLine -Color DarkGray
::     Write-BoxLine -Content 'Press any key to return.' -Color Gray
::     Write-UiBorderLine -Color DarkGray
::     [void][Console]::ReadKey($true)
:: }
::
:: function Launch-ExplanationsMode {
::     while ($true) {
::         $selection = Read-Menu -Title 'Explanations' -Subtitle 'Learn what the tools are, what they are good for, and what SYTA recommends.' -Items @(
::             [pscustomobject]@{ Title = 'Beginner guide | simple'; Subtitle = 'Very simple explanation of each tool and the easiest place to start.'; Accent = 'Cyan'; Key = 'beginner' }
::             [pscustomobject]@{ Title = 'Advanced guide | more detail'; Subtitle = 'More detail about the differences between the tools and when to pick each one.'; Accent = 'Yellow'; Key = 'advanced' }
::             [pscustomobject]@{ Title = 'What should I install? | short answer'; Subtitle = 'Direct recommendation if you just want the short answer.'; Accent = 'Green'; Key = 'recommend' }
::             [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the main menu.'; Accent = 'DarkGray'; Key = 'back' }
::         )
::
::         if (-not $selection -or $selection.Key -eq 'back') {
::             return
::         }
::
::         switch ($selection.Key) {
::             'beginner' {
::                 Show-ExplanationPanel -Title 'Beginner guide' -Lines @(
::                     'Codex is a strong all-around coding assistant from OpenAI.',
::                     'OMX is Codex with extra automation and more structure. It is usually for people who want a heavier setup.',
::                     'OpenCode is often the easiest and lightest place to begin.',
::                     'Claude Code and Gemini CLI are mostly worth it if you already use those services.',
::                     'If you are new, the easiest path is Install -> First install, then start with OpenCode or Codex.',
::                     'The Oh My tools are add-ons. They are optional extras, not the best first step for most beginners.'
::                 )
::             }
::             'advanced' {
::                 Show-ExplanationPanel -Title 'Advanced guide' -Lines @(
::                     'Codex is the direct OpenAI tool. Choose it if you want something solid without too many extra layers.',
::                     'OMX adds extra automation, planning helpers, and more guided workflows on top of Codex.',
::                     'OpenCode is lighter and faster to get moving with, but it gives you less built-in structure.',
::                     'Install only the tools you really plan to use. More tools means more logins, more updates, and more overlap.',
::                     'Oh My OpenAgent and Oh My OpenCode Slim are optional add-ons around OpenCode, not required for the basic setup.'
::                 )
::             }
::             'recommend' {
::                 Show-ExplanationPanel -Title 'What should I install?' -Lines @(
::                     'New Windows machine: use Install -> First install.',
::                     'If you want the simplest start, choose OpenCode first.',
::                     'If you want the OpenAI path, choose Codex first. Add OMX later only if you want more automation.',
::                     'Add the Oh My tools only after the base setup works and only if you understand why you want them.',
::                     'Skip any tool you do not have a subscription for, do not understand yet, or do not expect to use.'
::                 )
::             }
::         }
::     }
:: }
::
:: function Launch-UpdateMenu {
::     $items = @(
::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Claude Code, Gemini CLI.'; Accent = 'Green'; Key = 'UpdateLight' }
::         [pscustomobject]@{ Title = 'Update all'; Subtitle = 'Run the broader toolchain update pass, including system package managers.'; Accent = 'Yellow'; Key = 'UpdateAll' }
::         [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the main menu.'; Accent = 'DarkGray'; Key = 'back' }
::     )
::
::     if ($DryRun) {
::         return [pscustomobject]@{
::             Title = 'Update'
::             Subtitle = 'Run a lighter AI-tools-only update or the broader full maintenance pass.'
::             Items = $items
::         }
::     }
::
::     $selection = Read-Menu -Title 'Update' -Subtitle 'Run a lighter AI-tools-only update or the broader full maintenance pass.' -Items $items
::
::     if (-not $selection -or $selection.Key -eq 'back') {
::         return
::     }
::
::     switch ($selection.Key) {
::         'UpdateLight' { Launch-UpdateLightMode }
::         'UpdateAll' { Launch-UpdateMode }
::     }
:: }
::
:: function Start-LauncherSelfUpdate {
::     param([Parameter(Mandatory = $true)]$Update)
::
::     $helperPath = Join-Path $script:ScriptDir 'syta-self-update.ps1'
::     $escapedPath = $Update.LauncherPath.Replace("'", "''")
::     $escapedUrl = $Update.AssetUrl.Replace("'", "''")
::     $escapedTag = $Update.LatestTag.Replace("'", "''")
::     $digestValue = if ($null -ne $Update.Digest) { "$($Update.Digest)" } else { '' }
::     $escapedDigest = $digestValue.Replace("'", "''")
::     $command = "& '$helperPath' -TargetPath '$escapedPath' -DownloadUrl '$escapedUrl' -ReleaseTag '$escapedTag' -ExpectedDigest '$escapedDigest'"
::     return Open-WindowsPowerShellWindow -Title 'SYTA Self Update' -Command $command -UseWindowsTerminal:$false
:: }
::
:: function HandleLauncherUpdatePrompt {
::     if ($Mode -or $DryRun -or $SmokeTest) {
::         return $false
::     }
::
::     $update = Get-AvailableLauncherUpdate
::     if (-not $update) {
::         return $false
::     }
::
::     $choice = Prompt-LauncherUpdateChoice -Update $update
::     switch ($choice) {
::         'update' {
::             $null = Start-LauncherSelfUpdate -Update $update
::             return $true
::         }
::         'skip' {
::             Update-StateFields @{ dismissedReleaseTag = $update.LatestTag } | Out-Null
::             return $false
::         }
::         default {
::             return $false
::         }
::     }
:: }
::
:: function Get-ProjectDirectories {
::     Get-ChildItem -LiteralPath $script:ProjectsRoot -Directory -ErrorAction SilentlyContinue |
::         Where-Object { $_.Name -ne 'discussion' -and $_.Name -ne '.omx' } |
::         Sort-Object Name
:: }
::
:: function Get-NormalizedSearchText {
::     param([AllowNull()][string]$Value)
::
::     if ([string]::IsNullOrWhiteSpace($Value)) {
::         return ''
::     }
::
::     return (($Value.ToLowerInvariant()) -replace '[^a-z0-9]+', ' ').Trim()
:: }
::
:: function Get-CompactSearchText {
::     param([AllowNull()][string]$Value)
::
::     $normalized = Get-NormalizedSearchText -Value $Value
::     if (-not $normalized) {
::         return ''
::     }
::
::     return ($normalized -replace '\s+', '')
:: }
::
:: function Get-SearchTokens {
::     param([AllowNull()][string]$Value)
::
::     $normalized = Get-NormalizedSearchText -Value $Value
::     if (-not $normalized) {
::         return @()
::     }
::
::     return @($normalized -split '\s+' | Where-Object { $_ })
:: }
::
:: function Test-CompactSubsequence {
::     param(
::         [string]$Needle,
::         [string]$Haystack
::     )
::
::     if (-not $Needle -or -not $Haystack) {
::         return $false
::     }
::
::     $index = 0
::     foreach ($char in $Haystack.ToCharArray()) {
::         if ($char -eq $Needle[$index]) {
::             $index++
::             if ($index -ge $Needle.Length) {
::                 return $true
::             }
::         }
::     }
::
::     return $false
:: }
::
:: function Get-ProjectSearchScore {
::     param(
::         [Parameter(Mandatory = $true)][string]$Name,
::         [Parameter(Mandatory = $true)][string]$Query,
::         [switch]$IsRecent
::     )
::
::     $compactName = Get-CompactSearchText -Value $Name
::     $compactQuery = Get-CompactSearchText -Value $Query
::     if (-not $compactName -or -not $compactQuery) {
::         return $null
::     }
::
::     $normalizedName = Get-NormalizedSearchText -Value $Name
::     $normalizedQuery = Get-NormalizedSearchText -Value $Query
::     $tokens = @(Get-SearchTokens -Value $Query)
::     $score = 0
::
::     if ($compactName -eq $compactQuery) {
::         $score += 500
::     } elseif ($normalizedName -eq $normalizedQuery) {
::         $score += 460
::     } elseif ($compactName.StartsWith($compactQuery)) {
::         $score += 380
::     } elseif ($normalizedName.StartsWith($normalizedQuery)) {
::         $score += 340
::     } elseif ($compactName.Contains($compactQuery)) {
::         $score += 280
::     } elseif ($normalizedName.Contains($normalizedQuery)) {
::         $score += 240
::     }
::
::     $matchedTokens = 0
::     foreach ($token in $tokens) {
::         if ($compactName.StartsWith($token) -or $normalizedName -match ("(^|\s){0}" -f [regex]::Escape($token))) {
::             $score += 60
::             $matchedTokens++
::             continue
::         }
::
::         if ($compactName.Contains($token) -or $normalizedName.Contains($token)) {
::             $score += 35
::             $matchedTokens++
::         }
::     }
::
::     if ($tokens.Count -gt 0 -and $matchedTokens -eq $tokens.Count) {
::         $score += 40
::     }
::
::     if ($score -eq 0 -and (Test-CompactSubsequence -Needle $compactQuery -Haystack $compactName)) {
::         $score = 120
::     }
::
::     if ($score -eq 0) {
::         return $null
::     }
::
::     if ($IsRecent) {
::         $score += 15
::     }
::
::     return $score
:: }
::
:: function Find-ProjectsBySearchQuery {
::     param(
::         [Parameter(Mandatory = $true)][array]$Projects,
::         [Parameter(Mandatory = $true)][string]$Query
::     )
::
::     return @(
::         $Projects |
::             ForEach-Object {
::                 $score = Get-ProjectSearchScore -Name $_.Name -Query $Query -IsRecent:([bool]($_.PSObject.Properties.Match('IsRecent').Count -and $_.IsRecent))
::                 if ($null -ne $score) {
::                     [pscustomobject]@{
::                         Score = $score
::                         Project = $_
::                     }
::                 }
::             } |
::             Sort-Object @{ Expression = 'Score'; Descending = $true }, @{ Expression = { $_.Project.Name.ToLowerInvariant() }; Descending = $false } |
::             ForEach-Object { $_.Project }
::     )
:: }
::
:: function Prompt-NewProject {
::     while ($true) {
::         Clear-Host
::         Write-Banner -Tagline 'Create New Project' -Hint 'Leave blank to cancel'
::         Write-UiBorderLine -Color DarkGray
::         Write-BoxLine -Content "Folder root: $script:ProjectsRoot" -Color DarkGray
::         Write-BoxLine -Content 'Choose a short Windows-safe folder name.' -Color Gray
::         Write-UiBorderLine -Color DarkGray
::         Write-Host ''
::         $name = Read-Host (Localize-Text '   Project name')
::         if ([string]::IsNullOrWhiteSpace($name)) {
::             return $null
::         }
::
::         $trimmed = $name.Trim()
::         $invalid = [IO.Path]::GetInvalidFileNameChars() | Where-Object { $trimmed.Contains($_) }
::         if ($invalid.Count -gt 0) {
::             Show-InfoBox -Title 'Invalid project name' -Lines @('Avoid characters Windows cannot use in folder names.') -Accent Red -Hint 'Try another name'
::             Start-Sleep -Milliseconds 1000
::             continue
::         }
::
::         return [pscustomobject]@{
::             Title = $trimmed
::             Subtitle = "Project folder at $script:ProjectsRoot"
::             Accent = 'Cyan'
::             Name = $trimmed
::             Existing = Test-Path -LiteralPath (Join-Path $script:ProjectsRoot $trimmed)
::         }
::     }
:: }
::
:: function Select-ProjectList {
::     param(
::         [Parameter(Mandatory = $true)][array]$Projects,
::         [Parameter(Mandatory = $true)][string]$Title,
::         [Parameter(Mandatory = $true)][string]$Subtitle
::     )
::
::     $selection = Read-Menu -Title $Title -Subtitle $Subtitle -Items ($Projects + @(
::         [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the previous menu.'; Accent = 'DarkGray'; Key = 'back' }
::     ))
::
::     if (-not $selection -or ($selection.PSObject.Properties.Match('Key').Count -and $selection.Key -eq 'back')) {
::         return $null
::     }
::
::     return $selection
:: }
::
:: function Select-Project {
::     if ($ProjectName) {
::         return [pscustomobject]@{
::             Name = $ProjectName.Trim()
::             Existing = Test-Path -LiteralPath (Join-Path $script:ProjectsRoot $ProjectName.Trim())
::         }
::     }
::
::     Show-LoadProgress -Title 'Project Selector' -Status 'Loading recent projects' -Current 1 -Total 2 -Accent Cyan
::     $recent = @(Get-RecentProjects)
::     $recentLookup = @{}
::     foreach ($item in $recent) {
::         $recentLookup[$item.Name] = $true
::     }
::     Show-LoadProgress -Title 'Project Selector' -Status 'Scanning project folders' -Current 2 -Total 2 -Accent White
::     $existing = @(Get-ProjectDirectories | ForEach-Object {
::         $isRecent = $recentLookup.ContainsKey($_.Name)
::         [pscustomobject]@{
::             Title = $_.Name
::             Subtitle = if ($isRecent) { "Recent project folder in $script:ProjectsRoot" } else { "Project folder in $script:ProjectsRoot" }
::             Accent = if ($isRecent) { 'Cyan' } else { 'White' }
::             Name = $_.Name
::             Existing = $true
::             IsRecent = $isRecent
::         }
::     })
::
::     if ($existing.Count -eq 0 -and $recent.Count -eq 0) {
::         return Prompt-NewProject
::     }
::
::     $actions = @()
::     if ($recent.Count -gt 0) {
::         $actions += [pscustomobject]@{ Title = 'Recent projects'; Subtitle = "Jump into one of $($recent.Count) recently used project(s)."; Accent = 'Cyan'; Key = 'recent' }
::     }
::     if ($existing.Count -gt 0) {
::         $actions += [pscustomobject]@{ Title = 'Open existing project'; Subtitle = "Browse $($existing.Count) existing project folder(s)."; Accent = 'White'; Key = 'existing' }
::         $actions += [pscustomobject]@{ Title = 'Search projects'; Subtitle = 'Filter existing projects by a search term.'; Accent = 'White'; Key = 'search' }
::     }
::     $actions += [pscustomobject]@{ Title = 'Create new project'; Subtitle = 'Type a fresh project name and create its folder.'; Accent = 'Green'; Key = 'new' }
::     $actions += [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the previous menu.'; Accent = 'DarkGray'; Key = 'back' }
::
::     $action = Read-Menu -Title 'Project Selector' -Subtitle "Choose how to work inside $script:ProjectsRoot." -Items $actions
::     if (-not $action -or $action.Key -eq 'back') {
::         return $null
::     }
::
::     switch ($action.Key) {
::         'new' { return Prompt-NewProject }
::         'recent' { return Select-ProjectList -Projects $recent -Title 'Recent Projects' -Subtitle 'Choose a recently used project folder.' }
::         'existing' { return Select-ProjectList -Projects $existing -Title 'Existing Projects' -Subtitle 'Choose a project folder to open.' }
::         'search' {
::             while ($true) {
::                 Clear-Host
::                 Write-Banner -Tagline 'Search Projects' -Hint 'Leave blank to cancel'
::                 Write-UiBorderLine -Color DarkGray
::                 Write-BoxLine -Content 'Search scans existing folders under C:\.CODEX.' -Color Gray
::                 Write-BoxLine -Content 'Search is case-insensitive and matches partial words.' -Color DarkGray
::                 Write-UiBorderLine -Color DarkGray
::                 Write-Host ''
::                 $query = Read-Host (Localize-Text '   Search term')
::                 if ([string]::IsNullOrWhiteSpace($query)) {
::                     return $null
::                 }
::
::                 $matches = @(Find-ProjectsBySearchQuery -Projects $existing -Query $query)
::                 if ($matches.Count -eq 0) {
::                     Show-InfoBox -Title 'No project matches' -Lines @("No existing project matched '$query'.") -Accent Red -Hint 'Try another search'
::                     Start-Sleep -Milliseconds 1000
::                     continue
::                 }
::
::                 return Select-ProjectList -Projects $matches -Title 'Search Results' -Subtitle "Projects matching '$query'."
::             }
::         }
::     }
::
::     return $null
:: }
::
:: function Select-Agent {
::     if ($Agent) {
::         return ($script:AgentOptions | Where-Object Key -eq $Agent | Select-Object -First 1)
::     }
::
::     $items = Get-AgentMenuItems
::     return Read-Menu -Title 'Agent Selector' -Subtitle 'Choose the tool to launch in the project workspace.' -Items $items
:: }
::
:: function Ensure-ProjectDirectory {
::     param([Parameter(Mandatory = $true)][string]$Name)
::
::     $path = Join-Path $script:ProjectsRoot $Name
::     if (-not (Test-Path -LiteralPath $path)) {
::         $null = New-Item -ItemType Directory -Path $path -Force
::     }
::     return [System.IO.Path]::GetFullPath($path)
:: }
::
:: function Open-WslWindow {
::     param(
::         [Parameter(Mandatory = $true)][string]$Title,
::         [Parameter(Mandatory = $true)][string]$WindowsDirectory,
::         [Parameter(Mandatory = $true)][string]$WindowsScriptPath,
::         [string[]]$ScriptArguments = @()
::     )
::
::     $wslDir = Get-WslPath -WindowsPath $WindowsDirectory
::     $wslScript = Get-WslPath -WindowsPath $WindowsScriptPath
::     $distro = Get-PreferredWslDistro
::     $wslArgs = @()
::     if ($distro) {
::         $wslArgs += @('-d', $distro)
::     }
::     $wslArgs += @('--cd', $wslDir, '--exec', 'bash', $wslScript) + $ScriptArguments
::     $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
::
::     if ($DryRun) {
::         return [pscustomobject]@{
::             Title = $Title
::             WindowsDirectory = $WindowsDirectory
::             Script = $WindowsScriptPath
::             WslDirectory = $wslDir
::             WslScript = $wslScript
::             Arguments = $wslArgs
::             UsesWindowsTerminal = [bool]$wt
::         }
::     }
::
::     if ($wt) {
::         $wtArgs = @('new-tab', '--title', $Title, '--startingDirectory', $WindowsDirectory, 'wsl.exe') + $wslArgs
::         & $wt.Source @wtArgs | Out-Null
::         return
::     }
::
::     Start-Process -FilePath 'wsl.exe' -ArgumentList $wslArgs | Out-Null
:: }
::
:: function Get-InstallItems {
::     $distroInstalled = Test-WslUserDistroInstalled
::     $distroReady = Test-WslPreferredDistroReadyForCli
::     $pwshInfo = Get-PwshInfo
::     if ($distroReady) {
::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim')
::         $codexDiag = Get-ToolDiagnostics -Key 'codex'
::         $omxDiag = Get-ToolDiagnostics -Key 'omx'
::         $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'
::         $claudeDiag = Get-ToolDiagnostics -Key 'claude-code'
::         $geminiDiag = Get-ToolDiagnostics -Key 'gemini-cli'
::         $droidDiag = Get-ToolDiagnostics -Key 'droid-cli'
::         $omaDiag = Get-ToolDiagnostics -Key 'oh-my-openagent'
::         $omoDiag = Get-ToolDiagnostics -Key 'oh-my-opencode-slim'
::     } else {
::         $setupIncomplete = $distroInstalled
::         $codexDiag = New-WslMissingToolDiagnostics -Key 'codex' -SetupIncomplete:$setupIncomplete
::         $omxDiag = New-WslMissingToolDiagnostics -Key 'omx' -SetupIncomplete:$setupIncomplete
::         $opencodeDiag = New-WslMissingToolDiagnostics -Key 'opencode' -SetupIncomplete:$setupIncomplete
::         $claudeDiag = New-WslMissingToolDiagnostics -Key 'claude-code' -SetupIncomplete:$setupIncomplete
::         $geminiDiag = New-WslMissingToolDiagnostics -Key 'gemini-cli' -SetupIncomplete:$setupIncomplete
::         $droidDiag = New-WslMissingToolDiagnostics -Key 'droid-cli' -SetupIncomplete:$setupIncomplete
::         $omaDiag = New-WslMissingToolDiagnostics -Key 'oh-my-openagent' -SetupIncomplete:$setupIncomplete
::         $omoDiag = New-WslMissingToolDiagnostics -Key 'oh-my-opencode-slim' -SetupIncomplete:$setupIncomplete
::     }
::
::     return @(
::         [pscustomobject]@{
::             Title = 'First install | recommended'
::             Subtitle = 'Best beginner path for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.'
::             Accent = if ($distroReady -and $pwshInfo.Installed) { 'Green' } else { 'Yellow' }
::             Key = 'first-install'
::         }
::         [pscustomobject]@{
::             Title = 'WSL Ubuntu | system setup'
::             Subtitle = if ($distroReady) { "Installed | ready | distros: $(@(Get-WslUserDistros).Count)" } elseif ($distroInstalled) { "Installed | finish Ubuntu first launch | distros: $(@(Get-WslUserDistros).Count)" } else { 'Missing | runs wsl --install -d Ubuntu' }
::             Accent = if ($distroReady) { 'Green' } elseif ($distroInstalled) { 'Yellow' } else { 'Yellow' }
::             Key = 'wsl-ubuntu'
::         }
::         [pscustomobject]@{ Title = 'PowerShell 7 | optional'; Subtitle = $pwshInfo.MenuText; Accent = if ($pwshInfo.Installed) { 'Green' } else { 'Yellow' }; Key = 'powershell-7' }
::         [pscustomobject]@{ Title = 'Install core AI CLI tools | simple'; Subtitle = if ($distroReady) { 'Run Codex, OpenCode, Claude Code, and Gemini CLI in one pass.' } elseif ($distroInstalled) { 'WSL Linux setup incomplete | launch Ubuntu once first.' } else { 'WSL Linux distro missing | install Ubuntu first.' }; Accent = if ($distroReady) { 'Green' } else { 'Yellow' }; Key = 'all-ai-cli-tools' }
::         [pscustomobject]@{ Title = 'Cleaner helper | maintenance'; Subtitle = if ($distroReady) { 'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.' } elseif ($distroInstalled) { 'WSL Linux setup incomplete | launch Ubuntu once first.' } else { 'WSL Linux distro missing | install Ubuntu first.' }; Accent = if ($distroReady) { 'Cyan' } else { 'Yellow' }; Key = 'cleaner-helper' }
::         [pscustomobject]@{ Title = 'Reset tool configs | maintenance'; Subtitle = if ($distroReady) { 'Review tracked config/auth paths and remove only the ones you confirm.' } elseif ($distroInstalled) { 'WSL Linux setup incomplete | launch Ubuntu once first.' } else { 'WSL Linux distro missing | install Ubuntu first.' }; Accent = 'Yellow'; Key = 'reset-tool-configs' }
::         [pscustomobject]@{ Title = 'Codex CLI | guided'; Subtitle = $codexDiag.MenuText; Accent = if ($codexDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'codex' }
::         [pscustomobject]@{ Title = 'OpenCode | simple'; Subtitle = $opencodeDiag.MenuText; Accent = if ($opencodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'opencode' }
::         [pscustomobject]@{ Title = 'Oh My OpenAgent | advanced optional'; Subtitle = $omaDiag.MenuText; Accent = if ($omaDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Yellow' }; Key = 'oh-my-openagent' }
::         [pscustomobject]@{ Title = 'Oh My Codex / OMX | advanced optional'; Subtitle = $omxDiag.MenuText; Accent = if ($omxDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omx' }
::         [pscustomobject]@{ Title = 'Claude Code | optional'; Subtitle = $claudeDiag.MenuText; Accent = if ($claudeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'claude-code' }
::         [pscustomobject]@{ Title = 'Gemini CLI | optional'; Subtitle = $geminiDiag.MenuText; Accent = if ($geminiDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'gemini-cli' }
::         [pscustomobject]@{ Title = 'DROID CLI | optional'; Subtitle = $droidDiag.MenuText; Accent = if ($droidDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'droid-cli' }
::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim | optional'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.InstallText -ne (Localize-Text 'Missing')) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim' }
::         [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the main menu.'; Accent = 'DarkGray'; Key = 'back' }
::     )
:: }
::
:: function Get-CodingCliSummaryLines {
::     $items = @(
::         [pscustomobject]@{ Label = 'Codex'; Key = 'codex' }
::         [pscustomobject]@{ Label = 'OpenCode'; Key = 'opencode' }
::         [pscustomobject]@{ Label = 'Claude'; Key = 'claude-code' }
::         [pscustomobject]@{ Label = 'Gemini'; Key = 'gemini-cli' }
::     )
::
::     return @($items | ForEach-Object {
::         $diag = Get-ToolDiagnostics -Key $_.Key
::         ('{0,-8}: {1}; {2}; {3}' -f $_.Label, $diag.InstallText, $diag.VersionText, $diag.AuthText)
::     })
:: }
::
:: function Get-ResetConfigItems {
::     return @(
::         [pscustomobject]@{ Title = 'Codex / OMX configs'; Subtitle = 'Remove tracked Codex and OMX auth/config files.'; Accent = 'Cyan'; Key = 'codex-omx' }
::         [pscustomobject]@{ Title = 'OpenCode configs'; Subtitle = 'Remove tracked OpenCode base config files.'; Accent = 'Green'; Key = 'opencode' }
::         [pscustomobject]@{ Title = 'Oh My OpenAgent configs'; Subtitle = 'Remove tracked Oh My OpenAgent compatibility config files.'; Accent = 'Yellow'; Key = 'oh-my-openagent' }
::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim configs'; Subtitle = 'Remove tracked Oh My OpenCode Slim config files.'; Accent = 'White'; Key = 'oh-my-opencode-slim' }
::         [pscustomobject]@{ Title = 'Claude Code configs'; Subtitle = 'Remove tracked Claude Code config files.'; Accent = 'Magenta'; Key = 'claude-code' }
::         [pscustomobject]@{ Title = 'Gemini CLI configs'; Subtitle = 'Remove tracked Gemini and Google AI config folders.'; Accent = 'Blue'; Key = 'gemini-cli' }
::         [pscustomobject]@{ Title = 'All tracked configs'; Subtitle = 'Remove every tracked config/auth path shown by SYTA.'; Accent = 'Red'; Key = 'all' }
::         [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the previous menu.'; Accent = 'DarkGray'; Key = 'back' }
::     )
:: }
::
:: function Get-ResetConfigSelectionLabel {
::     param([Parameter(Mandatory = $true)][string]$Key)
::
::     $match = Get-ResetConfigItems | Where-Object Key -eq $Key | Select-Object -First 1
::     if ($match) {
::         return $match.Title
::     }
::
::     return $Key
:: }
::
:: function Select-ResetConfigTarget {
::     if ($ResetTarget) {
::         return $ResetTarget
::     }
::
::     if ($DryRun) {
::         return 'all'
::     }
::
::     $selection = Read-Menu -Title 'Reset tool configs' -Subtitle 'Choose which tool configs to reset.' -Items (Get-ResetConfigItems)
::     if (-not $selection -or $selection.Key -eq 'back') {
::         return $null
::     }
::
::     return $selection.Key
:: }
::
:: function Invoke-WslUbuntuInstallFlow {
::     Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell window opens immediately after this screen' -Lines @(
::         'Target  : WSL Ubuntu',
::         'Action  : Run wsl --install -d Ubuntu',
::         'Impact  : Installs Ubuntu into Windows Subsystem for Linux'
::     )
::     $scriptPath = Join-Path $script:ScriptDir 'syta-install-wsl-ubuntu.ps1'
::     $result = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA WSL Ubuntu Install') -Command ("& '$scriptPath'") -UseWindowsTerminal:$false
::     if ($DryRun) {
::         return $result
::     }
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
::     return $null
:: }
::
:: function Invoke-PowerShell7InstallFlow {
::     $pwshInfo = Get-PwshInfo
::     $pwshStatus = if ($pwshInfo.Installed) { 'Installed' } else { 'Missing' }
::     Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell window opens immediately after this screen' -Lines @(
::         'Target  : PowerShell 7',
::         "Current : $pwshStatus",
::         "Version : $($pwshInfo.Version)",
::         'Action  : Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell'
::     )
::     $scriptPath = Join-Path $script:ScriptDir 'syta-install-powershell7.ps1'
::     $result = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA PowerShell 7 Install') -Command ("& '$scriptPath'") -UseWindowsTerminal:$false
::     if ($DryRun) {
::         return $result
::     }
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
::     return $null
:: }
::
:: function Invoke-AllAiCliInstallFlow {
::     Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines (@(
::         'Target  : Install core AI CLI tools',
::         'Scope   : Codex, OpenCode, Claude Code, Gemini CLI'
::     ) + (Get-CodingCliSummaryLines))
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Install - Core AI CLI Tools') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('install', 'all-ai-cli-tools', $script:Language)
::
::     if ($DryRun) {
::         return $result
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
::     return $null
:: }
::
:: function Invoke-CleanerHelperFlow {
::     Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::         'Target  : Cleaner helper',
::         'Action  : Scan stale AI CLI installs and ask before removing old npm globals',
::         'Scope   : Older nvm Node versions, duplicate PATH entries, user-scoped npm installs'
::     )
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Install - Cleaner Helper') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('install', 'cleaner-helper', $script:Language)
::
::     if ($DryRun) {
::         return $result
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
::     return $null
:: }
::
:: function Invoke-ResetToolConfigsFlow {
::     $selection = Select-ResetConfigTarget
::     if (-not $selection) {
::         return $null
::     }
::
::     $selectionLabel = Get-ResetConfigSelectionLabel -Key $selection
::     Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::         'Target  : Reset tool configs',
::         'Action  : Review tracked config/auth paths and confirm which ones to remove',
::         'Scope   : Selected tracked config/auth paths, or all tracked config/auth paths',
::         ("Selection : {0}" -f $selectionLabel)
::     )
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Install - Config Reset Helper') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('install', 'reset-tool-configs', $script:Language, $selection)
::
::     if ($DryRun) {
::         $result | Add-Member -NotePropertyName ResetTarget -NotePropertyValue $selection
::         $result | Add-Member -NotePropertyName ResetTargetLabel -NotePropertyValue $selectionLabel
::         return $result
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
::     return $null
:: }
::
:: function Invoke-FirstInstallFlow {
::     $distroInstalled = Test-WslUserDistroInstalled
::     $distroReady = Test-WslPreferredDistroReadyForCli
::     $pwshInfo = Get-PwshInfo
::     $wslLine = if ($distroReady) { 'WSL     : Linux distro ready for CLI installs' } elseif ($distroInstalled) { 'WSL     : Ubuntu is installed but first Linux-user setup is still required' } else { 'WSL     : Will run wsl --install -d Ubuntu' }
::     $powerLine = if ($pwshInfo.Installed) { 'Power   : PowerShell 7 already installed; SYTA can repair it if needed' } else { 'Power   : SYTA will ask whether to install PowerShell 7' }
::
::     $cliLine = if ($distroReady) { 'CLI     : Ready to launch the core AI CLI tools now' } else { 'CLI     : Install the core AI CLI tools once a Linux distro is ready' }
::     $lines = @(
::         'Target  : First install',
::         $wslLine,
::         $powerLine,
::         $cliLine,
::         'Note    : Recommended path for a new machine or first SYTA setup',
::         'Note    : Oh My Codex / OMX and the Oh My OpenCode variants stay optional installs'
::     )
::     if (-not $distroReady) {
::         $lines += 'Note    : Ubuntu setup may require a reboot or first-run Linux account creation before CLI installs can continue'
::         if ($distroInstalled) {
::             $lines += 'Note    : Launch Ubuntu once and finish Linux user creation before installing CLI tools'
::         }
::     }
::
::     Show-InfoBox -Title 'First Install' -Accent Yellow -Hint 'SYTA keeps this selector open while new tabs launch' -Lines $lines
::
::     $result = [ordered]@{
::         WslInstall = $null
::         PowerShellInstall = $null
::         CliInstall = $null
::         RequiresRerunAfterUbuntuSetup = -not $distroReady
::     }
::
::     if ($DryRun) {
::         $scriptPath = Join-Path $script:ScriptDir 'syta-install-powershell7.ps1'
::         if (-not $distroReady) {
::             $result.WslInstall = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA WSL Ubuntu Install') -Command 'wsl --install -d Ubuntu'
::         }
::
::         $result.PowerShellPrompt = if ($pwshInfo.Installed) {
::             'would-ask-repair-or-skip'
::         } else {
::             'would-ask-install-or-skip'
::         }
::         $result.PowerShellInstall = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA PowerShell 7 Install') -Command ("& '$scriptPath'") -UseWindowsTerminal:$false
::
::         if ($distroReady) {
::             $result.CliInstall = Open-WslWindow `
::                 -Title (Localize-Text 'SYTA Install - Core AI CLI Tools') `
::                 -WindowsDirectory $script:ScriptDir `
::                 -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::                 -ScriptArguments @('install', 'all-ai-cli-tools', $script:Language)
::         }
::
::         return [pscustomobject]$result
::     }
::
::     if (-not $distroReady -and -not $distroInstalled) {
::         $result.WslInstall = Invoke-WslUbuntuInstallFlow
::     }
::
::     if (Prompt-PowerShell7Choice -Installed $pwshInfo.Installed) {
::         $result.PowerShellInstall = Invoke-PowerShell7InstallFlow
::     }
::
::     if (-not $distroReady) {
::         Show-InfoBox -Title 'Continue later' -Accent Yellow -Hint 'Back' -Lines @(
::             $(if ($distroInstalled) { 'Ubuntu is installed, but its first Linux-user setup is not finished yet.' } else { 'Ubuntu setup was started in a separate PowerShell window.' }),
::             'After Ubuntu finishes installing, rerun First install to continue with the core AI CLI tools.',
::             'If Windows asks for a reboot, restart Windows first.',
::             'If Ubuntu asks you to create your Linux user, finish that step first.',
::             'You can also use Install core AI CLI tools later if Ubuntu is already ready.'
::         )
::         Start-Sleep -Milliseconds 1500
::         return
::     }
::
::     $result.CliInstall = Invoke-AllAiCliInstallFlow
:: }
:: function Launch-CodeMode {
::     $project = Select-Project
::     if (-not $project) {
::         return
::     }
::
::     $agent = Select-Agent
::     if (-not $agent) {
::         return
::     }
::
::     $projectDir = Ensure-ProjectDirectory -Name $project.Name
::     $diag = Get-ToolDiagnostics -Key $agent.Key -Refresh
::     Show-InfoBox -Title 'Launch Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::         "Project : $projectDir",
::         "Tool    : $($agent.Title)",
::         "Install : $($diag.InstallText)",
::         "Version : $($diag.VersionText)",
::         "Auth    : $($diag.AuthText)",
::         "Path    : $($diag.PathText)"
::     )
::
::     $result = Open-WslWindow `
::         -Title "$(Localize-Text $agent.WindowTitle) - $($project.Name)" `
::         -WindowsDirectory $projectDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('code', $agent.Key, $script:Language)
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Add-RecentProject -Name $project.Name
::     Start-Sleep -Milliseconds 500
:: }
::
:: function Launch-UpdateMode {
::     $lines = @(
::         'Scope   : APT, Homebrew, npm, pnpm, pipx, uv, rustup, dotnet',
::         "Folder  : $script:ScriptDir"
::     ) + (Get-CodingCliSummaryLines)
::     Show-InfoBox -Title 'Full Update Preflight' -Accent Yellow -Hint 'A new terminal tab opens immediately after this screen' -Lines $lines
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Updater') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('update', $script:Language)
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
:: }
::
:: function Launch-UpdateLightMode {
::     $lines = @(
::         'Scope   : Codex, OMX, OpenCode, Claude Code, Gemini CLI',
::         "Folder  : $script:ScriptDir"
::     ) + (Get-CodingCliSummaryLines)
::     Show-InfoBox -Title 'Light Update Preflight' -Accent Green -Hint 'A new terminal tab opens immediately after this screen' -Lines $lines
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Light Updater') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('update-light', $script:Language)
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
:: }
::
:: function Launch-InstallMode {
::     $selection = if ($InstallTarget) {
::         (Get-InstallItems | Where-Object Key -eq $InstallTarget | Select-Object -First 1)
::     } else {
::         try {
::             Show-LoadProgress -Title 'Installer' -Status 'Checking Windows prerequisites' -Current 1 -Total 2 -Accent Yellow
::             $distroInstalled = Test-WslUserDistroInstalled
::             $distroReady = Test-WslPreferredDistroReadyForCli
::             $null = Get-PwshInfo
::             if ($distroReady) {
::                 Show-LoadProgress -Title 'Installer' -Status 'Loading WSL tool diagnostics' -Current 2 -Total 2 -Accent Cyan
::             } elseif ($distroInstalled) {
::                 Show-LoadProgress -Title 'Installer' -Status 'Preparing install options' -Detail 'Ubuntu is installed, but its first Linux-user setup is not finished yet.' -Current 2 -Total 2 -Accent Yellow
::             } else {
::                 Show-LoadProgress -Title 'Installer' -Status 'Preparing install options' -Detail 'No WSL Linux distro is ready yet, so SYTA will show safe setup choices only.' -Current 2 -Total 2 -Accent Yellow
::             }
::             Read-Menu -Title 'Installer' -Subtitle 'Install or repair WSL Ubuntu and supported coding CLIs.' -Items (Get-InstallItems)
::         } catch {
::             Show-InfoBox -Title 'Installer' -Accent Yellow -Hint 'Back' -Lines @(
::                 'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.',
::                 'You can still install WSL Ubuntu or PowerShell 7 from here.',
::                 'You can still use First install from here for the guided beginner path.'
::             )
::             Read-Menu -Title 'Installer' -Subtitle 'Install or repair WSL Ubuntu and supported coding CLIs.' -Items @(
::                 [pscustomobject]@{ Title = 'First install (recommended)'; Subtitle = 'Best beginner path for WSL Ubuntu, optional PowerShell 7, and the core AI CLI tools.'; Accent = 'Yellow'; Key = 'first-install' }
::                 [pscustomobject]@{ Title = 'WSL Ubuntu'; Subtitle = 'Missing | runs wsl --install -d Ubuntu'; Accent = 'Yellow'; Key = 'wsl-ubuntu' }
::                 [pscustomobject]@{ Title = 'PowerShell 7'; Subtitle = 'Missing | install via winget and set as Windows Terminal default.'; Accent = 'Yellow'; Key = 'powershell-7' }
::                 [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the main menu.'; Accent = 'DarkGray'; Key = 'back' }
::             )
::         }
::     }
::     if (-not $selection -or $selection.Key -eq 'back') {
::         return
::     }
::
::     if ($selection.Key -eq 'first-install') {
::         $result = Invoke-FirstInstallFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     }
::
::     if ($selection.Key -eq 'wsl-ubuntu') {
::         $result = Invoke-WslUbuntuInstallFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     }
::
::     if ($selection.Key -eq 'powershell-7') {
::         $result = Invoke-PowerShell7InstallFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     }
::
::     $wslRequiredKeys = @('all-ai-cli-tools', 'cleaner-helper', 'reset-tool-configs', 'codex', 'opencode', 'omx', 'claude-code', 'gemini-cli', 'droid-cli', 'oh-my-openagent', 'oh-my-opencode-slim')
::     if ($wslRequiredKeys -contains $selection.Key -and -not (Test-WslPreferredDistroReadyForCli)) {
::         $distroInstalled = Test-WslUserDistroInstalled
::         $lines = if ($distroInstalled) {
::             @(
::                 'Ubuntu is installed, but its first Linux-user setup is not finished yet.',
::                 'Launch Ubuntu once and finish Linux user creation before installing CLI tools.',
::                 'After that, rerun First install or this install action.'
::             )
::         } else {
::             @(
::                 'WSL Ubuntu is not ready yet.',
::                 'Run First install or WSL Ubuntu first.',
::                 'Then come back here once Ubuntu setup is complete.'
::             )
::         }
::
::         if ($DryRun) {
::             [pscustomobject]@{
::                 Blocked = 'wsl-not-ready'
::                 Key = $selection.Key
::                 DistroInstalled = $distroInstalled
::                 DistroReady = $false
::                 Lines = $lines
::             } | ConvertTo-Json -Depth 4
::             return
::         }
::
::         Show-InfoBox -Title 'Continue later' -Accent Yellow -Hint 'Back' -Lines $lines
::         Start-Sleep -Milliseconds 1500
::         return
::     }
::
::     if ($selection.Key -eq 'all-ai-cli-tools') {
::         $result = Invoke-AllAiCliInstallFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     }
::
::     if ($selection.Key -eq 'cleaner-helper') {
::         $result = Invoke-CleanerHelperFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     }
::
::     if ($selection.Key -eq 'reset-tool-configs') {
::         $result = Invoke-ResetToolConfigsFlow
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         return
::     } elseif ($selection.Key -eq 'oh-my-openagent' -or $selection.Key -eq 'oh-my-opencode-slim') {
::         $diag = Get-ToolDiagnostics -Key $selection.Key -Refresh
::         $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'
::         $extraLines = if ($selection.Key -eq 'oh-my-openagent') {
::             @(
::                 'This is an OpenCode add-on, not a separate coding CLI.',
::                 'OpenCode should be installed first. SYTA will install it automatically if needed.',
::                 'Best if you already use OpenCode and want more helper features around it.'
::             )
::         } else {
::             @(
::                 'This is an OpenCode add-on, not a separate coding CLI.',
::                 'OpenCode should be installed first. SYTA will install it automatically if needed.',
::                 'Best if you want a lighter OpenCode add-on instead of the bigger OpenAgent setup.'
::             )
::         }
::
::         Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines (@(
::             "Target  : $($selection.Title)",
::             "Current : $($diag.InstallText)",
::             "Version : $($diag.VersionText)",
::             "Auth    : $($diag.AuthText)",
::             "Path    : $($diag.PathText)",
::             ("OpenCode : {0}" -f $opencodeDiag.InstallText)
::         ) + $extraLines)
::     } else {
::         $diag = Get-ToolDiagnostics -Key $selection.Key -Refresh
::         Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines @(
::             "Target  : $($selection.Title)",
::             "Current : $($diag.InstallText)",
::             "Version : $($diag.VersionText)",
::             "Auth    : $($diag.AuthText)",
::             "Path    : $($diag.PathText)"
::         )
::     }
::
::     $result = Open-WslWindow `
::         -Title "SYTA Install - $($selection.Title)" `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('install', $selection.Key, $script:Language)
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
::     Clear-ToolDiagnosticsCache
:: }
::
:: if ($SmokeTest) {
::     [pscustomobject]@{
::         ScriptDir = $script:ScriptDir
::         ProjectsRoot = $script:ProjectsRoot
::         StateFile = $script:StateFile
::         BuildId = $script:BuildId
::         ReleaseTag = $script:ReleaseTag
::         Language = $script:Language
::         RecentProjects = @((Get-RecentProjects | Select-Object -ExpandProperty Name))
::         Agents = $script:AgentOptions.Key
::         WslDistros = Get-WslDistros
::         WtPath = (Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
::         WslScript = Get-WslPath -WindowsPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh')
::         UpdateScript = Get-WslPath -WindowsPath (Join-Path $script:ScriptDir 'update-wsl-coding-tools.sh')
::     } | ConvertTo-Json -Depth 4
::     exit 0
:: }
::
:: Ensure-MaximizedWindow
:: Show-IntroAnimation
::
:: if (HandleLauncherUpdatePrompt) {
::     exit 0
:: }
::
:: if ($Mode -eq 'Code') {
::     Launch-CodeMode
::     exit 0
:: }
::
:: if ($Mode -eq 'Install') {
::     Launch-InstallMode
::     exit 0
:: }
::
:: if ($Mode -eq 'Explanations') {
::     Launch-ExplanationsMode
::     exit 0
:: }
::
:: if ($Mode -eq 'CleanerHelper') {
::     $result = Invoke-CleanerHelperFlow
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::     }
::     exit 0
:: }
::
:: if ($Mode -eq 'Update') {
::     $result = Launch-UpdateMenu
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::     }
::     exit 0
:: }
::
:: if ($Mode -eq 'UpdateLight') {
::     Launch-UpdateLightMode
::     exit 0
:: }
::
:: if ($Mode -eq 'UpdateAll') {
::     Launch-UpdateMode
::     exit 0
:: }
::
:: while ($true) {
::     $modeChoice = Read-Menu -Title 'Mode Selector' -Subtitle 'Choose what SYTA should do.' -Items @(
::         [pscustomobject]@{ Title = 'Code'; Subtitle = 'Launch an agent with project selection, diagnostics, and recent-project support.'; Accent = 'Cyan'; Key = 'Code' }
::         [pscustomobject]@{ Title = 'Install'; Subtitle = 'Install WSL Ubuntu or supported coding CLIs with preflight diagnostics.'; Accent = 'Green'; Key = 'Install' }
::         [pscustomobject]@{ Title = 'Explanations'; Subtitle = 'Learn what the tools are, what SYTA recommends, and how to choose a setup.'; Accent = 'Blue'; Key = 'Explanations' }
::         [pscustomobject]@{ Title = 'Cleaner helper'; Subtitle = 'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.'; Accent = 'Cyan'; Key = 'CleanerHelper' }
::         [pscustomobject]@{ Title = 'Update'; Subtitle = 'Choose which update lane to run.'; Accent = 'Yellow'; Key = 'Update' }
::         [pscustomobject]@{ Title = 'Exit'; Subtitle = 'Close the launcher.'; Accent = 'DarkGray'; Key = 'Exit' }
::     )
::
::     if (-not $modeChoice -or $modeChoice.Key -eq 'Exit') {
::         exit 0
::     }
::
::     switch ($modeChoice.Key) {
::         'Code' { Launch-CodeMode }
::         'Install' { Launch-InstallMode }
::         'Explanations' { Launch-ExplanationsMode }
::         'CleanerHelper' { Invoke-CleanerHelperFlow }
::         'Update' { Launch-UpdateMenu }
::     }
:: }
::
::END:syta-agentic-launcher.ps1

::BEGIN:syta-tool-diagnostics.sh
:: #!/usr/bin/env bash
:: set -u
::
:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
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
:: }
::
:: find_nvm_binary() {
::   local name="$1"
::   local dir
::   for dir in $(find "${NVM_DIR:-$HOME/.nvm}/versions/node" -mindepth 1 -maxdepth 1 -type d -printf '%f
:: ' 2>/dev/null | sort -Vr); do
::     if [ -x "${NVM_DIR:-$HOME/.nvm}/versions/node/$dir/bin/$name" ]; then
::       printf '%s
:: ' "${NVM_DIR:-$HOME/.nvm}/versions/node/$dir/bin/$name"
::       return 0
::     fi
::   done
::   return 1
:: }
::
:: print_kv() {
::   printf '%s=%s
:: ' "$1" "$2"
:: }
::
:: emit_tool_diagnostics() {
::   local key="$1"
::   local command_name=''
::   local version=''
::   local auth='not-detected'
::   local config=''
::   local path=''
::   local installed=0
::   local install_source='unknown'
::
::   case "$key" in
::     codex)
::       command_name='codex'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::       ;;
::     omx)
::       command_name='omx'
::       [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::       ;;
::     opencode)
::       command_name='opencode'
::       [ -f "$HOME/.config/opencode/opencode.json" ] && config="$HOME/.config/opencode/opencode.json" && auth='config-present'
::       [ "$auth" = 'not-detected' ] && [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::       ;;
::     claude-code)
::       command_name='claude'
::       [ -n "${ANTHROPIC_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.config/claude" ] || [ -f "$HOME/.claude.json" ]; } && auth='config-present'
::       ;;
::     gemini-cli)
::       command_name='gemini'
::       { [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::       [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.config/gemini" ] || [ -d "$HOME/.config/google" ]; } && auth='config-present'
::       ;;
::     droid-cli)
::       command_name='droid'
::       [ -n "${FACTORY_API_KEY:-}" ] && auth='env-key'
::       [ "$auth" = 'not-detected' ] && [ -d "$HOME/.factory" ] && auth='config-present'
::       ;;
::     oh-my-openagent)
::       [ -f "$HOME/.config/opencode/oh-my-openagent.jsonc" ] && config="$HOME/.config/opencode/oh-my-openagent.jsonc" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/oh-my-openagent.json" ] && config="$HOME/.config/opencode/oh-my-openagent.json" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/oh-my-opencode.jsonc" ] && config="$HOME/.config/opencode/oh-my-opencode.jsonc" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/oh-my-opencode.json" ] && config="$HOME/.config/opencode/oh-my-opencode.json" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/opencode.json" ] && grep -Eq '"oh-my-openagent"|"oh-my-opencode"' "$HOME/.config/opencode/opencode.json" && config="$HOME/.config/opencode/opencode.json" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/opencode.jsonc" ] && grep -Eq '"oh-my-openagent"|"oh-my-opencode"' "$HOME/.config/opencode/opencode.jsonc" && config="$HOME/.config/opencode/opencode.jsonc" && auth='config-present'
::       ;;
::     oh-my-opencode-slim)
::       [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ] && config="$HOME/.config/opencode/oh-my-opencode-slim.json" && auth='config-present'
::       [ -z "$config" ] && [ -f "$HOME/.config/opencode/oh-my-opencode-slim.jsonc" ] && config="$HOME/.config/opencode/oh-my-opencode-slim.jsonc" && auth='config-present'
::       ;;
::     *)
::       print_kv key "$key"
::       print_kv installed 0
::       print_kv path ''
::       print_kv version ''
::       print_kv auth 'not-detected'
::       print_kv config ''
::       print_kv install_source 'unknown'
::       return 0
::       ;;
::   esac
::
::   if [ -n "$command_name" ]; then
::     if command -v "$command_name" >/dev/null 2>&1; then
::       path="$(command -v "$command_name")"
::       installed=1
::     else
::       path="$(find_nvm_binary "$command_name" 2>/dev/null || true)"
::       [ -n "$path" ] && installed=1
::     fi
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
::   if { [ "$key" = 'oh-my-opencode-slim' ] || [ "$key" = 'oh-my-openagent' ]; } && [ -n "$config" ]; then
::     installed=1
::     path="$config"
::     install_source='config'
::   fi
::
::   if [ "$installed" -eq 1 ] && [ -n "$command_name" ] && [ -x "$path" ]; then
::     version="$($path --version 2>/dev/null | head -n 1)"
::   fi
::
::   print_kv key "$key"
::   print_kv installed "$installed"
::   print_kv path "$path"
::   print_kv version "$version"
::   print_kv auth "$auth"
::   print_kv config "$config"
::   print_kv install_source "$install_source"
:: }
::
:: load_user_env
::
:: if [ "$#" -eq 0 ]; then
::   set -- unknown
:: fi
::
:: for key in "$@"; do
::   printf '__SYTA_DIAG_BEGIN__=%s\n' "$key"
::   emit_tool_diagnostics "$key"
::   printf '__SYTA_DIAG_END__=%s\n' "$key"
:: done
::END:syta-tool-diagnostics.sh
::BEGIN:syta-install-powershell7.ps1
:: $ErrorActionPreference = 'Stop'
::
:: try {
::     [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
::     [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
::     $OutputEncoding = [Console]::OutputEncoding
:: } catch {
:: }
:: if (("$env:SYTA_LANGUAGE" -match '^fr') -or ("$env:SYTA_LANG" -match '^fr')) {
::     $script:Language = 'fr'
:: } elseif (("$env:SYTA_LANGUAGE" -match '^zh') -or ("$env:SYTA_LANG" -match '^zh')) {
::     $script:Language = 'zh'
:: } else {
::     $script:Language = 'en'
:: }
::
:: function T {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     if ($script:Language -eq 'fr') { return $Fr }
::     if ($script:Language -eq 'zh') { return $Zh }
::     return $En
:: }
::
:: function Write-Stage {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     Write-Host ''
::     Write-Host ("== " + (T $En $Fr $Zh) + " ==") -ForegroundColor Cyan
:: }
::
:: function Set-WindowsTerminalDefaultPowerShellProfile {
::     $wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
::     if (-not (Test-Path -LiteralPath $wtPath)) {
::         Write-Host (T 'Windows Terminal settings.json not found. Skipping default-profile update.' 'settings.json de Windows Terminal introuvable. Mise a jour du profil par defaut ignoree.' '未找到 Windows Terminal 的 settings.json。跳过默认配置文件更新。') -ForegroundColor Yellow
::         return
::     }
::
::     $raw = Get-Content -LiteralPath $wtPath -Raw -ErrorAction Stop
::     if ([string]::IsNullOrWhiteSpace($raw)) {
::         $raw = '{`n  "defaultProfile": "PowerShell"`n}`n'
::     } elseif ($raw -match '"defaultProfile"\s*:\s*"[^"]*"') {
::         $raw = [regex]::Replace($raw, '"defaultProfile"\s*:\s*"[^"]*"', '"defaultProfile": "PowerShell"', 1)
::     } else {
::         $raw = [regex]::Replace($raw, '^\s*\{', "{`n  `"defaultProfile`": `"PowerShell`",", 1)
::     }
::
::     Set-Content -LiteralPath $wtPath -Value $raw -Encoding utf8
::     Write-Host (T 'Windows Terminal default profile set to PowerShell.' 'Le profil par defaut de Windows Terminal a ete defini sur PowerShell.' 'Windows Terminal 默认配置文件已设为 PowerShell。') -ForegroundColor Green
:: }
::
:: function Resolve-WinGet {
::     $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
::     if ($cmd) {
::         return $cmd.Source
::     }
::
::     Write-Stage 'Repair WinGet registration' 'Reparer l''enregistrement WinGet' '修复 WinGet 注册'
::     try {
::         Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop | Out-Null
::     } catch {
::         throw (T 'winget.exe is not available and WinGet registration repair failed.' 'winget.exe est indisponible et la reparation de son enregistrement a echoue.' 'winget.exe 不可用，修复 WinGet 注册失败。')
::     }
::
::     $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
::     if ($cmd) {
::         return $cmd.Source
::     }
::
::     throw (T 'winget.exe is still not available after registration repair.' 'winget.exe reste indisponible apres la reparation de son enregistrement.' '修复注册后 winget.exe 仍不可用。')
:: }
::
:: Write-Stage 'Install PowerShell 7' 'Installer PowerShell 7' '安装 PowerShell 7'
:: $winget = Resolve-WinGet
:: $pwshExisting = Get-Command pwsh.exe -ErrorAction SilentlyContinue
:: $wingetArgs = @(
::     '--id', 'Microsoft.PowerShell',
::     '--source', 'winget',
::     '--exact',
::     '--accept-package-agreements',
::     '--accept-source-agreements',
::     '--disable-interactivity',
::     '--silent'
:: )
::
:: if ($pwshExisting) {
::     & $winget upgrade @wingetArgs
:: } else {
::     & $winget install @wingetArgs
:: }
::
:: if ($LASTEXITCODE -ne 0) {
::     throw (T 'PowerShell 7 installation or upgrade failed.' 'L''installation ou la mise a niveau de PowerShell 7 a echoue.' 'PowerShell 7 安装或升级失败。')
:: }
::
:: Write-Stage 'Verify pwsh' 'Verifier pwsh' '验证 pwsh'
:: $pwsh = Get-Command pwsh.exe -ErrorAction Stop
:: & $pwsh.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
::
:: Write-Stage 'Set Windows Terminal default profile' 'Definir le profil par defaut Windows Terminal' '设置 Windows Terminal 默认配置文件'
:: Set-WindowsTerminalDefaultPowerShellProfile
::
:: Write-Host ''
:: Write-Host (T 'PowerShell 7 install flow completed.' 'Flux d''installation PowerShell 7 termine.' 'PowerShell 7 安装流程已完成。') -ForegroundColor Green
::
::END:syta-install-powershell7.ps1
::BEGIN:syta-wsl-session.sh
:: #!/usr/bin/env bash
:: set -u
::
:: script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
:: mode="${1:-}"
:: tool_key="${2:-}"
:: lang_raw="${3:-${SYTA_LANGUAGE:-${SYTA_LANG:-auto}}}"
:: tool_option="${4:-}"
::
:: normalize_lang() {
::   case "${1:-auto}" in
::     fr*|FR*) printf 'fr\n' ;;
::     zh*|ZH*) printf 'zh\n' ;;
::     en*|EN*) printf 'en\n' ;;
::     *) printf 'en\n' ;;
::   esac
:: }
::
:: msg() {
::   local key="$1"
::   local value="${2:-}"
::   case "$lang" in
::     fr)
::       case "$key" in
::         missing_agent) printf 'Cle agent manquante.\n' ;;
::         missing_install) printf 'Cible d''installation manquante.\n' ;;
::         unknown_mode) printf 'Mode de session inconnu : %s\n' "$value" ;;
::         session_exit) printf 'Code de sortie de session : %s\n' "$value" ;;
::         session_ok) printf 'Operation terminee.\n' ;;
::         session_failed) printf 'Operation terminee avec une erreur.\n' ;;
::         return_main) printf 'Revenez a la fenetre principale de SYTA pour choisir autre chose ou lancer une installation.\n' ;;
::         close_window) printf 'Appuyez sur Entree pour terminer cette session. Si l''onglet reste ouvert, fermez-le puis revenez a SYTA.\n' ;;
::       esac
::       ;;
::     zh)
::       case "$key" in
::         missing_agent) printf '缺少代理键。\n' ;;
::         missing_install) printf '缺少安装目标。\n' ;;
::         unknown_mode) printf '未知会话模式：%s\n' "$value" ;;
::         session_exit) printf '会话退出码：%s\n' "$value" ;;
::         session_ok) printf '操作已完成。\n' ;;
::         session_failed) printf '操作因错误结束。\n' ;;
::         return_main) printf '返回主 SYTA 窗口以选择其他操作或安装缺失的工具。\n' ;;
::         close_window) printf '按 Enter 结束此会话。如果标签页仍保持打开，请关闭它并返回 SYTA。\n' ;;
::       esac
::       ;;
::     *)
::       case "$key" in
::         missing_agent) printf 'Missing agent key.\n' ;;
::         missing_install) printf 'Missing install target.\n' ;;
::         unknown_mode) printf 'Unknown session mode: %s\n' "$value" ;;
::         session_exit) printf 'Session exit code: %s\n' "$value" ;;
::         session_ok) printf 'Operation completed.\n' ;;
::         session_failed) printf 'Operation finished with an error.\n' ;;
::         return_main) printf 'Go back to the main SYTA window to choose another action or install the missing tool.\n' ;;
::         close_window) printf 'Press Enter to finish this session. If the tab stays open, close it and return to SYTA.\n' ;;
::       esac
::       ;;
::   esac
:: }
::
:: detect_shell() {
::   local detected=""
::   if command -v getent >/dev/null 2>&1; then
::     detected="$(getent passwd "$USER" | awk -F: '{print $7}')"
::   fi
::
::   if [ -z "$detected" ] || [ ! -x "$detected" ]; then
::     detected="${SHELL:-/bin/bash}"
::   fi
::
::   case "$(basename "$detected")" in
::     bash|zsh|sh) printf '%s\n' "$detected" ;;
::     *) printf '/bin/bash\n' ;;
::   esac
:: }
::
:: lang="$(normalize_lang "$lang_raw")"
:: export SYTA_LANG="$lang"
:: export SYTA_LANGUAGE="$lang"
::
:: shell_bin="$(detect_shell)"
:: shell_name="$(basename "$shell_bin")"
::
:: run_in_shell() {
::   local payload="$1"
::   case "$shell_name" in
::     bash|zsh|sh) exec "$shell_bin" -ic "$payload" ;;
::     *) exec /bin/bash -ic "$payload" ;;
::   esac
:: }
::
:: quote_arg() {
::   printf '%q' "$1"
:: }
::
:: runner_cmd=""
:: case "$mode" in
::   code)
::     if [ -z "$tool_key" ]; then msg missing_agent; exit 64; fi
::     runner_cmd="export SYTA_LANG=$(quote_arg "$lang"); export SYTA_LANGUAGE=$(quote_arg "$lang"); bash $(quote_arg "$script_dir/syta-run-agent.sh") $(quote_arg "$tool_key")"
::     ;;
::   install)
::     if [ -z "$tool_key" ]; then msg missing_install; exit 64; fi
::     runner_cmd="export SYTA_LANG=$(quote_arg "$lang"); export SYTA_LANGUAGE=$(quote_arg "$lang"); bash $(quote_arg "$script_dir/syta-install-tool.sh") $(quote_arg "$tool_key")"
::     if [ -n "$tool_option" ]; then
::       runner_cmd="$runner_cmd $(quote_arg "$tool_option")"
::     fi
::     ;;
::   update)
::     runner_cmd="export SYTA_LANG=$(quote_arg "$lang"); export SYTA_LANGUAGE=$(quote_arg "$lang"); bash $(quote_arg "$script_dir/update-wsl-coding-tools.sh")"
::     ;;
::   update-light)
::     runner_cmd="export SYTA_LANG=$(quote_arg "$lang"); export SYTA_LANGUAGE=$(quote_arg "$lang"); bash $(quote_arg "$script_dir/update-ai-cli-tools.sh")"
::     ;;
::   *)
::     msg unknown_mode "$mode"
::     exit 64
::     ;;
:: esac
::
:: case "$lang" in
::   fr)
::     success_text="Operation terminee."
::     failure_text="Operation terminee avec une erreur."
::     exit_prefix="Code de sortie de session : "
::     return_text="Revenez a la fenetre principale de SYTA pour choisir autre chose ou lancer une installation."
::     close_text="Appuyez sur Entree pour terminer cette session. Si l'onglet reste ouvert, fermez-le puis revenez a SYTA."
::     ;;
::   zh)
::     success_text="操作已完成。"
::     failure_text="操作因错误结束。"
::     exit_prefix="会话退出码："
::     return_text="返回主 SYTA 窗口以选择其他操作或安装缺失的工具。"
::     close_text="按 Enter 结束此会话。如果标签页仍保持打开，请关闭它并返回 SYTA。"
::     ;;
::   *)
::     success_text="Operation completed."
::     failure_text="Operation finished with an error."
::     exit_prefix="Session exit code: "
::     return_text="Go back to the main SYTA window to choose another action or install the missing tool."
::     close_text="Press Enter to finish this session. If the tab stays open, close it and return to SYTA."
::     ;;
:: esac
::
:: payload="$runner_cmd; syta_rc=\$?; printf '\n'; if [ \"\$syta_rc\" -eq 0 ]; then printf '%s\n' $(quote_arg "$success_text"); else printf '%s\n' $(quote_arg "$failure_text"); fi; printf '%s%s\n\n' $(quote_arg "$exit_prefix") \"\$syta_rc\"; printf '%s\n' $(quote_arg "$return_text"); printf '%s\n' $(quote_arg "$close_text"); read -r _syta_close_prompt || true; exit \"\$syta_rc\""
:: run_in_shell "$payload"
::
::END:syta-wsl-session.sh
::BEGIN:syta-run-agent.sh
:: #!/usr/bin/env bash
:: set -u
::
:: agent_key="${1:-}"
:: lang="${SYTA_LANG:-en}"
::
:: normalize_lang() {
::   case "${1:-en}" in
::     fr*|FR*) printf 'fr\n' ;;
::     zh*|ZH*) printf 'zh\n' ;;
::     *) printf 'en\n' ;;
::   esac
:: }
::
:: lang="$(normalize_lang "$lang")"
::
:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::   [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::   [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::   [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::   hash -r 2>/dev/null || true
:: }
::
:: msg() {
::   local key="$1"
::   local value="${2:-}"
::   case "$lang" in
::     fr)
::       case "$key" in
::         workspace) printf ' Espace de travail : %s\n' "$value" ;;
::         missing_bash) printf 'bash n''est pas disponible dans cet environnement WSL.\n' ;;
::         current_path) printf 'PATH actuel : %s\n' "$value" ;;
::         codex_missing) printf 'codex n''est pas disponible dans le PATH.\n' ;;
::         omx_missing) printf 'omx n''est pas disponible dans le PATH.\n' ;;
::         opencode_missing) printf 'opencode n''est pas disponible dans le PATH.\n' ;;
::         claude_missing) printf 'claude n''est pas disponible dans le PATH.\n' ;;
::         gemini_missing) printf 'gemini n''est pas disponible dans le PATH.\n' ;;
::         launch_codex) printf 'Lancement de Codex YOLO...\n\n' ;;
::         launch_omx) printf 'Lancement de OMX MADMAX HIGH...\n\n' ;;
::         launch_opencode) printf 'Lancement de OpenCode...\n\n' ;;
::         launch_claude) printf 'Lancement de Claude Code...\n\n' ;;
::         launch_gemini) printf 'Lancement de Gemini CLI...\n\n' ;;
::         unknown_agent) printf 'Cle agent inconnue : %s\n' "$value" ;;
::         agent_exit) printf '\nL''agent s''est termine avec le code %s.\n' "$value" ;;
::         session_end) printf '\nSession agent terminee.\n' ;;
::       esac
::       ;;
::     zh)
::       case "$key" in
::         workspace) printf ' 工作区：%s\n' "$value" ;;
::         missing_bash) printf '此 WSL 环境中没有 bash。\n' ;;
::         current_path) printf '当前 PATH：%s\n' "$value" ;;
::         codex_missing) printf 'PATH 中没有 codex。\n' ;;
::         omx_missing) printf 'PATH 中没有 omx。\n' ;;
::         opencode_missing) printf 'PATH 中没有 opencode。\n' ;;
::         claude_missing) printf 'PATH 中没有 claude。\n' ;;
::         gemini_missing) printf 'PATH 中没有 gemini。\n' ;;
::         launch_codex) printf '正在启动 Codex YOLO...\n\n' ;;
::         launch_omx) printf '正在启动 OMX MADMAX HIGH...\n\n' ;;
::         launch_opencode) printf '正在启动 OpenCode...\n\n' ;;
::         launch_claude) printf '正在启动 Claude Code...\n\n' ;;
::         launch_gemini) printf '正在启动 Gemini CLI...\n\n' ;;
::         unknown_agent) printf '未知代理键：%s\n' "$value" ;;
::         agent_exit) printf '\n代理已退出，状态码为 %s。\n' "$value" ;;
::         session_end) printf '\n代理会话已结束。\n' ;;
::       esac
::       ;;
::     *)
::       case "$key" in
::         workspace) printf ' Workspace: %s\n' "$value" ;;
::         missing_bash) printf 'bash is not available in this WSL environment.\n' ;;
::         current_path) printf 'Current PATH: %s\n' "$value" ;;
::         codex_missing) printf 'codex is not available in PATH.\n' ;;
::         omx_missing) printf 'omx is not available in PATH.\n' ;;
::         opencode_missing) printf 'opencode is not available in PATH.\n' ;;
::         claude_missing) printf 'claude is not available in PATH.\n' ;;
::         gemini_missing) printf 'gemini is not available in PATH.\n' ;;
::         launch_codex) printf 'Launching Codex YOLO...\n\n' ;;
::         launch_omx) printf 'Launching OMX MADMAX HIGH...\n\n' ;;
::         launch_opencode) printf 'Launching OpenCode...\n\n' ;;
::         launch_claude) printf 'Launching Claude Code...\n\n' ;;
::         launch_gemini) printf 'Launching Gemini CLI...\n\n' ;;
::         unknown_agent) printf 'Unknown agent key: %s\n' "$value" ;;
::         agent_exit) printf '\nAgent exited with status %s.\n' "$value" ;;
::         session_end) printf '\nAgent session ended.\n' ;;
::       esac
::       ;;
::   esac
:: }
::
:: show_header() {
::   printf '\n'
::   printf '============================================================\n'
::   printf ' SYTA Super Launcher\n'
::   msg workspace "$PWD"
::   printf '============================================================\n\n'
:: }
::
:: run_agent() {
::   case "$agent_key" in
::     codex-yolo)
::       if ! command -v codex >/dev/null 2>&1; then msg codex_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_codex; codex --yolo ;;
::     omx-madmax-high)
::       if ! command -v omx >/dev/null 2>&1; then msg omx_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_omx; omx --madmax --high ;;
::     opencode)
::       if ! command -v opencode >/dev/null 2>&1; then msg opencode_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_opencode; opencode ;;
::     claude-code)
::       if ! command -v claude >/dev/null 2>&1; then msg claude_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_claude; claude ;;
::     gemini-cli)
::       if ! command -v gemini >/dev/null 2>&1; then msg gemini_missing; msg current_path "$PATH"; return 127; fi
::       msg launch_gemini; gemini ;;
::     *) msg unknown_agent "$agent_key"; return 64 ;;
::   esac
:: }
::
:: show_header
:: load_user_env
:: if ! command -v bash >/dev/null 2>&1; then msg missing_bash; exit 1; fi
:: run_agent
:: rc=$?
:: if [ "$rc" -ne 0 ]; then
::   msg agent_exit "$rc"
::   exit "$rc"
:: fi
:: msg session_end
::
::END:syta-run-agent.sh
::BEGIN:syta-install-tool.sh
:: #!/usr/bin/env bash
:: set -u
::
:: NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
:: tool_key="${1:-}"
:: tool_option="${2:-}"
::
:: show_header() {
::   printf '
:: '
::   printf '============================================================
:: '
::   printf ' SYTA Installer
:: '
::   printf ' Workspace: %s
:: ' "$PWD"
::   printf '============================================================
:: '
::   printf '
:: '
:: }
::
:: run_step() {
::   local label="$1"
::   shift
::   printf '== %s ==
:: ' "$label"
::   if "$@"; then
::     printf 'OK
::
:: '
::   else
::     local rc=$?
::     printf 'FAILED (%s)
::
:: ' "$rc"
::     return "$rc"
::   fi
:: }
::
:: load_user_env() {
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
:: }
::
:: have_nvm() {
::   [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]
:: }
::
:: nvm_preferred_target() {
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
:: prompt_yes_no() {
::   local prompt="$1"
::   local reply=""
::   printf '%s [y/N] ' "$prompt"
::   IFS= read -r reply || return 1
::   case "$reply" in
::     y|Y|yes|YES)
::       return 0
::       ;;
::     *)
::       return 1
::       ;;
::   esac
:: }
::
:: cleaner_specs() {
::   cat <<'EOF'
:: codex|@openai/codex
:: omx|oh-my-codex
:: opencode|opencode-ai
:: claude|@anthropic-ai/claude-code
:: gemini|@google/gemini-cli
:: comment-checker|@code-yeongyu/comment-checker
:: EOF
:: }
::
:: expand_home_path() {
::   case "${1:-}" in
::     "~") printf '%s\n' "$HOME" ;;
::     "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
::     *) printf '%s\n' "${1:-}" ;;
::   esac
:: }
::
:: reset_config_specs() {
::   cat <<'EOF'
:: codex-omx|Codex / OMX config|file|~/.codex/config.toml
:: codex-omx|Codex / OMX auth|file|~/.codex/auth.json
:: opencode|OpenCode config|file|~/.config/opencode/opencode.json
:: opencode|OpenCode config|file|~/.config/opencode/opencode.jsonc
:: oh-my-openagent|Oh My OpenAgent config|file|~/.config/opencode/oh-my-openagent.json
:: oh-my-openagent|Oh My OpenAgent config|file|~/.config/opencode/oh-my-openagent.jsonc
:: oh-my-openagent|Oh My OpenAgent legacy config|file|~/.config/opencode/oh-my-opencode.json
:: oh-my-openagent|Oh My OpenAgent legacy config|file|~/.config/opencode/oh-my-opencode.jsonc
:: oh-my-opencode-slim|Oh My OpenCode Slim config|file|~/.config/opencode/oh-my-opencode-slim.json
:: oh-my-opencode-slim|Oh My OpenCode Slim config|file|~/.config/opencode/oh-my-opencode-slim.jsonc
:: claude-code|Claude Code config directory|dir|~/.config/claude
:: claude-code|Claude Code config file|file|~/.claude.json
:: gemini-cli|Gemini CLI config directory|dir|~/.config/gemini
:: gemini-cli|Google AI config directory|dir|~/.config/google
:: EOF
:: }
::
:: ensure_sudo() {
::   if ! command -v sudo >/dev/null 2>&1; then
::     printf 'sudo is not available. Cannot install system packages automatically.
:: '
::     return 1
::   fi
::   printf 'sudo access may be required for prerequisites.
:: '
::   sudo -v
:: }
::
:: ensure_curl() {
::   if command -v curl >/dev/null 2>&1; then
::     return 0
::   fi
::   printf 'curl is required but missing.
:: '
::   ensure_sudo || return 1
::   run_step "APT update" sudo apt-get update || return 1
::   run_step "Install curl" sudo apt-get install -y curl || return 1
:: }
::
:: ensure_node_runtime_libs() {
::   if ldconfig -p 2>/dev/null | grep -q 'libatomic.so.1'; then
::     return 0
::   fi
::   printf 'libatomic.so.1 is missing. This is required by some Node distributions.
:: '
::   if command -v apt-get >/dev/null 2>&1; then
::     ensure_sudo || return 1
::     run_step "APT update" sudo apt-get update || return 1
::     run_step "Install libatomic1" sudo apt-get install -y libatomic1 || return 1
::     return 0
::   fi
::   printf 'Automatic fix is only implemented for apt-based distros.
:: '
::   return 1
:: }
::
:: ensure_nvm() {
::   ensure_curl || return 1
::   ensure_node_runtime_libs || return 1
::   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::   if [ ! -s "$NVM_DIR/nvm.sh" ]; then
::     run_step "Install nvm from GitHub" bash -lc "curl -fsSL '$NVM_INSTALL_URL' | bash" || return 1
::   fi
::   if [ ! -s "$NVM_DIR/nvm.sh" ]; then
::     printf 'nvm install completed but %s/nvm.sh is still missing.
:: ' "$NVM_DIR"
::     return 1
::   fi
::   # shellcheck source=/dev/null
::   . "$NVM_DIR/nvm.sh"
::   command -v nvm >/dev/null 2>&1
:: }
::
:: with_nvm() {
::   bash -lc '
::     export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
::     [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
::     export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
::     [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true
::     [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true
::     . "$NVM_DIR/nvm.sh"
::     nvm_preferred_target() {
::       local def cur latest
::       def="$(nvm version default 2>/dev/null || true)"
::       case "$def" in ""|N/A|system) def="" ;; esac
::       if [ -n "$def" ]; then printf "%s
:: " "$def"; return 0; fi
::       cur="$(nvm current 2>/dev/null || true)"
::       case "$cur" in ""|none|system) cur="" ;; esac
::       if [ -n "$cur" ]; then printf "%s
:: " "$cur"; return 0; fi
::       latest="$(find "$NVM_DIR/versions/node" -mindepth 1 -maxdepth 1 -type d -printf "%f
:: " 2>/dev/null | sort -V | tail -n 1)"
::       [ -n "$latest" ] && printf "%s
:: " "$latest"
::     }
::     target="$(nvm_preferred_target)"
::     [ -n "$target" ] && nvm use "$target" >/dev/null 2>&1 || true
::     "$@"
::   ' bash "$@"
:: }
::
:: ensure_node_npm_latest() {
::   ensure_nvm || return 1
::   local target
::   target="$(nvm_preferred_target 2>/dev/null || true)"
::   if [ -z "$target" ]; then
::     run_step "Install latest Node.js via nvm" bash -lc 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; . "$NVM_DIR/nvm.sh"; nvm install node' || return 1
::     run_step "Set default Node.js via nvm" bash -lc 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; . "$NVM_DIR/nvm.sh"; nvm alias default node >/dev/null; nvm use default >/dev/null' || return 1
::   else
::     run_step "Use existing Node.js via nvm" bash -lc "export NVM_DIR="\${NVM_DIR:-\$HOME/.nvm}"; . "\$NVM_DIR/nvm.sh"; nvm use '$target' >/dev/null" || return 1
::     run_step "Set default Node.js via nvm" bash -lc "export NVM_DIR="\${NVM_DIR:-\$HOME/.nvm}"; . "\$NVM_DIR/nvm.sh"; nvm alias default '$target' >/dev/null" || return 1
::   fi
::   run_step "Upgrade npm to latest" bash -lc 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; . "$NVM_DIR/nvm.sh"; target="$(nvm version default 2>/dev/null || nvm current 2>/dev/null)"; nvm use "$target" >/dev/null; npm install -g npm@latest' || return 1
::   load_user_env
:: }
::
:: install_codex() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Codex CLI" with_nvm npm install -g @openai/codex || return 1
::   load_user_env
::   with_nvm codex --version 2>/dev/null || true
:: }
::
:: install_claude_code() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Claude Code" with_nvm npm install -g @anthropic-ai/claude-code || return 1
::   load_user_env
::   with_nvm claude --version 2>/dev/null || true
:: }
::
:: install_gemini_cli() {
::   ensure_node_npm_latest || return 1
::   run_step "Install Gemini CLI" with_nvm npm install -g @google/gemini-cli || return 1
::   load_user_env
::   with_nvm gemini --version 2>/dev/null || true
:: }
::
:: install_droid_cli() {
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
:: install_opencode() {
::   ensure_curl || return 1
::   if run_step "Install OpenCode" bash -lc 'curl -fsSL https://opencode.ai/install | bash'; then
::     load_user_env
::     if command -v opencode >/dev/null 2>&1; then
::       opencode --version 2>/dev/null || true
::       return 0
::     fi
::   fi
::   printf 'Falling back to npm-based OpenCode install.
::
:: '
::   ensure_node_npm_latest || return 1
::   run_step "Install OpenCode via npm fallback" with_nvm npm install -g opencode-ai || return 1
::   load_user_env
::   if command -v opencode >/dev/null 2>&1; then
::     opencode --version 2>/dev/null || true
::     return 0
::   fi
::   printf 'OpenCode install finished but opencode is still not on PATH.
:: '
::   return 1
:: }
::
:: install_omx() {
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
:: install_oh_my_openagent() {
::   load_user_env
::   if ! command -v opencode >/dev/null 2>&1; then
::     printf 'OpenCode is not installed yet. Installing OpenCode first.\n\n'
::     install_opencode || return 1
::     load_user_env
::   fi
::   if ! command -v opencode >/dev/null 2>&1; then
::     printf 'OpenCode binary is still not on PATH after install.\n'
::     return 1
::   fi
::   ensure_node_npm_latest || return 1
::   printf 'Launching the official Oh My OpenAgent interactive installer.\n'
::   printf 'Use this flow to choose your subscriptions and preferred provider setup.\n\n'
::   run_step "Install Oh My OpenAgent" with_nvm npx oh-my-opencode install || return 1
::   run_step "Oh My OpenAgent doctor" with_nvm npx oh-my-opencode doctor || return 1
:: }
::
:: install_oh_my_opencode_slim() {
::   load_user_env
::   if ! command -v opencode >/dev/null 2>&1; then
::     printf 'OpenCode is not installed yet. Installing OpenCode first.
::
:: '
::     install_opencode || return 1
::     load_user_env
::   fi
::   if ! command -v opencode >/dev/null 2>&1; then
::     printf 'OpenCode binary is still not on PATH after install.
:: '
::     return 1
::   fi
::   ensure_node_npm_latest || return 1
::   run_step "Install comment-checker" with_nvm npm install -g @code-yeongyu/comment-checker || return 1
::   load_user_env
::   run_step "Install Oh My OpenCode Slim" with_nvm npx oh-my-opencode install --no-tui --claude=no --openai=no --gemini=no --copilot=no --opencode-zen=no --zai-coding-plan=no --opencode-go=no --skip-auth || return 1
::   run_step "Oh My OpenCode doctor" with_nvm npx oh-my-opencode doctor || return 1
:: }
::
:: install_all_ai_cli_tools() {
::   local overall=0
::   install_codex || overall=1
::   install_claude_code || overall=1
::   install_gemini_cli || overall=1
::   install_opencode || overall=1
::   return "$overall"
:: }
::
:: run_cleaner_helper() {
::   local preferred=""
::   local version=""
::   local binary=""
::   local package=""
::   local version_text=""
::   local bin_path=""
::   local current_path=""
::   local hit=""
::   local overall=0
::   local key=""
::   local found=""
::   local existing=""
::   local joined_packages=""
::   local -a versions=()
::   local -a stale_actions=()
::   local -a duplicate_paths=()
::   local -a version_packages=()
::
::   printf 'Scanning for stale npm-based AI CLI installs and duplicate PATH entries.\n'
::   printf 'Only tracked npm globals in older nvm Node versions are eligible for automatic cleanup.\n\n'
::
::   if have_nvm; then
::     preferred="$(nvm_preferred_target 2>/dev/null || true)"
::     while IFS= read -r version; do
::       [ -n "$version" ] && versions+=("$version")
::     done < <(find "${NVM_DIR:-$HOME/.nvm}/versions/node" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V)
::
::     if [ -n "$preferred" ]; then
::       printf 'Preferred nvm Node version: %s\n' "$preferred"
::     else
::       printf 'nvm was detected, but no preferred/default Node version was resolved.\n'
::     fi
::
::     for version in "${versions[@]}"; do
::       while IFS='|' read -r binary package; do
::         [ -n "$binary" ] || continue
::         bin_path="${NVM_DIR:-$HOME/.nvm}/versions/node/$version/bin/$binary"
::         if [ -x "$bin_path" ] && [ "$version" != "$preferred" ]; then
::           version_text="$("$bin_path" --version 2>/dev/null | head -n 1 || true)"
::           stale_actions+=("$version|$binary|$package|$version_text")
::         fi
::       done < <(cleaner_specs)
::     done
::   else
::     printf 'nvm was not detected. Cleaner helper will only inspect duplicate PATH entries.\n'
::   fi
::
::   if command -v which >/dev/null 2>&1; then
::     while IFS='|' read -r binary package; do
::       [ -n "$binary" ] || continue
::       current_path="$(command -v "$binary" 2>/dev/null || true)"
::       while IFS= read -r hit; do
::         [ -n "$hit" ] || continue
::         [ "$hit" = "$current_path" ] && continue
::         key="$binary|$hit"
::         found=0
::         for existing in "${duplicate_paths[@]}"; do
::           if [ "$existing" = "$key" ]; then
::             found=1
::             break
::           fi
::         done
::         if [ "$found" -eq 0 ]; then
::           duplicate_paths+=("$key")
::         fi
::       done < <(which -a "$binary" 2>/dev/null | awk '!seen[$0]++')
::     done < <(cleaner_specs)
::   fi
::
::   if [ ${#stale_actions[@]} -eq 0 ]; then
::     printf '\nNo stale tracked npm globals were found in older nvm Node versions.\n'
::   else
::     printf '\nStale tracked npm globals found in older nvm Node versions:\n'
::     for found in "${stale_actions[@]}"; do
::       IFS='|' read -r version binary package version_text <<< "$found"
::       if [ -n "$version_text" ]; then
::         printf ' - Node %s: %s (%s) -> %s\n' "$version" "$binary" "$package" "$version_text"
::       else
::         printf ' - Node %s: %s (%s)\n' "$version" "$binary" "$package"
::       fi
::     done
::   fi
::
::   if [ ${#duplicate_paths[@]} -gt 0 ]; then
::     printf '\nAdditional PATH hits detected outside the active command location:\n'
::     for found in "${duplicate_paths[@]}"; do
::       IFS='|' read -r binary hit <<< "$found"
::       printf ' - %s: %s\n' "$binary" "$hit"
::     done
::     printf 'These are shown for review. Automatic cleanup only targets tracked npm globals in older nvm Node versions.\n'
::   fi
::
::   if [ ${#stale_actions[@]} -eq 0 ]; then
::     printf '\nCleaner helper found nothing it can safely auto-clean.\n'
::     return 0
::   fi
::
::   if have_nvm && [ -z "$preferred" ]; then
::     printf '\nCleaner helper stayed in report-only mode because no preferred/default nvm Node version was resolved.\n'
::     printf 'Set an nvm default first, then rerun the cleaner if you want automated stale-package removal.\n'
::     return 0
::   fi
::
::   printf '\n'
::   if ! prompt_yes_no "Remove tracked npm globals from older nvm Node versions now?"; then
::     printf '\nCleanup skipped.\n'
::     return 0
::   fi
::
::   for version in "${versions[@]}"; do
::     version_packages=()
::     for found in "${stale_actions[@]}"; do
::       IFS='|' read -r found_version binary package version_text <<< "$found"
::       if [ "$found_version" = "$version" ]; then
::         version_packages+=("$package")
::       fi
::     done
::     if [ ${#version_packages[@]} -eq 0 ]; then
::       continue
::     fi
::
::     joined_packages=""
::     for package in "${version_packages[@]}"; do
::       joined_packages="$joined_packages '$package'"
::     done
::
::     printf '\nCleaning Node %s\n' "$version"
::     run_step "Remove tracked npm globals from Node $version" bash -lc "export PATH=\"\$HOME/.local/bin:\$HOME/bin:\$PATH\"; export NVM_DIR=\"\${NVM_DIR:-\$HOME/.nvm}\"; [ -f \"\$HOME/.profile\" ] && . \"\$HOME/.profile\" >/dev/null 2>&1 || true; [ -f \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\" >/dev/null 2>&1 || true; . \"\$NVM_DIR/nvm.sh\"; nvm use '$version' >/dev/null; npm uninstall -g$joined_packages" || overall=1
::   done
::
::   load_user_env
::   if [ "$overall" -eq 0 ]; then
::     printf 'Cleanup completed.\n'
::   else
::     printf 'Cleanup completed with failures.\n'
::   fi
::   return "$overall"
:: }
::
:: run_reset_tool_configs() {
::   local selection="${1:-all}"
::   local label=""
::   local kind=""
::   local raw_path=""
::   local target=""
::   local overall=0
::   local entry=""
::   local -a found_entries=()
::
::   printf 'Scanning tracked tool config/auth paths.\n'
::   printf 'This helper keeps broader history/session folders intact and only targets the tracked paths below.\n\n'
::
::   while IFS='|' read -r scope label kind raw_path; do
::     [ -n "$label" ] || continue
::     if [ "$selection" != 'all' ] && [ "$scope" != "$selection" ]; then
::       continue
::     fi
::     target="$(expand_home_path "$raw_path")"
::     if [ -e "$target" ]; then
::       found_entries+=("$label|$kind|$target")
::     fi
::   done < <(reset_config_specs)
::
::   if [ ${#found_entries[@]} -eq 0 ]; then
::     printf 'No tracked config/auth paths were found.\n'
::     return 0
::   fi
::
::   printf 'Tracked config/auth paths found:\n'
::   for entry in "${found_entries[@]}"; do
::     IFS='|' read -r label kind target <<< "$entry"
::     printf ' - %s (%s): %s\n' "$label" "$kind" "$target"
::   done
::
::   for entry in "${found_entries[@]}"; do
::     IFS='|' read -r label kind target <<< "$entry"
::     printf '\n'
::     if ! prompt_yes_no "Remove $label at $target?"; then
::       printf 'Skipped %s.\n' "$label"
::       continue
::     fi
::
::     if [ "$kind" = 'dir' ]; then
::       run_step "Remove $label" rm -rf -- "$target" || overall=1
::     else
::       run_step "Remove $label" rm -f -- "$target" || overall=1
::     fi
::   done
::
::   if [ "$overall" -eq 0 ]; then
::     printf 'Config reset completed.\n'
::   else
::     printf 'Config reset completed with failures.\n'
::   fi
::   return "$overall"
:: }
::
:: show_header
:: load_user_env
::
:: status=0
:: case "$tool_key" in
::   all-ai-cli-tools) install_all_ai_cli_tools || status=$? ;;
::   cleaner-helper) run_cleaner_helper || status=$? ;;
::   reset-tool-configs) run_reset_tool_configs "$tool_option" || status=$? ;;
::   codex) install_codex || status=$? ;;
::   opencode) install_opencode || status=$? ;;
::   omx) install_omx || status=$? ;;
::   claude-code) install_claude_code || status=$? ;;
::   gemini-cli) install_gemini_cli || status=$? ;;
::   droid-cli) install_droid_cli || status=$? ;;
::   oh-my-openagent) install_oh_my_openagent || status=$? ;;
::   oh-my-opencode-slim) install_oh_my_opencode_slim || status=$? ;;
::   *) printf 'Unknown install target: %s
:: ' "$tool_key"; exit 64 ;;
:: esac
::
:: if [ "$status" -eq 0 ]; then
::   printf '
:: Install flow completed.
:: '
:: else
::   printf '
:: Install flow failed with status %s.
:: ' "$status"
:: fi
::
:: exit "$status"
::
::END:syta-install-tool.sh
::BEGIN:update-ai-cli-tools.sh
:: #!/usr/bin/env bash
:: set -u
::
:: failures=0
::
:: run_step() {
::   local label="$1"
::   shift
::   echo
::   echo "== ${label} =="
::   if "$@"; then
::     echo OK
::   else
::     local rc=$?
::     echo "FAILED (${rc})"
::     failures=$((failures + 1))
::     return "$rc"
::   fi
:: }
::
:: load_user_env() {
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
:: }
::
:: have_cmd() {
::   command -v "$1" >/dev/null 2>&1
:: }
::
:: have_nvm() {
::   [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]
:: }
::
:: ensure_node_runtime_libs() {
::   if ldconfig -p 2>/dev/null | grep -q 'libatomic.so.1'; then
::     return 0
::   fi
::
::   if command -v sudo >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
::     run_step "Install libatomic1" sudo apt-get update && sudo apt-get install -y libatomic1 || true
::   fi
:: }
::
:: with_nvm() {
::   bash -lc 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"; [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"; export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true; [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true; . "$NVM_DIR/nvm.sh"; nvm use default >/dev/null 2>&1 || true; "$@"' bash "$@"
:: }
::
:: load_user_env
:: echo "Light update for AI coding CLIs"
:: echo "Working directory: $PWD"
:: echo
::
:: if have_nvm; then
::   echo "Node toolchain: nvm-managed"
::   ensure_node_runtime_libs
::   run_step "Refresh npm to latest" bash -lc 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; . "$NVM_DIR/nvm.sh"; nvm use default >/dev/null 2>&1 || nvm install node >/dev/null; npm install -g npm@latest' || true
::   load_user_env
:: else
::   echo "Node toolchain: system npm"
:: fi
::
:: echo
:: for tool in codex omx opencode claude gemini npm npx; do
::   if have_cmd "$tool"; then
::     printf '%-14s %s
:: ' "$tool" "$(command -v "$tool")"
::   fi
:: done
::
:: echo
::
:: if have_nvm || have_cmd npm; then
::   if have_cmd codex; then
::     if have_nvm; then
::       run_step "Update Codex CLI" with_nvm npm install -g @openai/codex || true
::     else
::       run_step "Update Codex CLI" npm install -g @openai/codex || true
::     fi
::   else
::     echo "== Update Codex CLI =="
::     echo SKIPPED
::   fi
::
::   if have_cmd omx; then
::     if have_nvm; then
::       run_step "Update Oh My Codex / OMX" with_nvm npm install -g oh-my-codex || true
::     else
::       run_step "Update Oh My Codex / OMX" npm install -g oh-my-codex || true
::     fi
::   else
::     echo
::     echo "== Update Oh My Codex / OMX =="
::     echo SKIPPED
::   fi
::
::   if have_cmd claude; then
::     if have_nvm; then
::       run_step "Update Claude Code" with_nvm npm install -g @anthropic-ai/claude-code || true
::     else
::       run_step "Update Claude Code" npm install -g @anthropic-ai/claude-code || true
::     fi
::   else
::     echo
::     echo "== Update Claude Code =="
::     echo SKIPPED
::   fi
::
::   if have_cmd gemini; then
::     if have_nvm; then
::       run_step "Update Gemini CLI" with_nvm npm install -g @google/gemini-cli || true
::     else
::       run_step "Update Gemini CLI" npm install -g @google/gemini-cli || true
::     fi
::   else
::     echo
::     echo "== Update Gemini CLI =="
::     echo SKIPPED
::   fi
::
::   load_user_env
:: else
::   echo "npm is missing. npm-managed CLI updates are skipped."
:: fi
::
:: if have_cmd opencode; then
::   if ! run_step "Update OpenCode" bash -lc 'curl -fsSL https://opencode.ai/install | bash'; then
::     if have_nvm || have_cmd npm; then
::       echo
::       echo 'Retrying OpenCode update with npm fallback.'
::       if have_nvm; then
::         run_step "Update OpenCode via npm fallback" with_nvm npm install -g opencode-ai || true
::       else
::         run_step "Update OpenCode via npm fallback" npm install -g opencode-ai || true
::       fi
::     fi
::   fi
:: else
::   echo
::   echo "== Update OpenCode =="
::   echo SKIPPED
:: fi
::
:: echo
:: if [ "$failures" -eq 0 ]; then
::   echo "Light update done."
:: else
::   echo "Light update finished with ${failures} failure(s)."
:: fi
::
:: exit "$failures"
::END:update-ai-cli-tools.sh
::BEGIN:update-wsl-coding-tools.sh
:: #!/usr/bin/env bash
:: set -u
::
:: failures=0
::
:: run_step() {
::   local label="$1"
::   shift
::   echo
::   echo "== ${label} =="
::   if "$@"; then
::     echo OK
::   else
::     local rc=$?
::     echo "FAILED (${rc})"
::     failures=$((failures + 1))
::     return "$rc"
::   fi
:: }
::
:: load_user_env() {
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
:: }
::
:: have_nvm() {
::   [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]
:: }
::
:: ensure_node_runtime_libs() {
::   if ldconfig -p 2>/dev/null | grep -q 'libatomic.so.1'; then
::     return 0
::   fi
::
::   if command -v sudo >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
::     run_step "Install libatomic1" sudo apt-get update && sudo apt-get install -y libatomic1 || true
::   fi
:: }
::
:: load_user_env
:: echo "Updating coding CLI tools in WSL..."
:: echo "Working directory: $PWD"
:: echo
::
:: if have_nvm; then
::   echo "Node toolchain: nvm-managed"
::   ensure_node_runtime_libs
::   run_step "Refresh npm to latest" bash -lc 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; . "$NVM_DIR/nvm.sh"; nvm use default >/dev/null 2>&1 || nvm install node >/dev/null; npm install -g npm@latest' || true
::   load_user_env
:: else
::   echo "Node toolchain: system package manager"
:: fi
::
:: echo
:: for tool in codex omx opencode npm pnpm pipx uv rustup; do
::   if command -v "$tool" >/dev/null 2>&1; then
::     printf '%-14s %s
:: ' "$tool" "$(command -v "$tool")"
::   fi
:: done
::
:: echo
::
:: sudo_ready=0
:: if command -v sudo >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
::   echo "APT updates may require your sudo password once in this tab."
::   if sudo -v; then
::     sudo_ready=1
::   else
::     echo "sudo authentication failed. APT steps will be skipped."
::   fi
:: fi
::
:: if command -v apt-get >/dev/null 2>&1 && [ "$sudo_ready" -eq 1 ]; then
::   run_step "APT update" sudo apt-get update || true
::   run_step "APT upgrade" sudo apt-get upgrade -y || true
:: else
::   echo
::   echo "== APT update/upgrade =="
::   echo SKIPPED
:: fi
::
:: if command -v brew >/dev/null 2>&1; then
::   run_step "Homebrew update" brew update || true
::   run_step "Homebrew upgrade" brew upgrade || true
:: else
::   echo
::   echo "== Homebrew update/upgrade =="
::   echo SKIPPED
:: fi
::
:: if command -v npm >/dev/null 2>&1; then
::   run_step "npm global update" npm update -g || true
:: else
::   echo
::   echo "== npm global update =="
::   echo SKIPPED
:: fi
::
:: if command -v pnpm >/dev/null 2>&1; then
::   run_step "pnpm global update" pnpm update -g || true
:: else
::   echo
::   echo "== pnpm global update =="
::   echo SKIPPED
:: fi
::
:: if command -v pipx >/dev/null 2>&1; then
::   run_step "pipx upgrade-all" pipx upgrade-all || true
:: else
::   echo
::   echo "== pipx upgrade-all =="
::   echo SKIPPED
:: fi
::
:: if command -v uv >/dev/null 2>&1; then
::   run_step "uv self update" uv self update || true
:: else
::   echo
::   echo "== uv self update =="
::   echo SKIPPED
:: fi
::
:: if command -v rustup >/dev/null 2>&1; then
::   run_step "rustup update" rustup update || true
:: else
::   echo
::   echo "== rustup update =="
::   echo SKIPPED
:: fi
::
:: if command -v cargo-install-update >/dev/null 2>&1; then
::   run_step "cargo install-update" cargo install-update -a || true
:: else
::   echo
::   echo "== cargo install-update =="
::   echo SKIPPED
:: fi
::
:: if command -v dotnet >/dev/null 2>&1; then
::   run_step "dotnet global tools" dotnet tool update -g --all || true
:: else
::   echo
::   echo "== dotnet global tools =="
::   echo SKIPPED
:: fi
::
:: echo
:: if [ "$failures" -eq 0 ]; then
::   echo Done.
:: else
::   echo "Update finished with ${failures} failure(s)."
:: fi
::
:: exit "$failures"
::END:update-wsl-coding-tools.sh
::BEGIN:syta-install-wsl-ubuntu.ps1
:: $ErrorActionPreference = 'Stop'
::
:: try {
::     [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
::     [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
::     $OutputEncoding = [Console]::OutputEncoding
:: } catch {
:: }
::
:: if (("$env:SYTA_LANGUAGE" -match '^fr') -or ("$env:SYTA_LANG" -match '^fr')) {
::     $script:Language = 'fr'
:: } elseif (("$env:SYTA_LANGUAGE" -match '^zh') -or ("$env:SYTA_LANG" -match '^zh')) {
::     $script:Language = 'zh'
:: } else {
::     $script:Language = 'en'
:: }
::
:: function T {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     if ($script:Language -eq 'fr') { return $Fr }
::     if ($script:Language -eq 'zh') { return $Zh }
::     return $En
:: }
::
:: function Write-Stage {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     Write-Host ''
::     Write-Host ("== " + (T $En $Fr $Zh) + " ==") -ForegroundColor Cyan
:: }
::
:: $wslExe = Join-Path $env:WINDIR 'System32\wsl.exe'
:: if (-not (Test-Path -LiteralPath $wslExe)) {
::     $cmd = Get-Command wsl.exe -ErrorAction SilentlyContinue
::     if ($cmd) {
::         $wslExe = $cmd.Source
::     }
:: }
::
:: if (-not (Test-Path -LiteralPath $wslExe)) {
::     throw (T 'wsl.exe was not found on this Windows system.' 'wsl.exe est introuvable sur ce systeme Windows.' '在此 Windows 系统上未找到 wsl.exe。')
:: }
::
:: function Get-WslDistroNames {
::     $raw = & $wslExe -l -q 2>$null
::     if ($LASTEXITCODE -ne 0 -or -not $raw) {
::         return @()
::     }
::
::     return @($raw | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
:: }
::
:: function Wait-ForUbuntuRegistration {
::     param([int]$TimeoutSeconds = 25)
::
::     for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
::         $distros = @(Get-WslDistroNames)
::         $ubuntu = @($distros | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1)
::         if ($ubuntu.Count -gt 0) {
::             return $ubuntu[0]
::         }
::
::         Start-Sleep -Seconds 1
::     }
::
::     return $null
:: }
::
:: function Test-LinuxUserReady {
::     param([Parameter(Mandatory = $true)][string]$DistroName)
::
::     & $wslExe -d $DistroName --exec sh -lc "grep -Ev '^nobody:' /etc/passwd | grep -Eq '^[^:]+:[^:]*:[1-9][0-9]{3,}:'" 2>$null
::     return ($LASTEXITCODE -eq 0)
:: }
::
:: Write-Stage 'Install WSL Ubuntu' 'Installer WSL Ubuntu' '安装 WSL Ubuntu'
:: & $wslExe --install -d Ubuntu
:: $installExitCode = $LASTEXITCODE
::
:: if ($installExitCode -ne 0) {
::     Write-Stage 'Retry WSL install using web download' 'Relancer l''installation WSL avec telechargement web' '使用网络下载重试 WSL 安装'
::     & $wslExe --install --web-download -d Ubuntu
::     $installExitCode = $LASTEXITCODE
:: }
::
:: if ($installExitCode -ne 0) {
::     throw (T "WSL Ubuntu install command failed with exit code $installExitCode." "La commande d''installation WSL Ubuntu a echoue avec le code $installExitCode." "WSL Ubuntu 安装命令失败，退出码为 $installExitCode。")
:: }
::
:: $registeredUbuntu = Wait-ForUbuntuRegistration
:: Write-Host ''
:: if ($registeredUbuntu) {
::     Write-Host ((T 'WSL distro registered: {0}' 'Distribution WSL enregistree : {0}' 'WSL 发行版已注册：{0}') -f $registeredUbuntu) -ForegroundColor Green
::     if (-not (Test-LinuxUserReady -DistroName $registeredUbuntu)) {
::         Write-Stage 'Launch Ubuntu first-run setup' 'Lancer la configuration initiale Ubuntu' '启动 Ubuntu 首次运行设置'
::         Write-Host (T 'Finish the Ubuntu first-run steps in this window. Create your Linux user if Ubuntu asks for it.' 'Terminez les etapes de premier lancement Ubuntu dans cette fenetre. Creez votre utilisateur Linux si Ubuntu le demande.' '请在此窗口中完成 Ubuntu 首次运行步骤。如果 Ubuntu 要求，请创建你的 Linux 用户。') -ForegroundColor Yellow
::         & $wslExe -d $registeredUbuntu
::         Write-Host ''
::     }
::
::     if (Test-LinuxUserReady -DistroName $registeredUbuntu) {
::         Write-Host (T 'Ubuntu first-run setup is complete. You can rerun First install to continue with CLI installs.' 'La configuration initiale Ubuntu est terminee. Vous pouvez relancer Premiere installation pour continuer les installations CLI.' 'Ubuntu 首次运行设置已完成。你可以重新运行“首次安装”以继续安装 CLI。') -ForegroundColor Green
::     } else {
::         Write-Host (T 'Ubuntu is registered, but its first-run Linux-user setup still is not complete.' 'Ubuntu est enregistre, mais la configuration initiale de l''utilisateur Linux n''est pas encore terminee.' 'Ubuntu 已注册，但首次 Linux 用户设置仍未完成。') -ForegroundColor Yellow
::         Write-Host (T 'Launch Ubuntu once, finish the Linux-user setup, then rerun First install.' 'Lancez Ubuntu une fois, terminez la configuration de l''utilisateur Linux, puis relancez Premiere installation.' '先启动一次 Ubuntu，完成 Linux 用户设置，然后重新运行“首次安装”。') -ForegroundColor Yellow
::     }
:: } else {
::     Write-Host (T 'WSL install command completed, but Ubuntu is not registered yet.' 'La commande d''installation WSL est terminee, mais Ubuntu n''est pas encore enregistre.' 'WSL 安装命令已完成，但 Ubuntu 尚未注册。') -ForegroundColor Yellow
::     Write-Host (T 'If Windows asks for a reboot, restart Windows first, then launch Ubuntu once and rerun First install.' 'Si Windows demande un redemarrage, redemarrez d''abord Windows, puis lancez Ubuntu une fois et relancez Premiere installation.' '如果 Windows 要求重启，请先重启 Windows，然后启动一次 Ubuntu 并重新运行“首次安装”。') -ForegroundColor Yellow
:: }
::END:syta-install-wsl-ubuntu.ps1
::BEGIN:syta-self-update.ps1
:: param(
::     [Parameter(Mandatory = $true)][string]$TargetPath,
::     [Parameter(Mandatory = $true)][string]$DownloadUrl,
::     [Parameter(Mandatory = $true)][string]$ReleaseTag,
::     [string]$ExpectedDigest = ''
:: )
::
:: $ErrorActionPreference = 'Stop'
::
:: try {
::     [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
::     [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
::     $OutputEncoding = [Console]::OutputEncoding
:: } catch {
:: }
::
:: if (("$env:SYTA_LANGUAGE" -match '^fr') -or ("$env:SYTA_LANG" -match '^fr')) {
::     $script:Language = 'fr'
:: } elseif (("$env:SYTA_LANGUAGE" -match '^zh') -or ("$env:SYTA_LANG" -match '^zh')) {
::     $script:Language = 'zh'
:: } else {
::     $script:Language = 'en'
:: }
::
:: function T {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     if ($script:Language -eq 'fr') { return $Fr }
::     if ($script:Language -eq 'zh') { return $Zh }
::     return $En
:: }
::
:: function Write-Stage {
::     param([string]$En, [string]$Fr, [string]$Zh)
::     Write-Host ''
::     Write-Host ("== " + (T $En $Fr $Zh) + " ==") -ForegroundColor Cyan
:: }
::
:: if (-not (Test-Path -LiteralPath (Split-Path -Parent $TargetPath))) {
::     throw (T "Target folder not found: $TargetPath" "Dossier cible introuvable : $TargetPath" "未找到目标文件夹：$TargetPath")
:: }
::
:: $tempFile = Join-Path $env:TEMP ("syta-super-launcher-" + $ReleaseTag + ".bat")
::
:: Write-Stage "Download $ReleaseTag" "Telecharger $ReleaseTag" "下载 $ReleaseTag"
:: Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempFile -UseBasicParsing
::
:: if ($ExpectedDigest) {
::     Write-Stage 'Verify digest' 'Verifier le digest' '验证摘要'
::     $actualDigest = (Get-FileHash -LiteralPath $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
::     $expected = ($ExpectedDigest -replace '^sha256:', '').ToLowerInvariant()
::     if ($actualDigest -ne $expected) {
::         throw (T "Downloaded launcher digest mismatch. Expected $expected, got $actualDigest." "Le digest du lanceur telecharge ne correspond pas. Attendu : $expected, obtenu : $actualDigest." "下载的启动器摘要不匹配。期望：$expected，实际：$actualDigest。")
::     }
:: }
::
:: Write-Stage 'Replace launcher' 'Remplacer le lanceur' '替换启动器'
:: $replaced = $false
:: for ($attempt = 1; $attempt -le 12; $attempt++) {
::     try {
::         Copy-Item -LiteralPath $tempFile -Destination $TargetPath -Force
::         $replaced = $true
::         break
::     } catch {
::         Start-Sleep -Milliseconds 500
::     }
:: }
::
:: if (-not $replaced) {
::     throw (T "Unable to replace launcher at $TargetPath." "Impossible de remplacer le lanceur a l''emplacement $TargetPath." "无法替换位于 $TargetPath 的启动器。")
:: }
::
:: Write-Stage 'Relaunch launcher' 'Relancer le lanceur' '重新启动启动器'
:: Start-Process -FilePath $TargetPath | Out-Null
::
:: Write-Host ''
:: Write-Host (T "Launcher updated to $ReleaseTag and relaunched." "Le lanceur a ete mis a jour vers $ReleaseTag puis relance." "启动器已更新到 $ReleaseTag 并重新启动。") -ForegroundColor Green
::END:syta-self-update.ps1
