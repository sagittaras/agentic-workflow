#!/usr/bin/env bash
# Test scripts/gh/pr-gate.sh — brána před review jedním voláním.
#
# Bez sítě: gh nahrazuje stub v PATH, který vrací těla z fixture a zápisy
# ukládá do souborů. Git běží nad dočasným repozitářem s bare originem.
#
# Kritérium 1: mapa sedí a příkaz projde → kód 0, issue dostane odškrtnuté
#              kritérium, PR komentář „Brána prošla" se správnými počty,
#              výstup příkazu se nevypisuje, pr_sha= a integration_sha= ano.
# Kritérium 2: chybějící řádek mapy → kód 1 s fail=, do trackeru se nezapisuje.
# Kritérium 3: selhaný ověřovací příkaz → kód 6 se sekcí [output], bez zápisu.
# Kritérium 4: PR mířící jinam než --base → kód 2 dřív, než cokoli spustí.
# Kritérium 5: --no-write projde bez zápisu do trackeru.
# Kritérium 6: bez ověřovacího příkazu projde s check=skipped a komentář řekne
#              „přeskočen".
# Kritérium 7: selhání zápisu do trackeru po zelené bráně → kód 4.
# Kritérium 8: selhání čtení z forge → kód 3, ne syrový kód gh (1 = nález).
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/gh/pr-gate.sh"

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
  git checkout -q -b milestone/x && git push -q origin milestone/x
  git checkout -q -b feat/x
  mkdir -p tests && echo 'exit 0' >tests/a.sh
  git add tests/a.sh && git commit -q -m test
  git push -q origin feat/x
) || { echo "fail=fixture reason=setup_failed"; exit 1; }

cat >"$fx/issue.md" <<'MD'
## Souhrn

Něco.

## Akceptační kritéria

- [ ] Testované kritérium.
- [ ] Dokumentace. (ověří člověk)
MD

cat >"$fx/pr-ok.md" <<'MD'
Closes #7

## Testy kritérií

| # | Kritérium | Test |
| --- | --- | --- |
| 1 | testované | `tests/a.sh` — `a` |
| 2 | dokumentace | ověří člověk |
MD
grep -v '^| 2 ' "$fx/pr-ok.md" >"$fx/pr-missing.md"

mkdir -p "$fx/bin"
cat >"$fx/bin/gh" <<'GH'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "issue view")
    case "$*" in
      *"--json body "*) [ -n "${FX_FAIL_READ:-}" ] && { echo "GraphQL: not found" >&2; exit 1; }; cat "$FX/issue.md" ;;
      *"--json state,url"*) printf 'state=OPEN\nurl=https://example.test/issues/7\n' ;;
      *) exit 99 ;;
    esac ;;
  "pr view")
    case "$*" in
      *"--json body "*) cat "$FX/pr.md" ;;
      *"headRefName,baseRefName"*) echo "feat/x $FX_PR_BASE" ;;
      *) exit 99 ;;
    esac ;;
  "issue edit")
    [ -n "${FX_FAIL_EDIT:-}" ] && { echo "HTTP 403" >&2; exit 1; }
    while [ "$#" -gt 0 ]; do [ "$1" = "--body-file" ] && cp "$2" "$FX/written-issue.md"; shift; done ;;
  "pr review")
    while [ "$#" -gt 0 ]; do [ "$1" = "--body-file" ] && cp "$2" "$FX/written-comment.md"; shift; done ;;
  *) echo "unexpected gh $*" >&2; exit 99 ;;
esac
GH
chmod +x "$fx/bin/gh"

run() { # run <pr body> <pr base> [args…] — vrací výstup v $out a kód v $rc
  local body="$1" prbase="$2"; shift 2
  cp "$body" "$fx/pr.md"
  rm -f "$fx/written-issue.md" "$fx/written-comment.md"
  out="$(cd "$fx/repo" && PATH="$fx/bin:$PATH" FX="$fx" FX_PR_BASE="$prbase" \
    bash "$script" -R o/r 12 --issue 7 --base milestone/x "$@" 2>&1)"
  rc=$?
}

