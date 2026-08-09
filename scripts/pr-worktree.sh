#!/usr/bin/env bash
# Připraví oddělenou pracovní kopii větve (typicky větve PR) v dočasném
# worktree a zase ji ukliď. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/pr-worktree.sh <label> <ref>     # založí nebo převezme
#   bash scripts/pr-worktree.sh --remove <label>  # ukliď
#
# Cesta se odvozuje z <label> deterministicky, ne z mktemp: volající skill
# pracuje ve víc voláních Bash za sebou a mezi nimi mu nepřežije stav shellu.
# Náhodná cesta by při druhém volání založila druhý, prázdný worktree — a
# ověřovací příkaz by pak spadl na chybějícím prostředí, ne na kódu.
# Jako label se hodí číslo PR: `pr-42`.
#
# Opakované spuštění nad týmž labelem existující worktree převezme
# (reused=true) — i s obnovenými závislostmi, které v něm už jsou.
#
# Skript je čtecí: nefetchuje nic, co nedostal, a sám nikdy necommituje,
# nepushuje, nemerguje ani nemaže větve. Odpojená HEAD je záměr — do worktree
# se nemá commitovat.
#
# Návratové kódy: 0 = hotovo, 2 = není repozitář, chybný argument nebo ref
# neexistuje, 3 = remote neodpověděl nebo fetch selhal.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

remove=false
if [ "${1:-}" = "--remove" ]; then
  remove=true
  shift
fi

label="${1:-}"
if [ -z "$label" ]; then
  echo "error=missing_label" >&2
  echo "hint=použití: pr-worktree.sh <label> <ref> | pr-worktree.sh --remove <label>" >&2
  exit 2
fi

if ! printf '%s' "$label" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "error=invalid_label" >&2
  echo "hint=label je kebab-case z malých písmen a číslic, např. 'pr-42'" >&2
  exit 2
fi

wt_raw="${TMPDIR:-/tmp}/sagittaras-worktree-$label"
if command -v cygpath >/dev/null 2>&1; then
  # Git Bash: git i nativní ověřovací příkazy rozumí smíšené cestě C:/…
  wt="$(cygpath -m "$wt_raw" 2>/dev/null || printf '%s' "$wt_raw")"
else
  wt="$wt_raw"
fi

echo "worktree=$wt"

# --- úklid ---------------------------------------------------------------
if $remove; then
  if [ -d "$wt" ]; then
    # Bez --force: když worktree remove odmítne (artefakty po buildu),
    # smažeme adresář a evidenci uklidí prune.
    git worktree remove "$wt" >/dev/null 2>&1 || {
      rm -rf "$wt" >/dev/null 2>&1 || true
      git worktree prune >/dev/null 2>&1 || true
    }
  else
    git worktree prune >/dev/null 2>&1 || true
  fi
  if [ -d "$wt" ]; then
    echo "removed=false"
    echo "hint=adresář '$wt' zůstal; nejspíš ho drží běžící proces" >&2
  else
    echo "removed=true"
  fi
  exit 0
fi

ref_arg="${2:-}"
if [ -z "$ref_arg" ]; then
  echo "error=missing_ref" >&2
  echo "hint=použití: pr-worktree.sh <label> <ref>" >&2
  exit 2
fi

# --- převzetí existujícího -----------------------------------------------
# Zakládat znovu by zahodilo obnovené závislosti, kvůli kterým se worktree
# mezi voláními drží.
if [ -d "$wt" ]; then
  echo "reused=true"
  existing_ref="$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'HEAD')"
  # abbrev-ref vrací u odpojené HEAD doslova "HEAD"; to není název větve.
  [ "$existing_ref" = "HEAD" ] && existing_ref="detached"
  echo "ref=$existing_ref"
  echo "head=$(git -C "$wt" rev-parse --short HEAD)"
  exit 0
fi

# --- co je na remotu -----------------------------------------------------
# ls-remote rozlišuje "větev tam není" (2) od "remote nemluví" (cokoli jiného);
# bez toho rozdílu by výpadek sítě vypadal jako chybějící větev.
rc=0
git ls-remote --exit-code --heads origin "$ref_arg" >/dev/null 2>&1 || rc=$?
case "$rc" in
  0)
    if ! git fetch origin "$ref_arg" --quiet; then
      echo "error=fetch_failed" >&2
      exit 3
    fi
    ref="origin/$ref_arg"
    ;;
  2)
    if git rev-parse --verify --quiet "refs/heads/$ref_arg" >/dev/null 2>&1; then
      ref="$ref_arg"
    else
      echo "error=ref_not_found" >&2
      echo "hint=větev '$ref_arg' není na remotu ani lokálně" >&2
      exit 2
    fi
    ;;
  *)
    echo "error=remote_unreachable" >&2
    echo "hint=git ls-remote origin '$ref_arg' selhal (kód $rc)" >&2
    exit 3
    ;;
esac

# --- založení ------------------------------------------------------------
# --detach: do ověřovací kopie se nemá commitovat a odpojená HEAD to říká
# nahlas. Zároveň tím větev nezablokujeme pro nikoho jiného.
if ! git worktree add --detach --quiet "$wt" "$ref"; then
  echo "error=worktree_failed" >&2
  echo "hint=nepodařilo se založit worktree v '$wt'" >&2
  exit 3
fi

echo "reused=false"
echo "ref=$ref"
echo "head=$(git -C "$wt" rev-parse --short HEAD)"
