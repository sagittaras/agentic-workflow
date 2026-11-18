---
name: open-pr
description: >-
  Otevře pull request pro práci na aktuální větvi — zjistí forge a základní
  větev z projektové konfigurace, nezapsané změny nechá zapsat a odeslat přes
  make-commit, sestaví název podle Conventional Commits a krátké tělo
  s odkazem na uzavírané issue, založí PR podle sdílených receptů a případně
  mu druhým voláním přiřadí milestone. Obsahoval-li prompt, kterým byl
  aktuální běh spuštěn, výslovný souhlas k mergi, PR i rovnou mergne. Výstupem
  je číslo a odkaz PR, případně i výsledek merge.
when_to_use: >-
  Použij, když má z odvedené práce vzniknout pull request — „otevři PR",
  „udělej z toho pull request", „pošli to na review" — a jako sdílený závěrečný
  krok skillů, které odvedly práci na větvi — implement-issue u jednotlivého
  issue, run-milestone u závěrečného PR celého milestonu.
  Nepoužívej pro pouhé zapsání a odeslání změn bez PR, na to slouží make-commit;
  ani pro založení pracovní větve, na to slouží create-branch; ani pro
  implementaci issue — tu vlastní implement-issue, který řeší obsah práce,
  kdežto tenhle skill jen mechaniku PR. Bez projektové konfigurace workflow
  skill PR nezakládá a odkáže na init-workflow.
argument-hint: "[základní větev, číslo issue, milestone nebo popis práce]"
model: sonnet
effort: medium
# Zařazení dle matice: dobře ohraničené zadání se známým tvarem výstupu →
# sonnet × medium (bod 2 rozhodovacího stromu), bez odchylky. Nikoli opus:
# matice velí rozhodovat podle nejtěžší práce, kterou skill dělá sám — obsah
# změn vlastní volající, commit deleguje na make-commit a skill drží jen
# mechaniku. Nikoli low: postup má deset kroků, dvě forge větve a několik
# stavů, které selhávají tiše (nepushnutá větev, duplicitní PR, nepřiřazený
# milestone). Stav větve a hledání existujícího PR drží skripty
# (branch-state.sh, gh/pr-for-branch.sh), takže úsudek zbývá na název, tělo
# a eskalace.
# Varování matice u medium („nevol u rozhodnutí, která se těžko vrací zpět")
# tady neplatí naplno: PR se zavírá jedním kliknutím a publikaci větve dělá
# cizí skript. Merge do výchozí větve nevratný je, ale brzdou proti němu je
# prokazatelný výslovný souhlas v promptu (krok 8), ne neschopnost mergovat.
# Odchylka od konvence pojmenování: tabulka sloves zná pro nový artefakt
# `write`/`create`, ale forge i uživatel říkají „otevři PR"; `open-pr` proto
# trefí spouštěcí frázi líp než `create-pr`.
user-invocable: true
# Vynechaná zvažovaná pole: allowed-tools — sada nástrojů se liší podle forge
# a na Gitea jde o odložené `mcp__gitea__*` načítané za běhu přes ToolSearch;
# uzavřený výčet by je nepokryl a gitea větev by tiše spadla při zakládání PR.
# Hranicí je tady podmínka výslovného souhlasu (Vstupní kontext, krok 8), ne zúžení práv;
# disable-model-invocation — automatické vyvolání na konci implement-issue je
# celý smysl skillu a PR je vratný artefakt (dá se zavřít);
# context/agent/background — název a tělo PR se píšou z kontextu odvedené
# práce a commit se dělá ve sdíleném pracovním stromu volajícího, fork by
# obojí rozbil; paths — spouští se z konverzace nebo z jiného skillu, ne prací
# nad konkrétními soubory; shell — skripty se spouští explicitním `bash`;
# disallowed-tools — bez allowed-tools by šlo o výčet bez protějšku;
# version/license — verzuje se celý plugin, ne jednotlivý skill.
---

# Open PR

Cílem je pull request otevřený proti správné základní větvi, s názvem a tělem, ze
kterých je poznat, co se mění a co se tím zavírá. Commit a push deleguje na
`sagittaras:make-commit`, zakládání větve na `sagittaras:create-branch`. Při rozporu
s tímhle postupem platí sdílené soubory pluginu.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | v kroku 1, když konfigurace chybí nebo v ní nenajdeš sekci `Forge` či `Větvení` |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | když skript skončí kódem, který postup níže nemapuje |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | na Gitea v kroku 6, dřív než sáhneš na tracker |

Obsah sdílených souborů nepřepisuj do odpovědi.

