#!/usr/bin/env bash
# Přiřadí pull requestu milestone. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-set-milestone.sh -R owner/repo <number> --milestone M
#
# Milestone při zakládání PR nastavit nelze, tohle je povinné druhé volání
# hned po pr-create.sh — ne kosmetika: close-milestone podle téhle vazby
# integrační PR dohledává.
#
# M je název milestonu. Milestone musí existovat, jinak gh volání odmítne.
#
# Výstup: number=, milestone=, url=.
#
# Návratové kódy: 0 = přiřazeno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
milestone=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --milestone) require_value "$1" "${2:-}"; milestone="$2"; shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
[ -n "$milestone" ] || die_usage "missing_milestone" "chybí --milestone"
gh_require

gh pr edit "$number" -R "$repo" --milestone "$milestone" >/dev/null

echo "number=$number"
gh pr view "$number" -R "$repo" --json milestone,url \
  --jq '"milestone=\(.milestone.title // "")\nurl=\(.url)"'
