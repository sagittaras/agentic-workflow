#!/usr/bin/env bash
# Test kritérií issue #52 ověřitelných příkazem.
#
# Kritérium 5: `skills/implement-issue/SKILL.md` nezná Zdroje pravdy.
# Kritérium 6: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

if grep -n "Zdroje pravdy" skills/implement-issue/SKILL.md; then
  echo "fail=criterion_5 reason=zdroje_pravdy_in_implement_issue"
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
