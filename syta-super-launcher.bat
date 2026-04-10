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
::     [ValidateSet('Code', 'Install', 'Explanations', 'CleanerHelper', 'Update', 'UpdateAll', 'UpdateLight')]
::     [string]$Mode,
::     [ValidateSet('codex-yolo', 'omx-madmax-high', 'opencode', 'claude-code', 'gemini-cli')]
::     [string]$Agent,
::     [ValidateSet('first-install', 'wsl-ubuntu', 'powershell-7', 'all-ai-cli-tools', 'cleaner-helper', 'codex', 'opencode', 'omx', 'claude-code', 'gemini-cli', 'oh-my-opencode-slim')]
::     [string]$InstallTarget,
::     [string]$ProjectName,
::     [switch]$NoAnimation,
::     [switch]$NoMaximize,
::     [switch]$DryRun,
::     [switch]$SmokeTest,
::     [ValidateSet('auto', 'fr', 'en')]
::     [Alias('Lang')]
::     [string]$UiLanguage = 'auto'
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
:: $script:RecentProjectCountCache = $null
:: $script:BuildId = 'SYTA-build-2026-04-10-031237Z'
:: $script:ReleaseTag = 'v1.4.9'
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
::     return 'en'
:: }
::
:: function Localize-Text {
::     param([string]$Text)
::
::     if ([string]::IsNullOrEmpty($Text) -or $script:Language -ne 'fr') {
::         return $Text
::     }
::
::     $map = @{
::         'Selector' = 'Selection'
::         'Arrows move, Enter selects, Esc goes back' = 'Fleches pour naviguer, Entree pour valider, Echap pour revenir'
::         'Please wait' = 'Veuillez patienter'
::         'Launching in a new terminal tab' = 'Ouverture immediate dans un nouvel onglet du terminal'
::         'SYTA keeps this selector open while new tabs launch' = 'SYTA garde ce selecteur ouvert pendant l''ouverture des nouveaux onglets'
::         'Boot sequence' = 'Demarrage'
::         'unpacking portable runtime' = 'extraction du runtime portable'
::         'loading command deck' = 'chargement du poste de commande'
::         'scanning WSL bridge' = 'analyse du pont WSL'
::         'mapping project roots' = 'cartographie des projets'
::         'arming install matrix' = 'preparation de la matrice d''installation'
::         'warming AI launch lanes' = 'prechauffage des voies IA'
::         'routing terminal host' = 'configuration de l''hote terminal'
::         'syncing updater engines' = 'synchronisation des moteurs de mise a jour'
::         'locking flight path' = 'verrouillage de la trajectoire'
::         'SYTA ready' = 'SYTA pret'
::         'telemetry: launcher online, diagnostics cache cold, routes ready' = 'telemetrie : lanceur en ligne, cache de diagnostic vide, routes pretes'
::         'Create New Project' = 'Creer un nouveau projet'
::         'Leave blank to cancel' = 'Laisser vide pour annuler'
::         'Choose a short Windows-safe folder name.' = 'Choisissez un nom de dossier court et compatible Windows.'
::         '   Project name' = '   Nom du projet'
::         'Invalid project name' = 'Nom de projet invalide'
::         'Avoid characters Windows cannot use in folder names.' = 'Evitez les caracteres interdits dans les noms de dossier Windows.'
::         'Try another name' = 'Essayez un autre nom'
::         'Back' = 'Retour'
::         'Project Selector' = 'Selection du projet'
::         'Recent Projects' = 'Projets recents'
::         'Existing Projects' = 'Projets existants'
::         'Search Projects' = 'Rechercher des projets'
::         'Search scans existing folders under C:\.CODEX.' = 'La recherche parcourt les dossiers existants sous C:\.CODEX.'
::         '   Search term' = '   Terme de recherche'
::         'No project matches' = 'Aucun projet correspondant'
::         'Try another search' = 'Essayez une autre recherche'
::         'Open existing project' = 'Ouvrir un projet existant'
::         'Type a fresh project name and create its folder.' = 'Saisissez un nouveau nom de projet et creez son dossier.'
::         'Filter existing projects by a search term.' = 'Filtrer les projets existants par terme de recherche.'
::         'Choose a recently used project folder.' = 'Choisissez un dossier de projet recent.'
::         'Choose a project folder to open.' = 'Choisissez un dossier de projet a ouvrir.'
::         'Choose the tool to launch in the project workspace.' = 'Choisissez l''outil a lancer dans l''espace de travail du projet.'
::         'Agent Selector' = 'Selection de l''agent'
::         'Mode Selector' = 'Selection du mode'
::         'Explanations' = 'Explications'
::         'Update' = 'Mise a jour'
::         'Choose which update lane to run.' = 'Choisissez le type de mise a jour a lancer.'
::         'Run a lighter AI-tools-only update or the broader full maintenance pass.' = 'Lancer soit une mise a jour legere des outils IA, soit la maintenance complete.'
::         'Light update' = 'Mise a jour legere'
::         'Update all' = 'Mise a jour complete'
::         'Update AI coding CLIs only: Codex, OMX, OpenCode, Claude Code, Gemini CLI.' = 'Mettre a jour seulement les CLI IA : Codex, OMX, OpenCode, Claude Code, Gemini CLI.'
::         'Run the broader toolchain update pass, including system package managers.' = 'Lancer la maintenance plus large de la chaine d''outils, y compris les gestionnaires systeme.'
::         'First install (recommended)' = 'Premiere installation (recommandee)'
::         'Best beginner path for WSL Ubuntu, optional PowerShell 7, and all AI CLI tools.' = 'Meilleur parcours debutant pour WSL Ubuntu, PowerShell 7 en option et toutes les CLI IA.'
::         'Recommended path for a new machine or first SYTA setup' = 'Parcours recommande pour une nouvelle machine ou une premiere installation SYTA'
::         'CLI     : Ready to launch all AI CLI tools now' = 'CLI     : pret a lancer maintenant toutes les CLI IA'
::         'CLI     : Full AI CLI install starts after Ubuntu is ready' = 'CLI     : l''installation complete des CLI IA demarre apres qu''Ubuntu soit pret'
::         'Note    : Recommended path for a new machine or first SYTA setup' = 'Note    : parcours recommande pour une nouvelle machine ou une premiere installation SYTA'
::         'Learn what the tools are, who they are for, and what SYTA recommends.' = 'Comprendre les outils, a qui ils servent et ce que SYTA recommande.'
::         'Learn what the tools are, what SYTA recommends, and how to choose a setup.' = 'Comprendre les outils, ce que SYTA recommande et comment choisir votre configuration.'
::         'Beginner guide' = 'Guide debutant'
::         'Ultra-beginner explanation of each tool and the easiest path through SYTA.' = 'Explication ultra debutant de chaque outil et du chemin le plus simple dans SYTA.'
::         'Advanced guide' = 'Guide avance'
::         'Higher-level tradeoffs, workflows, and why you might pick one tool over another.' = 'Vue plus avancee des compromis, workflows et raisons de choisir un outil plutot qu''un autre.'
::         'What should I install?' = 'Que dois-je installer ?'
::         'Straight recommendation based on simplicity, budget, and how hands-off you want setup to be.' = 'Recommandation directe selon la simplicite, le budget et le niveau d''autonomie souhaite.'
::         'Press any key to return.' = 'Appuyez sur une touche pour revenir.'
::         'Codex: OpenAI coding agent with strong editing and reasoning.' = 'Codex : agent de code OpenAI avec de bonnes capacites d''edition et de raisonnement.'
::         'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.' = 'OMX : surcouche avancee autour de Codex pour la planification, l''orchestration et des workflows plus lourds.'
::         'OpenCode: lightweight coding CLI and usually the easiest first start.' = 'OpenCode : CLI de code legere et souvent le point de depart le plus simple.'
::         'Claude Code and Gemini CLI: best if you already use those ecosystems.' = 'Claude Code et Gemini CLI : pertinents surtout si vous utilisez deja ces ecosystemes.'
::         'Best beginner path: Install -> First install, then start with OpenCode or Codex.' = 'Meilleur parcours debutant : Installation -> Premiere installation, puis commencer avec OpenCode ou Codex.'
::         'Oh My OpenCode Slim is an OpenCode add-on. It is separate from OpenAgent.' = 'Oh My OpenCode Slim est un module complementaire pour OpenCode. Il est distinct d''OpenAgent.'
::         'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.' = 'Codex est la voie OpenAI directe ; OMX ajoute davantage d''automatisation et d''orchestration opinionated.'
::         'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.' = 'OpenCode est souvent le workflow le plus leger ; Codex et OMX sont meilleurs si vous voulez une execution plus guidee.'
::         'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.' = 'Installez seulement les CLI que vous utiliserez vraiment. Plus d''outils signifie plus d''authentification, de mises a jour et de chevauchements.'
::         'Oh My OpenCode Slim stays focused on OpenCode helpers. It is not Oh My OpenAgent, which is heavier and more token-expensive.' = 'Oh My OpenCode Slim reste centre sur les aides OpenCode. Ce n''est pas Oh My OpenAgent, qui est plus lourd et plus couteux en tokens.'
::         'Brand-new Windows machine: Install -> First install.' = 'Nouvelle machine Windows : Installation -> Premiere installation.'
::         'Lowest-friction start: OpenCode.' = 'Demarrage le plus simple : OpenCode.'
::         'Best OpenAI-first path: Codex, then OMX if you want deeper automation.' = 'Meilleur parcours centre OpenAI : Codex, puis OMX si vous voulez plus d''automatisation.'
::         'Install Oh My OpenCode Slim only if you already like OpenCode and want extra helpers.' = 'Installez Oh My OpenCode Slim seulement si vous aimez deja OpenCode et voulez des aides supplementaires.'
::         'Skip tools you do not have keys, subscriptions, or a real workflow for.' = 'Ignorez les outils pour lesquels vous n''avez pas de cle, d''abonnement ou de vrai besoin.'
::         'Choose what SYTA should do.' = 'Choisissez ce que SYTA doit faire.'
::         'Install or repair WSL Ubuntu and supported coding CLIs.' = 'Installer ou reparer WSL Ubuntu et les CLI de codage prises en charge.'
::         'First install' = 'Premiere installation'
::         'Guided setup for WSL Ubuntu, optional PowerShell 7, and all AI CLI tools.' = 'Parcours guide pour WSL Ubuntu, PowerShell 7 en option, et toutes les CLI IA.'
::         'PowerShell 7 is already installed. Reinstall or repair it now?' = 'PowerShell 7 est deja installe. Le reinstaller ou le reparer maintenant ?'
::         'Would you like SYTA to install PowerShell 7 too?' = 'Voulez-vous aussi que SYTA installe PowerShell 7 ?'
::         'Skip PowerShell 7 for now' = 'Ignorer PowerShell 7 pour le moment'
::         'Continue without changing the Windows Terminal default profile.' = 'Continuer sans modifier le profil par defaut de Windows Terminal.'
::         'Install PowerShell 7 now' = 'Installer PowerShell 7 maintenant'
::         'Reinstall or repair PowerShell 7' = 'Reinstaller ou reparer PowerShell 7'
::         'Install all AI CLI tools' = 'Installer toutes les CLI IA'
::         'Run Codex, OMX, OpenCode, Claude Code, Gemini CLI, and Oh My OpenCode Slim in one pass.' = 'Lancer Codex, OMX, OpenCode, Claude Code, Gemini CLI et Oh My OpenCode Slim en une seule passe.'
::         'Cleaner helper' = 'Assistant de nettoyage'
::         'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.' = 'Analyser les anciennes installations nvm/npm des CLI IA et les doublons du PATH avant nettoyage.'
::         'SYTA Install - Cleaner Helper' = 'SYTA Installation - Assistant de nettoyage'
::         'Target  : Cleaner helper' = 'Cible   : Assistant de nettoyage'
::         'Action  : Scan stale AI CLI installs and ask before removing old npm globals' = 'Action  : analyser les CLI IA obsoletes et demander avant de supprimer les npm globaux anciens'
::         'Scope   : Older nvm Node versions, duplicate PATH entries, user-scoped npm installs' = 'Portee  : anciennes versions Node nvm, doublons du PATH, installations npm utilisateur'
::         'Loading live tool diagnostics' = 'Chargement des diagnostics des outils'
::         'Checking Windows prerequisites' = 'Verification des prerequis Windows'
::         'Loading WSL tool diagnostics' = 'Chargement des diagnostics WSL'
::         'Preparing install options' = 'Preparation des options d''installation'
::         'Ubuntu is missing, so SYTA will show safe setup choices only.' = 'Ubuntu est absent, SYTA affiche donc uniquement des options d''installation sures.'
::         'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.' = 'Les diagnostics live etaient indisponibles, SYTA a bascule vers un menu d''installation de secours.'
::         'You can still install WSL Ubuntu or PowerShell 7 from here.' = 'Vous pouvez toujours installer WSL Ubuntu ou PowerShell 7 depuis ici.'
::         'Loading recent projects' = 'Chargement des projets recents'
::         'Scanning project folders' = 'Analyse des dossiers projet'
::         'Selected item' = 'Element selectionne'
::         'Press Enter to choose the focused item.' = 'Appuyez sur Entree pour choisir l''element selectionne.'
::         'Launcher Update Available' = 'Mise a jour du lanceur disponible'
::         'Update now' = 'Mettre a jour maintenant'
::         'Later' = 'Plus tard'
::         'Skip this version' = 'Ignorer cette version'
::         'Download the latest portable batch and replace the current launcher.' = 'Telecharger le dernier batch portable et remplacer le lanceur actuel.'
::         'Keep using this version and check again later.' = 'Continuer avec cette version et reverifier plus tard.'
::         'Do not prompt again for' = 'Ne plus proposer pour'
::         'Download' = 'Telechargement'
::         'Verify download' = 'Verification du telechargement'
::         'Replace launcher' = 'Remplacement du lanceur'
::         'Relaunch updated launcher' = 'Relance du lanceur mis a jour'
::         'SYTA was updated to' = 'SYTA a ete mis a jour vers'
::         'Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell' = 'Installer PowerShell 7 avec winget et definir PowerShell comme profil par defaut de Windows Terminal'
::         'Install via winget and set Windows Terminal default profile to PowerShell.' = 'Installer via winget et definir PowerShell comme profil par defaut de Windows Terminal.'
::         'Return to the main menu.' = 'Revenir au menu principal.'
::         'Return to the previous menu.' = 'Revenir au menu precedent.'
::         'Launch Preflight' = 'Pre-verification avant lancement'
::         'Full Update Preflight' = 'Pre-verification avant mise a jour complete'
::         'Light Update Preflight' = 'Pre-verification avant mise a jour legere'
::         'Install Preflight' = 'Pre-verification avant installation'
::         'A new terminal tab opens immediately after this screen' = 'Un nouvel onglet du terminal s''ouvre juste apres cet ecran'
::         'A PowerShell tab opens immediately after this screen' = 'Un onglet PowerShell s''ouvre juste apres cet ecran'
::         'SYTA WSL Ubuntu Install' = 'SYTA Installation WSL Ubuntu'
::         'SYTA PowerShell 7 Install' = 'SYTA Installation PowerShell 7'
::         'SYTA Install - All AI CLI Tools' = 'SYTA Installation - Toutes les CLI IA'
::         'SYTA Light Updater' = 'SYTA Mise a jour legere'
::         'SYTA Updater' = 'SYTA Mise a jour complete'
::         'Continue later' = 'Continuer plus tard'
::         'Target  : First install' = 'Cible   : Premiere installation'
::         'WSL     : Ubuntu already installed' = 'WSL     : Ubuntu deja installe'
::         'WSL     : Will run wsl --install -d Ubuntu' = 'WSL     : executera wsl --install -d Ubuntu'
::         'Power   : SYTA will ask whether to install PowerShell 7' = 'Power   : SYTA demandera s''il faut installer PowerShell 7'
::         'Power   : PowerShell 7 already installed; SYTA can repair it if needed' = 'Power   : PowerShell 7 deja installe ; SYTA peut le reparer si besoin'
::         'CLI     : Install all AI CLI tools once Ubuntu is ready' = 'CLI     : installer toutes les CLI IA une fois Ubuntu pret'
::         'Note    : Ubuntu setup may require a reboot or first-run Linux account creation before CLI installs can continue' = 'Note    : l''installation d''Ubuntu peut necessiter un redemarrage ou la creation initiale du compte Linux avant de poursuivre les CLI'
::         'Ubuntu setup was started in a separate PowerShell window.' = 'L''installation d''Ubuntu a ete lancee dans une fenetre PowerShell separee.'
::         'After Ubuntu finishes installing, rerun First install to continue with AI CLI tools.' = 'Une fois Ubuntu installe, relancez Premiere installation pour continuer avec les CLI IA.'
::         'You can also use Install all AI CLI tools later if Ubuntu is already ready.' = 'Vous pourrez aussi utiliser Installer toutes les CLI IA plus tard si Ubuntu est deja pret.'
::         'Unknown tool' = 'Outil inconnu'
::         'Auth via env key' = 'Auth via cle d''environnement'
::         'Auth/config detected' = 'Auth/config detectee'
::         'Auth n/a' = 'Auth n/a'
::         'WSL Ubuntu missing' = 'WSL Ubuntu absent'
::         'Auth not detected' = 'Auth non detectee'
::         'Auth unknown' = 'Auth inconnue'
::         'Installed' = 'Installe'
::         'Configured only' = 'Configuration detectee seulement'
::         'Missing' = 'Absent'
::         'version not detected' = 'version non detectee'
::         'binary not found on PATH' = 'binaire introuvable dans le PATH'
::         'not installed' = 'non installe'
::         'via nvm' = 'via nvm'
::         'user-local' = 'utilisateur local'
::         'system-wide' = 'systeme'
::         'config-only' = 'config seulement'
::         'custom path' = 'chemin personnalise'
::         'unknown source' = 'source inconnue'
::     }
::
::     if ($map.ContainsKey($Text)) { return $map[$Text] }
::     if ($Text -match '^Projects root: (.+)$') { return "Racine des projets : $($Matches[1])" }
::     if ($Text -match '^Build: (.+)$') { return "Build : $($Matches[1])" }
::     if ($Text -match '^Recent projects tracked: (.+)$') { return "Projets recents suivis : $($Matches[1])" }
::     if ($Text -match '^Hint: (.+)$') { return "Astuce : $(Localize-Text $Matches[1])" }
::     if ($Text -match '^Folder root: (.+)$') { return "Racine du dossier : $($Matches[1])" }
::     if ($Text -match '^Recent project in (.+)$') { return "Projet recent dans $($Matches[1])" }
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
:: function Invoke-ToolDiagnosticsBatchScript {
::     param([string[]]$Keys)
::
::     if (-not (Test-UbuntuInstalled) -or -not $Keys -or $Keys.Count -eq 0) {
::         return @{}
::     }
::
::     $scriptPath = Join-Path $script:ScriptDir 'syta-tool-diagnostics.sh'
::     $wslScriptPath = Get-WslPath -WindowsPath $scriptPath
::     $wslDir = Get-WslPath -WindowsPath $script:ScriptDir
::     $output = & wsl.exe --cd $wslDir --exec bash $wslScriptPath @Keys 2>$null
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
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     Write-BoxLine -Content $Status -Color $Accent
::     Write-BoxLine -Content ("Step {0}/{1}" -f $safeCurrent, $safeTotal) -Color DarkGray
::     Write-BoxLine -Content $bar -Color $Accent
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
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
::         'wsl-missing' { return (Localize-Text 'WSL Ubuntu missing') }
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
::     if (-not (Test-UbuntuInstalled)) {
::         $diag = [pscustomobject]@{
::             Key = $resolvedKey
::             Installed = $false
::             Path = $null
::             PathText = $spec.InstallHint
::             Version = $null
::             VersionText = (Localize-Text 'WSL Ubuntu missing')
::             AuthRaw = 'wsl-missing'
::             AuthText = (Localize-Text 'WSL Ubuntu missing')
::             InstallSource = 'unknown'
::             InstallText = (Localize-Text 'Missing')
::             MenuText = (Localize-Text 'WSL Ubuntu missing')
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
::     $statusText = if ($installed) { Localize-Text "Installed ($sourceLabel)" } elseif ($configPath) { Localize-Text 'Configured only' } else { Localize-Text 'Missing' }
::
::     $diag = [pscustomobject]@{
::         Key = $ResolvedKey
::         Installed = $installed
::         Path = $path
::         PathText = if ($path) { $path } elseif ($configPath) { $configPath } else { $spec.InstallHint }
::         Version = $version
::         VersionText = if ($installed) { if ($version) { $version } else { (Localize-Text 'version not detected') } } elseif ($configPath) { (Localize-Text 'binary not found on PATH') } else { (Localize-Text 'not installed') }
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
::     param([Parameter(Mandatory = $true)][string]$Key)
::
::     $resolvedKey = Resolve-ToolKey $Key
::     $spec = $script:ToolSpecs[$resolvedKey]
::     $diag = [pscustomobject]@{
::         Key = $resolvedKey
::         Installed = $false
::         Path = $null
::         PathText = $spec.InstallHint
::         Version = $null
::         VersionText = (Localize-Text 'WSL Ubuntu missing')
::         AuthRaw = 'wsl-missing'
::         AuthText = (Localize-Text 'WSL Ubuntu missing')
::         InstallSource = 'unknown'
::         InstallText = (Localize-Text 'Missing')
::         MenuText = (Localize-Text 'WSL Ubuntu missing')
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
::     if (-not (Test-UbuntuInstalled)) {
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
::     $script:ToolDiagCache = @{}
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
::         [int]$Width = 72
::     )
::
::     $render = Shorten-Text -Text (Localize-Text $Content) -Max $Width
::     Write-Host ('  | ' + $render.PadRight($Width) + ' |') -ForegroundColor $Color
:: }
::
:: function Write-WrappedBoxText {
::     param(
::         [string]$Content,
::         [ConsoleColor]$Color = [ConsoleColor]::Gray,
::         [int]$Width = 72
::     )
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
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkCyan
::     Write-BoxLine -Content 'SYTA AGENTIC LAUNCHER' -Color Cyan
::     Write-BoxLine -Content 'Made by Sylvain T.' -Color Magenta
::     Write-BoxLine -Content $Tagline -Color Gray
::     Write-BoxLine -Content "Projects root: $script:ProjectsRoot" -Color White
::     Write-BoxLine -Content "SYTA $script:ReleaseTag" -Color DarkGray
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
::         Write-Host ("   " + $frame.Bar + "  " + (Localize-Text $frame.Status)) -ForegroundColor $frame.Accent
::         Write-Host '   Made by Sylvain T.' -ForegroundColor Magenta
::         Write-Host ('   ' + (Localize-Text 'telemetry: launcher online, diagnostics cache cold, routes ready')) -ForegroundColor DarkGray
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
:: function Show-DetailPanel {
::     param(
::         [string]$Label,
::         [string]$Title,
::         [string]$Detail = '',
::         [ConsoleColor]$Accent = [ConsoleColor]::Cyan
::     )
::
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     $localizedLabel = Localize-Text $Label
::     Write-BoxLine -Content ("{0}: {1}" -f $localizedLabel, $Title) -Color $Accent
::     if ($Detail) {
::         Write-BoxLine -Content $Detail -Color Gray
::     }
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
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
::     $psArgs = @(
::         '-NoExit',
::         '-ExecutionPolicy', 'Bypass',
::         '-Command', "`$env:SYTA_LANGUAGE = '$($script:Language)'; `$Host.UI.RawUI.WindowTitle = '$Title'; $Command"
::     )
::
::     if ($DryRun) {
::         return [pscustomobject]@{
::             Title = $Title
::             Command = $Command
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
::             $label = Localize-Text $label
::             $detail = Localize-Text $detail
::             Write-Host ('  ' + $prefix + (Shorten-Text -Text $label -Max 76)) -ForegroundColor $titleColor
::             if ($detail) {
::                 Write-Host ('     ' + (Shorten-Text -Text $detail -Max 74)) -ForegroundColor $detailColor
::             }
::             Write-Host ''
::         }
::
::         $selectedItem = $Items[$index]
::         $selectedLabel = if ($selectedItem.PSObject.Properties.Match('Title').Count) { $selectedItem.Title } else { [string]$selectedItem }
::         $selectedDetail = if ($selectedItem.PSObject.Properties.Match('Subtitle').Count) { $selectedItem.Subtitle } else { '' }
::         $selectedAccent = if ($selectedItem.PSObject.Properties.Match('Accent').Count) { $selectedItem.Accent } else { 'Cyan' }
::         Show-DetailPanel -Label 'Selected item' -Title $selectedLabel -Detail $selectedDetail -Accent $selectedAccent
::
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-BoxLine -Content 'Press Enter to choose the focused item.' -Color Gray
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
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     foreach ($line in $Lines) {
::         Write-WrappedBoxText -Content $line -Color Cyan
::     }
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     Write-BoxLine -Content 'Press any key to return.' -Color Gray
::     Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::     [void][Console]::ReadKey($true)
:: }
::
:: function Launch-ExplanationsMode {
::     while ($true) {
::         $selection = Read-Menu -Title 'Explanations' -Subtitle 'Learn what the tools are, who they are for, and what SYTA recommends.' -Items @(
::             [pscustomobject]@{ Title = 'Beginner guide'; Subtitle = 'Ultra-beginner explanation of each tool and the easiest path through SYTA.'; Accent = 'Cyan'; Key = 'beginner' }
::             [pscustomobject]@{ Title = 'Advanced guide'; Subtitle = 'Higher-level tradeoffs, workflows, and why you might pick one tool over another.'; Accent = 'Yellow'; Key = 'advanced' }
::             [pscustomobject]@{ Title = 'What should I install?'; Subtitle = 'Straight recommendation based on simplicity, budget, and how hands-off you want setup to be.'; Accent = 'Green'; Key = 'recommend' }
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
::                     'Codex: OpenAI coding agent with strong editing and reasoning.',
::                     'OMX: power-user wrapper around Codex for planning, orchestration, and heavier workflows.',
::                     'OpenCode: lightweight coding CLI and usually the easiest first start.',
::                     'Claude Code and Gemini CLI: best if you already use those ecosystems.',
::                     'Best beginner path: Install -> First install, then start with OpenCode or Codex.',
::                     'Oh My OpenCode Slim is an OpenCode add-on. It is separate from OpenAgent.'
::                 )
::             }
::             'advanced' {
::                 Show-ExplanationPanel -Title 'Advanced guide' -Lines @(
::                     'Codex is the direct OpenAI lane; OMX adds more opinionated automation and orchestration.',
::                     'OpenCode is often the lightest workflow; Codex and OMX are better when you want stronger guided execution.',
::                     'Install only the CLIs you will actually use. More tools means more auth, updates, and overlap.',
::                     'Oh My OpenCode Slim stays focused on OpenCode helpers. It is not Oh My OpenAgent, which is heavier and more token-expensive.'
::                 )
::             }
::             'recommend' {
::                 Show-ExplanationPanel -Title 'What should I install?' -Lines @(
::                     'Brand-new Windows machine: Install -> First install.',
::                     'Lowest-friction start: OpenCode.',
::                     'Best OpenAI-first path: Codex, then OMX if you want deeper automation.',
::                     'Install Oh My OpenCode Slim only if you already like OpenCode and want extra helpers.',
::                     'Skip tools you do not have keys, subscriptions, or a real workflow for.'
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
:: function Prompt-NewProject {
::     while ($true) {
::         Clear-Host
::         Write-Banner -Tagline 'Create New Project' -Hint 'Leave blank to cancel'
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
::         Write-BoxLine -Content "Folder root: $script:ProjectsRoot" -Color DarkGray
::         Write-BoxLine -Content 'Choose a short Windows-safe folder name.' -Color Gray
::         Write-Host '  +----------------------------------------------------------------------+' -ForegroundColor DarkGray
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
::     Show-LoadProgress -Title 'Project Selector' -Status 'Scanning project folders' -Current 2 -Total 2 -Accent White
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
::                 $query = Read-Host (Localize-Text '   Search term')
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
::     if ($ubuntuInstalled) {
::         Warm-ToolDiagnosticsCache -Keys @('codex', 'omx', 'opencode', 'claude-code', 'gemini-cli', 'oh-my-opencode-slim')
::         $codexDiag = Get-ToolDiagnostics -Key 'codex'
::         $omxDiag = Get-ToolDiagnostics -Key 'omx'
::         $opencodeDiag = Get-ToolDiagnostics -Key 'opencode'
::         $claudeDiag = Get-ToolDiagnostics -Key 'claude-code'
::         $geminiDiag = Get-ToolDiagnostics -Key 'gemini-cli'
::         $omoDiag = Get-ToolDiagnostics -Key 'oh-my-opencode-slim'
::     } else {
::         $codexDiag = New-WslMissingToolDiagnostics -Key 'codex'
::         $omxDiag = New-WslMissingToolDiagnostics -Key 'omx'
::         $opencodeDiag = New-WslMissingToolDiagnostics -Key 'opencode'
::         $claudeDiag = New-WslMissingToolDiagnostics -Key 'claude-code'
::         $geminiDiag = New-WslMissingToolDiagnostics -Key 'gemini-cli'
::         $omoDiag = New-WslMissingToolDiagnostics -Key 'oh-my-opencode-slim'
::     }
::
::     return @(
::         [pscustomobject]@{
::             Title = 'First install (recommended)'
::             Subtitle = 'Best beginner path for WSL Ubuntu, optional PowerShell 7, and all AI CLI tools.'
::             Accent = if ($ubuntuInstalled -and $pwshInfo.Installed) { 'Green' } else { 'Yellow' }
::             Key = 'first-install'
::         }
::         [pscustomobject]@{
::             Title = 'WSL Ubuntu'
::             Subtitle = if ($ubuntuInstalled) { "Installed | distros: $(@(Get-WslDistros).Count)" } else { 'Missing | runs wsl --install -d Ubuntu' }
::             Accent = if ($ubuntuInstalled) { 'Green' } else { 'Yellow' }
::             Key = 'wsl-ubuntu'
::         }
::         [pscustomobject]@{ Title = 'PowerShell 7'; Subtitle = $pwshInfo.MenuText; Accent = if ($pwshInfo.Installed) { 'Green' } else { 'Yellow' }; Key = 'powershell-7' }
::         [pscustomobject]@{ Title = 'Install all AI CLI tools'; Subtitle = if ($ubuntuInstalled) { 'Run Codex, OMX, OpenCode, Claude Code, Gemini CLI, and Oh My OpenCode Slim in one pass.' } else { 'WSL Ubuntu missing | install Ubuntu first.' }; Accent = if ($ubuntuInstalled) { 'Green' } else { 'Yellow' }; Key = 'all-ai-cli-tools' }
::         [pscustomobject]@{ Title = 'Cleaner helper'; Subtitle = if ($ubuntuInstalled) { 'Scan old nvm/npm AI CLI installs and duplicate PATH hits before cleaning.' } else { 'WSL Ubuntu missing | install Ubuntu first.' }; Accent = if ($ubuntuInstalled) { 'Cyan' } else { 'Yellow' }; Key = 'cleaner-helper' }
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
:: function Invoke-WslUbuntuInstallFlow {
::     Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell tab opens immediately after this screen' -Lines @(
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
::     return $null
:: }
::
:: function Invoke-PowerShell7InstallFlow {
::     $pwshInfo = Get-PwshInfo
::     $pwshStatus = if ($pwshInfo.Installed) { 'Installed' } else { 'Missing' }
::     Show-InfoBox -Title 'Install Preflight' -Accent Yellow -Hint 'A PowerShell tab opens immediately after this screen' -Lines @(
::         'Target  : PowerShell 7',
::         "Current : $pwshStatus",
::         "Version : $($pwshInfo.Version)",
::         'Action  : Install PowerShell 7 with winget and set Windows Terminal default profile to PowerShell'
::     )
::     $scriptPath = Join-Path $script:ScriptDir 'syta-install-powershell7.ps1'
::     $result = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA PowerShell 7 Install') -Command ("& '$scriptPath'")
::     if ($DryRun) {
::         return $result
::     }
::     Start-Sleep -Milliseconds 500
::     return $null
:: }
::
:: function Invoke-AllAiCliInstallFlow {
::     Show-InfoBox -Title 'Install Preflight' -Accent Cyan -Hint 'A new terminal tab opens immediately after this screen' -Lines (@(
::         'Target  : Install all AI CLI tools',
::         'Scope   : Codex, OMX, OpenCode, Claude Code, Gemini CLI, Oh My OpenCode Slim'
::     ) + (Get-CodingCliSummaryLines))
::
::     $result = Open-WslWindow `
::         -Title (Localize-Text 'SYTA Install - All AI CLI Tools') `
::         -WindowsDirectory $script:ScriptDir `
::         -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::         -ScriptArguments @('install', 'all-ai-cli-tools', $script:Language)
::
::     if ($DryRun) {
::         return $result
::     }
::
::     Start-Sleep -Milliseconds 500
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
::     return $null
:: }
::
:: function Invoke-FirstInstallFlow {
::     $ubuntuInstalled = Test-UbuntuInstalled
::     $pwshInfo = Get-PwshInfo
::     $wslLine = if ($ubuntuInstalled) { 'WSL     : Ubuntu already installed' } else { 'WSL     : Will run wsl --install -d Ubuntu' }
::     $powerLine = if ($pwshInfo.Installed) { 'Power   : PowerShell 7 already installed; SYTA can repair it if needed' } else { 'Power   : SYTA will ask whether to install PowerShell 7' }
::
::     $cliLine = if ($ubuntuInstalled) { 'CLI     : Ready to launch all AI CLI tools now' } else { 'CLI     : Full AI CLI install starts after Ubuntu is ready' }
::     $lines = @(
::         'Target  : First install',
::         $wslLine,
::         $powerLine,
::         $cliLine,
::         'Note    : Recommended path for a new machine or first SYTA setup'
::     )
::     if (-not $ubuntuInstalled) {
::         $lines += 'Note    : Ubuntu setup may require a reboot or first-run Linux account creation before CLI installs can continue'
::     }
::
::     Show-InfoBox -Title 'First Install' -Accent Yellow -Hint 'SYTA keeps this selector open while new tabs launch' -Lines $lines
::
::     $result = [ordered]@{
::         WslInstall = $null
::         PowerShellInstall = $null
::         CliInstall = $null
::         RequiresRerunAfterUbuntuSetup = -not $ubuntuInstalled
::     }
::
::     if ($DryRun) {
::         $scriptPath = Join-Path $script:ScriptDir 'syta-install-powershell7.ps1'
::         if (-not $ubuntuInstalled) {
::             $result.WslInstall = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA WSL Ubuntu Install') -Command 'wsl --install -d Ubuntu'
::         }
::
::         $result.PowerShellPrompt = if ($pwshInfo.Installed) {
::             'would-ask-repair-or-skip'
::         } else {
::             'would-ask-install-or-skip'
::         }
::         $result.PowerShellInstall = Open-WindowsPowerShellWindow -Title (Localize-Text 'SYTA PowerShell 7 Install') -Command ("& '$scriptPath'")
::
::         if ($ubuntuInstalled) {
::             $result.CliInstall = Open-WslWindow `
::                 -Title (Localize-Text 'SYTA Install - All AI CLI Tools') `
::                 -WindowsDirectory $script:ScriptDir `
::                 -WindowsScriptPath (Join-Path $script:ScriptDir 'syta-wsl-session.sh') `
::                 -ScriptArguments @('install', 'all-ai-cli-tools', $script:Language)
::         }
::
::         return [pscustomobject]$result
::     }
::
::     if (-not $ubuntuInstalled) {
::         $result.WslInstall = Invoke-WslUbuntuInstallFlow
::     }
::
::     if (Prompt-PowerShell7Choice -Installed $pwshInfo.Installed) {
::         $result.PowerShellInstall = Invoke-PowerShell7InstallFlow
::     }
::
::     if (-not $ubuntuInstalled) {
::         Show-InfoBox -Title 'Continue later' -Accent Yellow -Hint 'Back' -Lines @(
::             'Ubuntu setup was started in a separate PowerShell window.',
::             'After Ubuntu finishes installing, rerun First install to continue with AI CLI tools.',
::             'You can also use Install all AI CLI tools later if Ubuntu is already ready.'
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
::     $script:ToolDiagCache = @{}
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
:: }
::
:: function Launch-InstallMode {
::     $selection = if ($InstallTarget) {
::         (Get-InstallItems | Where-Object Key -eq $InstallTarget | Select-Object -First 1)
::     } else {
::         try {
::             Show-LoadProgress -Title 'Installer' -Status 'Checking Windows prerequisites' -Current 1 -Total 2 -Accent Yellow
::             $ubuntuInstalled = Test-UbuntuInstalled
::             $null = Get-PwshInfo
::             if ($ubuntuInstalled) {
::                 Show-LoadProgress -Title 'Installer' -Status 'Loading WSL tool diagnostics' -Current 2 -Total 2 -Accent Cyan
::             } else {
::                 Show-LoadProgress -Title 'Installer' -Status 'Preparing install options' -Detail 'Ubuntu is missing, so SYTA will show safe setup choices only.' -Current 2 -Total 2 -Accent Yellow
::             }
::             Read-Menu -Title 'Installer' -Subtitle 'Install or repair WSL Ubuntu and supported coding CLIs.' -Items (Get-InstallItems)
::         } catch {
::             Show-InfoBox -Title 'Installer' -Accent Yellow -Hint 'Back' -Lines @(
::                 'Live diagnostics were unavailable, so SYTA switched to a safe fallback install menu.',
::                 'You can still install WSL Ubuntu or PowerShell 7 from here.'
::             )
::             Read-Menu -Title 'Installer' -Subtitle 'Install or repair WSL Ubuntu and supported coding CLIs.' -Items @(
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
::     oh-my-opencode-slim)
::       [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ] && config="$HOME/.config/opencode/oh-my-opencode-slim.json" && auth='config-present'
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
::   if [ "$key" = 'oh-my-opencode-slim' ] && [ -n "$config" ]; then
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
:: $script:Language = if (("$env:SYTA_LANGUAGE" -match '^fr') -or ("$env:SYTA_LANG" -match '^fr')) { 'fr' } else { 'en' }
::
:: function T {
::     param([string]$En, [string]$Fr)
::     if ($script:Language -eq 'fr') { return $Fr }
::     return $En
:: }
::
:: function Write-Stage {
::     param([string]$En, [string]$Fr)
::     Write-Host ''
::     Write-Host ("== " + (T $En $Fr) + " ==") -ForegroundColor Cyan
:: }
::
:: function Set-WindowsTerminalDefaultPowerShellProfile {
::     $wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
::     if (-not (Test-Path -LiteralPath $wtPath)) {
::         Write-Host (T 'Windows Terminal settings.json not found. Skipping default-profile update.' 'settings.json de Windows Terminal introuvable. Mise a jour du profil par defaut ignoree.') -ForegroundColor Yellow
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
::     Write-Host (T 'Windows Terminal default profile set to PowerShell.' 'Le profil par defaut de Windows Terminal a ete defini sur PowerShell.') -ForegroundColor Green
:: }
::
:: Write-Stage 'Install PowerShell 7' 'Installer PowerShell 7'
:: if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
::     throw (T 'winget.exe is not available on this Windows system.' 'winget.exe n''est pas disponible sur ce systeme Windows.')
:: }
::
:: winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
::
:: Write-Stage 'Verify pwsh' 'Verifier pwsh'
:: $pwsh = Get-Command pwsh.exe -ErrorAction Stop
:: & $pwsh.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
::
:: Write-Stage 'Set Windows Terminal default profile' 'Definir le profil par defaut Windows Terminal'
:: Set-WindowsTerminalDefaultPowerShellProfile
::
:: Write-Host ''
:: Write-Host (T 'PowerShell 7 install flow completed.' 'Flux d''installation PowerShell 7 termine.') -ForegroundColor Green
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
::
:: normalize_lang() {
::   case "${1:-auto}" in
::     fr*|FR*) printf 'fr\n' ;;
::     en*|EN*) printf 'en\n' ;;
::     *) printf 'en\n' ;;
::   esac
:: }
::
:: msg() {
::   local key="$1"
::   local value="${2:-}"
::   if [ "$lang" = 'fr' ]; then
::     case "$key" in
::       missing_agent) printf 'Cle agent manquante.\n' ;;
::       missing_install) printf 'Cible d''installation manquante.\n' ;;
::       unknown_mode) printf 'Mode de session inconnu : %s\n' "$value" ;;
::       leaving_shell) printf 'Le shell %s reste ouvert pour le workspace.\n' "$value" ;;
::       session_exit) printf 'Code de sortie de session : %s\n' "$value" ;;
::     esac
::   else
::     case "$key" in
::       missing_agent) printf 'Missing agent key.\n' ;;
::       missing_install) printf 'Missing install target.\n' ;;
::       unknown_mode) printf 'Unknown session mode: %s\n' "$value" ;;
::       leaving_shell) printf 'Leaving %s open for the workspace.\n' "$value" ;;
::       session_exit) printf 'Session exit code: %s\n' "$value" ;;
::     esac
::   fi
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
:: payload="$runner_cmd; syta_rc=\$?; printf '\n'; msg session_exit \"\$syta_rc\"; printf '\n'; msg leaving_shell $(quote_arg "$shell_bin"); exec $(quote_arg "$shell_bin") -i"
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
::   if [ "$lang" = 'fr' ]; then
::     case "$key" in
::       workspace) printf ' Espace de travail : %s\n' "$value" ;;
::       missing_bash) printf 'bash n''est pas disponible dans cet environnement WSL.\n' ;;
::       current_path) printf 'PATH actuel : %s\n' "$value" ;;
::       codex_missing) printf 'codex n''est pas disponible dans le PATH.\n' ;;
::       omx_missing) printf 'omx n''est pas disponible dans le PATH.\n' ;;
::       opencode_missing) printf 'opencode n''est pas disponible dans le PATH.\n' ;;
::       claude_missing) printf 'claude n''est pas disponible dans le PATH.\n' ;;
::       gemini_missing) printf 'gemini n''est pas disponible dans le PATH.\n' ;;
::       launch_codex) printf 'Lancement de Codex YOLO...\n\n' ;;
::       launch_omx) printf 'Lancement de OMX MADMAX HIGH...\n\n' ;;
::       launch_opencode) printf 'Lancement de OpenCode...\n\n' ;;
::       launch_claude) printf 'Lancement de Claude Code...\n\n' ;;
::       launch_gemini) printf 'Lancement de Gemini CLI...\n\n' ;;
::       unknown_agent) printf 'Cle agent inconnue : %s\n' "$value" ;;
::       agent_exit) printf '\nL''agent s''est termine avec le code %s.\n' "$value" ;;
::       session_end) printf '\nSession agent terminee.\n' ;;
::     esac
::   else
::     case "$key" in
::       workspace) printf ' Workspace: %s\n' "$value" ;;
::       missing_bash) printf 'bash is not available in this WSL environment.\n' ;;
::       current_path) printf 'Current PATH: %s\n' "$value" ;;
::       codex_missing) printf 'codex is not available in PATH.\n' ;;
::       omx_missing) printf 'omx is not available in PATH.\n' ;;
::       opencode_missing) printf 'opencode is not available in PATH.\n' ;;
::       claude_missing) printf 'claude is not available in PATH.\n' ;;
::       gemini_missing) printf 'gemini is not available in PATH.\n' ;;
::       launch_codex) printf 'Launching Codex YOLO...\n\n' ;;
::       launch_omx) printf 'Launching OMX MADMAX HIGH...\n\n' ;;
::       launch_opencode) printf 'Launching OpenCode...\n\n' ;;
::       launch_claude) printf 'Launching Claude Code...\n\n' ;;
::       launch_gemini) printf 'Launching Gemini CLI...\n\n' ;;
::       unknown_agent) printf 'Unknown agent key: %s\n' "$value" ;;
::       agent_exit) printf '\nAgent exited with status %s.\n' "$value" ;;
::       session_end) printf '\nAgent session ended.\n' ;;
::     esac
::   fi
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
:: if ! run_agent; then rc=$?; msg agent_exit "$rc"; exit "$rc"; fi
:: msg session_end
::
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
:: show_header
:: load_user_env
::
:: status=0
:: case "$tool_key" in
::   all-ai-cli-tools) install_all_ai_cli_tools || status=$? ;;
::   cleaner-helper) run_cleaner_helper || status=$? ;;
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
:: function Write-Stage {
::     param([string]$Text)
::     Write-Host ''
::     Write-Host ("== " + $Text + " ==") -ForegroundColor Cyan
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
::     throw 'wsl.exe was not found on this Windows system.'
:: }
::
:: Write-Stage 'Install WSL Ubuntu'
:: & $wslExe --install -d Ubuntu
::
:: Write-Host ''
:: Write-Host 'WSL Ubuntu install command completed.' -ForegroundColor Green
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
:: function Write-Stage {
::     param([string]$Text)
::     Write-Host ''
::     Write-Host ("== " + $Text + " ==") -ForegroundColor Cyan
:: }
::
:: if (-not (Test-Path -LiteralPath (Split-Path -Parent $TargetPath))) {
::     throw "Target folder not found: $TargetPath"
:: }
::
:: $tempFile = Join-Path $env:TEMP ("syta-super-launcher-" + $ReleaseTag + ".bat")
::
:: Write-Stage "Download $ReleaseTag"
:: Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempFile -UseBasicParsing
::
:: if ($ExpectedDigest) {
::     Write-Stage 'Verify digest'
::     $actualDigest = (Get-FileHash -LiteralPath $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
::     $expected = ($ExpectedDigest -replace '^sha256:', '').ToLowerInvariant()
::     if ($actualDigest -ne $expected) {
::         throw "Downloaded launcher digest mismatch. Expected $expected, got $actualDigest."
::     }
:: }
::
:: Write-Stage 'Replace launcher'
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
::     throw "Unable to replace launcher at $TargetPath."
:: }
::
:: Write-Stage 'Relaunch launcher'
:: Start-Process -FilePath $TargetPath | Out-Null
::
:: Write-Host ''
:: Write-Host "Launcher updated to $ReleaseTag and relaunched." -ForegroundColor Green
::END:syta-self-update.ps1
