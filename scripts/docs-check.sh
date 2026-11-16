#!/usr/bin/env bash
# Ověří mechanická pravidla struktury znalostní báze podle shared/docs-tree.md.
# Výstup je key=value na stdout; nálezy jako řádky fail=.
#
# Použití: bash scripts/docs-check.sh
#
# Kontroluje repozitář, ve kterém je spuštěný (kořen podle git), ne ten, kde
# leží skript. Vstupní index je soubor index.md, na který odkazuje CLAUDE.md
# nebo .claude/CLAUDE.md; báze je složka vstupního indexu se vším pod ní.
# Hádání podle tvaru složek skript nedělá — bez odkazu z CLAUDE.md bázi nezná.
#
# Co hlídá:
#   - každý existující CLAUDE.md a .claude/CLAUDE.md odkazuje na vstupní index,
#   - každou stránku báze odkazuje index její složky; podsekci (její index.md)
#     odkazuje index nadřazené složky,
#   - relativní odkazy ve stránkách báze a v CLAUDE.md míří na existující soubor
#     nebo složku,
#   - kotva odkazu na markdown soubor existuje.
#
# Kotvy se odvozují z nadpisů jako na GitHubu: malá písmena, pryč všechno kromě
# písmen, číslic, "_", "-" a mezer, mezera → "-", opakovaný nadpis dostane
# příponu -1, -2… Malá písmena se odvozují pro ASCII, latinku (Latin-1,
# Latin Extended-A), řečtinu a azbuku; z ne-ASCII znaků se odstraňuje
# interpunkce Latin-1, rozsah U+2000–U+2BFF (pomlčky, uvozovky, šipky,
# matematické a další symboly) a emoji. Odkazy a nadpisy uvnitř bloků kódu
# (``` a ~~~) a inline kódu se nečtou. Odkazy s URL schématem (https:, mailto:…)
# a absolutní cesty skript nekontroluje.
#
# Výstup: řádky fail=<soubor> reason=<důvod>, u nálezů v odkazu doplněné
# o line=<řádek> link=<cíl>; result=pass, když nic nenašel.
#
# Důvody nálezu: missing_claude_md (není CLAUDE.md ani .claude/CLAUDE.md),
# missing_entry_index_link (CLAUDE.md neodkazuje na existující index.md),
# orphan_page (stránku neodkazuje index její složky), dead_link (cíl
# relativního odkazu neexistuje), missing_anchor (kotva v cílovém souboru
# neexistuje).
#
# Potřebuje jen bash, git, find a awk (gawk z Git for Windows stačí).
#
# Návratové kódy: 0 = struktura v pořádku, 1 = aspoň jeden nález,
# 2 = nejde o git repozitář.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

# Nadpisy i odkazy se zpracovávají po bajtech, aby výsledek nezávisel na
# locale; UTF-8 sekvence řeší awk program explicitně.
export LC_ALL=C

fail=0

