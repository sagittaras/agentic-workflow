#!/usr/bin/env bash
# Stáhne poslední stav větve, na které instalace stojí, a vypíše, co se změnilo
# — aby bylo poznat, jestli stačí reload, nebo je nutný restart.
#
# Bezpečnostní kontroly (cizí remote, necommitnuté změny, ff-only) nedělá sám,
# deleguje je na install.sh v kořeni pluginu. Existuje tak jen jedna
# implementace a nemá se co rozejít.
#
# Použití: bash "${CLAUDE_PLUGIN_ROOT}/skills/update-plugin/scripts/update.sh"
#
# Výstup: key=value na stdout, sekce s výpisy uvozené hlavičkou v [].
# Návratové kódy: 0 = hotovo (i když nebylo co stáhnout), 1 = poškozená
# instalace, jinak kód propuštěný z install.sh (2 = cíl je obsazený,
# 128 a spol. = selhal git, typicky nedostupný remote).

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
installer="$root/install.sh"

if [ ! -f "$installer" ]; then
  echo "error=installer_missing" >&2
  echo "path=$installer" >&2
  exit 1
fi

# Ne test na složku .git — u worktree a submodulu je .git soubor a instalace
# by se mylně označila za poškozenou.
if ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "error=not_a_git_installation" >&2
  echo "path=$root" >&2
  exit 1
fi

# install.sh dělá nepodmíněný checkout na zadanou větev, takže mu předáváme tu,
# na které instalace stojí. Bez toho by výchozí `main` přepnul strom komukoli,
# kdo instaluje z jiné větve — a diff by pak porovnával dvě různé větve.
branch="$(git -C "$root" rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "HEAD" ]; then
  echo "error=detached_head" >&2
  echo "path=$root" >&2
  exit 1
fi
echo "branch=$branch"

# Vytáhne z URL remotu tvar 'vlastník/repo', aby šly porovnat SSH i HTTPS varianty.
normalize_remote() {
  printf '%s' "$1" | sed -E 's#^git\+?ssh://##; s#^git@([^:/]+)[:/]#\1/#; s#^https?://##; s#^[^/]+/##; s#\.git$##'
}

echo "root=$root"

# Zjišťujeme to sami, ne z hlášek install.sh — vázat se na jeho formulace
# by znamenalo, že přeformulovaná věta tiše rozbije detekci.
if [ -n "$(git -C "$root" status --porcelain)" ]; then
  echo "install_dirty=true"
else
  echo "install_dirty=false"
fi

before="$(git -C "$root" rev-parse HEAD)"
after="$before"

# --- má ta větev vůbec protějšek na remotu? ------------------------------
# Bez téhle kontroly by install.sh spadl na `couldn't find remote ref`. Čistě
# lokální větev není chyba instalace — jen na ní není co stahovat.
set +e
git -C "$root" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
ls_code=$?
set -e

if [ "$ls_code" -eq 2 ]; then
  echo "before=$(git -C "$root" rev-parse --short "$before")"
  echo "after=$(git -C "$root" rev-parse --short "$after")"
  echo "updated=false"
  echo "commits=0"
  echo "reason=branch_not_on_remote"
elif [ "$ls_code" -ne 0 ]; then
  echo "error=remote_unreachable" >&2
  echo "branch=$branch" >&2
  exit "$ls_code"
else
  # --- stažení přes install.sh -------------------------------------------
  set +e
  output="$(bash "$installer" --target "$root" --ref "$branch" 2>&1)"
  code=$?
  set -e

  if [ "$code" -ne 0 ]; then
    echo "error=update_failed" >&2
    printf '%s\n' "$output" >&2
    exit "$code"
  fi

  after="$(git -C "$root" rev-parse HEAD)"

  echo "before=$(git -C "$root" rev-parse --short "$before")"
  echo "after=$(git -C "$root" rev-parse --short "$after")"

  if [ "$before" = "$after" ]; then
    echo "updated=false"
    echo "commits=0"
  else
    echo "updated=true"
    echo "commits=$(git -C "$root" rev-list --count "$before..$after")"
  fi
fi

