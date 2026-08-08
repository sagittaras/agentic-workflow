<#
.SYNOPSIS
    Nainstaluje nebo aktualizuje plugin sagittaras do uživatelské konfigurace Claude Code.

.DESCRIPTION
    Plugin se klonuje do ~/.claude/skills/sagittaras, odkud ho Claude Code načte
    nad všemi projekty. Skript je idempotentní: chybí-li cíl, naklonuje ho;
    existuje-li, přetáhne novinky z remotu. Nic nemaže — cizí nebo rozpracovaný
    obsah v cíli ohlásí a skončí, úklid nechá na uživateli.

.PARAMETER Target
    Cílová složka instalace. Výchozí ~/.claude/skills/sagittaras.

.PARAMETER Ref
    Větev, ze které se instaluje. Výchozí main.

.PARAMETER Https
    Klonuje přes HTTPS místo SSH — pro stroje bez nahraného SSH klíče.

.EXAMPLE
    ./install.ps1

.EXAMPLE
    ./install.ps1 -Https -Ref develop
#>
[CmdletBinding()]
param(
    [string]$Target,
    [string]$Ref = 'main',
    [switch]$Https
)

$ErrorActionPreference = 'Stop'

$RepoSlug   = 'sagittaras/agentic-workflow'
$PluginName = 'sagittaras'
$Remote     = if ($Https) { "https://github.com/$RepoSlug.git" } else { "git@github.com:$RepoSlug.git" }

if (-not $Target) {
    $configDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
    $Target = Join-Path $configDir "skills\$PluginName"
}

function Write-Info { param($Message) Write-Host "  $Message" }
function Write-Ok   { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "! $Message" -ForegroundColor Yellow }
function Write-Err  { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }

# Vytáhne z URL remotu tvar 'vlastník/repo', aby šly porovnat SSH i HTTPS varianty.
function ConvertTo-RepoSlug {
    param([string]$Url)
    if (-not $Url) { return '' }
    $Url -replace '^git\+?ssh://', '' `
         -replace '^git@[^:/]+[:/]', '' `
         -replace '^https?://[^/]+/', '' `
         -replace '\.git$', ''
}

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    $output = & git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "git $($Arguments -join ' ') selhalo:"
        Write-Info ($output -join [Environment]::NewLine)
        exit 1
    }
    return $output
}

# --- předpoklady ---------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err 'git není v PATH — bez něj instalaci nelze provést.'
    exit 1
}

# --- instalace nebo aktualizace ------------------------------------------
if (Test-Path -LiteralPath $Target) {
    # Ne test na složku .git — u worktree a submodulu je to soubor a legitimní
    # instalace by se označila za cizí obsah k ručnímu úklidu.
    & git -C $Target rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "V $Target už něco je, ale není to git repozitář."
        Write-Info 'Zkontroluj obsah a odstraň ho ručně, pak spusť skript znovu.'
        exit 2
    }

    $actual = (& git -C $Target remote get-url origin 2>$null) -join ''
    if ((ConvertTo-RepoSlug $actual) -ne $RepoSlug) {
        $shown = if ($actual) { $actual } else { '<žádný>' }
        Write-Err "V $Target je repozitář s cizím remotem: $shown"
        Write-Info "Očekáván $RepoSlug. Přesuň ho stranou a spusť skript znovu."
        exit 2
    }

    $dirty = (& git -C $Target status --porcelain) -join ''
    if ($dirty) {
        Write-Warn "Instalace v $Target má necommitnuté změny — aktualizaci přeskakuji."
        Write-Info 'Ulož je, nebo zahoď, a spusť skript znovu.'
    }
    else {
        Write-Info "Aktualizuji $Target …"
        Invoke-Git -C $Target fetch --quiet origin $Ref | Out-Null
        Invoke-Git -C $Target checkout --quiet $Ref | Out-Null
        Invoke-Git -C $Target merge --ff-only --quiet "origin/$Ref" | Out-Null
        Write-Ok "Aktualizováno na $(& git -C $Target rev-parse --short HEAD) ($Ref)."
    }
}
else {
    Write-Info "Klonuji $RepoSlug do $Target …"
    $parent = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Invoke-Git clone --quiet --branch $Ref $Remote $Target | Out-Null
    Write-Ok "Nainstalováno do $Target ($(& git -C $Target rev-parse --short HEAD))."
}

# --- ověření -------------------------------------------------------------
if (-not (Test-Path -LiteralPath (Join-Path $Target '.claude-plugin\plugin.json'))) {
    Write-Err 'V cíli chybí .claude-plugin/plugin.json — Claude Code plugin nenačte.'
    exit 1
}

$skills = Get-ChildItem -Path (Join-Path $Target 'skills') -Directory -ErrorAction SilentlyContinue |
          Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }

if (-not $skills) {
    Write-Err "Nenašel jsem žádný skill v $Target\skills\ — instalace je nekompletní."
    exit 1
}
foreach ($skill in $skills) { Write-Info "• ${PluginName}:$($skill.Name)" }
Write-Ok "Nalezeno skillů: $($skills.Count)"

# Skilly volají doprovodné .sh skripty — bez bashe spadnou na prvním volání.
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Warn 'bash není v PATH — skilly create-branch a make-commit se bez něj neobejdou.'
    Write-Info 'Nainstaluj Git for Windows a přidej Git Bash do PATH.'
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warn "CLI 'claude' není v PATH — plugin se načte, až Claude Code poběží."
}

Write-Host "`nHotovo. Spusť Claude Code znovu a skilly zkontroluj přes /help."
