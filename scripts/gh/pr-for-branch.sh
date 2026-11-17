#!/usr/bin/env bash
# Najde pull requesty, které rostou z dané head větve tohoto repozitáře.
# Vypisuje JSON pole bez těl.
#
# Použití:
#   bash scripts/gh/pr-for-branch.sh -R owner/repo <head> [--base B] [--state open|closed|all]
#
# Typicky před založením PR: „jedna head větev, jedno PR". Prázdné pole
# znamená, že z větve žádné PR (v daném stavu) neexistuje. Volající
# porovnává jen baseRefName vrácených položek, headRefName už sedí.
#
# Větev se filtruje přes gh pr list --head, tedy přesnou shodou názvu.
# PR z forků se vyřazují: větev stejného jména v cizím forku není ta, ze
# které se zakládá PR tady.
#
# --base zúží výpis na PR do jedné větve. Bez --state se hledá napříč
# stavy. Filtruje se z nejvýš 500 PR.
#
# Vrácená pole: number, title, state, isDraft, headRefName, baseRefName,
# url, mergedAt.
#
# Návratové kódy: 0 = v pořádku (i prázdné pole), 2 = chybný argument,
# 7 = gh chybí nebo není přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,state,isDraft,headRefName,baseRefName,url,mergedAt,isCrossRepository"
LIMIT=500

repo=""
head=""
base=""
state="all"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --base) require_value "$1" "${2:-}"; base="$2"; shift 2 ;;
    --state) require_value "$1" "${2:-}"; state="$2"; shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$head" ]; then head="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
[ -n "$head" ] || die_usage "missing_head" "chybí název head větve"
check_state "$state"
gh_require

args=(pr list -R "$repo" --head "$head" --state "$state" --limit "$LIMIT" --json "$FIELDS")
if [ -n "$base" ]; then
  args+=(--base "$base")
fi

gh "${args[@]}" --jq '[.[] | select(.isCrossRepository | not) | del(.isCrossRepository)]'
