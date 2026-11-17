#!/usr/bin/env bash
# Test scripts/gh/pr-for-branch.sh a receptu „Najdi PR podle head větve".
#
# Běží proti živému repozitáři sagittaras/agentic-workflow, potřebuje síť
# a přihlášené gh. Opírá se o zmergované PR #84 z větve
# fix/najdi-pr-pro-issue-podle-tela do main, které se už nezmění.
#
# Kritérium 1: k větvi vrátí PR 84, i s --base main.
# Kritérium 2: shoda názvu je přesná — prefix větve ani jiný základ nevrátí nic,
#              a --state open zmergované PR vynechá.
# Kritérium 3: řádek receptu v shared/forge-recipes.md vede na pr-for-branch.sh.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

repo="sagittaras/agentic-workflow"
head="fix/najdi-pr-pro-issue-podle-tela"
fail=0

has_pr() { grep -q "\"number\":$1[,}]" <<<"$2"; }
q() { bash scripts/gh/pr-for-branch.sh -R "$repo" "$@"; }

out="$(q "$head")" || { echo "fail=criterion_1 reason=script_failed"; exit 1; }
out_base="$(q "$head" --base main)" || { echo "fail=criterion_1 reason=script_failed_with_base"; exit 1; }
if ! has_pr 84 "$out" || ! has_pr 84 "$out_base"; then
  echo "fail=criterion_1 reason=pr_84_not_found"
  fail=1
fi

prefix="$(q fix/najdi-pr)" || { echo "fail=criterion_2 reason=script_failed"; exit 1; }
other_base="$(q "$head" --base milestone/neexistuje)" || { echo "fail=criterion_2 reason=script_failed"; exit 1; }
open="$(q "$head" --state open)" || { echo "fail=criterion_2 reason=script_failed"; exit 1; }
if [ "$prefix" != "[]" ] || [ "$other_base" != "[]" ] || [ "$open" != "[]" ]; then
  echo "fail=criterion_2 reason=filter_too_lenient"
  fail=1
fi

row="$(grep '^| Najdi PR podle head větve |' shared/forge-recipes.md)"
if ! grep -q 'gh/pr-for-branch.sh' <<<"$row"; then
  echo "fail=criterion_3 reason=recipe_not_updated"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
