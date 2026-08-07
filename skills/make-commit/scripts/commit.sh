#!/usr/bin/env bash
# Stagne zadané cesty a vytvoří commit se zprávou přečtenou ze stdin.
# Bez cest commitne to, co už staged je.
#
# Použití:
#   bash scripts/commit.sh <cesta>... <<'MSG'
#   feat(skills): add make-commit skill
#
#   Co-Authored-By: …
#   MSG
#
# Zpráva jde do gitu přes stdin, takže se nikde neexpanduje a do historie
# dorazí doslova. Skript záměrně neumí --amend, --no-verify ani force push:
# historie se jen rozrůstá, nikdy nepřepisuje.
#
# Návratové kódy: 0 = commit vytvořen, 2 = prázdná zpráva nebo není repozitář,
# 3 = není co commitnout.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

message="$(cat)"
if [ -z "${message//[[:space:]]/}" ]; then
  echo "error=empty_message" >&2
  exit 2
fi

if [ "$#" -gt 0 ]; then
  git add -- "$@"
fi

if git diff --cached --quiet; then
  echo "error=nothing_staged" >&2
  echo "hint=předej cesty ke stagování, nebo nejdřív něco stagni" >&2
  exit 3
fi

printf '%s\n' "$message" | git commit -F -

git --no-pager log -1 --format='commit=%h%nsubject=%s'
