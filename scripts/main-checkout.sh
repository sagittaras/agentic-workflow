#!/usr/bin/env bash
# Zjistí, jestli aktuální adresář je hlavní checkout repozitáře (ne worktree),
# kde hlavní checkout leží a jestli je čistý. Výstup je key=value na stdout.
#
# Použití:
#   bash scripts/main-checkout.sh
#
# run-milestone podle toho pouští issues sériových oblastí (typicky Unity):
# běží bez worktree, přímo v hlavním checkoutu, který má otevřený Editor, a jen
# do čistého stromu — rozdělaná práce by jinak přešla na větev dalšího agenta.
#
# Výstup:
#   main_checkout=true|false — běžíš v hlavním checkoutu
#   main_path=<cesta>        — kde hlavní checkout leží (první záznam
#                              `git worktree list`)
#   main_branch=<větev>      — co je v něm checkoutnuté; prázdné u odpojené HEAD
#   main_dirty=true|false    — má necommitnuté nebo nesledované změny
#
# Návratové kódy: 0 = zjištěno, 2 = nejde o git repozitář.

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error=not_a_git_repository" >&2
  exit 2
fi

git_dir="$(git rev-parse --absolute-git-dir)"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_path="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)"

if [ "$git_dir" = "$common_dir" ]; then
  echo "main_checkout=true"
else
  echo "main_checkout=false"
fi
echo "main_path=$main_path"
echo "main_branch=$(git -C "$main_path" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [ -n "$(git -C "$main_path" status --porcelain 2>/dev/null)" ]; then
  echo "main_dirty=true"
else
  echo "main_dirty=false"
fi
