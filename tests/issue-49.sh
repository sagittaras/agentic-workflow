#!/usr/bin/env bash
# Test kritérií issue #49 ověřitelných příkazem.
#
# Kritérium 1: `bash scripts/docs-check.sh` projde s kódem 0 a vypíše result=pass.
# Kritérium 2: nad dočasným repozitářem s vadnou bází ohlásí řádkem
#              fail=<soubor> reason=<důvod> sirotka, mrtvý odkaz, chybějící
#              kotvu a CLAUDE.md bez odkazu na vstupní index a skončí kódem 1.
# Kritérium 5: ověřovací příkaz u area:skills v CONTRIBUTING.md spouští vedle
#              lintu i `bash scripts/docs-check.sh`.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

fail=0

out="$(bash scripts/docs-check.sh)"
rc=$?
echo "$out"
if [ "$rc" -ne 0 ] || ! grep -qx 'result=pass' <<<"$out"; then
  echo "fail=criterion_1 reason=docs_check_failed"
  fail=1
fi

# Kritérium 2: nad dočasným repozitářem s vadnou bází musí skript ohlásit
# každý druh nálezu a skončit kódem 1.
script="$root/scripts/docs-check.sh"
fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT

(
  cd "$fx" || exit 1
  git init -q .
  mkdir -p .claude .docs/sec
  printf 'Bez odkazu na index.\n' >CLAUDE.md
  printf 'Viz [dokumentace](../.docs/index.md).\n' >.claude/CLAUDE.md
  cat >.docs/index.md <<'MD'
# Index

- [Sekce](sec/index.md) — sekce.
- [Stránka](page.md#čeština-a-kód) — existující kotva.
- [Kotva](page.md#neexistuje) — chybějící kotva.
- [Mrtvý](neexistuje.md) — mrtvý odkaz.
MD
  printf '# Čeština a kód\n' >.docs/page.md
  printf '# Sekce\n' >.docs/sec/index.md
  printf '# Sirotek\n' >.docs/sec/sirotek.md
)

fx_out="$(cd "$fx" && bash "$script")"
fx_rc=$?
echo "$fx_out"
if [ "$fx_rc" -ne 1 ]; then
  echo "fail=criterion_2 reason=unexpected_exit_code_$fx_rc"
  fail=1
fi
for expected in \
  'fail=CLAUDE.md reason=missing_entry_index_link' \
  'fail=.docs/sec/sirotek.md reason=orphan_page' \
  'fail=.docs/index.md reason=dead_link line=6 link=neexistuje.md' \
  'fail=.docs/index.md reason=missing_anchor line=5 link=page.md#neexistuje'; do
  if ! grep -qxF "$expected" <<<"$fx_out"; then
    echo "fail=criterion_2 reason=missing_finding expected=\"$expected\""
    fail=1
  fi
done
if grep -q 'page.md#čeština-a-kód\|result=pass' <<<"$fx_out"; then
  echo "fail=criterion_2 reason=false_finding"
  fail=1
fi

row="$(grep -E '^\| area:skills \|' CONTRIBUTING.md || true)"
if ! grep -qF 'bash scripts/lint-skills.sh' <<<"$row" ||
   ! grep -qF 'bash scripts/docs-check.sh' <<<"$row"; then
  echo "fail=criterion_5 reason=area_skills_command_missing_docs_check"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
