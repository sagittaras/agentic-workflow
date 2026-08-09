#!/usr/bin/env bash
# Založí nebo checkoutne integrační větev milestone/<slug> a přepne na ni.
# Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/milestone-branch.sh <slug>
#   bash scripts/milestone-branch.sh --check <slug>   # jen ověří, nic nemění
#
# Když větev na remotu už existuje, skript ji fetchne a checkoutne — nezaloží
# ji znovu. Znovuzaložení by zahodilo práci předchozího běhu, který se přerušil.
# Nová větev vzniká z origin/<výchozí větev> po fetchi, ne z aktuální větve,
# aby nezdědila rozpracované commity a zastaralý stav.
#
# Nově založenou větev skript rovnou publikuje. Není to pohodlí: dokud
# milestone/<slug> není na remotu, nelze proti ní otevřít PR, takže by první
# dávka issues každého milestonu skončila prací bez pull requestu.
#
# Klíč base= říká, z čeho větev stojí: origin/<výchozí větev> u nově založené,
# origin/<větev> u té převzaté z remotu, local u té, která už lokálně byla.
#
# Klíč pushed= říká, jestli publikování proběhlo (true), nebylo potřeba,
# protože větev na remotu už byla (false), nebo se nedělalo v režimu --check
# (skipped).
#
# Návratové kódy: 0 = hotovo, 2 = není repozitář nebo chybný argument,
# 3 = remote neodpověděl nebo push neprošel, 4 = pracovní strom není čistý
# (nebo checkout blokují rozpracované změny).

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

check_only=false
if [ "${1:-}" = "--check" ]; then
  check_only=true
  shift
fi

slug="${1:-}"
if [ -z "$slug" ]; then
  echo "error=missing_slug" >&2
  echo "hint=použití: milestone-branch.sh [--check] <slug>" >&2
  exit 2
fi

if ! printf '%s' "$slug" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "error=invalid_slug" >&2
  echo "hint=slug je kebab-case z malých písmen a číslic, např. 'sprint-3-onboarding'" >&2
  exit 2
fi

branch="milestone/$slug"
echo "branch=$branch"

# --- čistota pracovního stromu -------------------------------------------
# Blokují jen změny ve sledovaných souborech; ty by přepnutí větve odneslo
# s sebou do jiného kontextu. Untracked se jen hlásí.
staged_count="$(git diff --cached --name-only | wc -l | tr -d ' ')"
unstaged_count="$(git diff --name-only | wc -l | tr -d ' ')"
untracked_count="$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
echo "untracked_count=$untracked_count"

if [ "$staged_count" -gt 0 ] || [ "$unstaged_count" -gt 0 ]; then
  echo "error=dirty_worktree" >&2
  echo "hint=commitni nebo odlož rozpracované změny; integrační větev se zakládá z čistého stromu" >&2
  exit 4
fi

# --- výchozí větev -------------------------------------------------------
default_branch=""
if symref="$(git ls-remote --symref origin HEAD 2>/dev/null)"; then
  default_branch="$(printf '%s\n' "$symref" | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')"
fi
if [ -z "$default_branch" ]; then
  echo "error=default_branch_unavailable" >&2
  echo "hint=remote neodpověděl; bez znalosti výchozí větve skript větev nezaloží" >&2
  exit 3
fi
echo "default_branch=$default_branch"

# --- kde větev už je -----------------------------------------------------
exists_local=false
if git show-ref --verify --quiet "refs/heads/$branch"; then
  exists_local=true
fi

exists_remote=false
if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
  exists_remote=true
fi

echo "exists_local=$exists_local"
echo "exists_remote=$exists_remote"

if $exists_remote; then
  base_desc="origin/$branch"
elif $exists_local; then
  base_desc="local"
else
  base_desc="origin/$default_branch"
fi

if $check_only; then
  echo "created=false"
  echo "base=$base_desc"
  echo "pushed=skipped"
  echo "check=ok"
  exit 0
fi

# --- fetch ---------------------------------------------------------------
fetch_refs=("$default_branch")
if $exists_remote; then
  fetch_refs+=("$branch")
fi
if ! git fetch origin "${fetch_refs[@]}" --quiet; then
  echo "error=fetch_failed" >&2
  exit 3
fi

# --- checkout ------------------------------------------------------------
if $exists_local; then
  if ! git checkout --quiet "$branch"; then
    echo "error=checkout_blocked" >&2
    echo "hint=přepnutí na '$branch' selhalo; nejspíš kolidují untracked soubory" >&2
    exit 4
  fi
  created=false
  if $exists_remote; then
    # Doháníme remote, ale jen tam, kam to jde bez merge commitu. Rozejitou
    # historii skript neřeší, jen ohlásí.
    if git merge --ff-only --quiet "origin/$branch" 2>/dev/null; then
      echo "remote_sync=fast_forward_or_up_to_date"
    else
      echo "remote_sync=diverged"
    fi
  fi
elif $exists_remote; then
  if ! git checkout --quiet -b "$branch" --track "origin/$branch"; then
    echo "error=checkout_blocked" >&2
    echo "hint=převzetí větve '$branch' z remotu selhalo; nejspíš kolidují untracked soubory" >&2
    exit 4
  fi
  created=false
else
  if ! git checkout --quiet -b "$branch" --no-track "origin/$default_branch"; then
    echo "error=checkout_blocked" >&2
    echo "hint=založení větve selhalo; nejspíš kolidují untracked soubory s obsahem origin/$default_branch" >&2
    exit 4
  fi
  created=true
fi

echo "created=$created"
echo "base=$base_desc"

# --- publikace -----------------------------------------------------------
# Bez větve na remotu nejde založit PR, který by z ní vycházel. Publikujeme
# proto hned, ne až s prvním merge.
if $exists_remote; then
  echo "pushed=false"
else
  if ! git push --quiet --set-upstream origin "$branch"; then
    echo "error=push_failed" >&2
    echo "hint=větev '$branch' vznikla lokálně, ale nešla publikovat; bez remotu nad ní nepůjde otevřít PR" >&2
    exit 3
  fi
  echo "pushed=true"
fi

echo "head=$(git rev-parse --short HEAD)"
