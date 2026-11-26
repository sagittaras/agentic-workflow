#!/usr/bin/env bash
# Upraví tělo issue, jeho stav, milestone nebo labely. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/issue-update.sh -R owner/repo <number> [--body-file F|-] \
#     [--state closed|open] [--milestone <název>] [--add-label <název>]... [--remove-label <název>]...
#
# --milestone přesune issue do milestonu daného názvem (gh issue edit číslo
# milestonu nebere).
#
# --add-label připne existující label; víc labelů = víc přepínačů. Label,
# který v repozitáři není, gh odmítne a nenulový kód propadne ven — skript ho
# sám nezakládá (na to je label-create.sh). --remove-label label odepne.
#
# Tělo se předává souborem, nebo "-" ze stdin (heredoc), a nahrazuje se celé
# — gh nic nepřipojuje. Chceš-li přidat odstavec, přečti issue přes issue-read.sh, slož nové tělo
# do souboru a pošli ho sem; na dopsání poznámky je issue-comment.sh.
#
# Aspoň jeden z přepínačů musí padnout, jinak by volání jen zbytečně
# potvrdilo současný stav.
#
# Výstup: number=, body_updated=, labels= (názvy podle forge, oddělené čárkou),
# milestone= (název podle forge, prázdný bez milestonu), state=, url=.
#
# Návratové kódy: 0 = upraveno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
body_file=""
state=""
milestone=""
labels=()
unlabels=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --body-file) require_value "$1" "${2:-}"; body_file="$2"; shift 2 ;;
    --state) require_value "$1" "${2:-}"; state="$2"; shift 2 ;;
    --milestone) require_value "$1" "${2:-}"; milestone="$2"; shift 2 ;;
    --add-label) require_value "$1" "${2:-}"; labels+=("$2"); shift 2 ;;
    --remove-label) require_value "$1" "${2:-}"; unlabels+=("$2"); shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
if [ -z "$body_file" ] && [ -z "$state" ] && [ -z "$milestone" ] && [ "${#labels[@]}" -eq 0 ] && [ "${#unlabels[@]}" -eq 0 ]; then
  die_usage "nothing_to_update" "zadej --body-file, --state, --milestone, --add-label nebo --remove-label"
fi
case "$state" in
  ''|closed|open) : ;;
  *) die_usage "invalid_state" "--state je closed nebo open; dostal '$state'" ;;
esac
if [ -n "$body_file" ]; then
  require_body_file "$body_file"
fi
gh_require

body_updated=false
if [ -n "$body_file" ]; then
  gh issue edit "$number" -R "$repo" --body-file "$BODY_FILE" >/dev/null
  body_updated=true
fi

if [ -n "$milestone" ]; then
  gh issue edit "$number" -R "$repo" --milestone "$milestone" >/dev/null
fi

for l in "${labels[@]}"; do
  gh issue edit "$number" -R "$repo" --add-label "$l" >/dev/null
done
for l in "${unlabels[@]}"; do
  gh issue edit "$number" -R "$repo" --remove-label "$l" >/dev/null
done

case "$state" in
  closed) gh issue close "$number" -R "$repo" >/dev/null ;;
  open)   gh issue reopen "$number" -R "$repo" >/dev/null ;;
esac

echo "number=$number"
echo "body_updated=$body_updated"
gh issue view "$number" -R "$repo" --json state,url,milestone,labels \
  --jq '"labels=\([.labels[].name] | join(","))\nmilestone=\(.milestone.title // "")\nstate=\(.state)\nurl=\(.url)"'
