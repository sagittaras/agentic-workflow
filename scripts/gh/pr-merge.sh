#!/usr/bin/env bash
# Mergne pull request. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-merge.sh -R owner/repo <number> [--squash] [--delete-branch]
#
# Bez --squash vznikne merge commit. Strategii vždycky předej výslovně podle
# sekce Větvení projektové konfigurace — výchozí merge commit je jen to,
# co skript udělá, když mu nikdo nic neřekl, ne doporučení.
#
# Rebase merge skript záměrně neumí: přepisuje historii commitů, a to tenhle
# plugin nedělá nikde. Merge se nevynucuje přes --admin; když GitHub merge
# odmítne kvůli nesplněné ochraně větve, nenulový kód propadne ven a je to
# tak správně — obcházet ochranu není práce pro skript.
#
# --delete-branch smaže zdrojovou větev na remotu. Zapíná se výslovně;
# u integrační větve to nechceš, dokud milestone neskončil.
#
# Výstup: number=, merged=true, method=, deleted_branch=, state=, url=.
#
# Návratové kódy: 0 = mergnuto, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
method="merge"
delete_branch=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --squash) method="squash"; shift ;;
    --merge) method="merge"; shift ;;
    --delete-branch) delete_branch=true; shift ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
gh_require

args=(pr merge "$number" -R "$repo" "--$method")
if $delete_branch; then
  args+=(--delete-branch)
fi

gh "${args[@]}" >/dev/null

echo "number=$number"
echo "merged=true"
echo "method=$method"
echo "deleted_branch=$delete_branch"
gh pr view "$number" -R "$repo" --json state,url,mergedAt \
  --jq '"state=\(.state)\nurl=\(.url)\nmerged_at=\(.mergedAt // "")"'
