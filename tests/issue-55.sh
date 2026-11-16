#!/usr/bin/env bash
# Test kritérií issue #55 ověřitelných příkazem.
#
# Kritérium 1: `grep -n "Zdroje pravdy" skills/write-ux-spec/SKILL.md` nic
# nevrátí. Umístění z indexu sekce rozhraní a odkázání z nadřazeného indexu je
# úsudek nad textem; test hlídá aspoň, že skill odkazuje na shared/docs-tree.md.
# Kritérium 5: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

f=skills/write-ux-spec/SKILL.md
fail=0

if grep -n "Zdroje pravdy" "$f"; then
  echo "fail=criterion_1 reason=zdroje_pravdy_present"
  fail=1
fi

if ! grep -q "shared/docs-tree.md" "$f"; then
  echo "fail=criterion_1 reason=docs_tree_not_referenced"
  fail=1
fi

if ! bash scripts/lint-skills.sh >/dev/null; then
  echo "fail=criterion_5 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
