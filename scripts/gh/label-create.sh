#!/usr/bin/env bash
# Založí label. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/label-create.sh -R owner/repo --name N --color C [--description D]
#
# Barva je šest hexa číslic, s křížkem i bez něj; skript křížek odstraní,
# protože API ho odmítá. Label se stejným názvem GitHub odmítne (422)
# a nenulový kód propadne ven — existující labely si nejdřív vypiš
# přes label-list.sh.
#
# Výstup: name=, color=, url=.
#
# Návratové kódy: 0 = založeno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
name=""
color=""
description=""
have_description=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --name) require_value "$1" "${2:-}"; name="$2"; shift 2 ;;
    --color) require_value "$1" "${2:-}"; color="$2"; shift 2 ;;
    --description) require_value "$1" "${2:-}"; description="$2"; have_description=true; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
[ -n "$name" ] || die_usage "missing_name" "chybí --name"
[ -n "$color" ] || die_usage "missing_color" "chybí --color"

color="${color#\#}"
if ! printf '%s' "$color" | grep -qE '^[0-9a-fA-F]{6}$'; then
  die_usage "invalid_color" "--color je šest hexa číslic, např. 1d76db; dostal '$color'"
fi
gh_require

args=(api --method POST "repos/$repo/labels" -f "name=$name" -f "color=$color")
if $have_description; then
  args+=(-f "description=$description")
fi
args+=(--jq '"name=\(.name)\ncolor=\(.color)\nurl=\(.url)"')

gh "${args[@]}"
