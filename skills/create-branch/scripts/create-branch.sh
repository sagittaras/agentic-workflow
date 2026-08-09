#!/usr/bin/env bash
# Založí novou větev z čerstvé výchozí větve remotu a přepne na ni.
#
# Použití:
#   bash scripts/create-branch.sh <type>/<popis>
#   bash scripts/create-branch.sh --check <type>/<popis>   # jen ověří, nezakládá
#   bash scripts/create-branch.sh --base <ref> <type>/<popis>
#
# Větev se zakládá z origin/<výchozí větev> po fetchi, ne z aktuální větve —
# jinak by zdědila rozpracované commity a zastaralý stav. Upstream se
# nenastavuje (--no-track): nová větev nepatří k origin/<default> a publikuje
# se až vlastním pushem.
#
# --base <ref> zakládá z jiného základu než z výchozí větve. Existuje kvůli
# integračním větvím milestonů: práce na issue patří nad milestone/<slug>,
# ne nad výchozí větev, jinak by PR nesl i commity, které do něj nepatří.
# Přednost má origin/<ref>; jen když na remotu není, bere se lokální větev.
#
# Rozpracované změny v pracovním stromu přechází s tebou na novou větev.
# Odmítne-li to git kvůli kolizi se změnami mezi starým a novým bodem,
# skript to ohlásí a nic nezmění.
#
# Návratové kódy: 0 = hotovo, 2 = není repozitář nebo chybí argument,
# 3 = špatný tvar názvu, 4 = větev už existuje, 5 = nelze zjistit výchozí
# větev nebo zadaný --base neexistuje, 6 = fetch selhal, 7 = přepnutí selhalo
# (nejspíš kolize změn).

set -euo pipefail

TYPES='feat|fix|docs|refactor|test|chore|ci|build|perf|style'

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

check_only=false
base_arg=""
name=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) check_only=true; shift ;;
    --base)
      if [ -z "${2:-}" ]; then
        echo "error=missing_base_value" >&2
        echo "hint=--base čeká název větve, ze které se má vycházet" >&2
        exit 2
      fi
      base_arg="$2"; shift 2 ;;
    -*)
      echo "error=unknown_option" >&2
      echo "hint=neznámý přepínač $1" >&2
      exit 2 ;;
    *)
      if [ -z "$name" ]; then name="$1"; shift
      else
        echo "error=unexpected_argument" >&2
        echo "hint=přebývá argument '$1'" >&2
        exit 2
      fi ;;
  esac
done

if [ -z "$name" ]; then
  echo "error=missing_branch_name" >&2
  echo "hint=použití: create-branch.sh [--check] [--base <ref>] <type>/<popis>" >&2
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

# --- základ větve --------------------------------------------------------
# Zadaný --base má přednost před výchozí větví. Remote vyhrává nad lokální
# větví téhož jména: lokální kopie integrační větve bývá pozadu a nová větev
# by z ní zdědila stav, který ostatní už nevidí.
base_on_remote=false
if [ -n "$base_arg" ]; then
  if git ls-remote --exit-code --heads origin "$base_arg" >/dev/null 2>&1; then
    base_on_remote=true
    base_ref="origin/$base_arg"
    fetch_ref="$base_arg"
  elif git show-ref --verify --quiet "refs/heads/$base_arg"; then
    base_ref="$base_arg"
  else
    echo "error=base_branch_not_found" >&2
    echo "hint=základ '$base_arg' není na remotu ani lokálně" >&2
    exit 5
  fi
else
  default_branch=""
  if symref="$(git ls-remote --symref origin HEAD 2>/dev/null)"; then
    default_branch="$(printf '%s\n' "$symref" | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')"
  fi
  if [ -z "$default_branch" ]; then
    echo "error=default_branch_unavailable" >&2
    echo "hint=remote neodpověděl; bez znalosti výchozí větve skript větev nezaloží" >&2
    exit 5
  fi
  base_on_remote=true
  base_ref="origin/$default_branch"
  fetch_ref="$default_branch"
fi

echo "branch=$name"
echo "base=$base_ref"

if $check_only; then
  echo "check=ok"
  exit 0
fi

# --- fetch a založení ----------------------------------------------------
if $base_on_remote; then
  if ! git fetch origin "$fetch_ref" --quiet; then
    echo "error=fetch_failed" >&2
    exit 6
  fi
fi

if ! git checkout -b "$name" --no-track "$base_ref"; then
  echo "error=checkout_failed" >&2
  echo "hint=rozpracované změny nejspíš kolidují s rozdílem proti $base_ref" >&2
  exit 7
fi

echo "created=true"
echo "head=$(git rev-parse --short HEAD)"
