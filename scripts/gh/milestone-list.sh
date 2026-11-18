#!/usr/bin/env bash
# Vypíše milestony repozitáře jako jedno ploché JSON pole.
#
# Použití:
#   bash scripts/gh/milestone-list.sh -R owner/repo [--state open|closed|all]
#
# Čte se přes GraphQL, ne přes REST: REST počty open_issues a closed_issues
# zahrnují i pull requesty, kterým plugin milestone přiřazuje, takže by se
# s výpisem z issue-list.sh nikdy neshodovaly (běh M1, nález F3). Tady jsou
# open_issues a closed_issues jen za issues a slouží jako kontrola, jestli výpis
# issues nebyl useknutý. Stránkuje se po 100 a stránky se slévají do jednoho
# pole — výstup se nemusí zplošťovat.
#
# Vrácená pole: number, title, state (open|closed), description, due_on,
# html_url, open_issues, closed_issues.
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

case "$state" in
  open) states="[OPEN]" ;;
  closed) states="[CLOSED]" ;;
  all) states="[OPEN, CLOSED]" ;;
esac

query='query($owner: String!, $name: String!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    milestones(first: 100, after: $endCursor, states: '"$states"') {
      nodes {
        number title state description dueOn url
        openIssues: issues(states: [OPEN]) { totalCount }
        closedIssues: issues(states: [CLOSED]) { totalCount }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}'
filter='.data.repository.milestones.nodes[] | {number, title, state: (.state | ascii_downcase), description, due_on: .dueOn, html_url: .url, open_issues: .openIssues.totalCount, closed_issues: .closedIssues.totalCount}'

# Jeden kompaktní objekt na řádek; do pole se slévá až po úspěchu gh, aby
# selhání v půlce stránkování nevypsalo useknuté, ale platné pole.
lines="$(gh api graphql --paginate -f owner="${repo%%/*}" -f name="${repo#*/}" \
  -f query="$query" --jq "$filter")"

printf '[%s]\n' "$(printf '%s' "$lines" | paste -sd, -)"
