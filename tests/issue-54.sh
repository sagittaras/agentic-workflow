#!/usr/bin/env bash
# Test kritérií issue #54 ověřitelných příkazem.
#
# Kritérium 3: write-adr i review-adr čtou zázemí sestupem od CLAUDE.md;
# `grep -n "Zdroje pravdy" skills/write-adr/SKILL.md skills/review-adr/SKILL.md`
# nic nevrátí. Test navíc ověří, že oba skilly sestup od CLAUDE.md zmiňují.
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

for f in skills/write-adr/SKILL.md skills/review-adr/SKILL.md; do
  if ! grep -q "sestupem od \`CLAUDE.md\`" "$f"; then
    echo "fail=criterion_3 reason=missing_descent file=$f"
    fail=1
  fi
done

if ! bash scripts/lint-skills.sh >/dev/null; then
  echo "fail=criterion_5 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
