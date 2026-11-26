#!/usr/bin/env bash
# Test scripts/gh/pr-watch.sh a přepínačů --add-label a --remove-label
# v scripts/gh/issue-update.sh.
#
# Běží proti živému repozitáři sagittaras/agentic-workflow, potřebuje síť
# a přihlášené gh. Opírá se o větev, do které nikdy nepovede PR, a o PR #90
# a #91 zmergovaná do main 18. a 19. 11. 2026.
#
# Kritérium 1: pr-watch.sh bez --base, s chybným --since nebo --interval
#              skončí kódem 2 dřív, než sáhne na gh.
# Kritérium 2: pr-watch.sh --once nad základní větví bez otevřených PR vypíše
#              event=idle a next_since ve tvaru 2026-11-26T14:00:00Z; zadané
#              --since vrátí beze změny.
# Kritérium 3: issue-update.sh přijme --add-label i --remove-label jako jedinou
#              změnu a bez hodnoty je odmítne kódem 2 (živé issue se neupravuje).
# Kritérium 4: shared/git-scripts.md popisuje pr-watch.sh i oba přepínače labelů.
# Kritérium 5: merge se hlásí podle času, i když PR skript nikdy neviděl
#              otevřené: --since mezi oběma merge vrátí event=merged pr=91, ne pr=90,
#              a next_since nejméně čas merge #91.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"
repo="sagittaras/agentic-workflow"
nobase="zz-pr-watch-test-nikdy-neexistuje"
fail=0

bash scripts/gh/pr-watch.sh -R "$repo" --once >/dev/null 2>&1; rc1=$?
bash scripts/gh/pr-watch.sh -R "$repo" --base main --since 2026-11-26 --once >/dev/null 2>&1; rc2=$?
bash scripts/gh/pr-watch.sh -R "$repo" --base main --interval 0 --once >/dev/null 2>&1; rc3=$?
if [ "$rc1" -ne 2 ] || [ "$rc2" -ne 2 ] || [ "$rc3" -ne 2 ]; then
  echo "fail=criterion_1 reason=bad_args_not_rejected rc1=$rc1 rc2=$rc2 rc3=$rc3"; fail=1
fi

out="$(bash scripts/gh/pr-watch.sh -R "$repo" --base "$nobase" --once)" || { echo "fail=criterion_2 reason=script_failed"; exit 1; }
grep -qx 'event=idle' <<<"$out" || { echo "fail=criterion_2 reason=no_idle out=$out"; fail=1; }
grep -Eqx 'next_since=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' <<<"$out" \
  || { echo "fail=criterion_2 reason=bad_next_since out=$out"; fail=1; }
out="$(bash scripts/gh/pr-watch.sh -R "$repo" --base "$nobase" --since 2026-01-02T03:04:05Z --once)" \
  || { echo "fail=criterion_2 reason=script_failed_with_since"; exit 1; }
grep -qx 'next_since=2026-01-02T03:04:05Z' <<<"$out" || { echo "fail=criterion_2 reason=since_changed out=$out"; fail=1; }

# Bez -R skript skončí na require_repo dřív, než by label poslal do gh.
bash scripts/gh/issue-update.sh 1 --add-label precedent >/dev/null 2>&1; rc4=$?
bash scripts/gh/issue-update.sh -R "$repo" 1 --add-label >/dev/null 2>&1; rc5=$?
bash scripts/gh/issue-update.sh 1 --remove-label precedent >/dev/null 2>&1; rc6=$?
bash scripts/gh/issue-update.sh -R "$repo" 1 --remove-label >/dev/null 2>&1; rc7=$?
err="$(bash scripts/gh/issue-update.sh -R "$repo" 1 2>&1 >/dev/null)"
if [ "$rc4" -ne 2 ] || [ "$rc5" -ne 2 ] || [ "$rc6" -ne 2 ] || [ "$rc7" -ne 2 ] \
   || ! grep -q -- '--add-label' <<<"$err" || ! grep -q -- '--remove-label' <<<"$err"; then
  echo "fail=criterion_3 reason=label_args rc4=$rc4 rc5=$rc5 rc6=$rc6 rc7=$rc7"; fail=1
fi

grep -q '^### `gh/pr-watch.sh' shared/git-scripts.md || { echo "fail=criterion_4 reason=watch_doc_missing"; fail=1; }
grep -q '^| `issue-update.sh` |.*--add-label.*--remove-label' shared/git-scripts.md \
  || { echo "fail=criterion_4 reason=label_doc_missing"; fail=1; }

out="$(bash scripts/gh/pr-watch.sh -R "$repo" --base main --since 2026-11-19T00:00:00Z --once)" \
  || { echo "fail=criterion_5 reason=script_failed"; exit 1; }
grep -qx 'event=merged pr=91 at=2026-11-19T13:52:01Z' <<<"$out" || { echo "fail=criterion_5 reason=merge_missing"; fail=1; }
if grep -q '^event=merged pr=90 ' <<<"$out"; then echo "fail=criterion_5 reason=old_merge_reported"; fail=1; fi
# Pozdější merge do main next_since posouvá, starší než merge #91 být nesmí.
ns="$(sed -n 's/^next_since=//p' <<<"$out")"
if [[ "$ns" < "2026-11-19T13:52:01Z" ]]; then echo "fail=criterion_5 reason=bad_next_since ns=$ns"; fail=1; fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
