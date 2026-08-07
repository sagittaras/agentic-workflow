#!/usr/bin/env bash
# Vypíše stav repozitáře, ze kterého create-branch rozhoduje, než založí větev.
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
  echo "detached=true"
  echo "branch="
else
  echo "detached=false"
  echo "branch=$branch"
fi

# --- výchozí větev -------------------------------------------------------
# Ptáme se remotu; lokálnímu refs/remotes/origin/HEAD nevěříme, po změně
# výchozí větve na remotu zůstává zastaralý.
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
  echo "default_branch="
  echo "default_branch_source=unavailable"
  echo "on_default_branch=unknown"
fi

# --- rozpracovaná práce --------------------------------------------------
# Počty jdou po souborech; git status --porcelain níže sbaluje celé adresáře,
# takže se čísla a výpis nemusí shodovat.
echo "staged_count=$(git diff --cached --name-only | wc -l | tr -d ' ')"
echo "unstaged_count=$(git diff --name-only | wc -l | tr -d ' ')"
echo "untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"

# --- existující větve ----------------------------------------------------
echo
echo "[local_branches]"
git --no-pager branch --format='%(refname:short)'

echo
echo "[status]"
git status --porcelain
