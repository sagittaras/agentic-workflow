#!/usr/bin/env bash
# Společné pro skripty v scripts/gh/ — ověření gh, kontrola -R owner/repo
# a kontrola souboru s tělem. Nespouští se přímo, sourcuje se ze skriptů vedle.
#
# Repozitář se všude předává jako -R owner/repo. Bez něj by se gh řídilo
# podle aktuálního adresáře, což v izolovaném worktree neplatí a operace
# by tiše skončila v jiném repozitáři.
#
# Kódy, které tenhle soubor nastavuje: 2 = chybný nebo chybějící argument,
# 7 = gh chybí nebo není přihlášené.

# --- gh ------------------------------------------------------------------
gh_require() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "error=gh_not_found" >&2
    echo "hint=chybí GitHub CLI; nainstaluj https://cli.github.com a přihlas se přes 'gh auth login'" >&2
    exit 7
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "error=gh_not_authenticated" >&2
    echo "hint=gh není přihlášené; spusť 'gh auth login'" >&2
    exit 7
  fi
}

# --- argumenty -----------------------------------------------------------
die_usage() {
  echo "error=$1" >&2
  shift
  if [ "$#" -gt 0 ]; then
    echo "hint=$*" >&2
  fi
  exit 2
}

require_repo() {
  if [ -z "${1:-}" ]; then
    die_usage "missing_repo" "povinné je -R owner/repo; bez něj by se gh řídilo podle aktuálního adresáře"
  fi
  case "$1" in
    */*) : ;;
    *) die_usage "invalid_repo" "-R čekává tvar owner/repo, dostal '$1'" ;;
  esac
}

require_number() {
  if [ -z "${1:-}" ]; then
    die_usage "missing_number" "chybí číslo issue nebo PR"
  fi
  case "$1" in
    ''|*[!0-9]*) die_usage "invalid_number" "číslo issue nebo PR je celé číslo, dostal '$1'" ;;
  esac
}

require_body_file() {
  if [ -z "${1:-}" ]; then
    die_usage "missing_body_file" "tělo se předává souborem: --body-file <cesta>"
  fi
  if [ ! -f "$1" ]; then
    die_usage "body_file_not_found" "soubor s tělem '$1' neexistuje"
  fi
}

require_value() {
  # require_value <název přepínače> <hodnota>
  if [ -z "${2:-}" ]; then
    die_usage "missing_value" "přepínač $1 čeká hodnotu"
  fi
}

check_state() {
  case "${1:-}" in
    open|closed|all) : ;;
    *) die_usage "invalid_state" "--state je open, closed nebo all; dostal '${1:-}'" ;;
  esac
}
