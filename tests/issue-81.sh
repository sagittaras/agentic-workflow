#!/usr/bin/env bash
# Test kritérií issue #81: criteria-tests.sh pozná značku „ověří člověk“
# i s vysvětlivkou za oddělovačem.
#
# Nad dočasným repozitářem s bare originem dostane skript issue se třemi
# kritérii — testované, se značkou s vysvětlivkou a s holou značkou — a PR,
# které první kryje testem ze změny a zbylá dvě vede jako „ověří člověk“.
# Musí projít s human=2; dřív značku s vysvětlivkou nepoznal a hlásil
# fail=2 reason=unexpected_human.
#
# Druhý běh hlídá, že značka nepřijme cokoli: „(ověří člověkem)“ značka
# není, takže kritérium zůstává testované a mapa s „ověří člověk“ neprojde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/criteria-tests.sh"

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
  git push -q origin main
  git checkout -q -b fix/x
  mkdir -p tests && echo 'exit 0' >tests/a.sh
  git add tests/a.sh && git commit -q -m test
  git push -q origin fix/x
) || { echo "fail=fixture reason=setup_failed"; exit 1; }

cat >"$fx/pr.md" <<'MD'
## Testy kritérií

| # | Kritérium | Test |
| --- | --- | --- |
| 1 | testované | `tests/a.sh` — `a` |
| 2 | s vysvětlivkou | ověří člověk |
| 3 | holá značka | ověří člověk |
MD

cat >"$fx/issue-ok.md" <<'MD'
## Akceptační kritéria

- [ ] Testované kritérium.
- [ ] Kritérium s vysvětlivkou. (ověří člověk — repozitář nemá harness)
- [ ] Kritérium s holou značkou. (ověří člověk)
MD

out="$(cd "$fx/repo" && bash "$script" --issue-body "$fx/issue-ok.md" \
  --pr-body "$fx/pr.md" --base main --head fix/x 2>&1)"
rc=$?
echo "$out"
if [ "$rc" -ne 0 ] || ! grep -qx 'human=2' <<<"$out" || ! grep -qx 'result=pass' <<<"$out"; then
  echo "fail=criterion_1 reason=marker_with_note_not_recognized"
  fail=1
fi

sed 's/(ověří člověk — repozitář nemá harness)/(ověří člověkem)/' \
  "$fx/issue-ok.md" >"$fx/issue-bad.md"

out="$(cd "$fx/repo" && bash "$script" --issue-body "$fx/issue-bad.md" \
  --pr-body "$fx/pr.md" --base main --head fix/x 2>&1)"
rc=$?
echo "$out"
if [ "$rc" -ne 1 ] || ! grep -qx 'fail=2 reason=unexpected_human' <<<"$out"; then
  echo "fail=criterion_2 reason=marker_too_lenient"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
