#!/usr/bin/env bash
# Test kritérií issue #54 ověřitelných příkazem.
#
# Kritérium 3: write-adr i review-adr čtou zázemí sestupem od CLAUDE.md;
# `grep -n "Zdroje pravdy" skills/write-adr/SKILL.md skills/review-adr/SKILL.md`
# nic nevrátí. Test navíc ověří, že oba skilly sestup od CLAUDE.md zmiňují;
# write-adr od zavedení read-docs čte zázemí jím (skill čte bázi stromem
# podle shared/docs-tree.md), takže u něj stačí volání read-docs.
# Kritérium 5: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

if grep -n "Zdroje pravdy" skills/write-adr/SKILL.md skills/review-adr/SKILL.md; then
  echo "fail=criterion_3 reason=zdroje_pravdy_still_present"
  fail=1
fi

if ! grep -q "sestupem od \`CLAUDE.md\`" skills/review-adr/SKILL.md; then
  echo "fail=criterion_3 reason=missing_descent file=skills/review-adr/SKILL.md"
  fail=1
fi
if ! grep -q "sestupem od \`CLAUDE.md\`\|sagittaras:read-docs" skills/write-adr/SKILL.md; then
  echo "fail=criterion_3 reason=missing_descent file=skills/write-adr/SKILL.md"
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
