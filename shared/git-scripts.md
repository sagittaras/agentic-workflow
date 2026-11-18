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

### `branch-state.sh [--base B]`

Vypíše stav aktuální větve — to, z čeho se rozhoduje před založením PR nebo
před prací nad větví. Nic nemění kromě fetche základní větve.

- **Výstup:** `detached=`, `branch=`, `default_branch=`,
  `default_branch_source=remote|unavailable`, `on_default_branch=true|false|unknown`,
  `dirty=`, `upstream=`, `ahead=`, `behind=`, `pushed=`. S `--base` navíc `base=`,
  `base_fetched=`, `base_ref=`, `base_source=remote|local|missing`,
  `commits_ahead=`, `base_is_ancestor=`.
- **Kódy:** `0` · `2` nejde o git repozitář nebo chybný argument · `4` základní
  větev neexistuje ani na remotu, ani lokálně (výstup se přesto vypíše).

Proti základu porovnává **remote ref**, lokální větev je až náhrada — lokální
kopie bývá zastaralá a vydá věrohodně vypadající špatné číslo. Kdo potřebuje
základ na remotu (PR), čte `base_source`.

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
- **Kódy:** `0` · `2` chybný nebo chybějící argument, cíl je výchozí větev, nebo
  repozitář/větev neexistuje · `3` remote neodpověděl (fetch nebo push selhal) ·
  `4` nečistý pracovní strom, checkout selhal, nebo se lokální větev rozešla
  s remotem · `5` konflikt.

Při konfliktu merge **abortuj** a skonči kódem `5`. Řešit obsahový konflikt bez dohledu
není práce pro skript. Kódy `2`–`4` jsou výpadek volání nebo prostředí, ne konflikt —
volající je řeší jako svůj vlastní stav (chybný argument opravit a zopakovat, nečistý
strom nebo nedostupný remote eskalovat), ne jako nález review.

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
- **Kódy:** `0` merge i příkaz prošly · `2` chybný argument nebo některá z větví
  neexistuje · `3` remote nedostupný, nebo založení dočasného worktree selhalo ·
  `5` konflikt při merge · `6` příkaz selhal.
- **Nikdy nepushuje a nemazává větve.** Je to brána, ne merge.
- Kódy `2` a `3` jsou výpadek infrastruktury, ne nález review — nečerpají retry
  rozpočet issue.

### `criteria-tests.sh --issue-body F --pr-body F --base B --head H [--ticked-body F]`

Ověří mapu kritérium → test v těle PR (tabulka pod `## Testy kritérií`) proti
kritériím issue a proti souborům, které PR mění. Posuzuje úplnost mapy a cesty, ne
kvalitu testů. Tvar tabulky popisuje hlavička skriptu.

- **Výstup:** `criteria=`, `tested=`, `human=`, `changed_files=`, řádky
  `fail=<kritérium|pr> reason=<důvod>`, `ticked_body=` (jen s `--ticked-body` a pass),
  `result=pass|fail`.
- **Kódy:** `0` mapa sedí · `1` nález, patří zpátky implementující session ·
  `2` chybný argument, nečitelný soubor, neexistující větev nebo issue bez sekce
  kritérií · `3` remote nedostupný.
- **S `--ticked-body`** zapíše tělo issue s odškrtnutými kritérii, jejichž test
  potvrdil. Do trackeru nezapisuje — to je další krok volajícího.

### `mutation-check.sh --worktree W --base REF --file P [--file P…] -- <příkaz…>`

Mutačně ověří, jestli test hlídá produkční změnu: v pracovní kopii `W` vrátí změnu
zadaných souborů proti `REF` (`git diff | git apply -R`), pustí příkaz, kopii obnoví
a pustí ho znovu.

- **Výstup:** `base=`, `files=`, `applied=`, `mutant=killed|survived`, `restored=`,
  `original=pass|fail`, `verdict=covered|not_covered|inconclusive`, sekce
  `[mutant_output]` a `[original_output]`.
- **Kódy:** `0` mutace proběhla (výsledek nese `verdict`) · `2` chybný argument,
  `W` není pracovní kopie nebo `REF` neexistuje · `4` `W` není před startem čistá ·
  `5` `git apply -R` selhal nebo se soubory proti základu nemění · `6` obnovení selhalo.

