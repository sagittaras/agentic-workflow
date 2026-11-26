#!/usr/bin/env bash
# Hlídá PR do jedné základní větve a skončí, jakmile se u otevřených objeví
# nová připomínka člověka, nebo když některé PR do té větve někdo mergne či
# zavře. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-watch.sh -R owner/repo --base <větev> [--since <čas>] \
#     [--interval <s>] [--max-minutes <m>] [--once]
#
# Spouští se na pozadí: skript se ptá forge jedním GraphQL dotazem každých
# --interval sekund (výchozí 60) a čekání nestojí volajícího žádné tokeny —
# ozve se až výstupem při skončení. Pak ho volající spustí znovu s
# --since <next_since>, aby žádnou událost nedostal dvakrát ani neztratil.
#
# Připomínka = odeslané review (i s komentáři k řádkům, ty GitHub odesílá jako
# review) nebo obecný komentář u otevřeného PR, novější než --since. Nepočítá
# se komentář, jehož tělo začíná „## Brána prošla" (píše ho brána
# run-milestone), ani autor typu Bot nebo s loginem končícím na [bot] (CI,
# náhledy). Report ručně spuštěného verify-issue se počítá — vyžádal si ho
# člověk. Člověka od orchestrátoru rozlišit nejde, píšou pod týmž účtem gh.
#
# Merge a zavření se hlásí podle času (mergedAt, closedAt > --since), takže se
# neztratí ani PR otevřené a mergnuté mezi dvěma spuštěními.
#
# --since je čas ve tvaru 2026-11-26T14:00:00Z. Bez něj začne skript od
# aktuálního času serveru (hlavička Date odpovědi API; nedostane-li ji,
# od lokálního času).
#
# --once projde forge jen jednou a skončí, i když nic nenašel (event=none).
#
# Výstup (jeden nebo víc řádků event=, pak vždy next_since=):
#   event=feedback pr=<n> at=<čas> kind=review:<STATE>|comment
#   event=merged pr=<n> at=<čas>
#   event=closed pr=<n> at=<čas>   — zavřené bez merge
#   event=idle        — do základní větve nevede žádné otevřené PR a nic nového
#   event=timeout     — uplynulo --max-minutes (výchozí 240) bez události
#   event=none        — jen s --once, nic nového
#   next_since=<čas>  — --since pro další spuštění
#
# Návratové kódy: 0 = událost, idle, timeout nebo none · 2 = chybný argument ·
# 3 = forge pětkrát po sobě neodpověděl · 7 = gh chybí nebo není přihlášené.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

MARKER='## Brána prošla'
MAX_FAILS=5

repo=""
base=""
since=""
interval=60
max_minutes=240
once=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --base) require_value "$1" "${2:-}"; base="$2"; shift 2 ;;
    --since) require_value "$1" "${2:-}"; since="$2"; shift 2 ;;
    --interval) require_value "$1" "${2:-}"; interval="$2"; shift 2 ;;
    --max-minutes) require_value "$1" "${2:-}"; max_minutes="$2"; shift 2 ;;
    --once) once=true; shift ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *) die_usage "unexpected_argument" "přebývá argument '$1'" ;;
  esac
done

