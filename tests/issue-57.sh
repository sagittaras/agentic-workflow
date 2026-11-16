#!/usr/bin/env bash
# Test kritérií issue #57 ověřitelných příkazem.
#
# Kritérium 3: review-milestone dohledá ADR citované bez cesty sestupem od
#              CLAUDE.md (odkazem na shared/docs-tree.md) místo Zdrojů pravdy
#              a Globu `.docs/adr/`; `grep -n -E "Zdroje pravdy|\.docs/adr/"
#              skills/review-milestone/SKILL.md` nic nevrátí.
# Kritérium 4: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

skill=skills/review-milestone/SKILL.md
fail=0

if grep -n -E "Zdroje pravdy|\.docs/adr/" "$skill"; then
  echo "fail=criterion_3 reason=zdroje_pravdy_or_adr_glob_in_review_milestone"
  fail=1
fi

# Odstavec kroku 3 o ADR bez cesty: sestup stromem od CLAUDE.md podle
# kontraktu docs-tree.md.
step3="$(awk '/^### 3\. /{p=1; next} p&&/^### /{exit} p' "$skill" | tr '\n' ' ')"
for needle in 'bez cesty' 'stromem dokumentace od `CLAUDE.md`' 'shared/docs-tree.md'; do
  if ! grep -qF -- "$needle" <<<"$step3"; then
    echo "fail=criterion_3 reason=adr_descent_missing needle=\"$needle\""
    fail=1
  fi
done

if ! bash scripts/lint-skills.sh; then
  echo "fail=criterion_4 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
