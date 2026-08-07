#!/usr/bin/env bash
# Pushne aktuální větev.
#
# Použití:
#   bash scripts/push.sh              # jen když větev má upstream
#   bash scripts/push.sh --publish    # založí upstream u nové větve
#
# Bez --publish větev bez upstreamu nepublikuje. Publikování je viditelné
# navenek a patří uživateli, ne skriptu. Force push skript neumí záměrně.
#
# Návratové kódy: 0 = pushnuto, 2 = odpojená HEAD nebo není repozitář,
# 3 = větev nemá upstream a chybí --publish.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

publish=false
if [ "${1:-}" = "--publish" ]; then
  publish=true
fi

branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  echo "error=detached_head" >&2
  exit 2
fi

if upstream="$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)"; then
  git push
  echo "pushed=$upstream"
elif $publish; then
  git push -u origin "$branch"
  echo "pushed=origin/$branch"
  echo "upstream_created=true"
else
  echo "error=no_upstream" >&2
  echo "hint=větev '$branch' nemá upstream; spusť s --publish, má-li se publikovat" >&2
  exit 3
fi