require_repo "$repo"
[ -n "$base" ] || die_usage "missing_base" "povinné je --base <větev>, do které PR vedou"
case "$interval" in ''|*[!0-9]*|0) die_usage "invalid_interval" "--interval je kladné celé číslo sekund" ;; esac
case "$max_minutes" in ''|*[!0-9]*|0) die_usage "invalid_max_minutes" "--max-minutes je kladné celé číslo" ;; esac
if [ -n "$since" ] && ! [[ "$since" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  die_usage "invalid_since" "--since čeká tvar 2026-11-26T14:00:00Z, dostal '$since'"
fi
gh_require

if [ -z "$since" ]; then
  server_date="$(gh api -i rate_limit 2>/dev/null | tr -d '\r' | sed -n 's/^[Dd]ate: //p' | head -1 || true)"
  if [ -z "$server_date" ] || ! since="$(date -u -d "$server_date" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
    since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  fi
fi

owner="${repo%%/*}"
name="${repo#*/}"
query='query($owner:String!,$name:String!,$base:String!){repository(owner:$owner,name:$name){
open:pullRequests(baseRefName:$base,states:[OPEN],first:50){nodes{number
 reviews(last:50){nodes{submittedAt state body author{__typename login}}}
 comments(last:50){nodes{createdAt body author{__typename login}}}}}
merged:pullRequests(baseRefName:$base,states:[MERGED],first:20,orderBy:{field:UPDATED_AT,direction:DESC}){nodes{number mergedAt}}
closed:pullRequests(baseRefName:$base,states:[CLOSED],first:20,orderBy:{field:UPDATED_AT,direction:DESC}){nodes{number closedAt}}}}'

# Řádky „open <n>", „feedback <n> <čas> <kind>", „merged <n> <čas>"
# a „closed <n> <čas>". Čas ve tvaru ISO 8601 UTC jde porovnat jako řetězec.
# gh --jq nebere --arg, proto se $since (ověřený tvar) a značka dosazují do
# filtru přímo.
human='(.author == null or (.author.__typename != "Bot" and ((.author.login // "") | endswith("[bot]") | not)))'
nomark='((.body // "") | startswith("'"$MARKER"'") | not)'
filter='.data.repository as $r |
  ($r.open.nodes[] | .number as $n |
    "open \($n)",
    (.reviews.nodes[] | select(.submittedAt != null and .submittedAt > "'"$since"'")
       | select('"$human"' and '"$nomark"')
       | "feedback \($n) \(.submittedAt) review:\(.state)"),
    (.comments.nodes[] | select(.createdAt > "'"$since"'")
       | select('"$human"' and '"$nomark"')
       | "feedback \($n) \(.createdAt) comment")),
  ($r.merged.nodes[] | select(.mergedAt != null and .mergedAt > "'"$since"'") | "merged \(.number) \(.mergedAt)"),
  ($r.closed.nodes[] | select(.closedAt != null and .closedAt > "'"$since"'") | "closed \(.number) \(.closedAt)")'

fails=0
deadline=$(( $(date +%s) + max_minutes * 60 ))

while :; do
  if ! out="$(gh api graphql -f query="$query" -f owner="$owner" -f name="$name" -f base="$base" --jq "$filter" 2>/dev/null)"; then
    fails=$((fails + 1))
    if [ "$fails" -ge "$MAX_FAILS" ]; then
      echo "error=forge_unreachable" >&2
      echo "hint=GraphQL dotaz selhal ${MAX_FAILS}× po sobě; ověř síť a 'gh auth status'" >&2
      exit 3
    fi
    sleep "$interval"
    continue
  fi
  fails=0

  events=""
  latest="$since"
  while read -r kind n at extra; do
    case "$kind" in
      feedback) events+="event=feedback pr=$n at=$at kind=$extra"$'\n' ;;
      merged)   events+="event=merged pr=$n at=$at"$'\n' ;;
      closed)   events+="event=closed pr=$n at=$at"$'\n' ;;
      *) continue ;;
    esac
    if [[ "$at" > "$latest" ]]; then latest="$at"; fi
  done < <(printf '%s\n' "$out" | grep -E '^(feedback|merged|closed) ' || true)

  if [ -n "$events" ]; then
    printf '%s' "$events"
    echo "next_since=$latest"
    exit 0
  fi
  if ! printf '%s\n' "$out" | grep -q '^open '; then
    echo "event=idle"
    echo "next_since=$since"
    exit 0
  fi
  if [ "$once" = true ]; then
    echo "event=none"
    echo "next_since=$since"
    exit 0
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "event=timeout"
    echo "next_since=$since"
    exit 0
  fi
  sleep "$interval"
done
