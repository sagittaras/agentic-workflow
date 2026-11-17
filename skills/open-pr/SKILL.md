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
# Hranicí je tady podmínka výslovného souhlasu v Zásadách, ne zúžení práv;
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

Cílem je pull request otevřený proti správné základní větvi, s názvem a tělem,
ze kterých je poznat, co se mění a co se tím zavírá. Git mechaniku skill sám
nepíše — commit a push deleguje na `sagittaras:make-commit`, zakládání větve na
`sagittaras:create-branch`. Závazným kontraktem jsou sdílené soubory pluginu;
při rozporu s tímhle postupem platí ony.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | V kroku 1, když projektová konfigurace chybí nebo v ní nenajdeš sekci `Forge` či `Větvení` |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | Když skript skončí kódem, který postup níže nemapuje |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | Na Gitea v kroku 6, dřív než sáhneš na tracker — včetně sekce s nástrahami |

Obsah sdílených souborů si **přečti, ale nepřepisuj do odpovědi**. Recepty se
mění na jednom místě; kopie v konverzaci zastará a další běh podle ní založí PR
jinak.

## Skripty

Stav repozitáře i operace nad GitHubem jdou přes skripty pluginu, volané vždy
tvarem `bash "<cesta>"`. Příkaz `git` ani `gh` nevolej přímo.

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/scripts/forge-detect.sh` | Forge, `owner`/`repo` a výchozí větev z remotu |
| `${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh` | Stav větve: výchozí/odpojená, nezapsané změny, upstream; s `--base` i commity navíc proti základu |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-branch.sh` | Existující PR z head větve |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-create.sh` | Založí PR; tělo čte ze stdin přes `--body-file -` |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-set-milestone.sh` | Přiřadí PR milestone (podle názvu) |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh` | Mergne PR |

**Každý `gh/` skript potřebuje `-R <owner/repo>`** ze sekce `Forge` konfigurace.
Bez něj skončí kódem `2`; aktuální adresář v izolovaném worktree `run-milestone`
nemusí ukazovat na správný repozitář. Společné kódy `gh/` skriptů: `2` chybné
volání (oprav argumenty, opakování beze změny selže znovu), `7` chybí `gh` nebo
přihlášení — ohlas rovnou.

## Vstupní kontext

- Zadání od volajícího (může být prázdné): $ARGUMENTS

Ze zadání vytěž, co v něm je: **základní větev**, **číslo issue**, které PR
uzavírá, **milestone**, do kterého PR patří, **mapu kritérium → test**
a **poznámku o bráně** (obojí předává `implement-issue`) a **výslovný souhlas k mergi**
(fráze jako „a mergni", „udělej i merge", „vytvoř PR a slej to", „a rovnou
zmerguj"). Co v zadání není, doplň postupem níže — ale nikdy nepřebíjej to,
co volající předal.

**Souhlas k mergi musí být explicitní a musí pocházet z promptu, kterým byl
aktuální běh spuštěn** — dispečuje-li tě `run-milestone` nebo `implement-issue`,
souhlas hledej v zadání, které ti předaly ony (musí ho samy přenést z původního
promptu uživatele, jinak ho nemáš odkud vzít). Domněnka z kontextu konverzace
nestačí: „otevři PR" bez dalšího slova souhlas k mergi neznamená.

**Skill běží často neinteraktivně**, spuštěný na konci jiné úlohy. Celý postup
je proto napsaný tak, že se uživatele neptá — jediné místo, kde k němu míří
otázka, je Eskalace v kroku 10.

## Postup

### 1. Načti konfiguraci a zjisti stav

Přečti sekci `## Workflow (sagittaras)` v `CONTRIBUTING.md` v kořeni cílového
projektu. Potřebuješ podsekci **Forge** (kterou větev receptů použít a jaké
`owner/repo` předat) a **Větvení** (výchozí větev, tvar integrační větve,
a že do výchozí větve mergeuje jen člověk).

- **`CONTRIBUTING.md` neexistuje nebo sekci nemá** → nepokračuj a nedomýšlej si
  hodnoty. Řekni to a nabídni `/sagittaras:init-workflow`.
- **Chybí podsekce, kterou potřebuješ** → řekni která a nabídni doplnění; sám ji
  za pochodu nedoplňuj.

Pak spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/forge-detect.sh"`:

- **kód 2** (`not_a_git_repository`) → ohlas a skonči.
- **kód 3** (remote chybí nebo z něj nejde odvodit `owner/repo`) → ohlas
  a skonči; PR je operace nad remotem.
- **`forge=unknown`** → typ forge ber ze sekce `Forge` konfigurace. Chybí-li ale
  i `owner`/`repo`, zastav se.
- **`owner/repo` se liší od konfigurace** → **nehádej, který je správný**,
  a ohlas rozpor: běžíš nad jiným repozitářem, než pro který konfigurace platí.

Nakonec spusť `bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh"`. Jeho výstup
řídí krok 2 a začátek kroku 4.

### 2. Urči větev, ze které PR poroste

Volající obvykle už na své větvi stojí. **Pak ji použij a novou nezakládej** —
její commity by na nové větvi nebyly a PR by vzniklo prázdné.

| Výstup `branch-state.sh` | Co uděláš |
| --- | --- |
| `detached=true` | Zastav se a ohlas to — commit i větev by se ztratily při prvním přepnutí. |
| `on_default_branch=false` | `branch=` je head PR, jdi dál. |
| `on_default_branch=true`, `dirty=true` | Zavolej `sagittaras:create-branch` (změny přeberou s sebou) a pokračuj na nové větvi. **Předej mu hotový název** `<type>/<popis>` odvozený z rozpracovaných změn, jinak si ho nechá potvrdit uživatelem a v autonomním běhu se zastaví. Skončí-li s `checkout_failed`, ohlas to a nepokračuj. |
| `on_default_branch=true`, `dirty=false` | Zastav se a ohlas to. Přesun hotových commitů z výchozí větve je zásah do historie, který skill záměrně neumí. |
| `on_default_branch=unknown` | Remote neodpověděl na dotaz po výchozí větvi; ohlas to a skonči — bez remotu PR nevznikne. |

### 3. Urči základní větev

Základ PR je větev, **ze které se práce vyvíjela**:

- **Předal-li ji volající** (typicky integrační větev `milestone/<slug>`
  v milestone běhu), platí jeho hodnota. Výchozí větev z konfigurace si v tom
  případě **nedomýšlej** — PR mířící mimo integrační větev obejde integrační
  bránu `run-milestone` a zamíří rovnou do výchozí větve.
- **Jinak** vezmi výchozí větev ze sekce `Větvení`.

### 4. Zapiš a odešli rozdělanou práci

Je-li `dirty=false` a `pushed=true` z kroku 1, zavolání `make-commit`
přeskoč. Jinak zavolej nástrojem `Skill` skill `sagittaras:make-commit`.
**Vlastní commit logiku nepiš** a **push mu nezakazuj** — pushuje po každém
commitu a větev bez upstreamu sám publikuje; nad nepushnutou větví PR založit
nejde. Ohlásí-li, že **necommitnul** (brzda, odmítnutý hook), zastav se
a ohlas příčinu.

Pak ověř stav proti základu:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh" --base <base>
```

| Výstup | Co uděláš |
| --- | --- |
| kód 4 (`base_source=missing`) | Základ neexistuje ani lokálně; eskaluj. |
| `base_source=local` | Základ na remotu není, PR proti němu nejde založit; eskaluj. |
| `pushed=false` | Větev zůstala nepublikovaná. Eskaluj a **sám nedopushovávej** — publikace je výchozí chování `make-commit`, takže tu je překážka, kterou ohlásil. Zbylé `dirty=true` samo eskalaci neznamená: změny, které s prací nesouvisejí, `make-commit` vynechává záměrně. |
| `commits_ahead=0` | Nezakládej nic a ohlas to — prázdné PR nemá co recenzovat. |
| jinak | Pokračuj. |

### 5. Sestav název a tělo

**Název** je Conventional Commit odpovídající odvedené práci, ve stejném tvaru
jako názvy issues: `<type>(<scope>): <popis>`. Uzavírá-li PR právě jedno issue,
**vezmi jeho název doslova** — tracker pak ukazuje tentýž řetězec dvakrát a nic
se nerozchází. Jinak ho odvoď ze zapsaných commitů, ne ze zadání.

**Tělo** piš podle Formátu výstupu: krátké shrnutí a `Closes #N`, jen když PR
opravdu nějaké issue uzavírá.

Předal-li volající **mapu kritérium → test**, vlož ji pod nadpis
`## Testy kritérií` **doslova** — nezkracuj řádky, nepřečíslovávej je a nadpis
neměň. Orchestrátor ji čte skriptem podle nadpisu a čísel v prvním sloupci;
upravená mapa neprojde jeho branou, i když je obsahově stejná. Předal-li
**poznámku o bráně**, dej ji hned pod mapu. Nepředal-li ani jedno, sekci
nevkládej a nevymýšlej ji.

> `Closes #N` zabírá na obou forge až při merge do **výchozí** větve. V milestone
> běhu, kde PR míří do integrační větve, se tím issue nezavře; odkaz tam má
> smysl jako vazba, zavření vlastní `run-milestone` a `close-milestone`.

### 6. Založ PR

**Nejdřív ověř, že z head větve už otevřené PR není:**

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-branch.sh" -R <owner/repo> <head> --state open`
- **Gitea** → jedním voláním `ToolSearch` načti nástroje podle řádku „Pracuje
  s PR" v receptech, pak `list_pull_requests` se `state: "open"` a porovnej
  `head` v odpovědi s head větví.

| Výsledek | Co uděláš |
| --- | --- |
| prázdné pole | Založ PR. |
| PR se stejnou základní větví (`baseRefName`) | **Nezakládej druhé** — vrať stávající a skonči úspěchem. Opakované spuštění po přerušeném běhu je normální stav. |
| PR s jinou základní větví | Rozpor, který sám nerozsoudíš: eskaluj. |

**GitHub** — tělo předej heredocem s ukončovačem v uvozovkách ve stejném volání,
název v jednoduchých uvozovkách:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-create.sh" -R <owner/repo> \
  --base <base> --head <head> --title '<název>' --body-file - <<'BODY'
<tělo>
BODY
```

Skript vrátí `number=` a `url=`. Kód `2` s `error=empty_body` znamená rozbitý
heredoc — oprav ukončovač, ne obsah. U chyby 404 ověř oprávnění účtu podle
nástrah v receptech; jiný repozitář nezkoušej.

**Gitea** — `pull_request_write` → `create` s `base`, `head`, `title` a obsahem
těla přímo v parametru `body`; shell v cestě není.

### 7. Přiřaď milestone

Patří-li PR do milestonu, přiřaď mu ho **druhým voláním** hned po založení —
při zakládání to nejde ani na jedné forge a `close-milestone` podle téhle vazby
integrační PR dohledává.

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-set-milestone.sh" -R <owner/repo> <n> --milestone '<název milestonu>'`
- **Gitea** → `pull_request_write` → `update` s `pull_number` a **číselným id**
  milestonu (napřed ho dohledej ve výpisu milestonů, název nestačí).

Selže-li přiřazení, **PR nerušit** — už existuje a je platné. Ohlas jeho číslo
spolu s tím, že milestone přiřazený není, a eskaluj; `close-milestone` by jinak
milestone nezavřel.

Nepatří-li PR do milestonu, krok přeskoč.

### 8. Proveď merge, obsahoval-li prompt výslovný souhlas

Nenašel-li krok „Vstupní kontext" v promptu, kterým byl aktuální běh spuštěn,
výslovný souhlas k mergi, **krok přeskoč** — PR zůstává otevřené.

Souhlas našel → mergni strategií ze sekce `Větvení` (squash) a se smazáním
zdrojové větve:

- **GitHub** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R <owner/repo> <n> --squash --delete-branch`
- **Gitea** → `pull_request_write` → `merge` s `pull_number`,
  `merge_style: "squash"` a `delete_branch`.

Mergovat smíš **do jakékoli základní větve** — souhlas v promptu je přesně ta
výjimka, kterou řádek `merge do výchozí větve: jen člověk` v sekci `Větvení`
připouští. Integrační bránu `run-milestone` to nemění: ta svůj merge do
integrační větve provádí sama, tenhle krok se týká jen PR, které zakládáš ty.

Nenulový kód merge (konflikt, nesplněná ochrana větve) **neobcházej** — PR
zůstává otevřené, ohlas to v souhrnu a eskaluj podle kroku 10. Nezkoušej force
merge ani jiný recept.

### 9. Shrň výsledek

Vypiš souhrn podle Formátu výstupu: číslo a odkaz PR, base a head větev, co
uzavírá, přiřazený milestone, výsledek merge (proveden, nebo „neprovádí se")
a co jsi cestou přeskočil nebo delegoval. **Merge nenabízej jako svůj další
krok** — bez souhlasu v promptu se tady skill zastavuje.

### 10. Eskalace

Přeruš postup a ohlas stav, nastane-li kterákoli z těchto situací:

- chybí projektová konfigurace nebo v ní chybí sekce `Forge` či `Větvení`;
- `forge-detect.sh` skončí kódem `2` nebo `3`, nebo nezná `owner`/`repo`;
- `owner/repo` z detekce se liší od konfigurace;
- stojíš na výchozí větvi se vším zapsaným, na odpojené HEAD, nebo remote
  neodpověděl (`on_default_branch=unknown`);
- `create-branch` větev nezaložil (`checkout_failed`);
- `make-commit` necommitnul, nebo větev zůstala nepublikovaná;
- základní větev na remotu není (`base_source=local` nebo kód 4);
- head větev nemá ani po kroku 4 proti základní žádný commit navíc;
- z téhle head větve už existuje otevřené PR proti **jiné** základní větvi
  (shodné PR není důvod k eskalaci — vrať ho a skonči);
- PR vzniklo, ale přiřazení milestonu selhalo;
- prompt obsahoval souhlas k mergi, ale merge v kroku 8 selhal;
- forge vrátí 404 nebo `gh` chybí či není přihlášené (kód `7`).

Eskalace vždy shrne, co už vzniklo (commit, větev, PR), a položí **jednu
konkrétní otázku** nástrojem AskUserQuestion. Selže-li volání nebo odpověď
nedorazí, je uživatel mimo hru: nezakládej nic dalšího a stav jen ohlas —
nezaložený PR se doplní jedním během, kdežto zbloudilý PR proti výchozí větvi
uklízí někdo ručně.

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

- **Skill mergne jen na výslovný souhlas v promptu, jinak nikdy.** Bez něj je
  výstupem jen otevřené PR.
- **Základní větev se nedomýšlí.** Co předal volající, platí; výchozí větev
  z konfigurace je až fallback.
- **Git mechanika se deleguje bez výjimky.** Commit, push i publikace větve přes
  `sagittaras:make-commit`, větev přes `sagittaras:create-branch`. Napsat je
  potřetí znamená tři různá chování téže operace.
- **Tělo PR nikdy argumentem.** Na GitHubu heredocem přes `--body-file -`, na
  Gitea obsahem parametru `body`.
- **Sdílený kontrakt má přednost.** Odporuje-li tenhle postup receptům,
  konfiguraci nebo kontraktu skriptů, platí ony.
