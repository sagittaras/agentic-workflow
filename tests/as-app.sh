#!/usr/bin/env bash
# Test scripts/gh/as-app.sh.
#
# Běží bez sítě: curl nahrazuje stub na PATH, který zapíše hlavičku
# Authorization a vrátí připravené odpovědi GitHubu. Klíč je jednorázový,
# vyrobený openssl v dočasném adresáři.
#
# Kritérium 1: bez -R, app id, klíče nebo příkazu za -- skončí kódem 2.
# Kritérium 2: JWT má hlavičku RS256, iss = app id a podpis sedí na veřejný
#              klíč; token z odpovědi dostane příkaz v GH_TOKEN a na stdout
#              skriptu se nedostane nic jiného než výstup příkazu.
# Kritérium 3: odpověď 404 na hledání instalace skončí kódem 3 a příkaz se
#              nespustí.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"
fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
openssl genrsa -traditional -out "$tmp/key.pem" 2048 2>/dev/null \
  || openssl genrsa -out "$tmp/key.pem" 2048 2>/dev/null
openssl rsa -in "$tmp/key.pem" -pubout -out "$tmp/pub.pem" 2>/dev/null

mkdir -p "$tmp/bin"
cat >"$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
# Stub curl: zapíše Authorization a podle URL vrátí odpověď s HTTP kódem.
url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -H) case "$2" in Authorization:*) printf '%s\n' "$2" >"$STUB_DIR/auth";; esac; shift 2 ;;
    -X|-d|-w) shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  */installation)
    if [ "${STUB_MODE:-ok}" = "missing" ]; then printf '{\n  "message": "Not Found"\n}\n404'
    else printf '{\n  "id": 4242,\n  "account": {\n    "id": 99\n  }\n}\n200'; fi ;;
  */access_tokens) printf '{\n  "token": "ghs_stubtoken",\n  "expires_at": "2026-11-26T16:00:00Z"\n}\n201' ;;
  *) printf '{}\n500' ;;
esac
EOF
chmod +x "$tmp/bin/curl"

run() { PATH="$tmp/bin:$PATH" STUB_DIR="$tmp" bash scripts/gh/as-app.sh "$@"; }

# Kritérium 1
run --app-id 1 --key "$tmp/key.pem" -- true >/dev/null 2>&1; r1=$?
run -R o/r --key "$tmp/key.pem" -- true >/dev/null 2>&1; r2=$?
run -R o/r --app-id 1 --key "$tmp/missing.pem" -- true >/dev/null 2>&1; r3=$?
run -R o/r --app-id 1 --key "$tmp/key.pem" >/dev/null 2>&1; r4=$?
for r in "$r1" "$r2" "$r3" "$r4"; do
  [ "$r" -eq 2 ] || { echo "fail=criterion_1 reason=missing_arg_not_rejected codes=$r1,$r2,$r3,$r4"; fail=1; break; }
done

# Kritérium 2
out="$(run -R o/r --app-id 5938925 --key "$tmp/key.pem" -- sh -c 'echo "token=$GH_TOKEN"' 2>"$tmp/err")"; rc=$?
[ "$rc" -eq 0 ] || { echo "fail=criterion_2 reason=exit_$rc"; fail=1; }
[ "$out" = "token=ghs_stubtoken" ] || { echo "fail=criterion_2 reason=unexpected_stdout"; fail=1; }
grep -qx 'installation_id=4242' "$tmp/err" || { echo "fail=criterion_2 reason=installation_id_not_reported"; fail=1; }
grep -q 'ghs_stubtoken' "$tmp/err" && { echo "fail=criterion_2 reason=token_leaked_to_stderr"; fail=1; }
jwt="$(sed -n 's/^Authorization: Bearer //p' "$tmp/auth")"
b64d() { local s; s="$(tr -- '-_' '+/')"; while [ $(( ${#s} % 4 )) -ne 0 ]; do s="$s="; done; printf '%s' "$s" | openssl base64 -d -A; }
IFS=. read -r h p s <<<"$jwt"
printf '%s' "$h" | b64d | grep -q '"alg":"RS256"' || { echo "fail=criterion_2 reason=bad_header"; fail=1; }
printf '%s' "$p" | b64d | grep -q '"iss":"5938925"' || { echo "fail=criterion_2 reason=bad_iss"; fail=1; }
printf '%s' "$s" | b64d >"$tmp/sig.bin"
printf '%s' "$h.$p" | openssl dgst -sha256 -verify "$tmp/pub.pem" -signature "$tmp/sig.bin" >/dev/null 2>&1 \
  || { echo "fail=criterion_2 reason=signature_invalid"; fail=1; }

# Kritérium 3
out="$(STUB_MODE=missing run -R o/r --app-id 1 --key "$tmp/key.pem" -- echo ran 2>/dev/null)"; rc=$?
[ "$rc" -eq 3 ] || { echo "fail=criterion_3 reason=exit_$rc"; fail=1; }
[ -z "$out" ] || { echo "fail=criterion_3 reason=command_ran"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
