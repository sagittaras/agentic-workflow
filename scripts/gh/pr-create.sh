#!/usr/bin/env bash
# Založí pull request. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-create.sh -R owner/repo --base B --head H --title T --body-file F
#
# Tělo se předává vždy souborem; víceřádkový markdown se v argumentu tiše
# rozpadne o uvozovky a zpětné apostrofy.
#
# Milestone při zakládání nastavit nelze — ani tady, ani na Gitea. Je to
# povinné druhé volání hned po založení: pr-set-milestone.sh. Bez něj
# close-milestone integrační PR nedohledá.
#
# Větev --head musí být na remotu; skript nic nepushuje.
#
# Výstup: number=, url=.
#
# Návratové kódy: 0 = založeno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
base=""
head=""
title=""
body_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --base) require_value "$1" "${2:-}"; base="$2"; shift 2 ;;
    --head) require_value "$1" "${2:-}"; head="$2"; shift 2 ;;
    --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
    --body-file) require_value "$1" "${2:-}"; body_file="$2"; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
[ -n "$base" ] || die_usage "missing_base" "chybí --base"
[ -n "$head" ] || die_usage "missing_head" "chybí --head"
[ -n "$title" ] || die_usage "missing_title" "chybí --title"
require_body_file "$body_file"
gh_require

out="$(gh pr create -R "$repo" --base "$base" --head "$head" \
  --title "$title" --body-file "$body_file")"
url="$(printf '%s\n' "$out" | grep -E '^https?://' | tail -1 || true)"
if [ -z "$url" ]; then
  echo "error=unexpected_gh_output" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

echo "number=${url##*/}"
echo "url=$url"
