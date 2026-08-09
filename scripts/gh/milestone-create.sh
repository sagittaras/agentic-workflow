#!/usr/bin/env bash
# Založí milestone. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/milestone-create.sh -R owner/repo --title T [--description D]
#
# Popis se předává argumentem, protože je to jedna věta, ne markdown
# dokument; tělo souborem se předává tam, kde má víc řádků (issue, PR).
# Milestone se stejným názvem GitHub odmítne (422) a nenulový kód propadne ven.
#
# Výstup: number=, url=. Číslo je to, čím se milestone adresuje dál
# (milestone-update.sh), název je to, čím se filtruje (issue-list.sh).
#
# Návratové kódy: 0 = založeno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
title=""
description=""
have_description=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
    --description) require_value "$1" "${2:-}"; description="$2"; have_description=true; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
[ -n "$title" ] || die_usage "missing_title" "chybí --title"
gh_require

args=(api --method POST "repos/$repo/milestones" -f "title=$title")
if $have_description; then
  args+=(-f "description=$description")
fi
args+=(--jq '"number=\(.number)\nurl=\(.html_url)"')

gh "${args[@]}"
