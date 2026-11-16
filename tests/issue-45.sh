#!/usr/bin/env bash
# Test kritérií issue #45 ověřitelných příkazem.
#
# Kritérium 1: `shared/workflow-config.md` nezná podsekci Zdroje pravdy.
# Kritérium 2: podsekce Agenti v kontraktu nemá role recenzentů.
# Kritérium 5: `CONTRIBUTING.md` nemá podsekci Zdroje pravdy.
# Kritérium 6: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

if grep -n "Zdroje pravdy" shared/workflow-config.md; then
  echo "fail=criterion_1 reason=zdroje_pravdy_in_workflow_config"
  fail=1
fi

if grep -n -E "kvalita kódu|akceptační kritéria:" shared/workflow-config.md; then
  echo "fail=criterion_2 reason=reviewer_roles_in_workflow_config"
  fail=1
fi

if grep -n "Zdroje pravdy" CONTRIBUTING.md; then
  echo "fail=criterion_5 reason=zdroje_pravdy_in_contributing"
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
