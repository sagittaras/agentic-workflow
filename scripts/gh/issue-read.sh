#!/usr/bin/env bash
# Přečte issue včetně komentářů. Vypisuje JSON tak, jak ho vrátí gh, aby si
# volající vytáhl, co potřebuje, bez dalšího kola.
#
# Použití: bash scripts/gh/issue-read.sh -R owner/repo <number>
#
# Vrácená pole: number, title, body, state, labels, milestone, assignees,
# author, url, createdAt, updatedAt, comments,
# closedByPullRequestsReferences — to poslední je spolehlivá vazba na PR,
# které issue uzavírá; hledat "Closes #N" v tělech PR není potřeba.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh (typicky 1 u chybějícího issue nebo
# chybějícího oprávnění) propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,body,state,labels,milestone,assignees,author,url,createdAt,updatedAt,comments,closedByPullRequestsReferences"

repo=""
number=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
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

gh issue view "$number" -R "$repo" --json "$FIELDS"
