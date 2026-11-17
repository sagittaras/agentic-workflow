#!/usr/bin/env bash
# Test předávání těla gh skriptům přes --body-file - (stdin).
#
# Kritérium 1: require_body_file - přečte heredoc do dočasného souboru beze
#              změny, včetně $, zpětných apostrofů a uvozovek.
# Kritérium 2: dočasný soubor po skončení skriptu zmizí.
# Kritérium 3: prázdné stdin skončí kódem 2 s error=empty_body.
# Kritérium 4: všechny gh skripty, které berou --body-file, předávají gh
#              soubor z require_body_file, ne surový argument.
#
# Bez sítě a bez gh: _common.sh se sourcuje přímo.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
common="$root/scripts/gh/_common.sh"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT

fail=0

cat >"$fx/expected.md" <<'BODY'
Tělo s `kódem`, $PROMĚNNOU a "uvozovkami".

| # | Kritérium |
| --- | --- |
| 1 | `$(rm -rf /)` se nevykoná |
BODY

# Skript si do souboru poznamená cestu a zkopíruje obsah, než skončí.
out="$(bash -c '. "$1"; require_body_file -; cp "$BODY_FILE" "$2/got.md"; echo "$BODY_FILE"' \
  _ "$common" "$fx" <"$fx/expected.md")"
rc=$?
if [ "$rc" -ne 0 ] || ! cmp -s "$fx/expected.md" "$fx/got.md"; then
  echo "fail=criterion_1 reason=body_changed_or_failed rc=$rc"
  fail=1
fi

if [ -n "$out" ] && [ -e "$out" ]; then
  echo "fail=criterion_2 reason=temp_file_left path=$out"
  fail=1
fi

err="$(bash -c '. "$1"; require_body_file -' _ "$common" </dev/null 2>&1)"
rc=$?
if [ "$rc" -ne 2 ] || ! grep -qx 'error=empty_body' <<<"$err"; then
  echo "fail=criterion_3 reason=empty_body_not_rejected rc=$rc"
  fail=1
fi

for f in "$root"/scripts/gh/*.sh; do
  grep -q -- '--body-file)' "$f" || continue
  if grep -q -- '--body-file "\$body_file"' "$f" || ! grep -q -- '--body-file "\$BODY_FILE"' "$f"; then
    echo "fail=criterion_4 reason=raw_body_file_passed file=${f#$root/}"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
