#!/usr/bin/env bash
# Zavře nebo znovu otevře milestone. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/milestone-update.sh -R owner/repo <number> --state closed|open
#
# <number> je číslo milestonu z milestone-list.sh nebo milestone-create.sh,
# ne jeho název. Zavření milestonu neuzavírá jeho issues; skript nic
# takového nedělá a ani se na to neptá.
#
# Výstup: number=, state=, url=, open_issues=, closed_issues=.
#
# Návratové kódy: 0 = upraveno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
state=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
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
case "$state" in
  closed|open) : ;;
  *) die_usage "invalid_state" "--state je closed nebo open; dostal '${state:-}'" ;;
esac
gh_require

gh api --method PATCH "repos/$repo/milestones/$number" -f "state=$state" \
  --jq '"number=\(.number)\nstate=\(.state)\nurl=\(.html_url)\nopen_issues=\(.open_issues)\nclosed_issues=\(.closed_issues)"'
