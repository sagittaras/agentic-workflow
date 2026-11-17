#!/usr/bin/env bash
# Ověří mapu kritérium → test v těle PR proti kritériím issue a proti změně.
# Výstup je key=value na stdout; nálezy jako řádky fail=.
#
# Použití:
#   bash scripts/criteria-tests.sh --issue-body <soubor> --pr-body <soubor> \
#     --base <cílová větev> --head <větev PR> [--ticked-body <soubor>]
#
# Kritéria se čtou ze sekce "## Akceptační kritéria" těla issue (řádky "- [ ]"
# nebo "- [x]") v pořadí, v jakém tam stojí. Značka "(ověří člověk)" kritérium
# vyjímá z povinnosti mít test; platí i s vysvětlivkou za oddělovačem,
# třeba "(ověří člověk — důvod)".
#
# Mapa se čte z tabulky pod nadpisem "## Testy kritérií" v těle PR:
#
#   | # | Kritérium | Test |
#   | --- | --- | --- |
#   | 1 | <zkrácené znění> | `cesta/k/testu` — `název testu` |
#   | 2 | <zkrácené znění> | ověří člověk |
#
# Číslo v prvním sloupci je pořadí kritéria v issue. Cesta k testu (první
# hodnota v backticku) musí patřit mezi soubory, které PR mění proti cílové
# větvi (git diff base...head): test, který session nenapsala ani nerozšířila,
# kritérium nekryje.
#
# Skript posuzuje jen úplnost mapy a cesty — ne to, jestli test kritérium kryje
# dobře; to je úsudek pro člověka nebo ručně spuštěný verify-issue.
#
# S --ticked-body a výsledkem pass zapíše do souboru tělo issue, ve kterém jsou
# kritéria s potvrzeným testem odškrtnutá. Do trackeru skript sám nezapisuje.
#
# Výstup: criteria=, tested=, human=, changed_files=, řádky
# fail=<kritérium|pr> reason=<důvod>, ticked_body= (jen s --ticked-body a pass),
# result=pass|fail.
#
# Důvody nálezu (kód 1, patří zpátky session): missing_map_section, missing_row,
# no_test_path, test_not_in_change, unexpected_human, unknown_criterion,
# duplicate_row.
#
# Návratové kódy: 0 = mapa sedí, 1 = nález, 2 = chybný argument, nečitelný
# soubor, neexistující ref nebo issue bez sekce kritérií (error= na stderr),
# 3 = remote neodpověděl.

set -euo pipefail

die() { echo "error=$1" >&2; [ -n "${2:-}" ] && echo "hint=$2" >&2; exit "${3:-2}"; }

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die not_a_git_repository
cd "$root"

issue_body="" pr_body="" base="" head="" ticked_out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --issue-body)  issue_body="${2:-}"; shift 2 ;;
    --pr-body)     pr_body="${2:-}"; shift 2 ;;
    --base)        base="${2:-}"; shift 2 ;;
    --head)        head="${2:-}"; shift 2 ;;
    --ticked-body) ticked_out="${2:-}"; shift 2 ;;
    *) die unexpected_argument "neznámý argument '$1'" ;;
  esac
done
[ -n "$issue_body" ] && [ -n "$pr_body" ] && [ -n "$base" ] && [ -n "$head" ] \
  || die missing_argument "povinné: --issue-body --pr-body --base --head"
[ -r "$issue_body" ] || die unreadable_file "$issue_body"
[ -r "$pr_body" ] || die unreadable_file "$pr_body"

# --- změna PR ------------------------------------------------------------
# Přednost má stav na remotu; lokální větev jen tehdy, když na remotu není.
resolve_ref() {
  local b="$1" rc=0
  git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1 || rc=$?
  case "$rc" in
    0) git fetch --quiet origin "$b" || die fetch_failed "$b" 3
       echo "origin/$b" ;;
    2) git rev-parse --verify --quiet "refs/heads/$b" >/dev/null \
         || die ref_not_found "větev '$b' není na remotu ani lokálně"
       echo "$b" ;;
    *) die remote_unreachable "git ls-remote origin '$b' selhal (kód $rc)" 3 ;;
  esac
}
base_ref="$(resolve_ref "$base")"
head_ref="$(resolve_ref "$head")"
changed="$(git diff --name-only "$base_ref...$head_ref")"
changed_count="$(printf '%s\n' "$changed" | grep -c . || true)"