**Bez čisté kopie se nerozběhne** — obnovení dělá `git checkout -- .`, které by
cizí změny smazalo. `mutant=killed` znamená jen nenulový kód; jestli spadl test,
nebo build, rozhoduje volající ze sekce `[mutant_output]`. Při kódu `6` se
pracovní kopie zahazuje a zakládá znovu.

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
| `issue-read.sh` | `<number> [--body]` — s `--body` jen tělo jako text |
| `issue-list.sh` | `[--milestone M] [--state open\|closed\|all]` |
| `issue-create.sh` | `--title T --body-file F\|- [--milestone M] [--label L]…` |
| `issue-update.sh` | `<number> [--body-file F\|-] [--state closed]` |
| `issue-comment.sh` | `<number> --body-file F\|-` |
| `milestone-list.sh` | `[--state open\|closed\|all]` |
| `milestone-create.sh` | `--title T [--description D]` |
| `milestone-update.sh` | `<number> --state closed` |
| `label-list.sh` | — |
| `label-create.sh` | `--name N --color C [--description D]` |
| `pr-create.sh` | `--base B --head H --title T --body-file F\|-` |
| `pr-read.sh` | `<number> [--body]` — s `--body` jen tělo jako text |
| `pr-reviews.sh` | `<number>` — sekce `[reviews]`, `[line_comments]`, `[comments]`: všechny připomínky na jedno volání |
| `pr-update.sh` | `<number> --body-file F\|-` — nahradí celé tělo PR |
| `pr-list.sh` | `[--milestone M] [--state open\|closed\|all]` |
| `pr-for-issue.sh` | `<issue> [--base B] [--state open\|closed\|all]` — PR s `Closes #<issue>` v těle, i do integrační větve |
| `pr-for-branch.sh` | `<head> [--base B] [--state open\|closed\|all]` — PR z head větve tohoto repozitáře, přesná shoda názvu, bez forků |
| `pr-set-milestone.sh` | `<number> --milestone M` |
| `pr-comment.sh` | `<number> --body-file F\|-` |
| `pr-merge.sh` | `<number> [--squash] [--delete-branch]` |
| `pr-gate.sh` | `<number> --issue N --base B [--no-write] [-- <příkaz…>]` — brána před review jedním voláním, viz níž |

**Tělo se nikdy nepředává argumentem**, ale souborem, nebo ze stdin přes `--body-file -`
(heredoc s ukončovačem v uvozovkách ve stejném volání). Víceřádkový markdown v argumentu
se o uvozovky a zpětné apostrofy rozbije, a rozbije se tiše — vznikne issue s useknutým
tělem. Stdin ušetří dočasný soubor a nespoléhá na proměnnou s cestou, která mezi voláními
Bash nepřežije; prázdné tělo ze stdin skončí kódem `2` (`empty_body`).

Chybějící `gh` nebo nepřihlášený `gh auth status` hlas kódem `7` s vysvětlením na stderr;
skill to má uživateli říct rovnou, ne narazit až v půlce běhu milestonu.

### `gh/pr-gate.sh <PR> --issue N --base B [--no-write] [-- <příkaz…>]`

Brána `run-milestone` před review: přečte tělo issue a PR, hlavu i cíl PR vezme
z forge, spustí `criteria-tests.sh` a při kódu `0` `integration-gate.sh`. Prošlo-li
obojí, nahraje tělo issue s odškrtnutými kritérii a pošle k PR komentář „Brána
prošla"; s `--no-write` jen ohlásí, že by to udělal.

- **Výstup:** `pr=`, `issue=`, `head=`, `base=`, řádky `criteria-tests.sh` (bez
  `result=`), `criteria_tests=pass|fail`, řádky brány `merge=`, `check=`,
  `conflicts=`, `command=`, `exit_code=`, `worktree_removed=`, pak
  `issue_body=updated|skipped`, `comment_mode=review|comment|skipped`,
  `result=pass|fail`. Sekce brány (`[conflicts]`, `[merge_output]`, `[output]`)
  jen při neúspěchu; u kódů `2`, `3`, `4` a `7` řádek `result=` chybí a důvod nese
  `error=` na stderr.
- **Kódy:** `0` prošlo a je zapsáno · `1` nález v mapě kritérií · `2` chybný
  argument, PR nemíří do `--base` nebo issue bez sekce kritérií · `3` čtení
  z forge, remote nebo worktree selhalo · `4` brána prošla, ale zápis do trackeru
  selhal · `5` konflikt · `6` ověřovací příkaz selhal · `7` chybí `gh`.
