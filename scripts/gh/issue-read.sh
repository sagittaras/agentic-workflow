#!/usr/bin/env bash
# Přečte issue včetně komentářů. Vypisuje JSON tak, jak ho vrátí gh, aby si
# volající vytáhl, co potřebuje, bez dalšího kola.
#
# Použití: bash scripts/gh/issue-read.sh -R owner/repo <number> [--body]
#
# S --body vypíše jen tělo issue jako prostý text, aby šlo rovnou přesměrovat
# do souboru (třeba pro criteria-tests.sh) bez parsování JSON.
#
# Vrácená pole: number, title, body, state, labels, milestone, assignees,
# author, url, createdAt, updatedAt, comments,
# closedByPullRequestsReferences. To poslední GitHub plní jen u PR do výchozí
# větve; PR do integrační větve v něm chybí — ten najde gh/pr-for-issue.sh.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh (typicky 1 u chybějícího issue nebo
# chybějícího oprávnění) propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,body,state,labels,milestone,assignees,author,url,createdAt,updatedAt,comments,closedByPullRequestsReferences"

repo=""
number=""
body_only=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --body) body_only=true; shift ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
gh_require

if [ "$body_only" = true ]; then
  gh issue view "$number" -R "$repo" --json body --jq .body
else
  gh issue view "$number" -R "$repo" --json "$FIELDS"
fi
