#!/usr/bin/env bash
# Nahradí tělo pull requestu. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-update.sh -R owner/repo <number> --body-file F|-
#
# Tělo se předává souborem, nebo "-" ze stdin (heredoc), nikdy argumentem,
# a nahrazuje se celé — gh nic nepřipojuje. Chceš-li upravit jen část
# (typicky mapu kritérium → test pod "## Testy kritérií"), přečti tělo přes
# pr-read.sh --body a pošli sem celé nové.
#
# Stav, základní větev ani milestone skript nemění; milestone přiřazuje
# pr-set-milestone.sh.
#
# Výstup: number=, url=.
#
# Návratové kódy: 0 = upraveno, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

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

gh pr edit "$number" -R "$repo" --body-file "$BODY_FILE" >/dev/null

echo "number=$number"
gh pr view "$number" -R "$repo" --json url --jq '"url=\(.url)"'
