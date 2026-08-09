---
name: plan-milestone
description: >-
  Naplánuje milestone a jeho issues a založí je v trackeru — ověří připravenost
  zdrojů pravdy, vyzpovídá rozsah, sepíše issues podle šablony pluginu v pořadí
  závislostí a s kritérii ukotvenými v dokumentaci, a po potvrzení uživatelem
  založí chybějící labely, milestone a issues sekvenčně, aby odkazy na
  závislosti mířily na skutečná čísla.
when_to_use: >-
  Použij, když má z tématu vzniknout rozepsaný milestone — „naplánuj
  milestone", „rozepiš to na issues", „uděláme UI kit, připrav k tomu úkoly" —
  i tehdy, když uživatel popisuje větší práci, kterou je potřeba rozdělit
  a založit v trackeru. Nepoužívej pro jediný ad hoc issue mimo milestone,
  na to slouží file-issue; ani pro posouzení už hotového plánu, to dělá
  review-milestone; ani pro implementaci naplánovaných issues, tu řídí
  run-milestone. Bez projektové konfigurace workflow skill nezakládá nic
  a odkáže na init-workflow.
argument-hint: "[téma milestonu]"
model: opus
effort: high
# Zařazení dle matice: strategie / koncepční návrh → opus × high, bez odchylky.
# Nikoli sonnet: rozsah milestonu a ukotvení kritérií se špatně vrací zpět —
# špatně odhadnutý rozsah se projeví až o dvě fáze dál, při implementaci.
# Nikoli xhigh: skill neběží dlouho autonomně, exekuci vlastní run-milestone;
# těžiště je jeden rozmyšlený návrh se dvěma brzdami u uživatele.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
  - ToolSearch
  - "Bash(bash:*)"
  - mcp__gitea__label_read
  - mcp__gitea__label_write
  - mcp__gitea__milestone_read
  - mcp__gitea__milestone_write
  - mcp__gitea__issue_read
  - mcp__gitea__issue_write
  - mcp__gitea__list_issues
# Bash je zúžený na spouštění skriptů; git ani gh se nikdy nevolá přímo.
# Proto každé volání píš ve tvaru `bash <cesta>` — jinak nespadne do povolení.
# ToolSearch a nástroje mcp__gitea__* jsou tu kvůli Gitea větvi: jsou odložené
# a bez ToolSearch se nenačtou, bez uvedení v tomto výčtu se nezavolají. Názvy
# odpovídají tvaru, který předepisuje forge-recipes.md; běží-li v projektu
# Gitea MCP pod jiným prefixem, zápis do trackeru neproběhne — ohlas to a nech
# uživatele rozhodnout, výčet neobcházej. `issue_read` a `list_issues` postup
# potřebuje jen při dohledávání rozepsaného milestonu po přerušeném běhu;
# ve výčtu jsou proto, že je nese tentýž řádek receptu — je to cena za jediné
# volání ToolSearch místo dvou, a obojí je read-only.
# Write slouží výhradně dočasnému souboru s tělem issue, které GitHub skripty
# berou přes --body-file. Edit chybí záměrně: skill nikdy nedopisuje cizí
# dokumentaci (viz krok 2), a bez Edit to není jen slib v próze.
# Vynechaná zvažovaná pole: disable-model-invocation — skill je užitečný i když
# si ho model vyvolá sám z popisu větší rozdělené práce, a do trackeru nesáhne
# dřív než po potvrzení v kroku 7; context/agent/background — interview
# i potvrzení draftu vyžadují uživatele v hlavním kontextu, fork ani běh
# na pozadí nemají komu klást otázky; paths — spouští se z konverzace nad
# tématem, ne prací nad konkrétními soubory; shell — skripty se spouští
# explicitním `bash`; disallowed-tools — allowed-tools je uzavřený výčet, není
# co zakazovat navíc; version/license — verzuje se celý plugin, ne jednotlivý
# skill.
---

# Plan Milestone

Cílem je milestone, jehož issues jde implementovat bez doptávání: každé kritérium
je pozorovatelné chování ukotvené v konkrétní sekci konkrétního dokumentu a pořadí
issues odpovídá jejich závislostem. Závazným kontraktem jsou sdílené soubory
pluginu — při rozporu s tímhle postupem platí ony.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | V kroku 1, když projektová konfigurace chybí nebo v ní nenajdeš sekci, kterou potřebuješ |
| `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` | V kroku 5, dřív než napíšeš první název a první kritérium |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | V kroku 6, dřív než sáhneš na tracker — včetně sekce s nástrahami |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | V kroku 6 na GitHub projektech, dřív než složíš první volání skriptu: nese povinné argumenty i význam návratových kódů |