# --- awk: odkazy ---------------------------------------------------------
# Vypíše "<soubor>\t<řádek>\t<cíl>" pro každý inline odkaz [text](cíl)
# mimo bloky kódu a inline kód.
links_awk='
FNR == 1 { fence = "" }
{
  line = $0
  if (fence != "") {
    if (match(line, /^ {0,3}(`{3,}|~{3,})[ \t]*$/)) {
      f = line; sub(/^ +/, "", f); sub(/[ \t]+$/, "", f)
      if (substr(f, 1, 1) == substr(fence, 1, 1) && length(f) >= length(fence)) fence = ""
    }
    next
  }
  if (match(line, /^ {0,3}(`{3,}|~{3,})/)) {
    f = substr(line, RSTART, RLENGTH); sub(/^ +/, "", f)
    fence = f
    next
  }
  gsub(/`[^`]*`/, "", line)
  while (match(line, /\]\([^)]*\)/)) {
    t = substr(line, RSTART + 2, RLENGTH - 3)
    line = substr(line, RSTART + RLENGTH)
    sub(/^[ \t]+/, "", t)
    if (substr(t, 1, 1) == "<") {
      t = substr(t, 2); sub(/>.*/, "", t)
    } else {
      sub(/[ \t].*/, "", t)
    }
    if (t != "") printf "%s\t%d\t%s\n", FILENAME, FNR, t
  }
}
'

# --- awk: kotvy ----------------------------------------------------------
# Vypíše "<soubor>\t<kotva>" pro každý nadpis (ATX i setext) mimo bloky kódu.
anchors_awk='
function utf8(cp) {
  if (cp < 128) return sprintf("%c", cp)
  return sprintf("%c%c", 192 + int(cp / 64), 128 + cp % 64)
}
function pair(from, to) { lc[utf8(from)] = utf8(to) }
BEGIN {
  for (cp = 192; cp <= 222; cp++) if (cp != 215) pair(cp, cp + 32)
  for (cp = 256; cp <= 310; cp += 2) if (cp != 304) pair(cp, cp + 1)
  for (cp = 313; cp <= 327; cp += 2) pair(cp, cp + 1)
  for (cp = 330; cp <= 374; cp += 2) pair(cp, cp + 1)
  pair(376, 255)
  for (cp = 377; cp <= 381; cp += 2) pair(cp, cp + 1)
  for (cp = 913; cp <= 937; cp++) if (cp != 930) pair(cp, cp + 32)
  for (cp = 1024; cp <= 1039; cp++) pair(cp, cp + 80)
  for (cp = 1040; cp <= 1071; cp++) pair(cp, cp + 32)
}
function lower(s,    out, i, c, n) {
  s = tolower(s)
  out = ""
  n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 2)
    if (c in lc) { out = out lc[c]; i++ }
    else out = out substr(s, i, 1)
  }
  return out
}
function slug(text,    s) {
  gsub(/!?\[/, "", text)
  gsub(/\]\([^)]*\)/, "", text)
  gsub(/<[^>]*>/, "", text)
  sub(/^[ \t]+/, "", text); sub(/[ \t]+$/, "", text)
  s = lower(text)
  gsub(/\302[\240-\251\253-\264\266-\271\273-\277]/, "", s)
  gsub(/\303[\227\267]/, "", s)
  gsub(/\342[\200-\257][\200-\277]/, "", s)
  gsub(/\360\237[\200-\253][\200-\277]/, "", s)
  gsub(/[^a-z0-9_ \200-\377-]/, "", s)
  gsub(/ /, "-", s)
  return s
}
function emit(text,    s) {
  s = slug(text)
  if (s == "") return
  if (seen[FILENAME, s]++) s = s "-" (seen[FILENAME, s] - 1)
  printf "%s\t%s\n", FILENAME, s
}
FNR == 1 { fence = ""; prev = ""; front = ($0 == "---") }
{
  line = $0
  if (front) {
    if (FNR > 1 && line == "---") front = 0
    next
  }
  if (fence != "") {
    if (match(line, /^ {0,3}(`{3,}|~{3,})[ \t]*$/)) {
      f = line; sub(/^ +/, "", f); sub(/[ \t]+$/, "", f)
      if (substr(f, 1, 1) == substr(fence, 1, 1) && length(f) >= length(fence)) fence = ""
    }
    prev = ""
    next
  }
  if (match(line, /^ {0,3}(`{3,}|~{3,})/)) {
    f = substr(line, RSTART, RLENGTH); sub(/^ +/, "", f)
    fence = f
    prev = ""
    next
  }
  if (match(line, /^ {0,3}#{1,6}([ \t]|$)/)) {
    h = substr(line, RLENGTH + 1)
    sub(/[ \t]+#+[ \t]*$/, "", h)
    sub(/^#+[ \t]*$/, "", h)
    emit(h)
    prev = ""
    next
  }
  if (prev != "" && line ~ /^ {0,3}(=+|-+)[ \t]*$/) {
    emit(prev)
    prev = ""
    next
  }
  if (line ~ /^[ \t]*$/ || line ~ /^ {0,3}([-*+]|[0-9]+[.)]|>|\|)/ || line ~ /^ {4}/) prev = ""
  else prev = line
}
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

# --- CLAUDE.md a vstupní index -------------------------------------------

claude_files=()
for f in CLAUDE.md .claude/CLAUDE.md; do
  [ -f "$f" ] && claude_files+=("$f")
done

if [ "${#claude_files[@]}" -eq 0 ]; then
  echo "fail=CLAUDE.md reason=missing_claude_md"
  exit 1
fi

declare -A entry_index=()
for f in "${claude_files[@]}"; do
  found=0
  while IFS=$'\t' read -r src _ target; do
    case "$target" in
      \#*|/*|*:*) continue ;;
    esac
    path="$(urldecode "${target%%#*}")"
    dir="$(dir_of "$src")"
    resolved="$(norm "${dir:+$dir/}$path")"
    if [ "${resolved##*/}" = "index.md" ] && [ -f "$resolved" ]; then
      entry_index["$resolved"]=1
      found=1
    fi
  done < <(awk "$links_awk" "$f")
  if [ "$found" -eq 0 ]; then
    echo "fail=$f reason=missing_entry_index_link"
    fail=1
  fi
done

# --- stránky báze --------------------------------------------------------

pages=()
declare -A is_entry=()
for idx in "${!entry_index[@]}"; do
  is_entry["$idx"]=1
  base="$(dir_of "$idx")"
  while IFS= read -r -d '' p; do
    pages+=("${p#./}")
  done < <(find "${base:-.}" -type f -name '*.md' -print0)
done

scan=("${claude_files[@]}")
if [ "${#pages[@]}" -gt 0 ]; then
  mapfile -t sorted < <(printf '%s\n' "${pages[@]}" | sort -u)
  pages=("${sorted[@]}")
  scan+=("${pages[@]}")
fi

# --- odkazy: existence cíle ----------------------------------------------

declare -A linked=()      # "<zdroj>|<cíl>" — kam který soubor odkazuje
anchor_checks=()          # "<zdroj>\t<řádek>\t<odkaz>\t<cílový soubor>\t<kotva>"
anchor_files=()

while IFS=$'\t' read -r src line target; do
  case "$target" in
    /*) continue ;;
    \#*)
      anchor_checks+=("$src"$'\t'"$line"$'\t'"$target"$'\t'"$src"$'\t'"$(urldecode "${target#\#}")")
      anchor_files+=("$src")
      continue
      ;;
  esac
  scheme="${target%%[/#?]*}"
  case "$scheme" in *:*) continue ;; esac

  path_part="${target%%#*}"
  path_part="${path_part%%\?*}"
  path="$(urldecode "$path_part")"
  dir="$(dir_of "$src")"
  resolved="$(norm "${dir:+$dir/}$path")"

  if [ ! -e "${resolved:-.}" ]; then
    echo "fail=$src reason=dead_link line=$line link=$target"
    fail=1
    continue
  fi
  linked["$src|$resolved"]=1

  case "$target" in
    *\#*)
      case "$resolved" in
        *.md|*.MD|*.markdown)
          anchor_checks+=("$src"$'\t'"$line"$'\t'"$target"$'\t'"$resolved"$'\t'"$(urldecode "${target#*\#}")")
          anchor_files+=("$resolved")
          ;;
      esac
      ;;
  esac
done < <(awk "$links_awk" "${scan[@]}")

# --- kotvy ---------------------------------------------------------------

if [ "${#anchor_checks[@]}" -gt 0 ]; then
  declare -A anchors=()
  mapfile -t uniq_files < <(printf '%s\n' "${anchor_files[@]}" | sort -u)
  while IFS=$'\t' read -r file anchor; do
    anchors["$file#$anchor"]=1
  done < <(awk "$anchors_awk" "${uniq_files[@]}")

  for check in "${anchor_checks[@]}"; do
    IFS=$'\t' read -r src line target file anchor <<<"$check"
    if [ -z "${anchors["$file#$anchor"]+x}" ]; then
      echo "fail=$src reason=missing_anchor line=$line link=$target"
      fail=1
    fi
  done
fi

# --- sirotci -------------------------------------------------------------

for p in "${pages[@]}"; do
  [ -n "${is_entry["$p"]+x}" ] && continue
  dir="$(dir_of "$p")"
  if [ "${p##*/}" = "index.md" ]; then
    parent="$(dir_of "$dir")"
  else
    parent="$dir"
  fi
  parent_index="${parent:+$parent/}index.md"
  if [ -z "${linked["$parent_index|$p"]+x}" ]; then
    echo "fail=$p reason=orphan_page"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
