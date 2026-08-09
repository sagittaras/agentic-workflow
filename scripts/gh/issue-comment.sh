#!/usr/bin/env bash
# Přidá komentář k issue. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/issue-comment.sh -R owner/repo <number> --body-file F
#
# Tělo se předává vždy souborem; víceřádkový markdown se v argumentu tiše
# rozpadne o uvozovky a zpětné apostrofy.
#
# Výstup: number=, url= (odkaz na komentář, ne na issue).
#
# Návratové kódy: 0 = okomentováno, 2 = chybný argument, 7 = gh chybí nebo
# není přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
body_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --body-file) require_value "$1" "${2:-}"; body_file="$2"; shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
require_body_file "$body_file"
gh_require

out="$(gh issue comment "$number" -R "$repo" --body-file "$body_file")"
url="$(printf '%s\n' "$out" | grep -E '^https?://' | tail -1 || true)"

echo "number=$number"
echo "url=$url"