Obsah sdílených souborů si **přečti, ale nepřepisuj do odpovědi**. Šablona issue se
mění na jednom místě; kopie v konverzaci zastará a milestone pak nese dva různé tvary.

## Vstupní kontext

- Téma milestonu od uživatele (může být prázdné): $ARGUMENTS

Prázdné zadání znamená, že téma vytěžíš z konverzace. Nemáš-li ani z čeho vytěžit,
zeptej se na téma dřív, než začneš cokoli číst — readiness check bez tématu nemá
co ověřovat.

**Skill je interaktivní.** Selže-li volání AskUserQuestion nebo odpověď nedorazí,
**nezakládej nic**: vypiš draft do konverzace, řekni, na co potřebuješ odpověď,
a skonči. Rozepsaný milestone se z trackeru uklízí ručně, kdežto neodeslaný draft
nestojí nic.

## Postup

### 1. Načti projektovou konfiguraci

Přečti `.claude/sagittaras/workflow.md` v kořeni cílového projektu. Potřebuješ z ní
sekce **Forge** (kterou větev receptů použít), **Labely** (co smíš nasadit),
**Zdroje pravdy** (o co se kritéria opírají) a **Jazyk issues**.

- **Soubor neexistuje** → nepokračuj a nedomýšlej si hodnoty. Řekni uživateli, že
  projekt nemá workflow konfiguraci, a nabídni `/sagittaras:init-workflow`.
- **Chybí sekce, kterou potřebuješ** → řekni která a nabídni doplnění; sám ji
  za pochodu nedoplňuj. Odhadnutá taxonomie labelů rozbije routing v `run-milestone`
  a pozná se to až u review.

### 2. Readiness check

Přečti zdroje pravdy pro plánovanou oblast — skutečné dokumenty z konfigurace, ne
parafráze z konverzace. Pracuješ zatím s **předběžným maximálním rozsahem** odvozeným
z tématu; hranice se vytyčí až v kroku 4. Roztřiď, co v dokumentech chybí, na dvě
hromádky:

- **Blokující mezera** — nerozhodnutá věc, kvůli které nejde napsat ověřitelné
  kritérium pro práci, která má být uvnitř milestonu.
- **Otevřená otázka** — věc, kterou si dokument sám vědomě odkládá na později a na
  které žádné kritérium uvnitř milestonu nestojí. **Ty se neřeší.** Dopisovat cizí
  dokumentaci není práce plánování a rozhodnutí udělané mimochodem při psaní issues
  nikdo nezaznamená.

Hranice mezi hromádkami je závislost, ne důležitost: odložená otázka, o kterou se
opře kritérium ze zvoleného rozsahu, je blokující mezera. Protože rozsah se teprve
vytyčí, **po kroku 4 klasifikaci přehodnoť**: mezera, která se nově stala blokující,
musí projít krokem 3 znovu — rozhodnutí o ní patří pořád uživateli. Mezera, která
zúžením rozsahu blokovat přestala, se přesune mezi otevřené body v souhrnu, ať je
při dalším milestonu vidět.

**Výsledek ohlas uživateli dřív, než začneš cokoli draftovat.** Pro každou mezeru
uveď dokument a sekci, kde chybí, a jaké kritérium se o ni mělo opřít; otevřené
otázky vypiš jedním řádkem každou, ať je vidět, že jsi je nepřehlédl.

### 3. Nech rozhodnout o blokujících mezerách

Mezery **neřeš sám.** Nástrojem AskUserQuestion nech uživatele vybrat, jak dál —
varianty musí vést k různým výsledkům, jinak je volba jen zdánlivá:

- **doplnit dokumentaci teď** — plánování se pozastaví, uživatel rozhodne a skill
  pak čte znovu;
- **naplánovat bez dotčené práce** — dotčené issues v milestonu nevzniknou vůbec
  a mezera se vypíše v souhrnu jako otevřený bod;
- **naplánovat i tak** — issue vznikne s kritériem, které se před implementací musí
  doplnit; to je vědomý dluh, ne kompromis, protože `implement-issue` podspecifikované
  kritérium odmítne a vrátí ho zpátky sem.

Bez blokujících mezer krok přeskoč.

### 4. Interview rozsahu

Nástrojem AskUserQuestion vytyč hranice milestonu: co je uvnitř a co se odkládá.
**Rozsah nedomýšlej** — „jen kostra" a „kostra + první funkce" jsou dva různé plány
a rozdíl mezi nimi je několik issues a týden práce.