# --- co se změnilo --------------------------------------------------------
if [ "$before" != "$after" ]; then
  echo ""
  echo "[commits]"
  git -C "$root" log --oneline --no-decorate "$before..$after"

  echo ""
  echo "[skills]"
  # Stav skillu určuje jeho SKILL.md: přibyl-li, je skill nový; zmizel-li,
  # skill zanikl. Změna jen doprovodných souborů nebo skriptů je 'modified'.
  # --no-renames je nutnost: bez něj přijde přejmenovaný skill jako jediný
  # řádek R100 a rozpadl by se na 'modified' pod starým názvem — tedy přesně
  # tam, kde je potřeba rozpoznat zánik i vznik.
  git -C "$root" diff --no-renames --name-status "$before" "$after" -- skills SKILL.md | awk '
    {
      status = $1; path = $2
      if (path == "SKILL.md") { name = "(rozcestník)" }
      else if (path ~ /^skills\//) { split(path, p, "/"); name = p[2] }
      else { next }

      if (path ~ /SKILL\.md$/ && status ~ /^A/)      state[name] = "added"
      else if (path ~ /SKILL\.md$/ && status ~ /^D/) state[name] = "removed"
      else if (!(name in state))                     state[name] = "modified"
    }
    END { for (n in state) print state[n] "=" n }
  ' | sort

  echo ""
  echo "[files]"
  git -C "$root" diff --no-renames --name-status "$before" "$after"
fi

# --- vývojová kopie -------------------------------------------------------
# Pull do instalace nepřinese to, co leží necommitnuté nebo nepushnuté
# v odděleném klonu, ze kterého se plugin vyvíjí. Když v takovém klonu právě
# stojíme, řekneme to — jinak uživatel čeká změny, které nikdy neodešly.
echo ""
echo "[dev_copy]"

cwd_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$cwd_root" ]; then
  echo "detected=false"
  exit 0
fi

cwd_root="$(cd "$cwd_root" && pwd)"
if [ "$cwd_root" = "$root" ]; then
  echo "detected=false"
  exit 0
fi

cwd_remote="$(git -C "$cwd_root" remote get-url origin 2>/dev/null || true)"
inst_remote="$(git -C "$root" remote get-url origin 2>/dev/null || true)"

if [ -z "$cwd_remote" ] || [ "$(normalize_remote "$cwd_remote")" != "$(normalize_remote "$inst_remote")" ]; then
  echo "detected=false"
  exit 0
fi

echo "detected=true"
echo "path=$cwd_root"
# Ne 'branch=' — ten klíč je obsazený větví instalace a stejné jméno se dvěma
# významy by se v reportu spolehlivě zaměnilo.
echo "dev_branch=$(git -C "$cwd_root" rev-parse --abbrev-ref HEAD)"

if [ -n "$(git -C "$cwd_root" status --porcelain)" ]; then
  echo "dirty=true"
else
  echo "dirty=false"
fi

# Bez upstreamu je jisté, že neodešlo nic — create-branch upstream záměrně
# nezakládá, takže 'no_upstream' je běžný stav, ne neznámo.
if git -C "$cwd_root" rev-parse '@{u}' >/dev/null 2>&1; then
  echo "unpushed=$(git -C "$cwd_root" rev-list --count '@{u}..HEAD')"
else
  echo "unpushed=no_upstream"
fi

# Pushnutá, ale nezamergovaná větev je pro instalaci stejně neviditelná jako
# nepushnutá práce — instalace táhne jen tu větev, na které stojí. Vzdálený ref
# schválně neaktualizujeme: zastaralý ref nanejvýš varuje navíc, což je
# bezpečný směr.
# --verify -q je nutnost: bez něj rev-parse u neexistujícího refu vypíše zpátky
# svůj argument, fallback by se nikdy neuplatnil a vypadlo by unmerged=unknown.
cwd_default="$(git -C "$cwd_root" rev-parse --abbrev-ref --verify -q origin/HEAD 2>/dev/null || true)"
[ -n "$cwd_default" ] || cwd_default="origin/main"

if git -C "$cwd_root" rev-parse --verify -q "$cwd_default" >/dev/null 2>&1; then
  echo "unmerged=$(git -C "$cwd_root" rev-list --count "$cwd_default..HEAD")"
else
  echo "unmerged=unknown"
fi
