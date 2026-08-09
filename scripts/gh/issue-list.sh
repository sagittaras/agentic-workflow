#!/usr/bin/env bash
# Vypíše issues repozitáře, volitelně jen z jednoho milestonu.
# Vypisuje JSON pole tak, jak ho vrátí gh.
#
# Použití:
#   bash scripts/gh/issue-list.sh -R owner/repo [--milestone M] [--state open|closed|all]
#
# --milestone bere název milestonu, ne číslo. Bez --state se vypisují jen
# otevřené — na kontrolu „je všechno hotové" se ptej s --state all.
#
# gh issue list pull requesty nevrací, takže počet nenafoukne o PR; limit je
# pevných 500 položek. Když se milestone blíží té hranici, porovnej počet
# s open_issues + closed_issues z milestone-list.sh a radši to ohlas,
# než abys z useknutého výpisu rozhodl.
#
# Vrácená pole: number, title, state, labels, milestone, assignees, url,
# createdAt, updatedAt. Tělo issue ve výpisu není, na to je issue-read.sh.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,state,labels,milestone,assignees,url,createdAt,updatedAt"
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

args=(issue list -R "$repo" --state "$state" --limit "$LIMIT" --json "$FIELDS")
if [ -n "$milestone" ]; then
  args+=(--milestone "$milestone")
fi

gh "${args[@]}"
