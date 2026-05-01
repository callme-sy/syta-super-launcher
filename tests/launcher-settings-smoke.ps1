param(
    [string]$LauncherPath = (Join-Path $PSScriptRoot '..\syta-super-launcher.bat')
)

$ErrorActionPreference = 'Stop'

function Invoke-LauncherJson {
    param(
        [Parameter(Mandatory = $true)][string]$Launcher,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $argumentString = ($Arguments | ForEach-Object {
        if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ }
    }) -join ' '

    $raw = cmd.exe /d /c ('"{0}" {1}' -f $Launcher, $argumentString) | Out-String
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Launcher returned no output for: $argumentString"
    }

    $lines = $raw -split "`r?`n"
    $jsonStart = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimStart().StartsWith('{')) {
            $jsonStart = $i
            break
        }
    }

    if ($jsonStart -lt 0) {
        throw "Launcher output did not contain JSON for: $argumentString`n$raw"
    }

    $jsonText = (($lines[$jsonStart..($lines.Count - 1)]) -join [Environment]::NewLine).Trim()
    try {
        return $jsonText | ConvertFrom-Json
    } catch {
        throw "Launcher output was not valid JSON for: $argumentString`n$raw"
    }
}

$resolvedLauncher = (Resolve-Path -LiteralPath $LauncherPath).ProviderPath
$testRoot = Join-Path $env:TEMP ('syta-launcher-settings-smoke-' + [guid]::NewGuid().ToString('N'))
$settingsDir = Join-Path $testRoot 'config'
$projectsRoot = Join-Path $testRoot 'ProjectsRoot'
$settingsFile = Join-Path $settingsDir 'launcher-settings.json'

$null = New-Item -ItemType Directory -Path $settingsDir -Force
$null = New-Item -ItemType Directory -Path $projectsRoot -Force

@{
    projectsRoot = $projectsRoot
    uiLanguage = 'en'
    uiLanguagePrompted = $true
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile -Encoding utf8

$env:SYTA_SETTINGS_FILE = $settingsFile

try {
    $smoke = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-SmokeTest', '-NoAnimation')
    if ($smoke.ProjectsRoot -ne $projectsRoot) {
        throw "Expected ProjectsRoot '$projectsRoot' but got '$($smoke.ProjectsRoot)'."
    }

    if ($smoke.GlobalSettingsFile -ne $settingsFile) {
        throw "Expected GlobalSettingsFile '$settingsFile' but got '$($smoke.GlobalSettingsFile)'."
    }

    if (-not (@($smoke.MainMenuKeys) -contains 'Settings')) {
        throw 'Expected SmokeTest.MainMenuKeys to include Settings.'
    }

    $codeMenu = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'Code', '-DryRun', '-NoAnimation')
    if ($codeMenu.AgentDiagnostics -ne 'deferred-until-agent-selected') {
        throw "Expected Code dry-run to defer agent diagnostics but got '$($codeMenu.AgentDiagnostics)'."
    }

    if (-not ($codeMenu.Items | Where-Object Key -eq 'codex-yolo')) {
        throw 'Expected Code dry-run menu to include codex-yolo.'
    }

    if ($codeMenu.Items | Where-Object { "$($_.Subtitle)" -match 'Auth|version|Installed|Missing' }) {
        throw 'Expected Code dry-run menu to avoid live diagnostic status in agent subtitles.'
    }

    $settingsMenu = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'Settings', '-DryRun', '-NoAnimation')
    if (-not ($settingsMenu.Items | Where-Object Key -eq 'projects-root')) {
        throw 'Expected Settings dry-run menu to include a projects-root item.'
    }

    $updateMenu = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'Update', '-DryRun', '-NoAnimation')
    if (-not ($updateMenu.Items | Where-Object Key -eq 'LauncherUpdate')) {
        throw 'Expected Update dry-run menu to include a LauncherUpdate item.'
    }

    $launcherUpdate = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'LauncherUpdate', '-DryRun', '-NoAnimation')
    if (-not $launcherUpdate.ForceRefresh) {
        throw 'Expected LauncherUpdate dry-run to force a fresh release lookup.'
    }

    if (-not $launcherUpdate.IgnoreDismissed) {
        throw 'Expected LauncherUpdate dry-run to ignore dismissed-release gating.'
    }

    $extraMenu = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'Extra', '-DryRun', '-NoAnimation')
    if ($extraMenu.Items | Where-Object Key -eq 'settings') {
        throw 'Expected Extra dry-run menu to stop exposing launcher settings.'
    }

    $updateUtilities = Invoke-LauncherJson -Launcher $resolvedLauncher -Arguments @('-Mode', 'UpdateUtilities', '-DryRun', '-NoAnimation')
    if ($updateUtilities.WindowsDirectory -ne $projectsRoot) {
        throw "Expected UpdateUtilities dry-run to use '$projectsRoot' but got '$($updateUtilities.WindowsDirectory)'."
    }

    Write-Host 'launcher-settings-smoke: PASS'
} finally {
    Remove-Item Env:SYTA_SETTINGS_FILE -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
