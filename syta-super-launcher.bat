@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SYTA_PORTABLE_ROOT=%~dp0"
set "SYTA_SELF=%~f0"
for /f "usebackq delims=" %%I in (`powershell.exe -NoLogo -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "SYTA_RUNTIME=%TEMP%\syta-super-launcher-runtime-%%I"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$self=$env:SYTA_SELF;" ^
  "$out=$env:SYTA_RUNTIME;" ^
  "New-Item -ItemType Directory -Force -Path $out | Out-Null;" ^
  "$lines=Get-Content -LiteralPath $self;" ^
  "$name=$null;" ^
  "$buf=New-Object System.Collections.Generic.List[string];" ^
  "foreach($line in $lines){" ^
  "  if($line -like '::BEGIN:*'){ $name=$line.Substring(8); $buf.Clear(); continue }" ^
  "  if($line -like '::END:*'){ [IO.File]::WriteAllText((Join-Path $out $name), ($buf -join \"`n\"), (New-Object Text.UTF8Encoding $false)); $name=$null; continue }" ^
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
::     [ValidateSet('Code', 'Install', 'UpdateAll', 'UpdateLight')]
::     [string]$Mode,
::     [ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'claude-code', 'gemini-cli')]
::     [string]$Agent,
::     [ValidateSet('wsl-ubuntu', 'powershell-7', 'all-ai-cli-tools', 'codex', 'opencode', 'omx', 'claude-code', 'gemini-cli', 'oh-my-opencode-slim')]
::     [string]$InstallTarget,
::     [string]$ProjectName,
::     [switch]$NoAnimation,
::     [switch]$NoMaximize,
::     [switch]$DryRun,
::     [switch]$SmokeTest
:: )
::
:: $ErrorActionPreference = 'Stop'
::
:: $script:ScriptDir = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSCommandPath)).TrimEnd('\')
:: $script:ProjectsRoot = 'C:\.CODEX'
:: if (-not (Test-Path -LiteralPath $script:ProjectsRoot)) {
::     $null = New-Item -ItemType Directory -Path $script:ProjectsRoot -Force
:: }
:: $script:StateFile = Join-Path $script:ProjectsRoot '.syta-launcher-state.json'
:: $script:ToolDiagCache = @{}
:: $script:BuildId = 'SYTA-build-2026-04-08-085230Z'
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
::         Title = 'Codex (ChatGPT subscription required)'
::         Subtitle = 'Runs codex --yolo.'
::         Accent = 'Cyan'
::         WindowTitle = 'Codex YOLO'
::     }
::     [pscustomobject]@{
::         Key = 'omx-madmax-high'
::         Title = 'OMX (higher-tier paid OpenAI setup recommended)'
::         Subtitle = 'Runs omx --madmax --high.'
::         Accent = 'Yellow'
::         WindowTitle = 'OMX MADMAX HIGH'
::     }
::     [pscustomobject]@{
::         Key = 'opencode'
::         Title = 'OpenCode (free models available)'
::         Subtitle = 'Runs opencode.'
::         Accent = 'Green'
::         WindowTitle = 'OpenCode'
::     }
::     [pscustomobject]@{
::         Key = 'claude-code'
::         Title = 'Claude Code (Claude access required)'
::         Subtitle = 'Runs claude.'
::         Accent = 'Magenta'
::         WindowTitle = 'Claude Code'
::     }
::     [pscustomobject]@{
::         Key = 'gemini-cli'
::         Title = 'Gemini CLI (Gemini access required)'
::         Subtitle = 'Runs gemini.'
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
::     'oh-my-opencode-slim' = [pscustomobject]@{
::         Command = ''
::         VersionScript = ''
::         DetectScript = 'if [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ]; then echo "$HOME/.config/opencode/oh-my-opencode-slim.json"; elif [ -f "$HOME/.config/opencode/opencode.json" ]; then echo "$HOME/.config/opencode/opencode.json"; fi'
::         AuthScript = 'if [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ] || [ -f "$HOME/.config/opencode/opencode.json" ]; then echo config-present; else echo not-detected; fi'
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
::     if (-not (Test-UbuntuInstalled)) {
::         return $null
::     }
::
::     $result = & wsl.exe sh -lc $Script 2>$null
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
::     if (-not (Test-UbuntuInstalled)) {
::         return $null
::     }
::
::     $scriptPath = Join-Path $script:ScriptDir 'syta-tool-diagnostics.sh'
::     $wslScriptPath = Get-WslPath -WindowsPath $scriptPath
::     $wslDir = Get-WslPath -WindowsPath $script:ScriptDir
::     $output = & wsl.exe --cd $wslDir --exec bash $wslScriptPath $Key 2>$null
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
::     Save-StateObject ([pscustomobject]@{ recentProjects = $updated })
:: }
::
:: function Format-AuthStatus {
::     param([string]$Raw)
::
::     switch ($Raw) {
::         'env-key' { return 'Auth via env key' }
::         'config-present' { return 'Auth/config detected' }
::         'not-installed' { return 'Auth n/a' }
::         'wsl-missing' { return 'WSL Ubuntu missing' }
::         'not-detected' { return 'Auth not detected' }
::         default {
::             if ([string]::IsNullOrWhiteSpace($Raw)) { return 'Auth unknown' }
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
::             PathText = 'Unknown tool'
::             Version = $null
::             VersionText = 'Unknown tool'
::             AuthRaw = 'not-detected'
::             AuthText = 'Auth unknown'
::             InstallSource = 'unknown'
::             InstallText = 'Unknown'
::             MenuText = 'Unknown tool'
::         }
::         $script:ToolDiagCache[$resolvedKey] = $diag
::         return $diag
::     }
::
::     if (-not (Test-UbuntuInstalled)) {
::         $diag = [pscustomobject]@{
::             Key = $resolvedKey
::             Installed = $false
::             Path = $null
::             PathText = $spec.InstallHint
::             Version = $null
::             VersionText = 'WSL Ubuntu missing'
::             AuthRaw = 'wsl-missing'
::             AuthText = 'WSL Ubuntu missing'
::             InstallSource = 'unknown'
::             InstallText = 'Missing'
::             MenuText = 'WSL Ubuntu missing'
::         }
::         $script:ToolDiagCache[$resolvedKey] = $diag
::         return $diag
::     }
::
::     $raw = Invoke-ToolDiagnosticsScript -Key $resolvedKey
::     $installed = ($raw.installed -eq '1')
::     $path = if ($raw.path) { $raw.path } else { $null }
::     $version = if ($raw.version) { $raw.version } else { $null }
::     $authRaw = if ($raw.auth) { $raw.auth } else { 'not-detected' }
::     $installSource = if ($raw.install_source) { $raw.install_source } else { 'unknown' }
::
::     $sourceLabel = switch ($installSource) {
::         'nvm' { 'via nvm' }
::         'user' { 'user-local' }
::         'system' { 'system-wide' }
::         'config' { 'config-only' }
::         'custom' { 'custom path' }
::         default { 'unknown source' }
::     }
::
::     $configPath = if ($raw.config) { $raw.config } else { $null }
::     $statusText = if ($installed) { "Installed ($sourceLabel)" } elseif ($configPath) { 'Configured only' } else { 'Missing' }
::
::     $diag = [pscustomobject]@{
::         Key = $resolvedKey
::         Installed = $installed
::         Path = $path
::         PathText = if ($path) { $path } elseif ($configPath) { $configPath } else { $spec.InstallHint }
::         Version = $version
::         VersionText = if ($installed) { if ($version) { $version } else { 'version not detected' } } elseif ($configPath) { 'binary not found on PATH' } else { 'not installed' }
::         AuthRaw = $authRaw
::         AuthText = Format-AuthStatus -Raw $authRaw
::         InstallSource = $installSource
::         InstallText = $statusText
::     }
::     $diag | Add-Member -NotePropertyName MenuText -NotePropertyValue (Shorten-Text -Text ("$($diag.InstallText) | $($diag.VersionText) | $($diag.AuthText)"))
::     $script:ToolDiagCache[$resolvedKey] = $diag
::     return $diag
:: }
::
:: function Get-AgentMenuItems {
::     $script:ToolDiagCache = @{}
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
::         [int]$Width = 72
::     )
::
::     $render = Shorten-Text -Text $Content -Max $Width
::     Write-Host ('  | ' + $render.PadRight($Width) + ' |') -ForegroundColor $Color
:: }
::
:: function Write-Banner {
::     param(
::         [string]$Tagline = 'Selector',
::         [string]$Hint = 'Arrows move, Enter selects, Esc goes back'
::     )
::
::     $recentCount = @(Get-RecentProjects).Count
::     Write-Host ''
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkCyan
::     Write-BoxLine -Content 'SYTA AGENTIC LAUNCHER' -Color Cyan
::     Write-BoxLine -Content 'Made by Sylvain T.' -Color Magenta
::     Write-BoxLine -Content $Tagline -Color Gray
::     Write-BoxLine -Content "Projects root: $script:ProjectsRoot" -Color White
::     Write-BoxLine -Content "Build: $script:BuildId" -Color DarkGray
::     Write-BoxLine -Content "Recent projects tracked: $recentCount" -Color DarkGray
::     Write-BoxLine -Content "Hint: $Hint" -Color Gray
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkCyan
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
::         Write-Host ("   " + $frame.Bar + "  " + $frame.Status) -ForegroundColor $frame.Accent
::         Write-Host '   Made by Sylvain T.' -ForegroundColor Magenta
::         Write-Host '   Made by Sylvain T.' -ForegroundColor Cyan
::         Write-Host '   telemetry: launcher online, diagnostics cache cold, routes ready' -ForegroundColor DarkGray
::         Start-Sleep -Milliseconds 90
::     }
::
::     Start-Sleep -Milliseconds 220
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
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     foreach ($line in $Lines) {
::         Write-BoxLine -Content $line -Color $Accent
::     }
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     Write-Host ''
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
::         [Parameter(Mandatory = $true)][string]$Command
::     )
::
::     $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
::     $psArgs = @(
::         '-NoExit',
::         '-ExecutionPolicy', 'Bypass',
::         '-Command', "`$Host.UI.RawUI.WindowTitle = '$Title'; $Command"
::     )
::
::     if ($DryRun) {
::         return [pscustomobject]@{
::             Title = $Title
::             Command = $Command
::             UsesWindowsTerminal = [bool]$wt
::         }
::     }
::
::     if ($wt) {
::         $wtArgs = @('new-tab', '--title', $Title, 'powershell.exe') + $psArgs
::         & $wt.Source @wtArgs | Out-Null
::         return
::     }
::
::     Start-Process -FilePath 'powershell.exe' -ArgumentList $psArgs | Out-Null
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
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-BoxLine -Content $Subtitle -Color Gray
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-Host ''
::
::         for ($i = 0; $i -lt $Items.Count; $i++) {
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
::             Write-Host ('  ' + $prefix + (Shorten-Text -Text $label -Max 76)) -ForegroundColor $titleColor
::             if ($detail) {
::                 Write-Host ('     ' + (Shorten-Text -Text $detail -Max 74)) -ForegroundColor $detailColor
::             }
::             Write-Host ''
::         }
::
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-BoxLine -Content 'Keys: Up/Down move | Enter select | Esc back' -Color DarkGray
::         Write-BoxLine -Content ("Items: {0} | Selected: {1}/{2}" -f $Items.Count, ($index + 1), $Items.Count) -Color DarkGray
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
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
:: function Get-ProjectDirectories {
::     Get-ChildItem -LiteralPath $script:ProjectsRoot -Directory -ErrorAction SilentlyContinue |
::         Where-Object { $_.Name -ne 'discussion' -and $_.Name -ne '.omx' } |
::         Sort-Object Name
:: }
::
:: function Prompt-NewProject {
::     while ($true) {
::         Clear-Host
::         Write-Banner -Tagline 'Create New Project' -Hint 'Leave blank to cancel'
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-BoxLine -Content "Folder root: $script:ProjectsRoot" -Color DarkGray
::         Write-BoxLine -Content 'Choose a short Windows-safe folder name.' -Color Gray
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-Host ''
::         $name = Read-Host '   Project name'
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
::     $recent = @(Get-RecentProjects)
::     $existing = @(Get-ProjectDirectories | ForEach-Object {
::         [pscustomobject]@{
::             Title = $_.Name
::             Subtitle = "Project folder in $script:ProjectsRoot"
::             Accent = 'White'
::             Name = $_.Name
::             Existing = $true
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
::                 Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::                 Write-BoxLine -Content 'Search scans existing folders under C:\.CODEX.' -Color Gray
::                 Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::                 Write-Host ''
::                 $query = Read-Host '   Search term'
::                 if ([string]::IsNullOrWhiteSpace($query)) {
::                     return $null
::                 }
::
::                 $matches = @($existing | Where-Object { $_.Name -like "*$query*" })
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
::     $wslArgs = @('--cd', $wslDir, '--exec', 'bash', $wslScript) + $ScriptArguments
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
::     $script:ToolDiagCache = @{}
::     $ubuntuInstalled = Test-UbuntuInstalled
::     $pwshInfo = Get-PwshInfo
::     $codexDiag = Get-ToolDiagnostics -Key 'codex'
::     $omxDiag = Get-ToolDiagnostics -Key 'omx'
::     $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'
::     $claudeDiag = Get-ToolDiagnostics -Key 'claude-code'
::     $geminiDiag = Get-ToolDiagnostics -Key 'gemini-cli'
::     $omoDiag = Get-ToolDiagnostics -Key 'oh-my-opencode-slim'
::
::     return @(
::         [pscustomobject]@{
::             Title = 'WSL Ubuntu'
::             Subtitle = if ($ubuntuInstalled) { "Installed | distros: $(@(Get-WslDistros).Count)" } else { 'Missing | runs wsl --install -d Ubuntu' }
::             Accent = if ($ubuntuInstalled) { 'Green' } else { 'Yellow' }
::             Key = 'wsl-ubuntu'
::         }
::         [pscustomobject]@{ Title = 'PowerShell 7'; Subtitle = $pwshInfo.MenuText; Accent = if ($pwshInfo.Installed) { 'Green' } else { 'Yellow' }; Key = 'powershell-7' }
::         [pscustomobject]@{ Title = 'Install all AI CLI tools'; Subtitle = 'Run Codex, OMX, OpenCode, Claude Code, Gemini CLI, and Oh My OpenCode Slim in one pass.'; Accent = 'Green'; Key = 'all-ai-cli-tools' }
::         [pscustomobject]@{ Title = 'Codex CLI'; Subtitle = $codexDiag.MenuText; Accent = if ($codexDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'codex' }
::         [pscustomobject]@{ Title = 'OpenCode'; Subtitle = $opencodeDiag.MenuText; Accent = if ($opencodeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'opencode' }
::         [pscustomobject]@{ Title = 'Oh My Codex / OMX'; Subtitle = $omxDiag.MenuText; Accent = if ($omxDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'omx' }
::         [pscustomobject]@{ Title = 'Claude Code'; Subtitle = $claudeDiag.MenuText; Accent = if ($claudeDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'claude-code' }
::         [pscustomobject]@{ Title = 'Gemini CLI'; Subtitle = $geminiDiag.MenuText; Accent = if ($geminiDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'gemini-cli' }
::         [pscustomobject]@{ Title = 'Oh My OpenCode Slim'; Subtitle = $omoDiag.MenuText; Accent = if ($omoDiag.Installed) { 'Green' } else { 'Cyan' }; Key = 'oh-my-opencode-slim' }
::         [pscustomobject]@{ Title = 'Back'; Subtitle = 'Return to the main menu.'; Accent = 'DarkGray'; Key = 'back' }
::     )
:: }
::
:: function Get-CodingCliSummaryLines {
::     $items = @(
::         [pscustomobject]@{ Label = 'Codex'; Key = 'codex' }
::         [pscustomobject]@{ Label = 'OMX'; Key = 'omx' }
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
::         -Title "$($agent.WindowTitle) - $($project.Name)" `
::         -WindowsDirectory $projectDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('code', $agent.Key)
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
::     $script:ToolDiagCache = @{}
::     $lines = @(
::         'Scope   : APT, Homebrew, npm, pnpm, pipx, uv, rustup, dotnet',
::         "Folder  : $script:ScriptDir"
::     ) + (Get-CodingCliSummaryLines)
::     Show-InfoBox -Title 'Full Update Preflight' -Accent Yellow -Hint 'A new terminal tab opens immediately after this screen' -Lines $lines
::
::     $result = Open-WslWindow `
::         -Title 'SYTA Updater' `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('update')
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
:: }
::
:: function Launch-UpdateLightMode {
::     $script:ToolDiagCache = @{}
::     $lines = @(
::         'Scope   : Codex, OMX, OpenCode, Claude Code, Gemini CLI',
::         "Folder  : $script:ScriptDir"
::     ) + (Get-CodingCliSummaryLines)
::     Show-InfoBox -Title 'Light Update Preflight' -Accent Green -Hint 'A new terminal tab opens immediately after this screen' -Lines $lines
::
::     $result = Open-WslWindow `
::         -Title 'SYTA Light Updater' `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('update-light')
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
:: }
::
:: function Launch-InstallMode {
::     $selection = if ($InstallTarget) {
::         (Get-InstallItems | Where-Object Key -eq $InstallTarget | Select-Object -First 1)
::     } else {
::         Read-Menu -Title 'Installer' -Subtitle 'Install or repair WSL Ubuntu and supported coding CLIs.' -Items (Get-InstallItems)
::     }
::     if (-not $selection -or $selection.Key -eq 'back') {
::         return
::     }
::
::     if ($selection.Key -eq 'wsl-ubuntu') {
::         Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell tab opens immediately after this screen' -Lines @(
::             'Target  : WSL Ubuntu',
::             'Action  : Run wsl --install -d Ubuntu',
::             'Impact  : Installs Ubuntu into Windows Subsystem for Linux'
::         )
::         $result = Open-WindowsPowerShellWindow -Title 'SYTA WSL Ubuntu Install' -Command 'wsl --install -d Ubuntu'
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         Start-Sleep -Milliseconds 500
::         return
::     }
::
::     if ($selection.Key -eq 'powershell-7') {
::         $pwshInfo = Get-PwshInfo
::         Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell tab opens immediately after this screen' -Lines @(
::             'Target  : PowerShell 7',
::             "Current : $((if ($pwshInfo.Installed) { 'Installed' } else { 'Missing' }))",
::             "Version : $($pwshInfo.Version)",
::             'Action  : Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell'
::         )
::         $scriptPath = Join-Path $script:ScriptDir 'syta-install-powershell7.ps1'
::         $result = Open-WindowsPowerShellWindow -Title 'SYTA PowerShell 7 Install' -Command ("& '$scriptPath'")
::         if ($DryRun) {
::             $result | ConvertTo-Json -Depth 4
::             return
::         }
::         Start-Sleep -Milliseconds 500
::         return
::     }
::
::     if ($selection.Key -eq 'all-ai-cli-tools') {
::         Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines (@(
::             'Target  : Install all AI CLI tools',
::             'Scope   : Codex, OMX, OpenCode, Claude Code, Gemini CLI, Oh My OpenCode Slim'
::         ) + (Get-CodingCliSummaryLines))
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
::         -ScriptArguments @('install', $selection.Key)
::
::     if ($DryRun) {
::         $result | ConvertTo-Json -Depth 4
::         return
::     }
::
::     Start-Sleep -Milliseconds 500
:: }
::
:: if ($SmokeTest) {
::     [pscustomobject]@{
::         ScriptDir = $script:ScriptDir
::         ProjectsRoot = $script:ProjectsRoot
::         StateFile = $script:StateFile
::         BuildId = $script:BuildId
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
::         [pscustomobject]@{ Title = 'Light update'; Subtitle = 'Update AI coding CLIs only: Codex, OMX, OpenCode, Claude Code, Gemini CLI.'; Accent = 'Green'; Key = 'UpdateLight' }
::         [pscustomobject]@{ Title = 'Update all'; Subtitle = 'Run the broader toolchain update pass, including system package managers.'; Accent = 'Yellow'; Key = 'UpdateAll' }
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
::         'UpdateLight' { Launch-UpdateLightMode }
::         'UpdateAll' { Launch-UpdateMode }
::     }
:: }
::END:syta-agentic-launcher.ps1

::BEGIN:syta-tool-diagnostics.sh
:: #!/usr/bin/env bash
:: set -u
::
:: key="${1:-}"
::
:: load_user_env() {
::   export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
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
:: load_user_env
::
:: command_name=''
:: version=''
:: auth='not-detected'
:: config=''
::
:: case "$key" in
::   codex)
::     command_name='codex'
::     [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::     [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::     ;;
::   omx)
::     command_name='omx'
::     [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::     [ "$auth" = 'not-detected' ] && [ -f "$HOME/.codex/config.toml" ] && auth='config-present'
::     ;;
::   opencode)
::     command_name='opencode'
::     [ -f "$HOME/.config/opencode/opencode.json" ] && config="$HOME/.config/opencode/opencode.json" && auth='config-present'
::     [ "$auth" = 'not-detected' ] && [ -n "${OPENAI_API_KEY:-}" ] && auth='env-key'
::     ;;
::   claude-code)
::     command_name='claude'
::     [ -n "${ANTHROPIC_API_KEY:-}" ] && auth='env-key'
::     [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.config/claude" ] || [ -f "$HOME/.claude.json" ]; } && auth='config-present'
::     ;;
::   gemini-cli)
::     command_name='gemini'
::     { [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; } && auth='env-key'
::     [ "$auth" = 'not-detected' ] && { [ -d "$HOME/.config/gemini" ] || [ -d "$HOME/.config/google" ]; } && auth='config-present'
::     ;;
::   oh-my-opencode-slim)
::     [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ] && config="$HOME/.config/opencode/oh-my-opencode-slim.json" && auth='config-present'
::     [ "$auth" = 'not-detected' ] && [ -f "$HOME/.config/opencode/opencode.json" ] && config="$HOME/.config/opencode/opencode.json" && auth='config-present'
::     ;;
::   *)
::     print_kv key "$key"
::     print_kv installed 0
::     print_kv path ''
::     print_kv version ''
::     print_kv auth 'not-detected'
::     print_kv config ''
::     print_kv install_source 'unknown'
::     exit 0
::     ;;
:: esac
::
:: path=''
:: installed=0
:: install_source='unknown'
::
:: if [ -n "$command_name" ]; then
::   if command -v "$command_name" >/dev/null 2>&1; then
::     path="$(command -v "$command_name")"
::     installed=1
::   else
::     path="$(find_nvm_binary "$command_name" 2>/dev/null || true)"
::     [ -n "$path" ] && installed=1
::   fi
::
::   if [ "$installed" -eq 1 ]; then
::     case "$path" in
::       *"/.nvm/"*) install_source='nvm' ;;
::       *"/.local/"*|*"/bin/"*) install_source='user' ;;
::       /usr/*|/bin/*|/sbin/*) install_source='system' ;;
::       *) install_source='custom' ;;
::     esac
::   fi
:: fi
::
:: if [ "$key" = 'oh-my-opencode-slim' ] && [ -n "$config" ]; then
::   installed=1
::   path="$config"
::   install_source='config'
:: fi
::
:: if [ "$installed" -eq 1 ] && [ -n "$command_name" ] && [ -x "$path" ]; then
::   version="$($path --version 2>/dev/null | head -n 1)"
:: fi
::
:: print_kv key "$key"
:: print_kv installed "$installed"
:: print_kv path "$path"
:: print_kv version "$version"
:: print_kv auth "$auth"
:: print_kv config "$config"
:: print_kv install_source "$install_source"
::END:syta-tool-diagnostics.sh
::BEGIN:syta-install-powershell7.ps1
:: $ErrorActionPreference = 'Stop'
::
:: function Write-Stage {
::     param([string]$Text)
::     Write-Host ''
::     Write-Host ("== " + $Text + " ==") -ForegroundColor Cyan
:: }
::
:: function Set-WindowsTerminalDefaultPowerShellProfile {
::     $wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
::     if (-not (Test-Path -LiteralPath $wtPath)) {
::         Write-Host 'Windows Terminal settings.json not found. Skipping default-profile update.' -ForegroundColor Yellow
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
::     Write-Host 'Windows Terminal default profile set to PowerShell.' -ForegroundColor Green
:: }
::
:: Write-Stage 'Install PowerShell 7'
:: if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
::     throw 'winget.exe is not available on this Windows system.'
:: }
::
:: winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
::
:: Write-Stage 'Verify pwsh'
:: $pwsh = Get-Command pwsh.exe -ErrorAction Stop
:: & $pwsh.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
::
:: Write-Stage 'Set Windows Terminal default profile'
:: Set-WindowsTerminalDefaultPowerShellProfile
::
:: Write-Host ''
:: Write-Host 'PowerShell 7 install flow completed.' -ForegroundColor Green
::END:syta-install-powershell7.ps1
::BEGIN:syta-wsl-session.sh
:: #!/usr/bin/env bash
:: set -u
:: 
:: script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
:: mode="${1:-}"
:: tool_key="${2:-}"
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
::     bash|zsh|sh)
::       printf '%s\n' "$detected"
::       ;;
::     *)
::       printf '/bin/bash\n'
::       ;;
::   esac
:: }
:: 
:: shell_bin="$(detect_shell)"
:: shell_name="$(basename "$shell_bin")"
:: 
:: run_in_shell() {
::   local payload="$1"
::   case "$shell_name" in
::     bash|zsh|sh)
::       exec "$shell_bin" -ic "$payload"
::       ;;
::     *)
::       exec /bin/bash -ic "$payload"
::       ;;
::   esac
:: }
:: 
:: quote_arg() {
::   printf '%q' "$1"
:: }
:: 
:: runner_cmd=""
:: 
:: case "$mode" in
::   code)
::     if [ -z "$tool_key" ]; then
::       printf 'Missing agent key.\n'
::       exit 64
::     fi
::     runner_cmd="bash $(quote_arg "$script_dir/syta-run-agent.sh") $(quote_arg "$tool_key")"
::     ;;
::   install)
::     if [ -z "$tool_key" ]; then
::       printf 'Missing install target.\n'
::       exit 64
::     fi
::     runner_cmd="bash $(quote_arg "$script_dir/syta-install-tool.sh") $(quote_arg "$tool_key")"
::     ;;
::   update)
::     runner_cmd="bash $(quote_arg "$script_dir/update-wsl-coding-tools.sh")"
::     ;;
::   update-light)
::     runner_cmd="bash $(quote_arg "$script_dir/update-ai-cli-tools.sh")"
::     ;;
::   *)
::     printf 'Unknown session mode: %s\n' "$mode"
::     exit 64
::     ;;
:: esac
:: 
:: keep_open="printf '\n'; printf 'Leaving %s open for the workspace.\n' $(quote_arg "$shell_bin"); exec $(quote_arg "$shell_bin") -i"
:: payload="$runner_cmd; syta_rc=\$?; printf '\nSession exit code: %s\n' \"\$syta_rc\"; $keep_open"
:: 
:: run_in_shell "$payload"
::END:syta-wsl-session.sh
::BEGIN:syta-run-agent.sh
:: #!/usr/bin/env bash
:: set -u
:: 
:: agent_key="${1:-}"
:: 
:: show_header() {
::   printf '\n'
::   printf '============================================================\n'
::   printf ' SYTA Agentic Launcher\n'
::   printf ' Workspace: %s\n' "$PWD"
::   printf '============================================================\n'
::   printf '\n'
:: }
:: 
:: run_agent() {
::   case "$agent_key" in
::     codex-yolo)
::       if ! command -v codex >/dev/null 2>&1; then
::         printf 'codex is not available in PATH.\n'
::         printf 'Current PATH: %s\n' "$PATH"
::         return 127
::       fi
::       printf 'Launching Codex YOLO...\n\n'
::       codex --yolo
::       ;;
::     omx-madmax-high)
::       if ! command -v omx >/dev/null 2>&1; then
::         printf 'omx is not available in PATH.\n'
::         printf 'Current PATH: %s\n' "$PATH"
::         return 127
::       fi
::       printf 'Launching OMX MADMAX HIGH...\n\n'
::       omx --madmax --high
::       ;;
::     opencode)
::       if ! command -v opencode >/dev/null 2>&1; then
::         printf 'opencode is not available in PATH.\n'
::         printf 'Current PATH: %s\n' "$PATH"
::         return 127
::       fi
::       printf 'Launching OpenCode...\n\n'
::       opencode
::       ;;
::     claude-code)
::       if ! command -v claude >/dev/null 2>&1; then
::         printf 'claude is not available in PATH.\n'
::         printf 'Current PATH: %s\n' "$PATH"
::         return 127
::       fi
::       printf 'Launching Claude Code...\n\n'
::       claude
::       ;;
::     gemini-cli)
::       if ! command -v gemini >/dev/null 2>&1; then
::         printf 'gemini is not available in PATH.\n'
::         printf 'Current PATH: %s\n' "$PATH"
::         return 127
::       fi
::       printf 'Launching Gemini CLI...\n\n'
::       gemini
::       ;;
::     *)
::       printf 'Unknown agent key: %s\n' "$agent_key"
::       return 64
::       ;;
::   esac
:: }
:: 
:: show_header
:: 
:: if ! command -v bash >/dev/null 2>&1; then
::   printf 'bash is not available in this WSL environment.\n'
::   exit 1
:: fi
:: 
:: if ! run_agent; then
::   rc=$?
::   printf '\nAgent exited with status %s.\n' "$rc"
::   exit "$rc"
:: fi
:: 
:: printf '\nAgent session ended.\n'
::END:syta-run-agent.sh
::BEGIN:syta-install-tool.sh
:: #!/usr/bin/env bash
:: set -u
::
:: NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
:: tool_key="${1:-}"
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
::   install_omx || overall=1
::   install_oh_my_opencode_slim || overall=1
::   return "$overall"
:: }
::
:: show_header
:: load_user_env
::
:: status=0
:: case "$tool_key" in
::   all-ai-cli-tools) install_all_ai_cli_tools || status=$? ;;
::   codex) install_codex || status=$? ;;
::   opencode) install_opencode || status=$? ;;
::   omx) install_omx || status=$? ;;
::   claude-code) install_claude_code || status=$? ;;
::   gemini-cli) install_gemini_cli || status=$? ;;
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
::   bash -lc 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"; export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; [ -f "$HOME/.profile" ] && . "$HOME/.profile" >/dev/null 2>&1 || true; [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" >/dev/null 2>&1 || true; . "$NVM_DIR/nvm.sh"; nvm use default >/dev/null 2>&1 || true; "$@"' bash "$@"
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