run "$fx/pr-ok.md" milestone/x -- sh -c 'echo BUILD-$((40+2)); exit 0'
if [ "$rc" -ne 0 ] || ! grep -qx 'result=pass' <<<"$out" \
   || ! grep -qE '^pr_sha=[0-9a-f]{40}$' <<<"$out" || ! grep -qE '^integration_sha=[0-9a-f]{40}$' <<<"$out" \
   || ! grep -qx -- '- \[x\] Testované kritérium.' "$fx/written-issue.md" 2>/dev/null \
   || ! grep -qx -- '- \[ \] Dokumentace. (ověří člověk)' "$fx/written-issue.md" 2>/dev/null \
   || ! grep -q 'Testy kritérií: 1 z 2, 1 ověří člověk' "$fx/written-comment.md" 2>/dev/null \
   || ! grep -q '— prošel' "$fx/written-comment.md" 2>/dev/null \
   || grep -q 'BUILD-42' <<<"$out"; then
  echo "$out"; echo "fail=criterion_1 reason=pass_path_wrong rc=$rc"; fail=1
fi

run "$fx/pr-missing.md" milestone/x -- true
if [ "$rc" -ne 1 ] || ! grep -qx 'fail=2 reason=missing_row' <<<"$out" \
   || [ -e "$fx/written-issue.md" ] || [ -e "$fx/written-comment.md" ]; then
  echo "$out"; echo "fail=criterion_2 reason=criteria_fail_path_wrong rc=$rc"; fail=1
fi

run "$fx/pr-ok.md" milestone/x -- sh -c 'echo BOOM; exit 3'
if [ "$rc" -ne 6 ] || ! grep -qx '\[output\]' <<<"$out" || ! grep -q 'BOOM' <<<"$out" \
   || [ -e "$fx/written-issue.md" ]; then
  echo "$out"; echo "fail=criterion_3 reason=check_fail_path_wrong rc=$rc"; fail=1
fi

run "$fx/pr-ok.md" main -- true
if [ "$rc" -ne 2 ] || ! grep -qx 'error=base_mismatch' <<<"$out" || grep -q '^criteria=' <<<"$out"; then
  echo "$out"; echo "fail=criterion_4 reason=base_mismatch_not_rejected rc=$rc"; fail=1
fi

run "$fx/pr-ok.md" milestone/x --no-write -- true
if [ "$rc" -ne 0 ] || ! grep -qx 'issue_body=skipped' <<<"$out" || [ -e "$fx/written-issue.md" ]; then
  echo "$out"; echo "fail=criterion_5 reason=no_write_wrote rc=$rc"; fail=1
fi

run "$fx/pr-ok.md" milestone/x
if [ "$rc" -ne 0 ] || ! grep -qx 'check=skipped' <<<"$out" \
   || ! grep -q 'Ověřovací příkaz: přeskočen' "$fx/written-comment.md" 2>/dev/null; then
  echo "$out"; echo "fail=criterion_6 reason=no_command_path_wrong rc=$rc"; fail=1
fi

FX_FAIL_EDIT=1 run "$fx/pr-ok.md" milestone/x -- true
if [ "$rc" -ne 4 ] || ! grep -qx 'error=issue_update_failed' <<<"$out"; then
  echo "$out"; echo "fail=criterion_7 reason=write_failure_not_code_4 rc=$rc"; fail=1
fi

FX_FAIL_READ=1 run "$fx/pr-ok.md" milestone/x -- true
if [ "$rc" -ne 3 ] || ! grep -qx 'error=issue_read_failed' <<<"$out"; then
  echo "$out"; echo "fail=criterion_8 reason=read_failure_not_code_3 rc=$rc"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
