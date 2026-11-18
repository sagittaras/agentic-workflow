#!/usr/bin/env bash
# Test scripts/integration-gate.sh — SHA obou větví a přeskočení opakované brány.
#
# Bez sítě: git běží nad dočasným repozitářem s bare originem.
#
# Kritérium 1: brána vypíše pr_sha= a integration_sha= rovné špičkám větví.
# Kritérium 2: --same-as se stejnými SHA → reused=true, kód 0, příkaz neběží
#              a worktree se nezakládá.
# Kritérium 3: --same-as po posunu integrační větve → reused=false a brána
#              proběhne celá (příkaz běží).
# Kritérium 4: --same-as bez dvou hodnot → kód 2.
# Kritérium 5: --same-as po posunu větve PR (integrační stojí) → reused=false.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/integration-gate.sh"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT
fail=0

(
  set -e
  git init -q --bare "$fx/origin.git"
  git init -q -b main "$fx/repo"
  cd "$fx/repo"
  git config user.email test@example.com
  git config user.name test
  git remote add origin "$fx/origin.git"
  echo base >README.md
  git add README.md && git commit -q -m base
  git checkout -q -b milestone/x && git push -q origin milestone/x
  git checkout -q -b feat/x
  echo a >a.txt && git add a.txt && git commit -q -m a
  git push -q origin feat/x
) || { echo "fail=fixture reason=setup_failed"; exit 1; }

gate() { out="$(cd "$fx/repo" && bash "$script" "$@" 2>&1)"; rc=$?; }
kv() { sed -n "s/^$1=//p" <<<"$out" | head -1; }

pr_tip="$(git -C "$fx/repo" rev-parse feat/x)"
int_tip="$(git -C "$fx/repo" rev-parse milestone/x)"

gate feat/x milestone/x
if [ "$rc" -ne 0 ] || [ "$(kv pr_sha)" != "$pr_tip" ] || [ "$(kv integration_sha)" != "$int_tip" ]; then
  echo "$out"; echo "fail=criterion_1 reason=sha_lines_wrong rc=$rc"; fail=1
fi

gate feat/x milestone/x --same-as "$pr_tip" "$int_tip" -- sh -c 'echo RAN; exit 1'
if [ "$rc" -ne 0 ] || [ "$(kv reused)" != true ] || grep -q 'RAN' <<<"$out" \
   || grep -q '^worktree=' <<<"$out"; then
  echo "$out"; echo "fail=criterion_2 reason=reuse_not_applied rc=$rc"; fail=1
fi

(
  set -e
  cd "$fx/repo"
  git checkout -q milestone/x
  echo b >b.txt && git add b.txt && git commit -q -m b
  git push -q origin milestone/x
) || { echo "fail=fixture reason=advance_failed"; exit 1; }

gate feat/x milestone/x --same-as "$pr_tip" "$int_tip" -- sh -c 'echo RAN; exit 0'
if [ "$rc" -ne 0 ] || [ "$(kv reused)" != false ] || ! grep -q 'RAN' <<<"$out" \
   || [ "$(kv integration_sha)" = "$int_tip" ]; then
  echo "$out"; echo "fail=criterion_3 reason=moved_base_reused rc=$rc"; fail=1
fi

gate feat/x milestone/x --same-as "$pr_tip"
if [ "$rc" -ne 2 ] || ! grep -qx 'error=missing_value' <<<"$out"; then
  echo "$out"; echo "fail=criterion_4 reason=bad_same_as_accepted rc=$rc"; fail=1
fi

int_tip2="$(git -C "$fx/repo" rev-parse milestone/x)"
(
  set -e
  cd "$fx/repo"
  git checkout -q feat/x
  echo c >c.txt && git add c.txt && git commit -q -m c
  git push -q origin feat/x
) || { echo "fail=fixture reason=pr_advance_failed"; exit 1; }

gate feat/x milestone/x --same-as "$pr_tip" "$int_tip2"
if [ "$rc" -ne 0 ] || [ "$(kv reused)" != false ] || [ "$(kv pr_sha)" = "$pr_tip" ]; then
  echo "$out"; echo "fail=criterion_5 reason=moved_pr_reused rc=$rc"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
