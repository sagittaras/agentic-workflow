#!/usr/bin/env bash
# Vypíše mapu znalostní báze: strom indexů jako vnořený markdown seznam,
# u každé stránky a podsekce odkaz s cestou vůči kořeni repozitáře a větu,
# kterou ji popisuje index její složky. Čtenář podle mapy vybere stránky
# jedním voláním, místo aby otevíral indexy po jednom (shared/docs-tree.md,
# § Jak najít odpověď v bázi).
#
# Použití: bash scripts/docs-map.sh
#
# Mapuje repozitář, ve kterém je spuštěný (kořen podle git), ne ten, kde leží
# skript. Vstupní index je soubor index.md, na který odkazuje CLAUDE.md nebo
# .claude/CLAUDE.md — stejně jako v docs-check.sh. Odkazují-li na různé
# indexy, vypíše strom každého z nich.
#
# Do mapy patří odkazy indexu na vlastní stránky (soubor .md v jeho složce)
# a na podsekce (index.md v přímé podsložce); do podsekcí sestupuje
# rekurzivně. Větu bere z položky seznamu, jejímž prvním odkazem stránka je,
# a odkazy uvnitř věty nahradí jejich textem. Přednost má odkaz bez kotvy
# v položce seznamu; stránku odkázanou jen mimo seznam vypíše bez věty,
# stránku odkázanou jen s kotvou na konci, s cestou bez kotvy. Odkazy uvnitř bloků kódu, inline
# kódu a frontmatteru se nečtou.
#
# Výstup (cesty vůči kořeni, který nese první řádek):
#   root=<absolutní cesta ke kořeni repozitáře>
#   - [<nadpis vstupního indexu>](<cesta>)
#     - [<text odkazu>](<cesta>) — <věta>
#       - …
# Neodkazuje-li žádný CLAUDE.md na existující index.md, vypíše řádky
# fail=<soubor> reason=<důvod> s důvody missing_claude_md
# a missing_entry_index_link, stejnými jako docs-check.sh.
#
# Potřebuje jen bash, git a awk (gawk z Git for Windows stačí).
#
# Návratové kódy: 0 = mapa vypsaná, 1 = projekt bázi nemá, 2 = nejde o git
# repozitář.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

# Text se zpracovává po bajtech, aby výsledek nezávisel na locale; pomlčky
# v UTF-8 řeší awk program explicitně.
export LC_ALL=C

