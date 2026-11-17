#!/usr/bin/env bash
# Test scripts/branch-state.sh nad dočasným repozitářem s bare originem.
#
# Kritérium 1: na výchozí větvi se vším pushnutým hlásí on_default_branch=true,
#              dirty=false a pushed=true.
# Kritérium 2: nová větev bez upstreamu s jedním commitem a nesledovaným
#              souborem hlásí pushed=false, dirty=true a vůči --base main
#              commits_ahead=1, base_source=remote, base_is_ancestor=true.
# Kritérium 3: základ, který je jen lokální, hlásí base_source=local
#              a base_ref bez origin/.
# Kritérium 4: neexistující základ skončí kódem 4 s base_source=missing.
# Kritérium 5: odpojená HEAD hlásí detached=true a prázdnou branch.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/branch-state.sh"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT

fail=0
has() { grep -qx "$1" <<<"$2"; }
check() {
  # check <kritérium> <očekávaný řádek> <výstup>
  if ! has "$2" "$3"; then
    echo "fail=$1 reason=missing_line expected='$2'"
    fail=1
  fi
}

(
  set -e
  git init -q --bare -b main "$fx/origin.git"
  git init -q -b main "$fx/repo"
  cd "$fx/repo"
  git config user.email test@example.com
  git config user.name test
  git remote add origin "$fx/origin.git"
  echo base >README.md
  git add README.md && git commit -q -m base
  git push -q -u origin main
) || { echo "fail=fixture reason=setup_failed"; exit 1; }

run() { (cd "$fx/repo" && bash "$script" "$@" 2>/dev/null); }

out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || { echo "fail=criterion_1 reason=exit_$rc"; fail=1; }
check criterion_1 'on_default_branch=true' "$out"
check criterion_1 'dirty=false' "$out"
check criterion_1 'pushed=true' "$out"

(cd "$fx/repo" && git checkout -q -b feat/x && echo x >x.txt && git add x.txt \
  && git commit -q -m x && echo y >untracked.txt) || { echo "fail=fixture reason=branch_setup"; exit 1; }
out="$(run --base main)"; rc=$?
[ "$rc" -eq 0 ] || { echo "fail=criterion_2 reason=exit_$rc"; fail=1; }
check criterion_2 'branch=feat/x' "$out"
check criterion_2 'on_default_branch=false' "$out"
check criterion_2 'dirty=true' "$out"
check criterion_2 'upstream=' "$out"
check criterion_2 'pushed=false' "$out"
check criterion_2 'base_ref=origin/main' "$out"
check criterion_2 'base_source=remote' "$out"
check criterion_2 'commits_ahead=1' "$out"
check criterion_2 'base_is_ancestor=true' "$out"

(cd "$fx/repo" && git branch -q milestone/lokalni main) || { echo "fail=fixture reason=local_base"; exit 1; }
out="$(run --base milestone/lokalni)"; rc=$?
[ "$rc" -eq 0 ] || { echo "fail=criterion_3 reason=exit_$rc"; fail=1; }
check criterion_3 'base_fetched=false' "$out"
check criterion_3 'base_ref=milestone/lokalni' "$out"
check criterion_3 'base_source=local' "$out"

out="$(run --base neexistuje)"; rc=$?
[ "$rc" -eq 4 ] || { echo "fail=criterion_4 reason=exit_$rc"; fail=1; }
check criterion_4 'base_source=missing' "$out"

(cd "$fx/repo" && rm untracked.txt && git checkout -q --detach HEAD) || { echo "fail=fixture reason=detach"; exit 1; }
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || { echo "fail=criterion_5 reason=exit_$rc"; fail=1; }
check criterion_5 'detached=true' "$out"
check criterion_5 'branch=' "$out"

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
