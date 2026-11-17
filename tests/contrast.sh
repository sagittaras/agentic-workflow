#!/usr/bin/env bash
# Test skills/write-art-bible/scripts/contrast.sh proti známým poměrům WCAG.
#
# Kritérium 1: černá na bílé je 21:1, #777 na bílé 4.47:1 a neprojde AA,
#              ale projde AA pro velký text; zkrácený zápis se rozvine.
# Kritérium 2: poměr těsně pod prahem se nevypíše zaokrouhlený na práh.
# Kritérium 3: barva mimo hex skončí kódem 2.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/skills/write-art-bible/scripts/contrast.sh"
fail=0

out="$(bash "$script" '#000:#fff' 777:FFFFFF)" || { echo "fail=criterion_1 reason=script_failed"; exit 1; }
grep -qx '000000:ffffff ratio=21.00:1 aa=pass aa_large=pass aaa=pass' <<<"$out" \
  || { echo "fail=criterion_1 reason=black_on_white"; fail=1; }
grep -qx '777777:ffffff ratio=4.47:1 aa=fail aa_large=pass aaa=fail' <<<"$out" \
  || { echo "fail=criterion_1 reason=grey_on_white"; fail=1; }

# #767676 na bílé je 4.54:1, #777777 4.478:1 — pod prahem nesmí ukázat 4.50.
out="$(bash "$script" 777777:ffffff)"
if grep -q 'ratio=4.50' <<<"$out"; then
  echo "fail=criterion_2 reason=rounded_up_to_threshold"; fail=1
fi

bash "$script" zz:fff >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] || { echo "fail=criterion_3 reason=invalid_color_rc_$rc"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