U každé varianty uveď **doporučení a vysvětlený kompromis** — co se získá a co se tím
odloží. Varianta bez ceny vypadá jako zadarmo a uživatel pak schválí rozsah, který
odsouhlasit nechtěl.

Ptej se po kolech, dokud neumíš vyjmenovat, co v milestonu je, co v něm není,
a podle čeho se pozná, že je hotový.

### 5. Sepiš draft issues

Otevři `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` a piš přesně podle něj —
tvar názvu, sekce těla i pravidla pro psaní kritérií. Jazyk textu určuje sekce
`Jazyk issues` z konfigurace.

Nad rámec šablony platí:

- **Pořadí je topologické.** Žádné issue nesmí záviset na issue uvedeném později.
  Vzniklý cyklus rozetni tak, že rozdělíš jedno z issues, ne tak, že závislost
  zamlčíš — `run-milestone` z ní staví graf a zamlčená hrana pošle práci na
  rozpracovaný základ.
- **Každé kritérium ukotvi** v konkrétní sekci konkrétního dokumentu a tu sekci uveď
  v `Reference`. Neumíš-li zdroj ukázat, kritérium do issue nepatří — patří do
  readiness checku jako mezera. Věrohodně znějící parafráze bez opory projde všemi
  fázemi až k `verify-issue`, kde stojí čas inženýra i recenzenta.
- **Labely urči rovnou**, podle pravidel v Zásadách níže. Povolené hodnoty bere výčet
  ze sekce `Labely`; label mimo něj nezakládej bez potvrzení v kroku 7.

### 6. Zjisti stav trackeru

Otevři `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md`, vyber sloupec podle sekce
`Forge` z konfigurace a **volání neodvozuj z hlavy**. Na Gitea si jedním voláním
`ToolSearch` načti odložené nástroje podle řádku „Zakládá issues a milestony".
**Sekci s nástrahami přečti hned teď**, ne až před zápisem — část chyb v trackeru
selhává tiše (nepřipnutý label vypadá jako úspěšné volání) a pozná se až u review.

Vypiš **existující labely a existující milestony**. Jsou to čtecí operace, takže
zásada „do trackeru se zapisuje až po potvrzení" platí dál; jenže bez nich neumíš
uživateli v kroku 7 říct, které labely se skutečně budou zakládat, a kolizi názvu
milestonu bys zjistil až po odkývaném draftu.

Na GitHubu skriptům předávej repozitář jako `-R <owner/repo>` ze sekce `Forge`;
tabulka receptů argument neuvádí, ale bez něj skript skončí kódem `2` a `gh` by se
jinak řídilo podle aktuálního adresáře, který v izolovaném worktree ukazuje jinam.
Doslovný tvar volání:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/label-list.sh" -R <owner/repo>
```

Na nenulový kód reaguj dřív, než cokoli vznikne:

- **`7`** — chybí `gh`, nebo není přihlášené. Ohlas to a skonči; uživatel to má vědět
  dřív, než v trackeru leží půlka milestonu.
- **`127`** — skript na disku není. Ohlas, který chybí, a nezakládej nic; rozepsaný
  milestone bez zbytku skriptů se dokončit nedá.
- **`2`** — chybný nebo chybějící argument, nejčastěji vynechané `-R`. Oprav volání
  a zopakuj.

Zbylé kódy vyhledej v `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md`.

**Milestone stejného názvu už existuje** → nezakládej druhý. Zeptej se, jestli navázat
na existující, nebo zvolit jiný název; tichý duplikát se z trackeru uklízí ručně.

### 7. Předlož draft a počkej na potvrzení

Vypiš draft podle Formátu výstupu a **počkej na potvrzení nástrojem AskUserQuestion**.
Tohle je povinná brzda, ne zdvořilost: tabulka názvů a pořadí závislostí se čte půl
minuty a je to jediné místo, kde uživatel zachytí špatně odhadnutý rozsah dřív, než
z něj bude deset issues v trackeru, které někdo musí ručně zavírat.

Zároveň si nech potvrdit labely — jmenovitě ty, které podle kroku 6 v projektu ještě
nejsou a chystáš se je založit, každý s navrženou barvou. Barvu předávej hexem bez
`#`; typové a oblastní drž v odlišných barevných rodinách, ať je routing čitelný na
první pohled.

Připomínky zapracuj a draft předlož znovu. Do kroku 8 jdi až s potvrzeným draftem.

### 8. Založ milestone a issues

Volání skládej stejně jako v kroku 6 — z receptů, na GitHubu vždy s `-R <owner/repo>`.
Zakládej v tomhle pořadí; jiné pořadí vyrobí objekty, na které se další volání nemá
jak odkázat:

1. **Chybějící labely** — bez nich se nasazení labelu na issue tiše mine účinkem.
2. **Milestone** — do popisu napiš, co pro tenhle milestone znamená „hotovo".
   Podle toho `review-milestone` hledá díry a překryvy a `close-milestone` pozná,
   že se smí zavřít. **Jedna až dvě věty na jednom řádku**: popis se předává
   argumentem, takže víceřádkový markdown se v shellu tiše rozbije. Co se do dvou
   vět nevejde, patří do issues.
3. **Issues sekvenčně, ne paralelně.** Tělo každého issue musí v sekci `Závisí na`
   odkazovat na **skutečná čísla** těch, na kterých závisí, a ta vzniknou až
   založením. Paralelní běh vyrobí sadu issues odkazujících na čísla, která si model
   domyslel — a graf závislostí v `run-milestone` z toho složí nesmysl. Každé volání
   nese rovnou `milestone` i `labels`: issue mimo milestone je tichá chyba stejného
   druhu jako nepřipnutý label a hledá se pak napříč celým trackerem.

Tělo issue vypiš do **dočasného souboru mimo pracovní strom repozitáře** a předej ho
podle receptu (`--body-file` u `gh` skriptů, obsah souboru v parametru `body`
u Gitea MCP) — nikdy argumentem, víceřádkový markdown se o uvozovky a zpětné
apostrofy rozbije, a rozbije se tiše. Soubor uvnitř stromu by tam zůstal jako
nesledovaná veteš a nečistý strom shodí `milestone-branch.sh` hned na začátku
`run-milestone`, který na tenhle skill navazuje. **Do dokumentace projektu nezapisuj
nic** — mezery hlásíš, neopravuješ.

Selže-li zápis uprostřed, **nezačínej znovu od začátku**: vypiš, co už vzniklo,
a zeptej se, jak pokračovat. Opakovaný běh nad rozpracovaným milestonem vyrobí
duplikáty. U chyby 404 na zápisu ověř oprávnění účtu podle nástrah v receptech;
jiný repozitář nezkoušej.

### 9. Shrň výsledek

Vypiš souhrnnou tabulku podle Formátu výstupu a jako další krok doporuč
`/sagittaras:review-milestone`. Plán **neposuzuješ sám**: recenzent sdílející kontext
s autorem si odkývá vlastní úvahu, proto review patří někomu, kdo tvůj kontext nevidí.
Sám ho nespouštěj — rozhodnutí patří uživateli.

## Formát výstupu

**Draft k potvrzení** (krok 7) — čísla ve sloupci `#` jsou pořadí v draftu, ne čísla
issues; ta zatím neexistují:

```
Milestone: <název> — hotovo, když <definice hotového>

| # | Název issue | area | Závisí na | Ukotveno v |
| --- | --- | --- | --- | --- |
| 1 | <type>(<scope>): <popis> | area:<oblast> | — | <dokument § sekce> |
| 2 | <type>(<scope>): <popis> | area:<oblast> | #1 | <dokument § sekce> |

Chybějící labely k založení: <název (barva hexem bez #)>, … nebo „žádné"
Vědomě odloženo mimo milestone: <výčet s jednou větou proč>
```

**Souhrn po založení** (krok 9):

```
Milestone: <název> — <odkaz>

| Číslo | Název | Závisí na | Odkaz |
| --- | --- | --- | --- |
| #<n> | <název issue> | #<n>, #<n> | <url> |

Založené labely: <výčet, nebo „žádné">
Otevřené body k doplnění před implementací: <výčet, nebo „žádné">
Další krok: /sagittaras:review-milestone
```

## Zásady

- **Právě jeden `area:*` label na issue, podle kódu, kterého se kritéria dotýkají —
  ne podle tématu milestonu.** Podle tohohle labelu vybírá `run-milestone` inženýra,
  takže chyba pošle práci špatnému specialistovi a projeví se až u review PR.
- **Typový label se musí shodovat s typem v názvu issue.** `implement-issue` z něj
  odvozuje typ větve i commitu; rozpor je nález pro `review-milestone`.
- **Blokující mezery skill neřeší ani nedopisuje.** Pojmenuje je a rozhodnutí nechá
  uživateli; architektonické rozhodnutí udělané mimochodem při psaní issue nikde
  nezůstane a nikdo o něm neví.
- **Do trackeru se zapisuje až po potvrzení draftu.** Před krokem 8 skill jen čte;
  nic nezakládá a nic nemění.
- **Sdílený kontrakt má přednost.** Odporuje-li tenhle postup šabloně issue,
  konfiguraci nebo receptům, platí ony.