# --- awk: položky a odkazy -----------------------------------------------
# Vypíše záznamy oddělené tabulátorem:
#   H <nadpis>                  první nadpis 1. úrovně souboru,
#   I <text> <cíl> <věta>       první odkaz položky seznamu a zbytek položky,
#   L <text> <cíl>              každý další odkaz mimo bloky kódu.
# Inline kód se před hledáním odkazů schová za zástupné značky a ve výstupu
# se vrátí, aby věta zůstala celá a odkaz uvnitř kódu se nepočítal.
map_awk='
function protect(s,    out) {
  ncode = 0; out = ""
  while (match(s, /`[^`]*`/)) {
    code[++ncode] = substr(s, RSTART, RLENGTH)
    out = out substr(s, 1, RSTART - 1) "\001" ncode "\002"
    s = substr(s, RSTART + RLENGTH)
  }
  return out s
}
function restore(s,    i, tok, p) {
  for (i = 1; i <= ncode; i++) {
    tok = "\001" i "\002"
    while ((p = index(s, tok)) > 0)
      s = substr(s, 1, p - 1) code[i] substr(s, p + length(tok))
  }
  return s
}
function title_of(m,    t) { t = m; sub(/^\[/, "", t); sub(/\]\(.*$/, "", t); return t }
function target_of(m,    t) {
  t = m; sub(/^\[[^]]*\]\(/, "", t); sub(/\)$/, "", t)
  sub(/^[ \t]+/, "", t)
  if (substr(t, 1, 1) == "<") { t = substr(t, 2); sub(/>.*/, "", t) }
  else sub(/[ \t].*/, "", t)
  return t
}
function strip_links(s,    m) {
  while (match(s, /\[[^]]*\]\([^)]*\)/)) {
    m = substr(s, RSTART, RLENGTH)
    s = substr(s, 1, RSTART - 1) title_of(m) substr(s, RSTART + RLENGTH)
  }
  return s
}
function links_of(p,    m) {
  while (match(p, /\[[^]]*\]\([^)]*\)/)) {
    m = substr(p, RSTART, RLENGTH)
    p = substr(p, RSTART + RLENGTH)
    printf "L\t%s\t%s\t\n", restore(title_of(m)), restore(target_of(m))
  }
}
function flush(    p, m, rest, s) {
  if (item == "") return
  p = protect(item)
  item = ""
  if (!match(p, /\[[^]]*\]\([^)]*\)/)) return
  m = substr(p, RSTART, RLENGTH)
  rest = substr(p, RSTART + RLENGTH)
  sub(/^[*_]+/, "", rest); sub(/^[ \t]+/, "", rest)
  sub(/^(\342\200\224|\342\200\223|-|:)/, "", rest); sub(/^[ \t]+/, "", rest)
  s = restore(strip_links(rest)); sub(/[ \t]+$/, "", s)
  printf "I\t%s\t%s\t%s\n", restore(title_of(m)), restore(target_of(m)), s
  links_of(rest)
}
FNR == 1 { flush(); fence = ""; h1 = 0; front = ($0 == "---") }
{
  line = $0
  gsub(/\t/, " ", line)
  if (front) {
    if (FNR > 1 && line == "---") front = 0
    next
  }
  if (fence != "") {
    if (match(line, /^ {0,3}(`{3,}|~{3,})[ \t]*$/)) {
      f = line; sub(/^ +/, "", f); sub(/[ \t]+$/, "", f)
      if (substr(f, 1, 1) == substr(fence, 1, 1) && length(f) >= length(fence)) fence = ""
    }
    next
  }
  if (match(line, /^ {0,3}(`{3,}|~{3,})/)) {
    flush()
    f = substr(line, RSTART, RLENGTH); sub(/^ +/, "", f)
    fence = f
    next
  }
  if (!h1 && match(line, /^ {0,3}#[ \t]+/)) {
    flush()
    h = substr(line, RLENGTH + 1); sub(/[ \t]+#+[ \t]*$/, "", h)
    printf "H\t%s\n", h
    h1 = 1
    next
  }
  if (match(line, /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/)) {
    flush()
    item = substr(line, RLENGTH + 1)
    next
  }
  if (item != "" && line ~ /^[ \t]+[^ \t]/) {
    sub(/^[ \t]+/, "", line)
    item = item " " line
    next
  }
  flush()
  links_of(protect(line))
}
END { flush() }
'

# --- pomocné funkce ------------------------------------------------------

# Normalizuje cestu vůči kořeni: odstraní "." a vyřeší "..". Cestu, která
# z kořene utíká, vrátí s prefixem "../".
norm() {
  local IFS=/ part out=()
  for part in $1; do
    case "$part" in
      ''|.) ;;
      ..)
        if [ "${#out[@]}" -gt 0 ] && [ "${out[-1]}" != ".." ]; then
          unset 'out[-1]'
        else
          out+=("..")
        fi
        ;;
      *) out+=("$part") ;;
    esac
  done
  printf '%s' "${out[*]}"
}

# Dekóduje %XX v cíli odkazu.
urldecode() {
  local s="${1//+/%2B}"
  printf '%b' "${s//%/\\x}"
}

dir_of() {
  case "$1" in
    */*) printf '%s' "${1%/*}" ;;
    *) printf '' ;;
  esac
}

# Vyřeší relativní cíl odkazu ze souboru $1 na cestu vůči kořeni; kotvu
# odřízne jako docs-check.sh. Odkaz jen na kotvu, s URL schématem nebo
# absolutní vrátí prázdný.
resolve() {
  local src="$1" target="${2%%#*}" scheme
  case "$target" in
    ''|/*) return 0 ;;
  esac
  scheme="${target%%[/?]*}"
  case "$scheme" in *:*) return 0 ;; esac
  local dir path
  dir="$(dir_of "$src")"
  path="$(urldecode "${target%%\?*}")"
  norm "${dir:+$dir/}$path"
}

# --- mapa ----------------------------------------------------------------

declare -A visited=()

# Vypíše stránky a podsekce indexu $1, odsazené řetězcem $2.
map_index() {
  local idx="$1" indent="$2" dir prefix kind title target sentence resolved rel
  local -a kinds=() titles=() paths=() sentences=()
  local -A seen=()
  visited["$idx"]=1
  dir="$(dir_of "$idx")"
  prefix="${dir:+$dir/}"

  while IFS=$'\t' read -r kind title target sentence; do
    case "$kind" in I|L) ;; *) continue ;; esac
    case "$target" in *\#*) kind=A ;; esac
    resolved="$(resolve "$idx" "$target")"
    [ -n "$resolved" ] || continue
    [ -f "$resolved" ] || continue
    case "$resolved" in "$prefix"*) ;; *) continue ;; esac
    rel="${resolved#"$prefix"}"
    case "$rel" in
      index.md) continue ;;
      */*/*) continue ;;
      */index.md) ;;
      */*) continue ;;
      *.md) ;;
      *) continue ;;
    esac
    kinds+=("$kind"); titles+=("$title"); paths+=("$resolved"); sentences+=("$sentence")
  done < <(awk "$map_awk" "$idx")

  # Položky seznamu v pořadí indexu, pak stránky odkázané jen mimo seznam,
  # nakonec stránky odkázané jen s kotvou.
  local pass i
  for pass in I L A; do
    for i in "${!paths[@]}"; do
      [ "${kinds[$i]}" = "$pass" ] || continue
      resolved="${paths[$i]}"
      [ -z "${seen["$resolved"]+x}" ] || continue
      seen["$resolved"]=1
      if [ -n "${sentences[$i]}" ]; then
        printf '%s- [%s](%s) — %s\n' "$indent" "${titles[$i]}" "$resolved" "${sentences[$i]}"
      else
        printf '%s- [%s](%s)\n' "$indent" "${titles[$i]}" "$resolved"
      fi
      case "$resolved" in
        */index.md)
          if [ -z "${visited["$resolved"]+x}" ]; then
            map_index "$resolved" "$indent  "
          fi
          ;;
      esac
    done
  done
}

claude_files=()
for f in CLAUDE.md .claude/CLAUDE.md; do
  if [ -f "$f" ]; then
    claude_files+=("$f")
  fi
done

if [ "${#claude_files[@]}" -eq 0 ]; then
  echo "fail=CLAUDE.md reason=missing_claude_md"
  exit 1
fi

entries=()
declare -A is_entry=()
missing=()
for f in "${claude_files[@]}"; do
  found=0
  while IFS=$'\t' read -r kind _ target _; do
    case "$kind" in I|L) ;; *) continue ;; esac
    resolved="$(resolve "$f" "$target")"
    if [ "${resolved##*/}" = "index.md" ] && [ -f "$resolved" ]; then
      found=1
      if [ -z "${is_entry["$resolved"]+x}" ]; then
        is_entry["$resolved"]=1
        entries+=("$resolved")
      fi
    fi
  done < <(awk "$map_awk" "$f")
  if [ "$found" -eq 0 ]; then
    missing+=("$f")
  fi
done

if [ "${#entries[@]}" -eq 0 ]; then
  for f in "${missing[@]}"; do
    echo "fail=$f reason=missing_entry_index_link"
  done
  exit 1
fi

echo "root=$root"
for idx in "${entries[@]}"; do
  # Bez exit: předčasně ukončený druhý awk by prvnímu poslal SIGPIPE
  # a pipefail by skript shodil.
  title="$(awk "$map_awk" "$idx" | awk -F '\t' '$1 == "H" && !done { print $2; done = 1 }')"
  printf -- '- [%s](%s)\n' "${title:-$idx}" "$idx"
  map_index "$idx" "  "
done
