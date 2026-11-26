#!/usr/bin/env bash
# Test scripts/main-checkout.sh — běží offline nad dočasným repozitářem
# s jedním přidaným worktree.
#
# Kritérium 1: v hlavním checkoutu vypíše main_checkout=true, main_path na něj,
#              main_branch a main_dirty=false u čistého stromu.
# Kritérium 2: ve worktree vypíše main_checkout=false a main_path hlavního
#              checkoutu, ne worktree.
# Kritérium 3: nesledovaný soubor v hlavním checkoutu → main_dirty=true, i když
#              se ptáš z worktree.
# Kritérium 4: mimo git repozitář kód 2.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/main-checkout.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

main="$tmp/main"
mkdir -p "$main"
git -C "$main" init -q -b main
git -C "$main" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$main" worktree add -q -b feat/x "$tmp/wt"
main_abs="$(cd "$main" && git rev-parse --show-toplevel)"
flat() { tr '\n' ' ' <<<"$1"; }

out="$(cd "$main" && bash "$script")"
grep -qx 'main_checkout=true' <<<"$out" && grep -qxF "main_path=$main_abs" <<<"$out" \
  && grep -qx 'main_branch=main' <<<"$out" && grep -qx 'main_dirty=false' <<<"$out" \
  || { echo "fail=criterion_1 out=$(flat "$out")"; fail=1; }

out="$(cd "$tmp/wt" && bash "$script")"
grep -qx 'main_checkout=false' <<<"$out" && grep -qxF "main_path=$main_abs" <<<"$out" \
  || { echo "fail=criterion_2 out=$(flat "$out")"; fail=1; }

touch "$main/rozdelane.txt"
out="$(cd "$tmp/wt" && bash "$script")"
grep -qx 'main_dirty=true' <<<"$out" || { echo "fail=criterion_3 out=$(flat "$out")"; fail=1; }

mkdir -p "$tmp/nogit"
(cd "$tmp/nogit" && GIT_CEILING_DIRECTORIES="$tmp" bash "$script" >/dev/null 2>&1); rc=$?
[ "$rc" -eq 2 ] || { echo "fail=criterion_4 rc=$rc"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
