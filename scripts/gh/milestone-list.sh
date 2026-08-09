#!/usr/bin/env bash
# Vypíše milestony repozitáře. Vypisuje JSON tak, jak ho vrátí gh.
#
# Použití:
#   bash scripts/gh/milestone-list.sh -R owner/repo [--state open|closed|all]
#
# gh nemá `gh milestone`, jde se přes gh api. Stránkuje se po 100 a sbírá se
# přes --paginate. Novější gh umí --slurp a slepí stránky do jednoho pole;
# starší vypíše víc polí za sebou — na to se koukej, než výstup naparsuješ.
# Klíče open_issues a closed_issues z každého milestonu slouží jako kontrola,
# jestli výpis issues nebyl useknutý.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
state="open"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --state) require_value "$1" "${2:-}"; state="$2"; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
check_state "$state"
gh_require

path="repos/$repo/milestones?state=$state&per_page=100"

if gh api --help 2>/dev/null | grep -q -- '--slurp'; then
  gh api "$path" --paginate --slurp
else
  gh api "$path" --paginate
fi
