#!/usr/bin/env bash
# Vypíše stav repozitáře, ze kterého make-commit rozhoduje, než začne stagovat.
# Výstup je key=value na stdout; sekce s výpisy jsou uvozené hlavičkou v [].
#
# Použití: bash scripts/preflight.sh
#
# Návratové kódy: 0 = v pořádku, 2 = nejde o git repozitář.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

# --- větev ---------------------------------------------------------------
branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  # Odpojená HEAD (rebase, checkout commitu). Commit by se tiše ztratil.
  echo "detached=true"
  echo "branch="
else
  echo "detached=false"
  echo "branch=$branch"
fi

# --- výchozí větev -------------------------------------------------------
# Ptáme se remotu. Lokálnímu refs/remotes/origin/HEAD nevěříme: po změně
# výchozí větve na remotu zůstává zastaralý a vrátí věrohodně vypadající
# špatnou odpověď.
default_branch=""
if symref="$(git ls-remote --symref origin HEAD 2>/dev/null)"; then
  default_branch="$(printf '%s\n' "$symref" | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')"
fi

if [ -n "$default_branch" ]; then
  echo "default_branch=$default_branch"
  echo "default_branch_source=remote"
  if [ "$branch" = "$default_branch" ]; then
    echo "on_default_branch=true"
  else
    echo "on_default_branch=false"
  fi
else
  # Offline nebo bez remotu — konzervativně předpokládej výchozí větev.
  echo "default_branch="
  echo "default_branch_source=unavailable"
  echo "on_default_branch=unknown"
fi

# --- upstream ------------------------------------------------------------
if upstream="$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)"; then
  echo "upstream=$upstream"
else
  echo "upstream="
fi

# --- rozsah změn ---------------------------------------------------------
staged_count="$(git diff --cached --name-only | wc -l | tr -d ' ')"
unstaged_count="$(git diff --name-only | wc -l | tr -d ' ')"
untracked_count="$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
echo "staged_count=$staged_count"
echo "unstaged_count=$unstaged_count"
echo "untracked_count=$untracked_count"

echo
echo "[status]"
git status --porcelain

if [ "$staged_count" -gt 0 ]; then
  echo
  echo "[staged]"
  git --no-pager diff --cached --stat
fi
