#!/usr/bin/env bash
# Test scripts/gh/pr-reviews.sh a scripts/gh/pr-update.sh.
#
# Běží proti živému repozitáři sagittaras/agentic-workflow, potřebuje síť
# a přihlášené gh. Opírá se o zmergované PR #78, které nese review komentář
# „Brána prošla" od orchestrátoru a už se nezmění.
#
# Kritérium 1: pr-reviews.sh vypíše všechny tři sekce a v [reviews] najde
#              review s „Brána prošla".
# Kritérium 2: pr-update.sh bez -R nebo bez těla skončí kódem 2 dřív, než
#              sáhne na gh (živé PR se neupravuje).
# Kritérium 3: recepty v shared/forge-recipes.md vedou na oba skripty.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"
repo="sagittaras/agentic-workflow"
fail=0

out="$(bash scripts/gh/pr-reviews.sh -R "$repo" 78)" || { echo "fail=criterion_1 reason=script_failed"; exit 1; }
for s in '[reviews]' '[line_comments]' '[comments]'; do
  grep -qxF "$s" <<<"$out" || { echo "fail=criterion_1 reason=missing_section section=$s"; fail=1; }
done
reviews="$(sed -n '/^\[reviews\]$/,/^$/p' <<<"$out")"
grep -q 'Brána prošla' <<<"$reviews" || { echo "fail=criterion_1 reason=review_not_found"; fail=1; }

bash scripts/gh/pr-update.sh 78 --body-file README.md >/dev/null 2>&1; rc1=$?
bash scripts/gh/pr-update.sh -R "$repo" 78 >/dev/null 2>&1; rc2=$?
if [ "$rc1" -ne 2 ] || [ "$rc2" -ne 2 ]; then
  echo "fail=criterion_2 reason=missing_args_not_rejected rc1=$rc1 rc2=$rc2"; fail=1
fi

grep -q '^| Přečti připomínky k PR |.*gh/pr-reviews.sh' shared/forge-recipes.md \
  || { echo "fail=criterion_3 reason=reviews_recipe_missing"; fail=1; }
grep -q '^| Uprav tělo PR |.*gh/pr-update.sh' shared/forge-recipes.md \
  || { echo "fail=criterion_3 reason=update_recipe_missing"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