# --- kritéria issue ------------------------------------------------------
# Výstup: <pořadí>\t<1 = ověří člověk, 0 = test>
criteria="$(tr -d '\r' <"$issue_body" | awk '
  /^## / { in_sec = ($0 ~ /^## Akceptační kritéria[[:space:]]*$/); next }
  in_sec && /^- \[[ xX]\] / { n++; print n "\t" ($0 ~ /\(ověří člověk[)[:space:]—–:,-]/ ? 1 : 0) }
')"
[ -n "$criteria" ] || die missing_criteria_section "tělo issue nemá sekci '## Akceptační kritéria' s řádky '- [ ]'"
criteria_count="$(printf '%s\n' "$criteria" | grep -c .)"

# --- mapa v PR -----------------------------------------------------------
# Výstup: <číslo>\t<buňka Test>; hlavička a oddělovač tabulky odpadnou na čísle.
has_map="$(tr -d '\r' <"$pr_body" | grep -c '^## Testy kritérií[[:space:]]*$' || true)"
rows="$(tr -d '\r' <"$pr_body" | awk -F'|' '
  /^## / { in_sec = ($0 ~ /^## Testy kritérií[[:space:]]*$/); next }
  in_sec && /^\|/ {
    idx = $2; gsub(/[[:space:]]/, "", idx)
    if (idx !~ /^[0-9]+$/) next
    cell = $(NF-1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
    print idx "\t" cell
  }
')"

fails=() tested=0 human=0 confirmed=()
if [ "$has_map" -eq 0 ]; then
  fails+=("fail=pr reason=missing_map_section")
fi

# Řádky, které míří mimo kritéria issue, nebo se opakují.
if [ -n "$rows" ]; then
  while IFS=$'\t' read -r idx _; do
    [ "$idx" -ge 1 ] && [ "$idx" -le "$criteria_count" ] \
      || fails+=("fail=$idx reason=unknown_criterion")
  done <<<"$rows"
  while read -r dup; do
    [ -n "$dup" ] && fails+=("fail=$dup reason=duplicate_row")
  done < <(printf '%s\n' "$rows" | cut -f1 | sort -n | uniq -d)
fi

while IFS=$'\t' read -r i is_human; do
  [ "$is_human" -eq 1 ] && human=$((human + 1))
  [ "$has_map" -eq 0 ] && continue
  cell="$(printf '%s\n' "$rows" | awk -F'\t' -v i="$i" '$1 == i { print $2; exit }')"
  if [ -z "$cell" ]; then
    fails+=("fail=$i reason=missing_row"); continue
  fi
  path="$(printf '%s' "$cell" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')"
  path="${path#./}"
  if [ -z "$path" ]; then
    if [ "$is_human" -eq 1 ]; then continue; fi
    if printf '%s' "$cell" | grep -qi 'ověří člověk'; then
      fails+=("fail=$i reason=unexpected_human")
    else
      fails+=("fail=$i reason=no_test_path")
    fi
    continue
  fi
  if ! printf '%s\n' "$changed" | grep -qxF -- "$path"; then
    fails+=("fail=$i reason=test_not_in_change"); continue
  fi
  if [ "$is_human" -eq 0 ]; then
    tested=$((tested + 1)); confirmed+=("$i")
  fi
done <<<"$criteria"

echo "criteria=$criteria_count"
echo "tested=$tested"
echo "human=$human"
echo "changed_files=$changed_count"

if [ "${#fails[@]}" -gt 0 ]; then
  printf '%s\n' "${fails[@]}"
  echo "result=fail"
  exit 1
fi

if [ -n "$ticked_out" ]; then
  tr -d '\r' <"$issue_body" | awk -v list=" ${confirmed[*]} " '
    /^## / { in_sec = ($0 ~ /^## Akceptační kritéria[[:space:]]*$/); print; next }
    in_sec && /^- \[[ xX]\] / {
      n++
      if (index(list, " " n " ")) sub(/^- \[ \]/, "- [x]")
    }
    { print }
  ' >"$ticked_out"
  echo "ticked_body=$ticked_out"
fi
echo "result=pass"
