#!/usr/bin/env bash
# Najde definici agenta podle jména a vypíše z jejího frontmatteru model,
# effort a výčet nástrojů. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/agent-model.sh <jméno agenta>
#
# Hledá soubory *.md rekurzivně v .claude/agents/ kořene repozitáře a pak
# v ~/.claude/agents/ — první, jehož frontmatter má `name: <jméno>`. Název
# souboru nerozhoduje: init-workflow zapisuje do mapy Agenti hodnotu `name`,
# ne cestu. Agent pluginu (`plugin:jméno`) se nenajde.
#
# Výstup: found=true|false, path= (jen při nálezu), model=, effort=, tools=
# (názvy oddělené čárkou; prázdné, když definice výčet nemá a agent dědí
# všechny nástroje) a can_run_skills=true|false — false, když výčet existuje
# a chybí v něm Skill nebo Bash, bez nichž agent implement-issue neprovede.
# `model: inherit` se vypíše jako prázdný model.
#
# Návratové kódy: 0 = prohledáno (i když nenalezeno), 2 = chybí jméno.

set -euo pipefail

name="${1:-}"
if [ -z "$name" ]; then
  echo "error=missing_name" >&2
  echo "hint=použití: agent-model.sh <jméno agenta>" >&2
  exit 2
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Vypíše hodnotu klíče z frontmatteru (mezi prvními dvěma řádky ---).
# Výčet ve tvaru YAML seznamu (klíč bez hodnoty, pod ním „- položka") spojí
# čárkou. Konce řádků CRLF se odstraní dřív, než se cokoli porovná.
fm() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    inlist {
      if ($0 ~ /^[ \t]*-[ \t]*/) { v = $0; sub(/^[ \t]*-[ \t]*/, "", v); gsub(/^["\x27]+|["\x27 \t]+$/, "", v); out = out (out == "" ? "" : ",") v; next }
      exit
    }
    NR > 1 && index($0, key ":") == 1 {
      v = substr($0, length(key) + 2); gsub(/^[ \t"]+|[ \t"]+$/, "", v)
      if (v == "") { inlist = 1; next }
      print v; done = 1; exit
    }
    END { if (!done && out != "") print out }' "$1"
}

for dir in "$root/.claude/agents" "$HOME/.claude/agents"; do
  [ -d "$dir" ] || continue
  while IFS= read -r f; do
    if [ "$(fm "$f" name)" = "$name" ]; then
      model="$(fm "$f" model)"
      [ "$model" = "inherit" ] && model=""
      tools="$(fm "$f" tools | sed 's/[[:space:]]*,[[:space:]]*/,/g; s/^\[//; s/\]$//')"
      can=true
      if [ -n "$tools" ]; then
        case ",$tools," in *,Skill,*) : ;; *) can=false ;; esac
        case ",$tools," in *,Bash,*|*,Bash\(*) : ;; *) can=false ;; esac
      fi
      echo "found=true"
      echo "path=$f"
      echo "model=$model"
      echo "effort=$(fm "$f" effort)"
      echo "tools=$tools"
      echo "can_run_skills=$can"
      exit 0
    fi
  done < <(find "$dir" -type f -name '*.md' | sort)
done

echo "found=false"
echo "model="
echo "effort="
echo "tools="
echo "can_run_skills=true"
