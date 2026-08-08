#!/usr/bin/env bash
# Nainstaluje nebo aktualizuje plugin sagittaras do uživatelské konfigurace
# Claude Code (~/.claude/skills/sagittaras), odkud se načítá nad všemi projekty.
#
# Skript je idempotentní: chybí-li cíl, naklonuje ho; existuje-li, přetáhne
# novinky z remotu. Nic nemaže — cizí nebo rozpracovaný obsah v cíli ohlásí
# a skončí, úklid nechá na uživateli.
#
# Použití:
#   bash install.sh [--target <cesta>] [--ref <větev>] [--https]
#
# Návratové kódy: 0 = hotovo, 1 = chybí předpoklad, 2 = cíl je obsazený.

set -euo pipefail

REPO_SLUG="sagittaras/agentic-workflow"
REPO_SSH="git@github.com:${REPO_SLUG}.git"
REPO_HTTPS="https://github.com/${REPO_SLUG}.git"
PLUGIN_NAME="sagittaras"

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
target="$config_dir/skills/$PLUGIN_NAME"
ref="main"
remote="$REPO_SSH"

info() { printf '  %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
err()  { printf '✗ %s\n' "$*" >&2; }

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) target="${2:?--target vyžaduje cestu}"; shift 2 ;;
    --ref)    ref="${2:?--ref vyžaduje název větve}"; shift 2 ;;
    --https)  remote="$REPO_HTTPS"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "neznámý přepínač: $1"; usage >&2; exit 1 ;;
  esac
done

# --- předpoklady ---------------------------------------------------------
command -v git >/dev/null 2>&1 || { err "git není v PATH — bez něj instalaci nelze provést."; exit 1; }

# Vytáhne z URL remotu tvar 'vlastník/repo', aby šly porovnat SSH i HTTPS varianty.
normalize_remote() {
  printf '%s' "$1" | sed -E 's#^git\+?ssh://##; s#^git@([^:/]+)[:/]#\1/#; s#^https?://##; s#^[^/]+/##; s#\.git$##'
}

# --- instalace nebo aktualizace ------------------------------------------
if [ -e "$target" ]; then
  # Ne test na složku .git — u worktree a submodulu je to soubor a legitimní
  # instalace by se označila za cizí obsah k ručnímu úklidu.
  if ! git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
    err "V $target už něco je, ale není to git repozitář."
    info "Zkontroluj obsah a odstraň ho ručně, pak spusť skript znovu."
    exit 2
  fi

  actual="$(git -C "$target" remote get-url origin 2>/dev/null || true)"
  if [ "$(normalize_remote "$actual")" != "$REPO_SLUG" ]; then
    err "V $target je repozitář s cizím remotem: ${actual:-<žádný>}"
    info "Očekáván $REPO_SLUG. Přesuň ho stranou a spusť skript znovu."
    exit 2
  fi

  if [ -n "$(git -C "$target" status --porcelain)" ]; then
    warn "Instalace v $target má necommitnuté změny — aktualizaci přeskakuji."
    info "Ulož je, nebo zahoď, a spusť skript znovu."
  else
    info "Aktualizuji $target …"
    git -C "$target" fetch --quiet origin "$ref"
    git -C "$target" checkout --quiet "$ref"
    git -C "$target" merge --ff-only --quiet "origin/$ref"
    ok "Aktualizováno na $(git -C "$target" rev-parse --short HEAD) ($ref)."
  fi
else
  info "Klonuji $REPO_SLUG do $target …"
  mkdir -p "$(dirname "$target")"
  git clone --quiet --branch "$ref" "$remote" "$target"
  ok "Nainstalováno do $target ($(git -C "$target" rev-parse --short HEAD))."
fi

# --- ověření -------------------------------------------------------------
if [ ! -f "$target/.claude-plugin/plugin.json" ]; then
  err "V cíli chybí .claude-plugin/plugin.json — Claude Code plugin nenačte."
  exit 1
fi

count=0
for skill in "$target"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  name="$(basename "$(dirname "$skill")")"
  info "• $PLUGIN_NAME:$name"
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  err "Nenašel jsem žádný skill v $target/skills/ — instalace je nekompletní."
  exit 1
fi
ok "Nalezeno skillů: $count"

command -v claude >/dev/null 2>&1 \
  || warn "CLI 'claude' není v PATH — plugin se načte, až Claude Code poběží."

printf '\nHotovo. Spusť Claude Code znovu a skilly zkontroluj přes /help.\n'
