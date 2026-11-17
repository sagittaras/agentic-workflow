#!/usr/bin/env bash
# Mutačně ověří, jestli test hlídá produkční změnu: v pracovní kopii vrátí
# změnu zadaných produkčních souborů proti základu, pustí test (musí spadnout),
# kopii obnoví a pustí test znovu (musí projít).
# Výstup je key=value na stdout; sekce s výpisy jsou uvozené hlavičkou v [].
#
# Použití:
#   bash scripts/mutation-check.sh --worktree W --base REF --file P [--file P…] -- <příkaz…>
#
# W je oddělená pracovní kopie PR (typicky z pr-worktree.sh), REF základ PR
# (typicky origin/<pr-base>), P produkční soubory, jejichž změnu test hlídá —
# testy samotné mezi ně nepatří, nový test musí zůstat. Příkaz běží
# s pracovním adresářem W; složený příkaz zabal do bash -c '…'.
#
# Revert dělá git (diff merge-base..HEAD | apply -R), ne editace souborů,
# takže obnovení je deterministické a ověřitelné. Pracovní kopie musí být
# před startem čistá — jinak by obnovení smazalo cizí změny, a proto se
# skript bez čisté kopie ani nerozběhne.
#
# Výstup: base=, files=, applied=true|false, mutant=killed|survived,
# restored=true|false, original=pass|fail,
# verdict=covered|not_covered|inconclusive, sekce [mutant_output]
# a [original_output] (posledních 60 řádků).
#   covered      — s vrácenou změnou test spadl, s obnovenou prošel
#   not_covered  — test prošel i s vrácenou změnou: změnu nehlídá
#   inconclusive — test padá i nad obnovenou kopií, mutace nic nedokazuje
# mutant=killed znamená jen nenulový kód: spadl-li místo testu build, ukáže
# to [mutant_output] a důkaz to není.
#
# Návratové kódy: 0 = mutace proběhla (výsledek nese verdict), 2 = chybný
# argument, W není git pracovní kopie nebo REF neexistuje, 4 = W není před
# startem čistá, 5 = git apply -R selhal (kopie zůstala beze změny),
# 6 = obnovení selhalo — W zahoď a založ znovu.

set -euo pipefail

usage_error() {
  echo "error=$1" >&2
  [ "$#" -lt 2 ] || echo "hint=$2" >&2
  exit 2
}

wt=""
base=""
files=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --worktree) [ -n "${2:-}" ] || usage_error missing_value "--worktree čeká cestu"; wt="$2"; shift 2 ;;
    --base) [ -n "${2:-}" ] || usage_error missing_value "--base čeká ref"; base="$2"; shift 2 ;;
    --file) [ -n "${2:-}" ] || usage_error missing_value "--file čeká cestu"; files+=("$2"); shift 2 ;;
    --) shift; break ;;
    *) usage_error unknown_option "neznámý argument '$1'; příkaz odděl dvojicí pomlček" ;;
  esac
done
cmd=("$@")

[ -n "$wt" ] || usage_error missing_worktree "chybí --worktree"
[ -n "$base" ] || usage_error missing_base "chybí --base"
[ "${#files[@]}" -gt 0 ] || usage_error missing_file "zadej aspoň jeden produkční soubor přes --file"
[ "${#cmd[@]}" -gt 0 ] || usage_error missing_command "chybí testovací příkaz za --"

git -C "$wt" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || usage_error not_a_git_worktree "'$wt' není git pracovní kopie"
git -C "$wt" rev-parse --verify --quiet "$base^{commit}" >/dev/null \
  || usage_error base_not_found "ref '$base' neexistuje"

if [ -n "$(git -C "$wt" status --porcelain)" ]; then
  echo "error=worktree_dirty" >&2
  echo "hint=pracovní kopie není čistá; obnovení by smazalo cizí změny" >&2
  exit 4
fi

merge_base="$(git -C "$wt" merge-base "$base" HEAD)"
echo "base=$merge_base"
echo "files=${#files[@]}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$wt" diff --binary "$merge_base" HEAD -- "${files[@]}" >"$tmp/change.patch"
if [ ! -s "$tmp/change.patch" ]; then
  echo "applied=false"
  echo "error=empty_change" >&2
  echo "hint=zadané soubory se proti základu nemění; mutovat není co" >&2
  exit 5
fi
if ! git -C "$wt" apply -R "$tmp/change.patch" 2>"$tmp/apply.err"; then
  echo "applied=false"
  echo "error=apply_failed" >&2
  cat "$tmp/apply.err" >&2
  exit 5
fi
echo "applied=true"

run_cmd() {
  local out="$1" rc=0
  ( cd "$wt" && "${cmd[@]}" ) >"$out" 2>&1 || rc=$?
  return "$rc"
}

if run_cmd "$tmp/mutant.log"; then
  mutant=survived
else
  mutant=killed
fi
echo "mutant=$mutant"

# Obnovení: sledované soubory zpět na HEAD a pryč s tím, co revert vytvořil
# (soubor, který PR smazal, revert vrátil jako nesledovaný). Úklid je omezený
# na zadané soubory; ignorované artefakty (závislosti, build) zůstávají.
git -C "$wt" checkout -q -- . 2>/dev/null || true
git -C "$wt" clean -fdq -- "${files[@]}" 2>/dev/null || true
if [ -n "$(git -C "$wt" status --porcelain)" ]; then
  echo "restored=false"
  echo
  echo "[status]"
  git -C "$wt" status --porcelain
  exit 6
fi
echo "restored=true"

if run_cmd "$tmp/original.log"; then
  original=pass
else
  original=fail
fi
echo "original=$original"

if [ "$original" = fail ]; then
  verdict=inconclusive
elif [ "$mutant" = survived ]; then
  verdict=not_covered
else
  verdict=covered
fi
echo "verdict=$verdict"

echo
echo "[mutant_output]"
tail -n 60 "$tmp/mutant.log"
echo
echo "[original_output]"
tail -n 60 "$tmp/original.log"
