#!/usr/bin/env bash
# Vypíše stav aktuální větve vůči výchozí větvi, upstreamu a volitelně vůči
# základní větvi — to, z čeho se rozhoduje, než se nad větví založí PR nebo
# začne práce. Nic nemění kromě fetche základní větve.
#
# Použití:
#   bash scripts/branch-state.sh [--base B]
#
# Výstup key=value:
#   detached=true|false, branch=
#   default_branch=, default_branch_source=remote|unavailable,
#   on_default_branch=true|false|unknown
#   dirty=true|false            — nezapsané změny včetně nesledovaných souborů
#   upstream=, ahead=, behind=  — vůči upstreamu; bez upstreamu prázdné
#   pushed=true|false           — upstream existuje a nic nečeká na push
# S --base navíc:
#   base=, base_fetched=true|false,
#   base_ref=origin/B|B|        — remote ref má přednost před lokálním
#   base_source=remote|local|missing
#   commits_ahead=              — commity HEAD, které v base_ref nejsou
#   base_is_ancestor=true|false — větev opravdu vyšla z base_ref
#
# Výchozí větev se zjišťuje z remotu, ne z lokálního refs/remotes/origin/HEAD:
# ten po změně na serveru zůstává zastaralý.
#
# Základní větev se před porovnáním fetchne. Proti remote refu se porovnává
# proto, že lokální kopie bývá zastaralá a vydá věrohodně vypadající špatné
# číslo. Lokální větev je až náhrada: integrační větev milestonu na remotu
# být ještě nemusí. Selže-li fetch (offline, větev jen lokální), je
# base_fetched=false a porovnává se s tím, co je k dispozici.
#
# Návratové kódy: 0 = v pořádku, 2 = nejde o git repozitář nebo chybný
# argument, 4 = základní větev neexistuje ani na remotu, ani lokálně
# (výstup se přesto vypíše, s base_source=missing).

set -euo pipefail

base=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      if [ -z "${2:-}" ]; then
        echo "error=missing_value" >&2
        echo "hint=přepínač --base čeká název větve" >&2
        exit 2
      fi
      base="$2"; shift 2 ;;
    *)
      echo "error=unknown_option" >&2
      echo "hint=neznámý argument '$1'" >&2
      exit 2 ;;
  esac
done

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

if [ -n "$base" ] && ! git check-ref-format --branch "$base" >/dev/null 2>&1; then
  echo "error=invalid_base" >&2
  echo "hint='$base' není platný název větve" >&2
  exit 2
fi

# --- větev ---------------------------------------------------------------
branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  echo "detached=true"
else
  echo "detached=false"
fi
echo "branch=$branch"

# --- výchozí větev -------------------------------------------------------
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

# --- pracovní strom ------------------------------------------------------
if [ -n "$(git status --porcelain)" ]; then
  echo "dirty=true"
else
  echo "dirty=false"
fi

# --- upstream ------------------------------------------------------------
if upstream="$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)"; then
  counts="$(git rev-list --left-right --count "@{u}...HEAD")"
  behind="${counts%%[[:space:]]*}"
  ahead="${counts##*[[:space:]]}"
  echo "upstream=$upstream"
  echo "ahead=$ahead"
  echo "behind=$behind"
  if [ "$ahead" -eq 0 ]; then
    echo "pushed=true"
  else
    echo "pushed=false"
  fi
else
  echo "upstream="
  echo "ahead="
  echo "behind="
  echo "pushed=false"
fi

[ -n "$base" ] || exit 0

# --- základní větev ------------------------------------------------------
echo "base=$base"
if git fetch -q origin "$base" 2>/dev/null; then
  echo "base_fetched=true"
else
  echo "base_fetched=false"
fi

base_ref=""
base_source="missing"
if git show-ref --verify --quiet "refs/remotes/origin/$base"; then
  base_ref="origin/$base"
  base_source="remote"
elif git show-ref --verify --quiet "refs/heads/$base"; then
  base_ref="$base"
  base_source="local"
fi
echo "base_ref=$base_ref"
echo "base_source=$base_source"

if [ -z "$base_ref" ]; then
  echo "commits_ahead="
  echo "base_is_ancestor=false"
  echo "error=base_not_found" >&2
  exit 4
fi

echo "commits_ahead=$(git rev-list --count "$base_ref..HEAD")"
if git merge-base --is-ancestor "$base_ref" HEAD; then
  echo "base_is_ancestor=true"
else
  echo "base_is_ancestor=false"
fi
