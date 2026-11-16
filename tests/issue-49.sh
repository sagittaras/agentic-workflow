#!/usr/bin/env bash
# Test kritérií issue #49 ověřitelných příkazem.
#
# Kritérium 1: `bash scripts/docs-check.sh` projde s kódem 0 a vypíše result=pass.
# Kritérium 5: ověřovací příkaz u area:skills v CONTRIBUTING.md spouští vedle
#              lintu i `bash scripts/docs-check.sh`.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

out="$(bash scripts/docs-check.sh)"
rc=$?
echo "$out"
if [ "$rc" -ne 0 ] || ! grep -qx 'result=pass' <<<"$out"; then
  echo "fail=criterion_1 reason=docs_check_failed"
  fail=1
fi

row="$(grep -E '^\| area:skills \|' CONTRIBUTING.md || true)"
if ! grep -qF 'bash scripts/lint-skills.sh' <<<"$row" ||
   ! grep -qF 'bash scripts/docs-check.sh' <<<"$row"; then
  echo "fail=criterion_5 reason=area_skills_command_missing_docs_check"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
