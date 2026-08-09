# Kontrakt sdílených skriptů

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Popisuje skripty v
> `${CLAUDE_PLUGIN_ROOT}/scripts/` — co dělají, co vypisují a co znamenají jejich
> návratové kódy. Otevři ho, když skript **voláš** ze skillu, nebo když ho **píšeš**.

Skripty existují proto, aby se git plumbing a volání `gh` nevymýšlely při každém běhu
znovu. Platí pro ně stejná pravidla jako pro skripty u `make-commit`:

- `#!/usr/bin/env bash` a `set -euo pipefail`.
- Výstup `key=value` na stdout, jeden pár na řádek; delší výpisy v sekci uvozené
  hlavičkou v hranatých závorkách.
- **Skript zjišťuje a hlásí, nerozhoduje.** Rozhodnutí patří skillu — skript nesmí sám
  řešit konflikt, přepisovat historii ani pushovat něco, co po něm nikdo nechtěl.
- Chybové stavy nese návratový kód, ne text na stdout.
- Nikdy `--force`, `push --force`, `rebase` ani `reset --hard`.

---

## Git plumbing — `scripts/`

### `forge-detect.sh`

Zjistí z `git remote` a stavu repozitáře, s čím se pracuje.

- **Argumenty:** žádné.
- **Výstup:** `forge=gitea|github|unknown`, `host=`, `owner=`, `repo=`, `default_branch=`.
- **Kódy:** `0` v pořádku · `2` nejde o git repozitář · `3` remote chybí nebo z něj nelze
  odvodit owner/repo.

Výchozí větev ber z remotu, ne z lokálního `refs/remotes/origin/HEAD` — ten po změně na
serveru zůstává zastaralý a vrátí věrohodně vypadající nesmysl.

### `milestone-branch.sh <slug>`

Založí nebo checkoutne integrační větev `milestone/<slug>` z čerstvé výchozí větve
a nově založenou rovnou publikuje.

- **Výstup:** `branch=`, `created=true|false`, `base=`, `pushed=true|false|skipped`.
- **Kódy:** `0` · `2` nejde o git repozitář · `3` remote neodpověděl nebo push neprošel ·
  `4` pracovní strom není čistý.

Když větev na remotu už existuje, **fetchni a checkoutni ji** — nezakládej ji znovu.
Znovuzaložení by zahodilo práci předchozího běhu, který se přerušil.

**Publikace není odkladatelná.** Proti větvi, která je jen lokální, nejde otevřít pull
request — první dávka issues by odvedla práci, kterou nemá kam předat.

### `sync-branch.sh <branch>`

Vmerguje aktuální výchozí větev do zadané větve a pushne.

- **Výstup:** `result=up_to_date|fast_forward|merged|conflict`, `conflicts=` (seznam
  souborů, jen u `conflict`).
- **Kódy:** `0` · `5` konflikt.

Při konfliktu merge **abortuj** a skonči kódem `5`. Řešit obsahový konflikt bez dohledu
není práce pro skript.

### `pr-worktree.sh <label> <ref>` / `pr-worktree.sh --remove <label>`

Připraví oddělenou pracovní kopii větve v dočasném worktree — pro postupy, které nad
kódem pracují ve **víc voláních** za sebou (typicky `verify-issue`).

- **Výstup:** `worktree=`, `reused=true|false`, `ref=`, `head=`; u `--remove`
  `removed=true|false`.
- **Kódy:** `0` · `2` nejde o git repozitář, chybný argument nebo ref neexistuje ·
  `3` remote neodpověděl, fetch nebo založení selhalo.

Cesta se odvozuje z `<label>` **deterministicky, ne z `mktemp`**: mezi voláními Bash
nepřežije stav shellu, takže náhodná cesta by napodruhé založila druhý, prázdný
worktree — a ověřovací příkaz by pak spadl na chybějícím prostředí, ne na kódu.
Opakované spuštění nad týmž labelem worktree převezme i s obnovenými závislostmi.

Worktree stojí na odpojené HEAD: do ověřovací kopie se nemá commitovat.
Úklid po sobě je součást postupu, ne úklid navíc — nechaný worktree drží referenci
a mate další běh.

### `integration-gate.sh <pr-branch> <integration-branch> -- <příkaz…>`

Ověří, že PR obstojí proti aktuální špičce integrační větve. Merge dělá v dočasném
worktree, takže pracovní strom volajícího zůstane netknutý.

- **Výstup:** `merge=ok|conflict`, `check=pass|fail|skipped`, `worktree=`, plus sekce
  `[output]` s výstupem příkazu.
- **Kódy:** `0` merge i příkaz prošly · `5` konflikt při merge · `6` příkaz selhal.
- **Nikdy nepushuje a nemazává větve.** Je to brána, ne merge.

---

## GitHub operace — `scripts/gh/`

Tenké obálky nad `gh api` / `gh issue` / `gh pr`. Repozitář berou z `-R owner/repo`, které
skill předá ze sekce `Forge` konfigurace; bez něj by se řídily podle aktuálního adresáře,
což v izolovaném worktree nemusí platit.

Skripty, které něco zakládají, vypisují `number=` a `url=` — na to se skill odkazuje dál.
Skripty, které jen čtou, vypisují JSON tak, jak ho vrátí `gh`, aby si skill mohl vytáhnout,
co potřebuje, bez dalšího kola.

| Skript | Argumenty |
| --- | --- |
| `issue-read.sh` | `<number>` |
| `issue-list.sh` | `[--milestone M] [--state open\|closed\|all]` |
| `issue-create.sh` | `--title T --body-file F [--milestone M] [--label L]…` |
| `issue-update.sh` | `<number> [--body-file F] [--state closed]` |
| `issue-comment.sh` | `<number> --body-file F` |
| `milestone-list.sh` | `[--state open\|closed\|all]` |
| `milestone-create.sh` | `--title T [--description D]` |
| `milestone-update.sh` | `<number> --state closed` |
| `label-list.sh` | — |
| `label-create.sh` | `--name N --color C [--description D]` |
| `pr-create.sh` | `--base B --head H --title T --body-file F` |
| `pr-read.sh` | `<number>` |
| `pr-list.sh` | `[--milestone M] [--state open\|closed\|all]` |
| `pr-set-milestone.sh` | `<number> --milestone M` |
| `pr-comment.sh` | `<number> --body-file F` |
| `pr-merge.sh` | `<number> [--squash] [--delete-branch]` |

**Tělo se vždy předává souborem.** Víceřádkový markdown v argumentu se o uvozovky
a zpětné apostroly rozbije, a rozbije se tiše — vznikne issue s useknutým tělem.

Chybějící `gh` nebo nepřihlášený `gh auth status` hlas kódem `7` s vysvětlením na stderr;
skill to má uživateli říct rovnou, ne narazit až v půlce běhu milestonu.
