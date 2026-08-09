#!/usr/bin/env bash
# Ověří, že PR obstojí proti aktuální špičce integrační větve.
# Výstup je key=value na stdout; sekce s výpisy jsou uvozené hlavičkou v [].
#
# Použití:
#   bash scripts/integration-gate.sh <pr-branch> <integration-branch>
#   bash scripts/integration-gate.sh <pr-branch> <integration-branch> -- <příkaz…>
#
# Merge probíhá v dočasném worktree s odpojenou HEAD, takže pracovní strom
# volajícího zůstane netknutý a nezáleží na tom, na jaké větvi zrovna stojí.
# Worktree se po sobě uklidí vždy, i při konfliktu; jediná stopa, která
# zůstává, je sekce [output] s výstupem ověřovacího příkazu.
#
# Bez příkazu za -- se jen zkusí merge a check=skipped.
#
# Je to brána, ne merge: skript nikdy nepushuje, nemaže větve a výsledek
# merge nikam nezapisuje. Konflikt abortuje a ohlásí.
#
# Návratové kódy: 0 = merge i příkaz prošly, 2 = není repozitář nebo chybný
# argument, 3 = remote neodpověděl, 5 = konflikt při merge, 6 = ověřovací
# příkaz selhal.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

pr_branch="${1:-}"
integration_branch="${2:-}"
if [ -z "$pr_branch" ] || [ -z "$integration_branch" ]; then
  echo "error=missing_branch_argument" >&2
  echo "hint=použití: integration-gate.sh <pr-branch> <integration-branch> [-- <příkaz…>]" >&2
  exit 2
fi
shift 2

cmd=()
if [ "${1:-}" = "--" ]; then
  shift
  cmd=("$@")
elif [ "$#" -gt 0 ]; then
  echo "error=unexpected_argument" >&2
  echo "hint=ověřovací příkaz odděl dvojicí pomlček: -- <příkaz…>" >&2
  exit 2
fi

# --- co je na remotu -----------------------------------------------------
# ls-remote rozlišuje "větev tam není" (2) od "remote nemluví" (cokoli
# jiného); bez toho rozdílu by výpadek sítě vypadal jako chybějící větev.
remote_has() {
  local b="$1" rc=0
  git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1 || rc=$?
  case "$rc" in
    0) return 0 ;;
    2) return 1 ;;
    *)
      echo "error=remote_unreachable" >&2
      echo "hint=git ls-remote origin '$b' selhal (kód $rc)" >&2
      exit 3
      ;;
  esac
}

fetch_refs=()
if remote_has "$pr_branch"; then
  fetch_refs+=("$pr_branch")
fi
if remote_has "$integration_branch"; then
  fetch_refs+=("$integration_branch")
fi

if [ "${#fetch_refs[@]}" -gt 0 ]; then
  if ! git fetch origin "${fetch_refs[@]}" --quiet; then
    echo "error=fetch_failed" >&2
    exit 3
  fi
fi

resolve_ref() {
  local b="$1"
  if git rev-parse --verify --quiet "refs/remotes/origin/$b" >/dev/null 2>&1; then
    printf 'origin/%s' "$b"
  elif git rev-parse --verify --quiet "refs/heads/$b" >/dev/null 2>&1; then
    printf '%s' "$b"
  else
    return 1
  fi
}

pr_ref="$(resolve_ref "$pr_branch")" || {
  echo "error=pr_branch_not_found" >&2
  echo "hint=větev '$pr_branch' není lokálně ani na remotu" >&2
  exit 2
}
integration_ref="$(resolve_ref "$integration_branch")" || {
  echo "error=integration_branch_not_found" >&2
  echo "hint=větev '$integration_branch' není lokálně ani na remotu" >&2
  exit 2
}

echo "pr_ref=$pr_ref"
echo "integration_ref=$integration_ref"

# --- dočasný worktree ----------------------------------------------------
tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/sagittaras-gate.XXXXXX")"
wt_raw="$tmpdir/tree"
if command -v cygpath >/dev/null 2>&1; then
  # Git Bash: git i nativní ověřovací příkaz rozumí smíšené cestě C:/…
  wt="$(cygpath -m "$wt_raw")"
  outfile="$(cygpath -m "$tmpdir/output.log")"
else
  wt="$wt_raw"
  outfile="$tmpdir/output.log"
fi

cleanup_done=false
cleanup_ok=false
cleanup() {
  if $cleanup_done; then return 0; fi
  cleanup_done=true
  if [ -d "$wt" ]; then
    # Bez --force: když worktree remove odmítne (artefakty po buildu),
    # smažeme adresář a evidenci uklidí prune.
    git -C "$root" worktree remove "$wt" >/dev/null 2>&1 || {
      rm -rf "$wt" >/dev/null 2>&1 || true
      git -C "$root" worktree prune >/dev/null 2>&1 || true
    }
  fi
  rm -rf "$tmpdir" >/dev/null 2>&1 || true
  # Hlásí se až skutečný stav, ne záměr: worktree s uzamčenými soubory
  # (typicky běžící proces po buildu) na Windows zůstat může.
  if [ -d "$wt" ]; then cleanup_ok=false; else cleanup_ok=true; fi
}
trap cleanup EXIT

echo "worktree=$wt"

if ! git worktree add --detach --quiet "$wt" "$pr_ref"; then
  echo "error=worktree_failed" >&2
  echo "hint=nepodařilo se založit dočasný worktree v $wt" >&2
  exit 3
fi

# --- merge ---------------------------------------------------------------
if merge_out="$(git -C "$wt" merge --no-edit "$integration_ref" 2>&1)"; then
  echo "merge=ok"
else
  conflicts="$(git -C "$wt" diff --name-only --diff-filter=U || true)"
  git -C "$wt" merge --abort >/dev/null 2>&1 || true
  echo "merge=conflict"
  echo "check=skipped"
  echo "conflicts=$(printf '%s' "$conflicts" | tr '\n' ',' | sed 's/,$//')"
  cleanup
  echo "worktree_removed=$cleanup_ok"
  echo
  echo "[conflicts]"
  printf '%s\n' "$conflicts"
  echo
  echo "[merge_output]"
  printf '%s\n' "$merge_out"
  exit 5
fi

# --- ověřovací příkaz ----------------------------------------------------
if [ "${#cmd[@]}" -eq 0 ]; then
  echo "check=skipped"
  cleanup
  echo "worktree_removed=$cleanup_ok"
  exit 0
fi

echo "command=${cmd[*]}"

rc=0
( cd "$wt" && "${cmd[@]}" ) >"$outfile" 2>&1 || rc=$?

if [ "$rc" -eq 0 ]; then
  echo "check=pass"
else
  echo "check=fail"
fi
echo "exit_code=$rc"

# Výstup si přečteme dřív, než ho úklid smaže i s dočasným adresářem.
out_content="$(cat "$outfile")"
cleanup
echo "worktree_removed=$cleanup_ok"
echo
echo "[output]"
printf '%s\n' "$out_content"

if [ "$rc" -ne 0 ]; then
  exit 6
fi
