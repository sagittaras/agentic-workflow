#!/usr/bin/env bash
# Vypíše pull requesty repozitáře, volitelně jen z jednoho milestonu.
# Vypisuje JSON pole tak, jak ho vrátí gh.
#
# Použití:
#   bash scripts/gh/pr-list.sh -R owner/repo [--milestone M] [--state open|closed|all]
#
# --milestone bere název i číslo. gh pr list nemá přepínač na milestone,
# filtruje se vyhledávacím kvalifikátorem milestone:"<název>", který číslu
# nerozumí a s ním potichu vrátí [] (běh M1, nález F4) — číslo se proto napřed
# přeloží na název. Neexistující číslo propadne chybou gh, ne prázdným polem.
# Bez --state se vypisují jen otevřené; na kontrolu „všechno je mergnuté"
# se ptej s --state all a dívej se na mergedAt, ne jen na state.
#
# Limit je pevných 500 položek.
#
# Vrácená pole: number, title, state, isDraft, headRefName, baseRefName,
# milestone, labels, url, createdAt, updatedAt, mergedAt,
# closingIssuesReferences. Tělo PR se záměrně nevrací — u pěti set záznamů
# by zahltilo výstup. closingIssuesReferences GitHub plní jen u PR do výchozí
# větve; vazbu PR → issue i do integrační větve najde gh/pr-for-issue.sh.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,state,isDraft,headRefName,baseRefName,milestone,labels,url,createdAt,updatedAt,mergedAt,closingIssuesReferences"
LIMIT=500

repo=""
milestone=""
state="open"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --milestone) require_value "$1" "${2:-}"; milestone="$2"; shift 2 ;;
    --state) require_value "$1" "${2:-}"; state="$2"; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
check_state "$state"
gh_require

case "$milestone" in
  ''|*[!0-9]*) : ;;
  *) milestone="$(gh api "repos/$repo/milestones/$milestone" --jq .title)" ;;
esac

args=(pr list -R "$repo" --state "$state" --limit "$LIMIT" --json "$FIELDS")
if [ -n "$milestone" ]; then
  args+=(--search "milestone:\"$milestone\"")
fi

gh "${args[@]}"
