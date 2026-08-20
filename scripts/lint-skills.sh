#!/usr/bin/env bash
# Ověřovací příkaz pro area:skills — validuje frontmatter každého SKILL.md
# v repozitáři: musí začínat "---", mít uzavírací "---", a v bloku mezi nimi
# obsahovat aspoň "name:" a "description:". Nekontroluje sémantiku hodnot,
# jen že frontmatter existuje a je strojově čitelný.
#
# Návratové kódy: 0 = všechny SKILL.md v pořádku, 1 = aspoň jeden nevalidní.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

fail=0

while IFS= read -r -d '' f; do
  first_line="$(head -n 1 "$f")"
  if [ "$first_line" != "---" ]; then
    echo "fail=$f reason=missing_opening_frontmatter"
    fail=1
    continue
  fi

  end_line="$(awk 'NR>1 && $0=="---"{print NR; exit}' "$f")"
  if [ -z "$end_line" ]; then
    echo "fail=$f reason=missing_closing_frontmatter"
    fail=1
    continue
  fi

  block="$(sed -n "2,$((end_line - 1))p" "$f")"

  if ! grep -q '^name:' <<<"$block"; then
    echo "fail=$f reason=missing_name_field"
    fail=1
    continue
  fi

  if ! grep -q '^description:' <<<"$block"; then
    echo "fail=$f reason=missing_description_field"
    fail=1
    continue
  fi

  if grep -qP '\t' <<<"$block"; then
    echo "fail=$f reason=tab_character_in_frontmatter"
    fail=1
    continue
  fi
done < <(find skills -type f -name 'SKILL.md' -print0)

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