## Skripty

Skripty volej tvarem `bash "<cesta>"`; `git` ani `gh` nevolej přímo.

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/scripts/forge-detect.sh` | Forge, `owner`/`repo` a výchozí větev z remotu |
| `${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh` | Stav větve: výchozí/odpojená, nezapsané změny, upstream; s `--base` i commity navíc proti základu |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-branch.sh` | Existující PR z head větve |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-create.sh` | Založí PR; tělo čte ze stdin přes `--body-file -` |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-set-milestone.sh` | Přiřadí PR milestone (podle názvu) |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh` | Mergne PR |

Každý `gh/` skript potřebuje `-R <owner/repo>` ze sekce `Forge`. Společné kódy `gh/`
skriptů: `2` chybné volání (oprav argumenty, beze změny selže znovu), `7` chybí `gh`
nebo přihlášení — ohlas rovnou.

## Vstupní kontext

- Zadání od volajícího (může být prázdné): $ARGUMENTS

Ze zadání vytěž **základní větev**, **číslo issue**, které PR uzavírá, **milestone**,
**mapu kritérium → test** a **poznámku o bráně** (obojí předává `implement-issue`)
a **výslovný souhlas k mergi** („a mergni", „udělej i merge", „a rovnou zmerguj"). Co
volající předal, nepřebíjej; zbytek doplň postupem níže.

Souhlas k mergi platí, jen když je výslovný a stál v promptu, kterým byl aktuální běh
spuštěn; dispečuje-li tě jiný skill, jen když ho přenesl do zadání. „Otevři PR"
souhlas neznamená.

Uživatele se neptej — jediná otázka patří do eskalace (krok 10).

## Postup

### 1. Načti konfiguraci a zjisti stav

Ze sekce `## Workflow (sagittaras)` v `CONTRIBUTING.md` potřebuješ **Forge** (větev
receptů, `owner/repo`) a **Větvení** (výchozí větev, integrační větev, kdo smí mergovat
do výchozí). Chybí-li soubor nebo sekce, nepokračuj a nabídni `/sagittaras:init-workflow`;
chybí-li podsekce, nedoplňuj ji a eskaluj s jejím názvem.

Spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/forge-detect.sh"`:

| Výsledek | Co uděláš |
| --- | --- |
| kód 2 nebo 3 | eskaluj |
| `forge=unknown` | typ forge ber z konfigurace; chybí-li i `owner`/`repo`, eskaluj |
| `owner/repo` se liší od konfigurace | nehádej, který platí, a eskaluj |

Pak spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh"`; jeho výstup řídí krok 2.

### 2. Urči větev, ze které PR poroste

| Výstup `branch-state.sh` | Co uděláš |
| --- | --- |
| `detached=true` | eskaluj |
| `on_default_branch=false` | `branch=` je head PR — použij ji a novou nezakládej |
| `on_default_branch=true`, `dirty=true` | zavolej `sagittaras:create-branch` s hotovým názvem `<type>/<popis>` odvozeným z rozpracovaných změn (bez něj se zastaví na potvrzení); `checkout_failed` → eskaluj |
| `on_default_branch=true`, `dirty=false` | eskaluj — přesun commitů z výchozí větve skill neumí |
| `on_default_branch=unknown` | eskaluj — remote neodpověděl |

### 3. Urči základní větev

Předal-li ji volající (v milestone běhu integrační větev `milestone/<slug>`), platí jeho
hodnota a výchozí větev si nedomýšlej. Jinak vezmi výchozí větev ze sekce `Větvení`.

### 4. Zapiš a odešli rozdělanou práci

Je-li `dirty=false` a `pushed=true`, `make-commit` přeskoč. Jinak zavolej skill
`sagittaras:make-commit` a push mu nezakazuj. Necommitnul-li (brzda, odmítnutý hook),
eskaluj s příčinou. Pak:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh" --base <base>
```

| Výstup | Co uděláš |
| --- | --- |
| kód 4, nebo `base_source=local` | eskaluj — základ na remotu není |
| `pushed=false` | eskaluj a sám nedopushovávej; zbylé `dirty=true` samo eskalaci neznamená |
| `commits_ahead=0` | nic nezakládej a eskaluj |
| jinak | pokračuj |

### 5. Sestav název a tělo

**Název** je `<type>(<scope>): <popis>`. Uzavírá-li PR právě jedno issue, vezmi jeho
název doslova; jinak ho odvoď ze zapsaných commitů.

**Tělo** piš podle Formátu výstupu; `Closes #N` jen tehdy, když PR issue opravdu
uzavírá. Mapu kritérium → test vlož pod `## Testy kritérií` **doslova** — nezkracuj
řádky, nepřečíslovávej je a nadpis neměň; orchestrátor ji čte skriptem. Poznámku
o bráně dej hned pod mapu. Nepředal-li volající ani jedno, sekci nevkládej.

