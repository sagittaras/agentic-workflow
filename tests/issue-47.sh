#!/usr/bin/env bash
# Test kritérií issue #47 ověřitelných příkazem.
#
# Kritérium 4: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

if bash scripts/lint-skills.sh; then
  echo "result=pass"
  exit 0
fi

echo "fail=criterion_4 reason=lint_skills_failed"
exit 1
