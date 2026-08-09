#!/usr/bin/env bash
# Zjistí z remotu, s jakým repozitářem a s jakou forge se pracuje.
# Výstup je key=value na stdout.
#
# Použití: bash scripts/forge-detect.sh
#
# URL remotu se parsuje lokálně, bez sítě — přihlašovací údaje v URL se
# zahazují a nikam se nevypisují. Výchozí větev se naopak ptá remotu:
# lokálnímu refs/remotes/origin/HEAD nevěříme, po změně na serveru zůstává
# zastaralý a vrátí věrohodně vypadající nesmysl. Když remote neodpoví,
# vyjde default_branch prázdná — není to chyba, jen se to musí říct nahlas.
#
# forge=unknown je platný výsledek, ne selhání: pozná se jen github.com
# a hostitel s "gitea" v názvu. GitHub Enterprise ani Gitea na vlastní doméně
# z URL poznat nejdou — rozhoduje sekce Forge v projektové konfiguraci.
#
# Návratové kódy: 0 = v pořádku, 2 = nejde o git repozitář,
# 3 = remote chybí nebo z něj nelze odvodit owner/repo.

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error=not_a_git_repository" >&2
  exit 2
}
cd "$root"

# --- aktuální větev ------------------------------------------------------
# Volající ji potřebuje jako head pro pull request. Odpojená HEAD není chyba
# tohohle skriptu, ale head z ní neudělá nikdo — proto se hlásí zvlášť.
branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  echo "detached=true"
  echo "branch="
else
  echo "detached=false"
  echo "branch=$branch"
fi

# --- výběr remotu --------------------------------------------------------
# Přednost má origin; když není, bereme první, který repozitář zná.
remote=""
if git remote get-url origin >/dev/null 2>&1; then
  remote="origin"
else
  remote="$(git remote | head -1)"
fi

if [ -z "$remote" ]; then
  echo "error=no_remote" >&2
  echo "hint=repozitář nemá žádný remote; forge z čeho odvodit není" >&2
  exit 3
fi

url="$(git remote get-url "$remote" 2>/dev/null)" || {
  echo "error=remote_url_unavailable" >&2
  exit 3
}

# --- rozbor URL ----------------------------------------------------------
host=""
path=""
case "$url" in
  *://*)
    # scheme://[user[:heslo]@]host[:port]/owner/repo
    rest="${url#*://}"
    rest="${rest#*@}"          # přihlašovací údaje pryč, ven se nedostanou
    hostport="${rest%%/*}"
    host="${hostport%%:*}"
    if [ "$rest" = "$hostport" ]; then
      path=""
    else
      path="${rest#*/}"
    fi
    ;;
  *@*:*)
    # scp-like: git@host:owner/repo
    rest="${url#*@}"
    host="${rest%%:*}"
    path="${rest#*:}"
    ;;
  *)
    # lokální cesta nebo tvar, který neumíme rozebrat
    host=""
    path=""
    ;;
esac

path="${path%/}"
path="${path%.git}"
path="${path#/}"

owner=""
repo=""
if [ -n "$path" ] && [ "$path" != "${path%/*}" ]; then
  repo="${path##*/}"
  ownerpath="${path%/*}"
  owner="${ownerpath##*/}"
fi

if [ -z "$owner" ] || [ -z "$repo" ]; then
  echo "error=cannot_parse_remote" >&2
  echo "hint=z remotu '$remote' nejde odvodit owner/repo; doplň je do konfigurace ručně" >&2
  exit 3
fi

# --- forge ---------------------------------------------------------------
case "$host" in
  github.com|*.github.com) forge="github" ;;
  *gitea*)                 forge="gitea" ;;
  *)                       forge="unknown" ;;
esac

echo "remote=$remote"
echo "forge=$forge"
echo "host=$host"
echo "owner=$owner"
echo "repo=$repo"

# --- výchozí větev -------------------------------------------------------
default_branch=""
if symref="$(git ls-remote --symref "$remote" HEAD 2>/dev/null)"; then
  default_branch="$(printf '%s\n' "$symref" | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')"
fi

if [ -n "$default_branch" ]; then
  echo "default_branch=$default_branch"
  echo "default_branch_source=remote"
else
  echo "default_branch="
  echo "default_branch_source=unavailable"
fi
