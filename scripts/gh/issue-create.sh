#!/usr/bin/env bash
# Založí issue. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/issue-create.sh -R owner/repo --title T --body-file F \
#     [--milestone M] [--label L]…
#
# Tělo se předává vždy souborem. Víceřádkový markdown v argumentu se
# o uvozovky a zpětné apostrofy rozbije, a rozbije se tiše — vznikne issue
# s useknutým tělem.
#
# --label se smí opakovat; label musí v repozitáři existovat, jinak gh
# založení odmítne. Na doplnění chybějícího labelu je label-create.sh.
# --milestone bere název milestonu.
#
# Výstup: number=, url=.
#
# Návratové kódy: 0 = založeno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
title=""
body_file=""
milestone=""
labels=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
    --body-file) require_value "$1" "${2:-}"; body_file="$2"; shift 2 ;;
    --milestone) require_value "$1" "${2:-}"; milestone="$2"; shift 2 ;;
    --label) require_value "$1" "${2:-}"; labels+=("$2"); shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
[ -n "$title" ] || die_usage "missing_title" "chybí --title"
require_body_file "$body_file"
gh_require

args=(issue create -R "$repo" --title "$title" --body-file "$body_file")
if [ -n "$milestone" ]; then
  args+=(--milestone "$milestone")
fi
for label in ${labels[@]+"${labels[@]}"}; do
  args+=(--label "$label")
done

# gh vypisuje URL nového issue na poslední řádek; číslo je jeho poslední segment.
out="$(gh "${args[@]}")"
url="$(printf '%s\n' "$out" | grep -E '^https?://' | tail -1 || true)"
if [ -z "$url" ]; then
  echo "error=unexpected_gh_output" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

echo "number=${url##*/}"
echo "url=$url"
