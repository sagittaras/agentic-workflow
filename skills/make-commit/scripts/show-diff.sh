#!/usr/bin/env bash
# Vypíše diff, ze kterého se píše commit zpráva.
#
# Použití:
#   bash scripts/show-diff.sh                    # staged změny
#   bash scripts/show-diff.sh --worktree         # vše necommitnuté proti HEAD
#   bash scripts/show-diff.sh [--worktree] <cesta>...   # omezeno na cesty
#
# Návratové kódy: 0 = v pořádku, 2 = nejde o git repozitář.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

worktree=false
if [ "${1:-}" = "--worktree" ]; then
  worktree=true
  shift
fi

if $worktree; then
  # Staged i unstaged proti HEAD. Nové soubory diff neukáže, dokud nejsou
  # sledované — proto je vypisujeme zvlášť.
  git --no-pager diff HEAD -- "$@"
  untracked="$(git ls-files --others --exclude-standard -- "$@")"
  if [ -n "$untracked" ]; then
    echo
    echo "[untracked]"
    printf '%s\n' "$untracked"
  fi
else
  git --no-pager diff --cached -- "$@"
fi
