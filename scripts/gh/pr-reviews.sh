#!/usr/bin/env bash
# Vypíše připomínky k pull requestu na jedno volání: review s výrokem,
# komentáře k řádkům kódu a obecné komentáře. Vypisuje JSON v sekcích.
#
# Použití:
#   bash scripts/gh/pr-reviews.sh -R owner/repo <number>
#
# Připomínky na GitHubu leží na třech místech a pr-read.sh vrací jen obecné
# komentáře: review (výrok a souhrn) i komentáře k řádkům tam chybí. Kdo
# zapracovává připomínky, potřebuje všechny tři.
#
# Výstup:
#   [reviews]        — JSON pole: author, state, body, submittedAt
#   [line_comments]  — JSON objekt na řádek: id, path, line, author, body,
#                      in_reply_to (id komentáře, na který odpovídá), url
#   [comments]       — JSON pole: author, body, createdAt
#
# Komentáře k řádkům se stránkují přes celé PR; line je null u komentáře
# k řádku, který novější push změnil (GitHub ho drží jako outdated).
#
# Návratové kódy: 0 = v pořádku (i bez připomínek), 2 = chybný argument,
# 7 = gh chybí nebo není přihlášené. Nenulový kód od gh propadá ven beze změny.

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

repo=""
number=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$number" ]; then number="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$number"
gh_require

echo "[reviews]"
gh pr view "$number" -R "$repo" --json reviews \
  --jq '[.reviews[] | {author: .author.login, state, body, submittedAt}]'

echo
echo "[line_comments]"
gh api --paginate "repos/$repo/pulls/$number/comments" \
  --jq '.[] | {id, path, line, author: .user.login, body, in_reply_to: .in_reply_to_id, url: .html_url}'

echo
echo "[comments]"
gh pr view "$number" -R "$repo" --json comments \
  --jq '[.comments[] | {author: .author.login, body, createdAt}]'
