<#
.SYNOPSIS
    Installeer claude-skills (alle of specifieke) op Windows 11.

.DESCRIPTION
    Idempotent: tweede run doet git pull in plaats van clone.
    Kopieert skills naar %APPDATA%\Claude\skills en installeert tool-adapters
    (Copilot .instructions.md, Codex/ClaudeCode AGENTS.md).

.PARAMETER SkillFilter
    Optioneel: naam van een specifieke skill om alleen die te installeren.

.EXAMPLE
    .\install.ps1
    .\install.ps1 taskfiles
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$SkillFilter = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoUrl   = 'https://github.com/brechtparmentier/claude-skills.git'
$CacheDir  = if ($env:CLAUDE_SKILLS_CACHE) { $env:CLAUDE_SKILLS_CACHE }
             else { Join-Path $env:USERPROFILE '.cache\claude-skills' }
$TargetDir = Join-Path $env:USERPROFILE '.claude\skills'

function Write-Info  ([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok    ([string]$msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn  ([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   ([string]$msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

# Stap 1 — clone of pull cache
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

if (Test-Path (Join-Path $CacheDir '.git')) {
    Write-Info "Updating cache: $CacheDir"
    git -C $CacheDir fetch --tags --prune --quiet
    git -C $CacheDir pull --rebase --quiet
} else {
    Write-Info "Cloning: $RepoUrl → $CacheDir"
    git clone --quiet $RepoUrl $CacheDir
}

# Stap 2 — bepaal welke skills te installeren
$skillDirs = Get-ChildItem -Path $CacheDir -Recurse -Filter 'SKILL.md' -Depth 2 |
             Select-Object -ExpandProperty DirectoryName

if ($SkillFilter) {
    $filtered = $skillDirs | Where-Object { (Split-Path $_ -Leaf) -eq $SkillFilter }
    if (-not $filtered) {
        Write-Err "Skill '$SkillFilter' niet gevonden in $CacheDir"
        Write-Host "Beschikbaar:"
        $skillDirs | ForEach-Object { Write-Host "  - $(Split-Path $_ -Leaf)" }
        exit 1
    }
    $skillDirs = @($filtered)
}

$skills = @($skillDirs | ForEach-Object { Split-Path $_ -Leaf })

# Stap 3 — kopieer elke skill naar target dir
foreach ($skill in $skills) {
    $src = Join-Path $CacheDir $skill
    $dst = Join-Path $TargetDir $skill

    if (Test-Path $dst) {
        $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
        Write-Warn "$dst bestaat al — verplaats naar .backup-$ts"
        Rename-Item -Path $dst -NewName "${skill}.backup-${ts}"
    }

    Copy-Item -Path $src -Destination $dst -Recurse -Force

    $version = Select-String -Path (Join-Path $src 'SKILL.md') -Pattern '^version:' |
               Select-Object -First 1 | ForEach-Object { ($_.Line -split '\s+')[1] }
    Write-Ok "$skill v$($version ?? '?') → $dst"
}

Write-Host ""
Write-Ok "$($skills.Count) skill(s) geïnstalleerd in $TargetDir"
Write-Host "Test in een nieuwe Copilot/Claude Code sessie."

# Stap 4 — tool-adapters installeren
$VSCodePromptsDir = Join-Path $env:APPDATA 'Code\User\prompts'

function Install-Adapter {
    param([string]$Src, [string]$Dst, [string]$Label)
    if (-not $Dst) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dst) | Out-Null
    if (Test-Path $Dst) {
        $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
        Write-Warn "$Dst bestaat → .backup-$ts"
        Rename-Item -Path $Dst -NewName "$(Split-Path $Dst -Leaf).backup-${ts}"
    }
    Copy-Item -Path $Src -Destination $Dst -Force
    Write-Ok "$(($Label).PadRight(16)) → $Dst"
}

foreach ($skill in $skills) {
    $srcDir = Join-Path $CacheDir $skill

    # Copilot .instructions.md → VS Code prompts map
    $copilotSrc = Join-Path $srcDir "${skill}.instructions.md"
    if (Test-Path $copilotSrc) {
        Install-Adapter -Src $copilotSrc `
                        -Dst (Join-Path $VSCodePromptsDir "${skill}.instructions.md") `
                        -Label 'Copilot'
    }

    # Codex / ClaudeCode AGENTS.md
    $agentsSrc = Join-Path $srcDir 'AGENTS.md'
    if (Test-Path $agentsSrc) {
        Install-Adapter -Src $agentsSrc `
                        -Dst (Join-Path $env:USERPROFILE ".codex\AGENTS\${skill}.md") `
                        -Label 'Codex'
        Install-Adapter -Src $agentsSrc `
                        -Dst (Join-Path $env:USERPROFILE ".claude\AGENTS\${skill}.md") `
                        -Label 'ClaudeCode'
    }
}
