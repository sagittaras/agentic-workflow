#!/usr/bin/env bash
# Test scripts/mutation-check.sh nad dočasným repozitářem.
#
# Fixture: main má src/lib.sh vracející "a"; větev feat/x ho mění na "b"
# a přidává test tests/t.sh, který "b" hlídá, a test tests/slepy.sh, který
# projde vždy.
#
# Kritérium 1: hlídající test → verdict=covered, restored=true a pracovní
#              kopie je po běhu čistá a na HEAD.
# Kritérium 2: slepý test → verdict=not_covered.
# Kritérium 3: test padající i nad PR → verdict=inconclusive.
# Kritérium 4: nečistá kopie → kód 4 a nic se nezmění (rozpracovaný soubor
#              zůstane).
# Kritérium 5: soubor, který se proti základu nemění → kód 5.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/mutation-check.sh"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT
r="$fx/repo"
fail=0
has() { grep -qx "$1" <<<"$2"; }

(
  set -e
  git init -q -b main "$r"
  cd "$r"
  git config user.email test@example.com
  git config user.name test
  mkdir -p src tests
  printf 'echo a\n' >src/lib.sh
  printf 'base\n' >README.md
  git add . && git commit -q -m base
  git checkout -q -b feat/x
  printf 'echo b\n' >src/lib.sh
  printf '[ "$(bash src/lib.sh)" = b ]\n' >tests/t.sh
  printf 'exit 0\n' >tests/slepy.sh
  git add . && git commit -q -m change
) || { echo "fail=fixture reason=setup_failed"; exit 1; }

run() { bash "$script" --worktree "$r" --base main --file src/lib.sh -- "$@" 2>&1; }

out="$(run bash tests/t.sh)"; rc=$?
if [ "$rc" -ne 0 ] || ! has 'verdict=covered' "$out" || ! has 'restored=true' "$out"; then
  echo "fail=criterion_1 reason=not_covered_or_failed rc=$rc"; echo "$out"; fail=1
fi
if [ -n "$(git -C "$r" status --porcelain)" ] || [ "$(cat "$r/src/lib.sh")" != "echo b" ]; then
  echo "fail=criterion_1 reason=worktree_not_restored"; fail=1
fi

out="$(run bash tests/slepy.sh)"; rc=$?
if [ "$rc" -ne 0 ] || ! has 'verdict=not_covered' "$out"; then
  echo "fail=criterion_2 reason=blind_test_not_detected rc=$rc"; fail=1
fi

out="$(run false)"; rc=$?
if [ "$rc" -ne 0 ] || ! has 'verdict=inconclusive' "$out"; then
  echo "fail=criterion_3 reason=failing_original_not_inconclusive rc=$rc"; fail=1
fi

printf 'rozpracovano\n' >"$r/README.md"
out="$(run bash tests/t.sh)"; rc=$?
if [ "$rc" -ne 4 ] || [ "$(cat "$r/README.md")" != "rozpracovano" ]; then
  echo "fail=criterion_4 reason=dirty_worktree_touched rc=$rc"; fail=1
fi
git -C "$r" checkout -q -- README.md

out="$(bash "$script" --worktree "$r" --base main --file README.md -- bash tests/t.sh 2>&1)"; rc=$?
if [ "$rc" -ne 5 ]; then
  echo "fail=criterion_5 reason=empty_change_not_rejected rc=$rc"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
