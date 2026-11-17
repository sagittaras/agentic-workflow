#!/usr/bin/env bash
# Spočítá kontrastní poměr WCAG 2.x pro dvojice barev text × podklad.
#
# Použití:
#   bash scripts/contrast.sh <text>:<podklad> [<text>:<podklad>…]
#
# Barvy v hexu, se znakem # i bez něj; zkrácený zápis (fff) se rozvine.
# Jiné tvary (oklch, hsl, rgb) skript nepřevádí — převeď je na hex napřed.
#
# Výstup: sekce [pairs], jedna dvojice na řádek:
#   <text>:<podklad> ratio=<poměr>:1 aa=pass|fail aa_large=pass|fail aaa=pass|fail
# Prahy: AA běžný text 4.5, AA velký text 3, AAA běžný text 7. Poměr se
# vypisuje useknutý na dvě desetinná místa, verdikty se počítají z přesné
# hodnoty.
#
# Návratové kódy: 0 = spočítáno, 2 = chybný argument (nic se nevypíše).

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "error=missing_pair" >&2
  echo "hint=použití: contrast.sh <text>:<podklad> [<text>:<podklad>…]" >&2
  exit 2
fi

norm() {
  local h="${1#\#}"
  h="$(printf '%s' "$h" | tr 'A-F' 'a-f')"
  case "$h" in
    [0-9a-f][0-9a-f][0-9a-f])
      h="${h:0:1}${h:0:1}${h:1:1}${h:1:1}${h:2:1}${h:2:1}" ;;
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) : ;;
    *) return 1 ;;
  esac
  printf '%s' "$h"
}

pairs=()
for p in "$@"; do
  case "$p" in
    *:*) : ;;
    *) echo "error=invalid_pair" >&2; echo "hint='$p' není ve tvaru <text>:<podklad>" >&2; exit 2 ;;
  esac
  a="$(norm "${p%%:*}")" || { echo "error=invalid_color" >&2; echo "hint='${p%%:*}' není hex barva" >&2; exit 2; }
  b="$(norm "${p#*:}")" || { echo "error=invalid_color" >&2; echo "hint='${p#*:}' není hex barva" >&2; exit 2; }
  pairs+=("$a:$b")
done

echo "[pairs]"
for p in "${pairs[@]}"; do
  awk -v A="${p%%:*}" -v B="${p#*:}" '
    function hx(s,  i, n) { n = 0; for (i = 1; i <= 2; i++) n = n * 16 + index("0123456789abcdef", substr(s, i, 1)) - 1; return n }
    function ch(v) { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
    function lum(h) { return 0.2126 * ch(hx(substr(h, 1, 2))) + 0.7152 * ch(hx(substr(h, 3, 2))) + 0.0722 * ch(hx(substr(h, 5, 2))) }
    function v(r, t) { return r >= t ? "pass" : "fail" }
    BEGIN {
      a = lum(A); b = lum(B); hi = (a > b ? a : b); lo = (a > b ? b : a)
      r = (hi + 0.05) / (lo + 0.05)
      # Useknout, ne zaokrouhlit: 4.497 se nesmí vypsat jako 4.50 vedle aa=fail.
      printf "%s:%s ratio=%.2f:1 aa=%s aa_large=%s aaa=%s\n", A, B, int(r * 100) / 100, v(r, 4.5), v(r, 3), v(r, 7)
    }'
done
