#!/usr/bin/env bash
# Přidá k pull requestu review typu COMMENT. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-comment.sh -R owner/repo <number> --body-file F
#
# Tělo se předává vždy souborem; víceřádkový markdown se v argumentu tiše
# rozpadne o uvozovky a zpětné apostrofy.
#
# Primárně se zakládá review s výrokem COMMENT — to je protějšek Gitea
# pull_request_review_write se state COMMENT. Když GitHub review odmítne
# (typicky u PR založeného tímtéž účtem s omezeným tokenem), skript spadne
# zpátky na obyčejný komentář a řekne to klíčem mode=. Souhlas ani zamítnutí
# skript nikdy neposílá; schválení PR není práce pro skript.
#
# Výstup: number=, mode=review|comment, url=.
#
# Návratové kódy: 0 = okomentováno, 2 = chybný argument, 7 = gh chybí nebo
# není přihlášené. Nenulový kód od gh propadá ven, když selžou obě cesty.

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

mode="review"
if ! out="$(gh pr review "$number" -R "$repo" --comment --body-file "$body_file" 2>&1)"; then
  review_error="$out"
  mode="comment"
  if ! out="$(gh pr comment "$number" -R "$repo" --body-file "$body_file" 2>&1)"; then
    echo "error=comment_failed" >&2
    printf '%s\n' "$review_error" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
fi

url="$(printf '%s\n' "$out" | grep -E '^https?://' | tail -1 || true)"

echo "number=$number"
echo "mode=$mode"
echo "url=$url"
