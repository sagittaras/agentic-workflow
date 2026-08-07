#!/usr/bin/env bash
# Založí novou větev z čerstvé výchozí větve remotu a přepne na ni.
#
# Použití:
#   bash scripts/create-branch.sh <type>/<popis>
#   bash scripts/create-branch.sh --check <type>/<popis>   # jen ověří, nezakládá
#
# Větev se zakládá z origin/<výchozí větev> po fetchi, ne z aktuální větve —
# jinak by zdědila rozpracované commity a zastaralý stav. Upstream se
# nenastavuje (--no-track): nová větev nepatří k origin/<default> a publikuje
# se až vlastním pushem.
#
# Rozpracované změny v pracovním stromu přechází s tebou na novou větev.
# Odmítne-li to git kvůli kolizi se změnami mezi starým a novým bodem,
# skript to ohlásí a nic nezmění.
#
# Návratové kódy: 0 = hotovo, 2 = není repozitář nebo chybí argument,
# 3 = špatný tvar názvu, 4 = větev už existuje, 5 = nelze zjistit výchozí
# větev, 6 = fetch selhal, 7 = přepnutí selhalo (nejspíš kolize změn).

set -euo pipefail

TYPES='feat|fix|docs|refactor|test|chore|ci|build|perf|style'

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

name="${1:-}"
if [ -z "$name" ]; then
  echo "error=missing_branch_name" >&2
  echo "hint=použití: create-branch.sh [--check] <type>/<popis>" >&2
  exit 2
fi

# --- tvar názvu ----------------------------------------------------------
if ! printf '%s' "$name" | grep -qE "^($TYPES)/[a-z0-9]+(-[a-z0-9]+)*$"; then
  echo "error=invalid_branch_name" >&2
  echo "hint=tvar je <type>/<popis-v-kebab-case>; type je jeden z: ${TYPES//|/, }" >&2
  exit 3
fi

# --- kolize názvu --------------------------------------------------------
if git show-ref --verify --quiet "refs/heads/$name"; then
  echo "error=branch_exists_locally" >&2
  exit 4
fi
if git ls-remote --exit-code --heads origin "$name" >/dev/null 2>&1; then
  echo "error=branch_exists_on_remote" >&2
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
  exit 5
fi

echo "branch=$name"
echo "base=origin/$default_branch"

if $check_only; then
  echo "check=ok"
  exit 0
fi

# --- fetch a založení ----------------------------------------------------
if ! git fetch origin "$default_branch" --quiet; then
  echo "error=fetch_failed" >&2
  exit 6
fi

if ! git checkout -b "$name" --no-track "origin/$default_branch"; then
  echo "error=checkout_failed" >&2
  echo "hint=rozpracované změny nejspíš kolidují s rozdílem proti origin/$default_branch" >&2
  exit 7
fi

echo "created=true"
echo "head=$(git rev-parse --short HEAD)"
