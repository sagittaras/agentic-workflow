#!/usr/bin/env bash
# Test scripts/gh/pr-comment.sh — odkaz na review, které gh pr review nevypíše.
#
# Bez sítě: gh nahrazuje stub v PATH.
#
# Kritérium 1: review projde bez odkazu na výstupu → url= je poslední review
#              tohoto účtu, ne novější review někoho jiného.
# Kritérium 2: dotaz na reviews selže → kód 0 a prázdné url=, komentář platí.
# Kritérium 3: review GitHub odmítne → mode=comment a url= z gh pr comment.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/gh/pr-comment.sh"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT
fail=0

mkdir -p "$fx/bin"
cat >"$fx/bin/gh" <<'GH'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "pr review") [ -n "${FX_REJECT_REVIEW:-}" ] && { echo "Can not approve your own pull request" >&2; exit 1; }; exit 0 ;;
  "pr comment") echo "https://github.com/o/r/pull/12#issuecomment-9" ;;
  "api user") echo "bot" ;;
  "api repos/o/r/pulls/12/reviews")
    [ -n "${FX_FAIL_API:-}" ] && { echo '{"message":"Not Found","status":"404"}'; exit 1; }
    # gh --jq vyhodnotí filtr; stub vrací, co by filtr na autora "bot" vybral.
    case "$*" in
      *'select(.user.login == "bot")'*) printf '%s\n' \
        "https://github.com/o/r/pull/12#pullrequestreview-1" \
        "https://github.com/o/r/pull/12#pullrequestreview-3" ;;
      *) printf '%s\n' "https://github.com/o/r/pull/12#pullrequestreview-4" ;;
    esac ;;
  *) echo "unexpected gh $*" >&2; exit 99 ;;
esac
GH
chmod +x "$fx/bin/gh"

run() { out="$(printf 'tělo\n' | PATH="$fx/bin:$PATH" bash "$script" -R o/r 12 --body-file - 2>&1)"; rc=$?; }

run
if [ "$rc" -ne 0 ] || ! grep -qx 'mode=review' <<<"$out" \
   || ! grep -qx 'url=https://github.com/o/r/pull/12#pullrequestreview-3' <<<"$out"; then
  echo "$out"; echo "fail=criterion_1 reason=review_url_wrong rc=$rc"; fail=1
fi

FX_FAIL_API=1 run
if [ "$rc" -ne 0 ] || ! grep -qx 'url=' <<<"$out"; then
  echo "$out"; echo "fail=criterion_2 reason=api_failure_leaked rc=$rc"; fail=1
fi

FX_REJECT_REVIEW=1 run
if [ "$rc" -ne 0 ] || ! grep -qx 'mode=comment' <<<"$out" \
   || ! grep -qx 'url=https://github.com/o/r/pull/12#issuecomment-9' <<<"$out"; then
  echo "$out"; echo "fail=criterion_3 reason=comment_fallback_wrong rc=$rc"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
