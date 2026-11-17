#!/usr/bin/env bash
# Najde pull requesty, které v těle uzavírají dané issue (Closes/Fixes/Resolves #N).
# Vypisuje JSON pole bez těl.
#
# Použití:
#   bash scripts/gh/pr-for-issue.sh -R owner/repo <issue> [--base B] [--state open|closed|all]
#
# Vazbu čte z těla PR. closingIssuesReferences u PR ani
# closedByPullRequestsReferences u issue nestačí: GitHub je plní jen u PR do
# výchozí větve, takže PR do integrační větve milestone/<slug> v nich chybí
# i s "Closes #N" v těle. Vyhledávání GitHubu (in:body) se taky nepoužívá —
# čerstvě založené PR nemusí být zaindexované a shoda není přesná.
#
# Klíčové slovo se hledá bez ohledu na velikost písmen a číslo musí sedět
# celé: "Closes #56" k issue 5 nepatří.
#
# --base zúží výpis na PR do jedné větve (v běhu milestonu integrační).
# Bez --state se hledá napříč stavy. Filtruje se z nejvýš 500 PR.
#
# Vrácená pole: number, title, state, isDraft, headRefName, baseRefName,
# url, mergedAt.
#
# Návratové kódy: 0 = v pořádku (i prázdné pole), 2 = chybný argument,
# 7 = gh chybí nebo není přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,state,isDraft,headRefName,baseRefName,url,mergedAt,body"
LIMIT=500

repo=""
number=""
base=""
state="all"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --base) require_value "$1" "${2:-}"; base="$2"; shift 2 ;;
    --state) require_value "$1" "${2:-}"; state="$2"; shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
check_state "$state"
gh_require

# Číslo je ověřené jako celé číslo, do regexu ho jde vložit přímo.
filter='map(select((.body // "") | test("(?i)\\b(close[sd]?|fix(e[sd])?|resolve[sd]?):?\\s+#'"$number"'\\b")) | del(.body))'

args=(pr list -R "$repo" --state "$state" --limit "$LIMIT" --json "$FIELDS" --jq "$filter")
if [ -n "$base" ]; then
  args+=(--base "$base")
fi

gh "${args[@]}"
