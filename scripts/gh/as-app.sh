#!/usr/bin/env bash
# Spustí příkaz pod identitou GitHub App místo účtu člověka: z app id
# a privátního klíče vyrobí JWT, vymění ho za installation token aplikace
# nainstalované na repozitáři a příkaz pustí s GH_TOKEN=<token>. PR založené
# takhle má autora <aplikace>[bot] a člověk ho může formálně schválit —
# autorovi GitHub schválit vlastní PR nedovolí.
#
# Použití:
#   bash scripts/gh/as-app.sh -R owner/repo [--app-id ID] [--key CESTA] -- <příkaz…>
#   např. … -- gh pr create -R owner/repo --base B --head H --title T --body-file F
#
# --app-id a --key mají přednost před proměnnými SAGITTARAS_GH_APP_ID
# a SAGITTARAS_GH_APP_KEY. ID je App ID nebo Client ID aplikace, klíč je .pem
# stažený z nastavení aplikace („Generate a private key"). Klíč patří mimo
# repozitář.
#
# Token se nikam nevypisuje, jde rovnou do prostředí příkazu. Vypsaný token by
# skončil v transkriptu a auto mode by takové volání zamítl (Credential
# Materialization). Platí hodinu a je zúžený na repozitář z -R.
#
# Git push skript neřeší: autora PR určuje, kdo PR založí, ne kdo pushnul
# commity. Push pod účtem člověka vadí jen pravidlu „Require approval of the
# most recent reviewable push" — tam by se schválení téhož člověka nepočítalo.
#
# Na stderr vypíše installation_id=. Stdout i návratový kód patří příkazu.
#
# Návratové kódy: 2 = chybný argument, 3 = GitHub odmítl JWT nebo aplikace
# není na repozitáři nainstalovaná, 7 = chybí openssl nebo curl. Jinak kód
# spuštěného příkazu.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

API="https://api.github.com"

repo=""
app_id="${SAGITTARAS_GH_APP_ID:-}"
key="${SAGITTARAS_GH_APP_KEY:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --app-id) require_value "$1" "${2:-}"; app_id="$2"; shift 2 ;;
    --key) require_value "$1" "${2:-}"; key="$2"; shift 2 ;;
    --) shift; break ;;
    *) die_usage "unknown_option" "neznámý argument '$1'; příkaz patří za --" ;;
  esac
done

require_repo "$repo"
[ -n "$app_id" ] || die_usage "missing_app_id" "chybí --app-id nebo SAGITTARAS_GH_APP_ID"
[ -n "$key" ] || die_usage "missing_key" "chybí --key nebo SAGITTARAS_GH_APP_KEY"
[ -f "$key" ] || die_usage "key_not_found" "privátní klíč '$key' neexistuje"
[ "$#" -gt 0 ] || die_usage "missing_command" "za -- chybí příkaz, který se má spustit pod aplikací"

for tool in openssl curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error=${tool}_not_found" >&2
    exit 7
  fi
done

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# JWT: iat o minutu zpět kvůli posunu hodin, platnost pod desetiminutovým
# stropem GitHubu.
now="$(date +%s)"
header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url)"
payload="$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$((now - 60))" "$((now + 540))" "$app_id" | b64url)"
signature="$(printf '%s' "$header.$payload" | openssl dgst -sha256 -sign "$key" -binary | b64url)"
jwt="$header.$payload.$signature"

# api <metoda> <cesta> [tělo] — vypíše tělo odpovědi a na posledním řádku
# HTTP kód.
api() {
  curl -sS -X "$1" "$API$2" \
    -H "Authorization: Bearer $jwt" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    ${3:+-d "$3"} \
    -w '\n%{http_code}'
}

resp="$(api GET "/repos/$repo/installation")"
code="${resp##*$'\n'}"
if [ "$code" != "200" ]; then
  echo "error=installation_lookup_failed http=$code" >&2
  echo "hint=401 = špatné app id nebo klíč; 404 = aplikace není na $repo nainstalovaná" >&2
  exit 3
fi
# První "id" odpovědi je id instalace; vnořené account.id leží až za ním.
installation_id="$(printf '%s' "${resp%$'\n'*}" | tr -d ' \n\r' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)"
[ -n "$installation_id" ] || { echo "error=installation_id_not_parsed" >&2; exit 3; }
echo "installation_id=$installation_id" >&2

resp="$(api POST "/app/installations/$installation_id/access_tokens" "{\"repositories\":[\"${repo#*/}\"]}")"
code="${resp##*$'\n'}"
if [ "$code" != "201" ]; then
  echo "error=token_exchange_failed http=$code" >&2
  exit 3
fi
token="$(printf '%s' "${resp%$'\n'*}" | tr -d '\n\r' | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p')"
[ -n "$token" ] || { echo "error=token_not_parsed" >&2; exit 3; }

unset jwt resp
GH_TOKEN="$token" exec "$@"
