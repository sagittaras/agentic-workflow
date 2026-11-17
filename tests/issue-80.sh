#!/usr/bin/env bash
# Test kritérií issue #80: recept „Najdi PR patřící k issue“ najde na GitHubu
# i PR do integrační větve.
#
# Běží proti živému repozitáři sagittaras/agentic-workflow, potřebuje síť
# a přihlášené gh. Opírá se o PR, která už jsou zmergovaná a nezmění se:
# PR #75 míří do milestone/promitnuti-principu-1-7-3-1-do-skillu a v těle má
# "Closes #56", GitHub ho přesto k issue #56 nepropojí. Recept ho podle
# shared/forge-recipes.md musí najít — s --base i bez něj.
#
# Kritérium 1: gh/pr-for-issue.sh k issue 56 vrátí PR 75, i s --base
#              integrační větve.
# Kritérium 2: číslo musí sedět celé — k issue 5 PR 75 nepatří.
# Kritérium 3: řádek receptu v shared/forge-recipes.md vede na pr-for-issue.sh,
#              ne na closedByPullRequestsReferences.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

repo="sagittaras/agentic-workflow"
integration="milestone/promitnuti-principu-1-7-3-1-do-skillu"
fail=0

has_pr() { grep -q "\"number\":$1[,}]" <<<"$2"; }

out="$(bash scripts/gh/pr-for-issue.sh -R "$repo" 56)" || { echo "fail=criterion_1 reason=script_failed"; exit 1; }
out_base="$(bash scripts/gh/pr-for-issue.sh -R "$repo" 56 --base "$integration")" \
  || { echo "fail=criterion_1 reason=script_failed_with_base"; exit 1; }
if ! has_pr 75 "$out" || ! has_pr 75 "$out_base"; then
  echo "fail=criterion_1 reason=pr_75_not_found"
  fail=1
fi

out5="$(bash scripts/gh/pr-for-issue.sh -R "$repo" 5)" || { echo "fail=criterion_2 reason=script_failed"; exit 1; }
if has_pr 75 "$out5"; then
  echo "fail=criterion_2 reason=partial_number_match"
  fail=1
fi

row="$(grep '^| Najdi PR patřící k issue |' shared/forge-recipes.md)"
if ! grep -q 'gh/pr-for-issue.sh' <<<"$row" || grep -q 'closedByPullRequestsReferences' <<<"$row"; then
  echo "fail=criterion_3 reason=recipe_not_updated"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
