#!/usr/bin/env bash
# Test kritérií issue #51 ověřitelných příkazem.
#
# Kritérium 5: `plan-milestone` nečte Zdroje pravdy a ADR dohledá sestupem
#              od `CLAUDE.md` (odkazem na `shared/docs-tree.md`).
# Kritérium 6: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

if grep -n "Zdroje pravdy" skills/plan-milestone/SKILL.md; then
  echo "fail=criterion_5 reason=zdroje_pravdy_in_plan_milestone"
  fail=1
fi

if ! grep -q "shared/docs-tree.md" skills/plan-milestone/SKILL.md \
  || ! grep -q "CLAUDE.md" skills/plan-milestone/SKILL.md; then
  echo "fail=criterion_5 reason=missing_docs_tree_descent"
  fail=1
fi

if ! bash scripts/lint-skills.sh; then
  echo "fail=criterion_6 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
