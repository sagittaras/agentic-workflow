#!/usr/bin/env bash
# Test kritérií issue #50 ověřitelných příkazem.
#
# Kritérium 4: verify-issue otevírá dokument citovaný v Reference na cestě vůči
#              kořeni repozitáře a nedohledá-li ho, sestoupí stromem od
#              CLAUDE.md podle shared/docs-tree.md;
#              `grep -n "Zdroje pravdy" skills/verify-issue/SKILL.md` nic nevrátí.
# Kritérium 5: `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

skill=skills/verify-issue/SKILL.md
fail=0

if grep -n "Zdroje pravdy" "$skill"; then
  echo "fail=criterion_4 reason=zdroje_pravdy_in_verify_issue"
  fail=1
fi

# Odstavec o doplňkovém dokumentu v kroku 3: cesta vůči kořeni, pak sestup
# stromem od CLAUDE.md podle kontraktu docs-tree.md.
doc_par="$(awk '/^Cituje-li Reference \*\*vedle kódu i dokument\*\*/{p=1} p&&/^$/{exit} p' "$skill")"
if [ -z "$doc_par" ]; then
  echo "fail=criterion_4 reason=document_paragraph_missing"
  fail=1
else
  for needle in 'vůči kořeni repozitáře' 'Nedohledáš-li' 'stromem dokumentace od `CLAUDE.md`' 'shared/docs-tree.md'; do
    if ! grep -qF -- "$needle" <<<"$(tr '\n' ' ' <<<"$doc_par")"; then
      echo "fail=criterion_4 reason=document_lookup_missing needle=\"$needle\""
      fail=1
    fi
  done
fi

if ! bash scripts/lint-skills.sh; then
  echo "fail=criterion_5 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
