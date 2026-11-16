#!/usr/bin/env bash
# Test kritérií issue #56 ověřitelných příkazem.
#
# Kritérium 4: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

if ! bash scripts/lint-skills.sh; then
  echo "fail=criterion_4 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
