#!/usr/bin/env bash
# Test scripts/docs-map.sh nad dočasnými repozitáři.
#
# 1. Báze s víceřádkovou položkou, odkazem v tučném písmu, inline kódem
#    a odkazem ve větě, kotvou, odkazem mimo seznam, odkazem na cizí složku,
#    odkazem v bloku kódu, frontmatterem a vnořenou podsekcí → přesná mapa
#    s řádkem root= a kód 0.
# 2. Repozitář bez CLAUDE.md → fail=CLAUDE.md reason=missing_claude_md, kód 1.
# 3. CLAUDE.md bez odkazu na index → reason=missing_entry_index_link, kód 1.
# 4. Mimo git repozitář → kód 2.
# 5. CLAUDE.md a index odkazují jen s kotvou → mapa s takovou stránkou, kód 0.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/docs-map.sh"

fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

check() {
  local name="$1" expected_rc="$2" expected="$3" dir="$4" out rc
  out="$(cd "$dir" && bash "$script" 2>/dev/null)"
  rc=$?
  if [ "$rc" -ne "$expected_rc" ]; then
    echo "fail=$name reason=unexpected_exit_code_$rc"
    fail=1
  fi
  if [ -n "$expected" ] && [ "$out" != "$expected" ]; then
    echo "fail=$name reason=unexpected_output"
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$out")
    fail=1
  fi
}

# --- 1. báze ---------------------------------------------------------------
fx="$tmp/base"
mkdir -p "$fx/.docs/sec/sub" "$fx/.docs/jinde" "$fx/.claude"
(
  cd "$fx" || exit 1
  git init -q .
  printf 'Viz [dokumentace](.docs/index.md).\n' >CLAUDE.md
  printf 'Viz [dokumentace](../.docs/index.md#sekce).\n' >.claude/CLAUDE.md
  cat >.docs/index.md <<'MD'
---
title: frontmatter se nečte
---

# Projekt — dokumentace

Úvod s odkazem na [sekci](sec/index.md), která má i položku níž.

- **[Sekce](sec/index.md)** — první řádek věty
  pokračuje na druhém.
- [Stránka](page.md): věta s `kódem [x](y.md)` a [odkazem](sec/a.md#kotva).
- [Kotva](page.md#kotva) — odkaz s kotvou do mapy nepatří.
- [Cizí](jinde/a.md) — stránka mimo vlastní složku.

Jen v próze: [Próza](prose.md).

```markdown
- [V kódu](code.md) — nepatří.
```
MD
  cat >.docs/sec/index.md <<'MD'
# Sekce

- [Stránka A](a.md) — popis A.
- [Zpět](../index.md) — odkaz nahoru.
- [Podsekce](sub/index.md) — vnořená podsekce.
MD
  printf '# Podsekce\n\n- [Stránka B](b.md) — popis B.\n' >.docs/sec/sub/index.md
  printf '# Jinde\n\n- [Stránka C](a.md) — popis C.\n' >.docs/jinde/index.md
  for p in page.md prose.md code.md sec/a.md sec/sub/b.md jinde/a.md; do
    printf '# Stránka\n\n## Kotva\n' >".docs/$p"
  done
)

fx_root="$(git -C "$fx" rev-parse --show-toplevel)"
expected="root=$fx_root
$(cat <<'OUT'
- [Projekt — dokumentace](.docs/index.md)
  - [Sekce](.docs/sec/index.md) — první řádek věty pokračuje na druhém.
    - [Stránka A](.docs/sec/a.md) — popis A.
    - [Podsekce](.docs/sec/sub/index.md) — vnořená podsekce.
      - [Stránka B](.docs/sec/sub/b.md) — popis B.
  - [Stránka](.docs/page.md) — věta s `kódem [x](y.md)` a odkazem.
  - [Próza](.docs/prose.md)
OUT
)"
check base 0 "$expected" "$fx"

# --- 5. odkazy jen s kotvou ---------------------------------------------------
# CLAUDE.md odkazuje vstupní index jen s kotvou a index stránku jen s kotvou
# (docs-check.sh obojí uzná) → mapa vznikne a stránka v ní je, za stránkami
# odkázanými bez kotvy.
fa="$tmp/anchors"
mkdir -p "$fa/.docs"
(
  cd "$fa" || exit 1
  git init -q .
  printf 'Viz [dokumentace](.docs/index.md#sekce).\n' >CLAUDE.md
  cat >.docs/index.md <<'MD'
# Báze

## Sekce

- [Část A](a.md#kotva) — věta k části A.
- [B](b.md) — stránka B.
MD
  printf '# A\n\n## Kotva\n' >.docs/a.md
  printf '# B\n' >.docs/b.md
)
fa_root="$(git -C "$fa" rev-parse --show-toplevel)"
expected="root=$fa_root
$(cat <<'OUT'
- [Báze](.docs/index.md)
  - [B](.docs/b.md) — stránka B.
  - [Část A](.docs/a.md) — věta k části A.
OUT
)"
check anchors 0 "$expected" "$fa"

# --- 2. bez CLAUDE.md --------------------------------------------------------
mkdir -p "$tmp/no-claude" && git -C "$tmp/no-claude" init -q .
check no_claude 1 'fail=CLAUDE.md reason=missing_claude_md' "$tmp/no-claude"

# --- 3. CLAUDE.md bez odkazu na index ----------------------------------------
mkdir -p "$tmp/no-link" && git -C "$tmp/no-link" init -q .
printf 'Bez odkazu.\n' >"$tmp/no-link/CLAUDE.md"
check no_link 1 'fail=CLAUDE.md reason=missing_entry_index_link' "$tmp/no-link"

# --- 4. mimo git ---------------------------------------------------------------
mkdir -p "$tmp/no-git"
check no_git 2 '' "$tmp/no-git"

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi

exit "$fail"
