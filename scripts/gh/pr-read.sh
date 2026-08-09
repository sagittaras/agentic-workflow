#!/usr/bin/env bash
# Přečte pull request včetně komentářů a stavu review. Vypisuje JSON tak,
# jak ho vrátí gh.
#
# Použití: bash scripts/gh/pr-read.sh -R owner/repo <number>
#
# Vrácená pole: number, title, body, state, isDraft, mergeable,
# mergeStateStatus, reviewDecision, headRefName, baseRefName, milestone,
# labels, url, createdAt, updatedAt, additions, deletions, changedFiles,
# comments. Seznam změněných souborů uvnitř není, jen jejich počet.
#
# mergeable GitHub počítá asynchronně; hned po pushi může vyjít UNKNOWN.
# Na rozhodnutí „projde to" se ptej integration-gate.sh, ne tohohle pole.
#
# Návratové kódy: 0 = v pořádku, 2 = chybný argument, 7 = gh chybí nebo není
# přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

FIELDS="number,title,body,state,isDraft,mergedAt,mergeCommit,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName,milestone,labels,url,createdAt,updatedAt,additions,deletions,changedFiles,comments"

repo=""
number=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
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

gh pr view "$number" -R "$repo" --json "$FIELDS"
