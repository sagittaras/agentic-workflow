#!/usr/bin/env bash
# Vmerguje čerstvou výchozí větev do zadané větve a pushne ji.
# Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/sync-branch.sh <branch>
#   bash scripts/sync-branch.sh --no-push <branch>   # jen merge, bez pushe
#
# Skript končí na zadané větvi — merge se nedá udělat odjinud. Konflikt
# neřeší: merge abortuje, vypíše kolidující soubory a skončí kódem 5.
# Historie se jen rozrůstá, nikdy nepřepisuje: žádný rebase, žádný force.
#
# result=up_to_date  větev už výchozí obsahuje, nic se nemerguje
# result=fast_forward  větev byla jen pozadu, posunula se bez merge commitu
# result=merged  vznikl merge commit
# result=conflict  merge abortován, viz conflicts= a sekci [conflicts]
#
# Návratové kódy: 0 = hotovo, 2 = není repozitář nebo chybný argument,
# 3 = remote neodpověděl nebo push neprošel, 4 = pracovní strom není čistý
# nebo se lokální větev rozešla s remotem, 5 = konflikt.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

do_push=true
if [ "${1:-}" = "--no-push" ]; then
  do_push=false
  shift
fi

branch="${1:-}"
if [ -z "$branch" ]; then
  echo "error=missing_branch" >&2
  echo "hint=použití: sync-branch.sh [--no-push] <branch>" >&2
  exit 2
fi
echo "branch=$branch"

# --- čistota pracovního stromu -------------------------------------------
staged_count="$(git diff --cached --name-only | wc -l | tr -d ' ')"
unstaged_count="$(git diff --name-only | wc -l | tr -d ' ')"
if [ "$staged_count" -gt 0 ] || [ "$unstaged_count" -gt 0 ]; then
  echo "error=dirty_worktree" >&2
  echo "hint=commitni nebo odlož rozpracované změny; do špinavého stromu se nemerguje" >&2
  exit 4
fi

# --- výchozí větev -------------------------------------------------------
default_branch=""
if symref="$(git ls-remote --symref origin HEAD 2>/dev/null)"; then
  default_branch="$(printf '%s\n' "$symref" | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')"
fi
if [ -z "$default_branch" ]; then
  echo "error=default_branch_unavailable" >&2
  echo "hint=remote neodpověděl; bez znalosti výchozí větve není co mergovat" >&2
  exit 3
fi
echo "default_branch=$default_branch"

if [ "$branch" = "$default_branch" ]; then
  echo "error=target_is_default_branch" >&2
  echo "hint=výchozí větev se sama do sebe nemerguje; zkontroluj argument" >&2
  exit 2
fi

# --- fetch ---------------------------------------------------------------
exists_remote=false
if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
  exists_remote=true
fi

fetch_refs=("$default_branch")
if $exists_remote; then
  fetch_refs+=("$branch")
fi
if ! git fetch origin "${fetch_refs[@]}" --quiet; then
  echo "error=fetch_failed" >&2
  exit 3
fi

# --- přepnutí na cílovou větev -------------------------------------------
if git show-ref --verify --quiet "refs/heads/$branch"; then
  if ! git checkout --quiet "$branch"; then
    echo "error=checkout_failed" >&2
    exit 4
  fi
  if $exists_remote; then
    # Lokální větev musí stát na špičce remotu, jinak by push stejně neprošel.
    # Doháníme jen fast-forwardem; rozejitou historii skript neřeší.
    if ! git merge --ff-only --quiet "origin/$branch" 2>/dev/null; then
      if [ "$(git rev-list --count "origin/$branch..HEAD")" -gt 0 ] \
        && [ "$(git rev-list --count "HEAD..origin/$branch")" -gt 0 ]; then
        echo "error=local_branch_diverged" >&2
        echo "hint=lokální '$branch' a origin/$branch se rozešly; srovnat je musí člověk" >&2
        exit 4
      fi
    fi
  fi
elif $exists_remote; then
  if ! git checkout --quiet -b "$branch" --track "origin/$branch"; then
    echo "error=checkout_failed" >&2
    exit 4
  fi
else
  echo "error=branch_not_found" >&2
  echo "hint=větev '$branch' není lokálně ani na remotu" >&2
  exit 2
fi

# --- merge ---------------------------------------------------------------
behind="$(git rev-list --count "HEAD..origin/$default_branch")"
ahead="$(git rev-list --count "origin/$default_branch..HEAD")"
echo "behind=$behind"
echo "ahead=$ahead"

if [ "$behind" -eq 0 ]; then
  result="up_to_date"
else
  if merge_err="$(git merge --no-edit "origin/$default_branch" 2>&1)"; then
    if [ "$ahead" -eq 0 ]; then
      result="fast_forward"
    else
      result="merged"
    fi
  else
    conflicts="$(git diff --name-only --diff-filter=U || true)"
    git merge --abort 2>/dev/null || true
    echo "result=conflict"
    echo "conflicts=$(printf '%s' "$conflicts" | tr '\n' ',' | sed 's/,$//')"
    echo
    echo "[conflicts]"
    printf '%s\n' "$conflicts"
    echo
    echo "[merge_output]"
    printf '%s\n' "$merge_err"
    exit 5
  fi
fi

echo "result=$result"
echo "head=$(git rev-parse --short HEAD)"

# --- push ----------------------------------------------------------------
if ! $do_push; then
  echo "pushed="
  exit 0
fi

if [ "$result" = "up_to_date" ] && $exists_remote \
  && [ "$(git rev-list --count "origin/$branch..HEAD")" -eq 0 ]; then
  echo "pushed=nothing_to_push"
  exit 0
fi

if git rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1; then
  if ! git push --quiet; then
    echo "error=push_failed" >&2
    exit 3
  fi
  echo "pushed=$(git rev-parse --abbrev-ref '@{u}')"
else
  if ! git push --quiet -u origin "$branch"; then
    echo "error=push_failed" >&2
    exit 3
  fi
  echo "pushed=origin/$branch"
  echo "upstream_created=true"
fi
