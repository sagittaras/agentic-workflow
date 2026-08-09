#!/usr/bin/env bash
# Vypíše labely repozitáře. Vypisuje JSON tak, jak ho vrátí gh.
#
# Použití: bash scripts/gh/label-list.sh -R owner/repo
#
# Vrácená pole: name, color, description. Na GitHubu se labely připínají
# názvem (na rozdíl od Gitea, kde jde o číselná ID) — tenhle výpis slouží
# k ověření, že název, který chceš připnout, v repozitáři opravdu existuje.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

LIMIT=500

repo=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    *) die_usage "unknown_option" "neznámý argument '$1'" ;;
  esac
done

require_repo "$repo"
gh_require

gh label list -R "$repo" --limit "$LIMIT" --json name,color,description
