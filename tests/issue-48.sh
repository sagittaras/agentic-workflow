#!/usr/bin/env bash
# Test kritérií issue #48 ověřitelných příkazem.
#
# Kritérium 3: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

if bash scripts/lint-skills.sh; then
  echo "result=pass"
  exit 0
fi

echo "fail=criterion_3 reason=lint_skills_failed"
exit 1
