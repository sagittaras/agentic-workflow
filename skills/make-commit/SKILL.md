---
name: make-commit
description: >-
  Zapíše rozdělanou práci jako commit podle Conventional Commits — zjistí stav
  repozitáře, rozdělí změny do logických celků, sestaví zprávu z diffu
  a commitne; hotový commit rovnou pushne, a nemá-li větev upstream, publikuje
  ji. Vynechá to jen tehdy, když si to uživatel vymíní. Všechny operace nad
  gitem provádí přes připravené skripty, které neumí přepsat historii.
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
# Matice u medium varuje před rozhodnutími, která se těžko vrací zpět — commit
# a jeho push takové jsou. Zůstáváme přesto na medium, protože nevratnost tu
# nesnižuje kvalita úsudku, ale absence brzdy: proti ní stojí zastavení na
# výchozí větvi (krok 1) a fakt, že publikace míří na vlastní pracovní větev,
# kde nikomu nepřekáží — rozdělení do commitů si skill určuje sám z diffu.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - "Bash(bash:*)"
# Bash je zúžený na spouštění skriptů; git se nikdy nevolá přímo (viz sekce Skripty).
# Proto každé volání píš ve tvaru `bash <cesta>` — jinak nespadne do povolení.
# Užší vzor by musel spoléhat na tvar cesty ke skriptu, což je křehčí.
# Vynechaná zvažovaná pole: disable-model-invocation — automatické dokončení
# úlohy commitem je žádoucí a brzdou je krok 1 (zastavení na výchozí větvi),
# ne zákaz vyvolání;
# Write/Edit — skill nezapisuje soubory, zpráva jde do gitu stdinem;
# context/agent/background — skill pracuje nad sdíleným pracovním stromem
# volajícího a fork by ho rozbil; paths —
# spouští se z konverzace, ne prací nad konkrétními soubory; shell — skripty
# se spouští explicitním `bash`; disallowed-tools — allowed-tools je uzavřený
# výčet, není co zakazovat navíc.
---

# Make Commit

Cílem je jednotná, strojově čitelná historie. Formát zprávy drží
`${CLAUDE_PLUGIN_ROOT}/skills/make-commit/conventional-commits.md`; přečti ho před první
zprávou.

## Skripty

Git jen přes skripty, volané tvarem `bash "<cesta>"`; `git` přímo nevolej.

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/preflight.sh` | Stav repozitáře jako `key=value`, výpis změn a zavedené scopy |
| `${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/show-diff.sh` | Staged diff; s `--worktree` vše necommitnuté proti HEAD |
| `${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/commit.sh` | Stagne zadané cesty a commitne se zprávou ze stdinu |
| `${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/push.sh` | Pushne větev; nemá-li upstream, publikuje ji na `origin` |

Návratové kódy popisuje hlavička každého skriptu; nenulový kód vždy vyhodnoť.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

Zadání je vodítko pro `type`, `scope` a rozdělení do celků; o obsahu zprávy rozhoduje
diff. Za neinteraktivní běh považuj až situaci, kdy volání AskUserQuestion selže nebo
odpověď nedorazí — ne to, že tě spustil jiný skill.

## Postup

### 1. Zjisti stav

Spusť `bash "${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/preflight.sh"`:

| Výstup | Co uděláš |
| --- | --- |
| `error=not_a_git_repository` (kód 2) | ohlas a skonči |
| `detached=true` | zastav se a ohlas to |
| `on_default_branch=true` nebo `unknown` | zeptej se nástrojem AskUserQuestion, jestli má práce jít přímo do výchozí větve, nebo se má napřed založit větev skillem `create-branch` (sám větve nezakládej); neinteraktivně necommituj a ohlas, že změny čekají na rozhodnutí |
| `staged_count`, `unstaged_count` i `untracked_count` jsou 0 | není co commitovat — jdi rovnou na krok 5 (nepushnuté commity nebo chybějící upstream) |

Ze sekce `[recent_scopes]` si vezmi slovník zavedených scopů.

### 2. Urči rozsah

Je-li něco staged, commituj výhradně to. Jinak rozděl změny z `[status]` do logických
celků podle oblasti a povahy změny — víc celků, víc commitů. Rozdělení proveď sám bez
čekání na potvrzení a vypiš ho prostým textem.

Při přímém vyvolání uživatelem je rozsahem celý pracovní strom, nezúžil-li ho. Při
spuštění na konci jiné úlohy vynech změny, které s ní zjevně nesouvisejí, a vynechání
ohlas.

### 3. Napiš zprávu

Pro každý celek si vypiš diff:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/show-diff.sh" --worktree <cesty>
```

U staged výběru vynech `--worktree`; u většího rozsahu si diff vyžádej po souborech.
Soubory ze sekce `[untracked]` si přečti nástrojem Read — diff jejich obsah neukáže.
Zprávu piš z diffu, ne z paměti konverzace.

### 4. Commitni

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/commit.sh" <cesty> <<'MSG'
<zpráva>
MSG
```

Zprávu předávej vždy heredocem s ukončovačem v uvozovkách. Je-li výběr už staged,
cesty vynech. Skript vrátí `commit=<hash>` a `subject=<popis>`. Odmítne-li commit hook,
ohlas příčinu — soubory needituješ. Přeformátoval-li hook soubory sám, stagni je znovu
a commit zopakuj.

### 5. Pushni

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/make-commit/scripts/push.sh"
```

Pushni po každém commitu; větev bez upstreamu skript publikuje na `origin`. Push vynech
jen tehdy, když ho uživatel nebo volající skill výslovně odmítl, a vynechání ohlas.

| Výsledek | Co uděláš |
| --- | --- |
| `error=no_remote` (kód 4) | ohlas, že commit zůstal lokálně; remote nezakládej |
| `error=detached_head` (kód 2) | zastav se a ohlas to |
| push odmítnutý remotem (oprávnění, posunutá větev) | ohlas příčinu; force push ani přepis historie nezkoušej |

### 6. Shrň výsledek

Pro každý commit uveď hash a popis, kam se pushlo (nebo proč ne), a co jsi z rozsahu
vynechal i s důvodem.

## Zásady

- **Historie se jen rozrůstá.** Žádný `--amend`, force push ani přeskakování hooků —
  ani jinou cestou než skripty.
