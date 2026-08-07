---
name: make-commit
description: >-
  Zapíše rozdělanou práci jako commit podle Conventional Commits — zjistí stav
  repozitáře, rozdělí změny do logických celků, sestaví zprávu z diffu,
  commitne a volitelně pushne. Všechny operace nad gitem provádí přes
  připravené skripty, takže jsou deterministické a neumí přepsat historii.
when_to_use: >-
  Použij, když má uživatel rozdělanou práci k zapsání — „commitni to",
  „udělej commit", „zapiš změny", „commitni a pushni" — nebo jako závěrečný
  krok jiné úlohy, která něco změnila v pracovním stromu. Nepoužívej pro
  operace přepisující historii (amend, rebase, force push), ty skill záměrně
  neumí; ani pro zakládání větve, na to slouží create-branch.
argument-hint: "[rozsah nebo popis změny]"
model: sonnet
effort: medium
# Zařazení dle matice: rutinní tvorba podle jasného zadání → sonnet × medium.
# Vstupem je diff, výstupem zpráva v pevném formátu; úsudek je potřeba jen
# na rozdělení do celků, což nezvedá úlohu o kategorii výš.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - "Bash(bash:*)"
# Bash je zúžený na spouštění skriptů; git se nikdy nevolá přímo (viz Zásady).
# Užší vzor než "bash:*" by musel spoléhat na tvar cesty ke skriptu, což je
# křehčí než zákaz přímého gitu vyjádřený v těle skillu.
# Vynechaná zvažovaná pole: Write/Edit — skill nezapisuje soubory, zpráva jde
# do gitu stdinem; context/agent/background — rozdělení do celků konzultuje
# s uživatelem a pracuje nad sdíleným pracovním stromem, fork by obojí rozbil;
# paths — spouští se z konverzace, ne prací nad konkrétními soubory;
# disallowed-tools — allowed-tools je uzavřený výčet, není co zakazovat navíc.
---

# Make Commit

Cílem je jednotná, strojově čitelná historie — z takové jde generovat changelog
a na první pohled rozeznat povahu změny. Závazný formát zprávy drží
[conventional-commits.md](conventional-commits.md); přečti si ho, než začneš
psát první zprávu.

Veškerá práce s gitem jde přes skripty v `scripts/`. Důvod není pohodlí, ale
předvídatelnost: skripty mají ošetřené hraniční stavy (odpojená HEAD, zastaralý
lokální ref na výchozí větev, chybějící upstream) a neumí operace, které přepisují
historii. Příkaz `git` proto nevolej přímo, ani když se to zdá rychlejší.

## Skripty

| Skript | Co dělá |
| --- | --- |
| `scripts/preflight.sh` | Vypíše stav repozitáře jako `key=value` + výpis změn |
| `scripts/show-diff.sh` | Staged diff; s `--worktree` vše necommitnuté proti HEAD |
| `scripts/commit.sh` | Stagne zadané cesty a commitne se zprávou ze stdinu |
| `scripts/push.sh` | Pushne větev; `--publish` založí upstream nové větvi |

Každý skript má v hlavičce popis použití a návratových kódů. Nenulový kód vždy
vyhodnoť — `nothing_staged` znamená jiný postup než `detached_head`.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

Zadání ber jako vodítko pro `type`, `scope` a rozdělení do celků. O obsahu
zprávy ale rozhoduje diff, ne zadání.

## Postup

### 1. Zjisti stav

Spusť `scripts/preflight.sh` a vyhodnoť výstup:

- **`detached=true`** → zastav se a ohlas to. Commit na odpojené HEAD se tiše
  ztratí, jakmile se přepne větev.
- **`on_default_branch=true`** → zeptej se uživatele, jestli má práce opravdu
  jít přímo do výchozí větve, nebo se má nejdřív založit nová — na to slouží
  skill `create-branch`, sám větve nezakládej. Běžíš-li neinteraktivně,
  **necommituj** a jen ohlas, že změny leží na výchozí větvi a čekají na
  rozhodnutí; zápis do sdílené výchozí větve se špatně bere zpět, takže tady
  opatrnost vítězí nad plynulostí.
- **`on_default_branch=unknown`** (offline, `default_branch_source=unavailable`)
  → chovej se, jako bys na výchozí větvi byl.
- **`staged_count=0` i `unstaged_count=0` i `untracked_count=0`** → není co
  commitovat, skonči.

### 2. Urči rozsah

Je-li něco staged, commituj **výhradně to** — někdo ten výběr udělal vědomě
a rozšířit ho by znamenalo commitnout cizí práci.

Jinak projdi `[status]` z preflightu a rozděl změny do logických celků podle
oblasti a povahy změny. Smíchaný commit znehodnotí `type` i `scope`: změna,
která je zároveň `feat` i `fix` v jiné oblasti, nemá správnou zprávu.

Při přímém vyvolání uživatelem („commitni to") je rozsahem celý pracovní strom,
pokud uživatel sám nezúžil. Při automatickém spuštění na konci jiné úlohy vynech
změny, které s ní zjevně nesouvisejí — a vynechání ohlas.

**Víc celků → víc commitů.** Rozdělení navrhni uživateli prostým textem a nech
ho rozhodnout. Neinteraktivně commitni vše jako jeden celek a rozdělení jen
doporuč ve shrnutí — čekání na odpověď, která nepřijde, by zaseklo běh.

### 3. Napiš zprávu

Pro každý celek si nech vypsat diff — `scripts/show-diff.sh --worktree <cesty>`
u ještě nestagovaných změn, `scripts/show-diff.sh` u staged výběru. U většího
rozsahu si ho vyžádej po souborech.

Zprávu piš **z diffu, ne z paměti konverzace**. Commituješ to, co je skutečně
v repu — včetně změn, o kterých konverzace nemluvila. Formát a pravidla drží
[conventional-commits.md](conventional-commits.md).

### 4. Commitni

```bash
bash scripts/commit.sh <cesty> <<'MSG'
<zpráva>
MSG
```

Zprávu předávej vždy takhle — heredocem s ukončovačem v uvozovkách. Bez uvozovek
by shell expandoval `$` a zpětné apostrofy a do historie by dorazilo něco jiného,
než jsi napsal. Je-li výběr už staged z kroku 2, cesty vynech.

Skript vrátí `commit=<hash>` a `subject=<popis>`. Odmítne-li commit hook, oprav
příčinu, nebo ji ohlas uživateli — neobcházej ji.

### 5. Pushni

Spusť `scripts/push.sh`. Skončí-li s `error=no_upstream`, větev nemá kam pushnout:
publikuj ji přes `--publish` **jen na výslovné přání uživatele**, jinak to ohlas
ve shrnutí. Push úplně vynech, pokud uživatel řekl, že ho nechce.

### 6. Shrň výsledek

Pro každý commit uveď hash a popis, kam se pushlo (nebo proč ne), a co jsi
z rozsahu vynechal i s důvodem.

## Zásady

- **Git jen přes skripty.** Přímé volání `git` obchází ošetřené hraniční stavy,
  kvůli kterým skripty vznikly.
- **Historie se jen rozrůstá.** Žádný `--amend`, žádný force push, žádné
  přeskakování hooků. Skripty tyhle operace záměrně neumí — nesnaž se je obejít
  jinou cestou.
- **Zpráva se píše z diffu.** Konverzace je vodítko, diff je pravda.
- **Staged výběr je zadání**, ne návrh k rozšíření.
- **Publikování větve patří uživateli.** Větev bez upstreamu nikdy nepublikuj
  sám od sebe.