### 6. Založ PR

Napřed ověř, že z head větve otevřené PR není:

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-branch.sh" -R <owner/repo> <head> --state open`
- **Gitea** → jedním `ToolSearch` načti nástroje z řádku „Pracuje s PR" receptů, pak
  `list_pull_requests` se `state: "open"` a porovnej `head` s head větví.

| Výsledek | Co uděláš |
| --- | --- |
| prázdné pole | založ PR |
| PR se stejnou základní větví | nezakládej druhé — vrať stávající a skonči úspěchem |
| PR s jinou základní větví | eskaluj |

**GitHub** — tělo heredocem s ukončovačem v uvozovkách ve stejném volání, název
v jednoduchých uvozovkách:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-create.sh" -R <owner/repo> \
  --base <base> --head <head> --title '<název>' --body-file - <<'BODY'
<tělo>
BODY
```

Skript vrátí `number=` a `url=`. Kód 2 s `error=empty_body` je rozbitý heredoc —
oprav ukončovač, ne obsah. U 404 ověř oprávnění účtu podle nástrah v receptech;
jiný repozitář nezkoušej.

**Gitea** — `pull_request_write` → `create` s `base`, `head`, `title` a tělem v `body`.

### 7. Přiřaď milestone

Patří-li PR do milestonu, přiřaď ho druhým voláním hned po založení:

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-set-milestone.sh" -R <owner/repo> <n> --milestone '<název milestonu>'`
- **Gitea** → `pull_request_write` → `update` s `pull_number` a **číselným id**
  milestonu z výpisu milestonů.

Selže-li přiřazení, PR neruš; ohlas jeho číslo a eskaluj.

### 8. Merge jen se souhlasem z promptu

Bez výslovného souhlasu krok přeskoč — PR zůstává otevřené. Se souhlasem mergni
strategií ze sekce `Větvení` (squash) se smazáním zdrojové větve:

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R <owner/repo> <n> --squash --delete-branch`
- **Gitea** → `pull_request_write` → `merge` s `pull_number`, `merge_style: "squash"`
  a `delete_branch`.

Souhlas v promptu platí pro jakoukoli základní větev — je to výjimka, kterou řádek
`merge do výchozí větve` v sekci `Větvení` připouští. Nenulový kód merge neobcházej
(žádný force merge ani jiný recept): PR zůstává otevřené a eskaluj.

### 9. Shrň výsledek

Vypiš souhrn podle Formátu výstupu. Merge nenabízej jako svůj další krok.

### 10. Eskalace

Eskaluješ v místech, kde to kroky říkají, a když forge vrátí 404 nebo `gh` skončí
kódem 7. Shrň, co už vzniklo (commit, větev, PR), a polož jednu konkrétní otázku
nástrojem AskUserQuestion. Selže-li volání nebo odpověď nedorazí, nic dalšího
nezakládej a stav jen ohlas.

## Formát výstupu

**Tělo PR** (krok 5) — `Closes` řádek vynech, když PR žádné issue neuzavírá;
sekci `Testy kritérií` a poznámku o bráně vynech, když je volající nepředal:

```markdown
<jedna až tři věty: co PR mění a proč, bez výčtu souborů>

## Testy kritérií

| # | Kritérium | Test |
| --- | --- | --- |
| 1 | <zkrácené znění kritéria> | `cesta/k/testu` — `název testu` |
| 2 | <zkrácené znění kritéria> | ověří člověk |

<poznámka o bráně, předal-li ji volající>

Closes #<n>
```

**Souhrn** (krok 9) — řádek `Merge` má dvě platné podoby:

```
PR #<číslo>: <název> — <url>

| | |
| --- | --- |
| Base | <základní větev> |
| Head | <pracovní větev> |
| Uzavírá | #<n>, nebo „—" |
| Milestone | <název>, nebo „—" |

Commity: <počet, nebo „nic nového k zapsání">
Merge: neprovádí se
```

Obsahoval-li prompt souhlas a merge v kroku 8 prošel, poslední řádek nahraď:

```
Merge: proveden — squash do <základní větev>, zdrojová větev smazána
```

## Zásady

- **Tělo PR nikdy argumentem** — na GitHubu heredocem přes `--body-file -`, na Gitea
  v parametru `body`.
