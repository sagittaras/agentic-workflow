#!/usr/bin/env bash
# Pushne aktuální větev; nemá-li upstream, rovnou ho založí.
#
# Použití: bash scripts/push.sh
#
# Argumenty skript nebere. Historický `--publish` je tichý no-op: publikace
# je dnes výchozí chování, protože práce, která zůstane jen lokálně, se ztrácí
# a nedá se z ní založit PR. Force push skript neumí záměrně.
#
# Návratové kódy: 0 = pushnuto, 2 = odpojená HEAD nebo není repozitář,
# 4 = repozitář nemá remote origin, kam publikovat.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  echo "error=detached_head" >&2
  exit 2
fi

if upstream="$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)"; then
  git push
  echo "pushed=$upstream"
else
  # Publikace nové větve. Bez remotu není kam — ohlas to jako stav, ne jako pád
  # gitu, aby skill poznal, že jde o lokální repozitář, a nehádal z hlášky.
  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "error=no_remote" >&2
    echo "hint=repozitář nemá remote 'origin'; commit zůstal jen lokálně" >&2
    exit 4
  fi
  git push -u origin "$branch"
  echo "pushed=origin/$branch"
  echo "upstream_created=true"
fi
