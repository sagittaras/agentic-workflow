---
name: triage-issue
description: >-
  Povýší jeden Poznámkový issue na Zadání — vyhledá v repozitáři existující
  precedent, který lze rozšířit, a pokud ho najde, přepíše tělo issue do
  tvaru Zadání s hranicemi, kódovým precedentem v Reference a checklistem
  akceptačních kritérií. Nenajde-li precedent, tělo nemění a okomentuje
  issue, že práce potřebuje napřed spárovanou implementační session. Je-li
  issue už Zadání ukotvené v kódu nebo je rozpracované, nic nemění. Výstupem
  je přepsané tělo, komentář s vysvětlením blokace, nebo hlášení, že nebylo
  co dělat.
when_to_use: >-
  Použij, když má issue bez kódem ukotvených akceptačních kritérií
  (Poznámka) přejít do stavu, kdy ho lze naimplementovat — „povyš issue #42
  na Zadání", „je tohle issue připravené k implementaci?", „zkus tomu najít
  vzor v kódu", typicky ručně po `file-issue`. Navržen je i jako krok pro
  budoucí vlnové plánování v `plan-milestone` — to volání zatím není
  propojené, `plan-milestone` dnes zakládá issues v jedné dávce. Nepoužívej
  pro založení nového issue z popisu, na to slouží `file-issue`; pro
  rozepsání tématu na celou sadu issues `plan-milestone`; pro implementaci
  už hotového Zadání `implement-issue`; ani pro nezávislé ověření hotového
  PR proti kritériím, to dělá `verify-issue`.
argument-hint: "[číslo issue]"
# Sloveso `triage` není v tabulce doporučených sloves konvencí; ponecháno
# vědomě — je to ustálené označení pro tenhle typ klasifikace a název fixuje
# interní `.docs/workflow-vision.md` § 3 pluginu.
context: fork
# Izoluje kontext a vlastní konfiguraci (model, effort) při volání z jiného
# skillu — hledání precedentu jinak zaplní kontext volajícího a zdědí jeho
# model i effort místo vlastních. Pracovní strom fork nechrání, protože ho
# tenhle skill nemění vůbec.
model: opus
effort: high
# Zařazení dle matice: posouzení shody s existujícím vzorem vyžaduje úsudek
# (bod 2/3 rozhodovacího stromu), ale rozsah je jeden issue → opus × high,
# stejná třída jako verify-issue/review-milestone/write-adr. Nikoli xhigh:
# skill nepíše kód ani neorchestruje víc fází, jen klasifikuje a přepisuje
# jeden dokument v trackeru.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - ToolSearch
  - "Bash(bash:*)"
  - mcp__gitea__issue_read
  - mcp__gitea__issue_write
disallowed-tools:
  - AskUserQuestion
# disallowed-tools je při uzavřeném allowed-tools redundantní záměrně: zákaz
# doptávání je invariant, který musí platit i tam, kde se allowed-tools
# neuplatní, protože skill běží bez uživatele (viz Zásady).
# Bash je zúžený na spouštění skriptů; gh ani git se nikdy nevolá přímo,
# proto volání piš ve tvaru `bash <cesta>`. Write slouží výhradně
# k dočasnému souboru s přepsaným tělem issue na GitHubu (--body-file);
# Edit ve výčtu není, skill do zdrojů projektu nezapisuje, jen do trackeru.
# Grep/Glob/Read hledají precedent v kódu.
# Vynechaná zvažovaná pole:
# disable-model-invocation — skill má být volatelný modelem i dnes, bez
# ohledu na budoucí propojení s plan-milestone: během konverzace o issue,
# které nemá ukotvená kritéria, nebo když se inženýrský agent chystá issue
# implementovat a zjistí, že na to nemá oporu, je automatické spuštění
# žádoucí;
# agent — profil žádného z dostupných agentů nesedí (skill spouští skripty
# a zapisuje do trackeru, neplánuje ani neopravuje), omezení práv nese
# allowed-tools;
# background — volající (typicky budoucí vlnová smyčka plan-milestone nebo
# člověk čekající na výsledek) potřebuje verdikt hned, běh na pozadí by ho
# oddálil bez důvodu;
# paths — spouští se číslem issue, ne prací nad konkrétními soubory;
# shell — skripty se spouští explicitním `bash`; version/license — verzuje
# se celý plugin, ne jednotlivý skill.
---

# Triage Issue

Cílem je issue, které je buď povýšené na Zadání s kritérii ukotvenými
v existujícím kódu, nebo zůstává Poznámkou s vysvětlením, proč na Zadání
ještě nemá co stavět. Skill sám architekturu nevymýšlí — jen klasifikuje
a přepisuje, a běží bez uživatele: nejasnost nebo chybějící vstup nejsou
důvod k dopytu, ale k hlášení a zastavení. Závazným kontraktem jsou sdílené
soubory pluginu; při rozporu s tímhle postupem platí ony, **s výjimkou
ukotvení Reference popsanou v Zásadách**.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | V kroku 1, když projektová konfigurace chybí nebo v ní nenajdeš sekci, kterou potřebuješ |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | V kroku 1, dřív než sáhneš na tracker — včetně sekce s nástrahami |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | V kroku 1, je-li forge GitHub — než spustíš první `gh/*.sh`, kvůli argumentům a návratovým kódům |
| `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` | V kroku 4, dřív než přepíšeš tělo do tvaru Zadání |

Obsah sdílených souborů si **přečti, ale nepřepisuj do odpovědi**. Šablona
issue se mění na jednom místě; kopie v konverzaci zastará a projekt pak nese
dva různé tvary těla.

## Vstupní kontext

- Vstup (číslo issue): $ARGUMENTS

Vznikne-li v budoucnu vlnová smyčka v `plan-milestone` (dnes ještě
nepropojená), číslo issue z ní přijde v jejím promptu, ne v argumentech —
hledej ho i tam. **Chybí-li číslo úplně, nezastavuj se na dopyt** — skonči
podle Formátu výstupu, varianta „Předčasný konec". Skill nemá od začátku do
konce žádnou interaktivní větev.

## Postup

### 1. Načti konfiguraci a přečti issue celé

Přečti `.claude/workflow.md` v kořeni cílového projektu. Potřebuješ sekce
**Forge** (kterou větev receptů použít a jaké `owner/repo` předat) a
**Jazyk issues** (v jakém jazyce psát přepsané tělo nebo komentář).

- **Soubor neexistuje** → nepokračuj a nedomýšlej si hodnoty. Ohlas to podle
  Formátu výstupu, varianta „Předčasný konec", a nabídni
  `/sagittaras:init-workflow`.
- **Chybí některá z těch sekcí** → řekni která, stejnou variantou; sám ji
  za pochodu nedoplňuj.

Otevři `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md`, vyber sloupec podle
sekce `Forge` a **volání neodvozuj z hlavy**. Na Gitea si napřed **jedním**
voláním `ToolSearch` načti odložené nástroje podle řádku „Jen čte
a komentuje". Řádek nese i `list_issues`/`milestone_read` navíc — tenhle
skill volá jen `issue_read` a `issue_write`, zbytek nepoužívá.

Přečti issue receptem „Přečti issue". Neexistuje-li, je uzavřené, nebo jde
o pull request, ne o issue, ohlas to variantou „Předčasný konec" — přepisovat
nebo komentovat nemáš co.

### 2. Zkontroluj, jestli je issue vůbec na tobě

Issue **nepřepisuj a jdi rovnou na krok 5** (varianta „Nedotčeno"), nastane-li
kterákoli z těchto situací:

1. sekce **Akceptační kritéria** obsahuje konkrétní, vyplněné body **a**
   sekce **Reference** cituje aspoň jednu cestu k souboru nebo vzoru v kódu
   repozitáře (ne jen sekci ADR/UX-spec dokumentu) — issue je Zadání ukotvené
   v kódu už teď;
2. v **Akceptačních kritériích** je aspoň jedno **zaškrtnuté** zaškrtávátko
   (`- [x]`) — issue je rozpracované, `verify-issue` už nad ním pracoval,
   a přepis by smazal jeho ověřovací záznam.

Neplatí-li ani jedna, jde o Poznámku pro účely tohohle skillu (typicky:
kritéria nevyplněná vůbec, nebo vyplněná, ale Reference míří jen na
dokument) — pokračuj krokem 3. Tenhle rozdíl je záměrný: issues z dnešního
`file-issue`/`plan-milestone` mají kritéria ukotvená v próze, a právě tuhle
populaci má `triage-issue` posunout na kódové ukotvení.

### 3. Hledej v repozitáři existující precedent

Ze scope v názvu issue (`<type>(<scope>): …`) a ze Souhrnu vytěž, na jakou
oblast kódu se práce vztahuje. Hledej `Glob`/`Grep`/`Read` existující
soubor, skill, modul nebo vzor, který popsaný požadavek **rozšiřuje**, ne
jen tematicky souvisí.

Test, který rozhoduje: *jde požadavek splnit úpravou nebo rozšířením
tohohle konkrétního souboru/vzoru, aniž by bylo nejdřív nutné vymyslet
architekturu, která v repozitáři ještě neexistuje?* Odpověď ano/ne určuje
větev v kroku 4. Nehledej vzor jen proto, aby se našel — vzdálená podobnost
(„taky se to týká skillů") nestačí, precedent musí být to konkrétní místo,
které issue rozšiřuje.

### 4a. Precedent existuje → přepiš na Zadání

Otevři `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` a piš podle něj,
s výjimkou Reference popsanou v Zásadách:

- **Souhrn** zachovej nebo zpřesni z původní Poznámky beze změny smyslu a
  dopiš do něj **hranice** — co práce podle nalezeného precedentu dělá,
  a je-li to nejednoznačné, i co nedělá.
- **Akceptační kritéria** napiš jako pozorovatelné chování, s prázdnými
  zaškrtávátky. Každé kritérium musí jít ukázat na nalezený precedent — bez
  téhle opory kritérium nepiš, radši issue ponech na kroku 4b.
- **Reference** ukazuje na **konkrétní soubor/vzor v kódu** nalezený
  v kroku 3, ne na sekci ADR nebo UX-spec dokumentu. Odkaz na ADR smíš
  přidat jen jako doplňkové omezení („nesahej na X, viz ADR-N") vedle
  kódové reference, nikdy místo ní.
- **Závisí na** zachovej beze změny, pokud ho původní Poznámka měla
  a jmenovala skutečné číslo issue.
- **Obsah mimo tyhle čtyři sekce zachovej**, typicky připojením na konec
  Souhrnu nebo do vlastní sekce za Referencí. Recept „Uprav tělo issue"
  nahrazuje tělo celé, nic nepřipojuje — reprodukční kroky, útržek logu nebo
  odkaz z původní Poznámky by jinak zápisem tiše zmizel.
- **Název a labely nech beze změny** — tenhle skill přepisuje jen tělo.
  Neodpovídá-li název tvaru `<type>(<scope>): …` nebo typový label typu
  v názvu, zmiň to v souhrnu podle Formátu výstupu jako poznámku pro
  autora; sám ani jedno neopravuj.

Zapiš přepsané tělo receptem „Uprav tělo issue". Na GitHubu tělo zapiš
předtím nástrojem `Write` do dočasného souboru **mimo pracovní strom
repozitáře** a předej ho přes `--body-file` — víceřádkový markdown se
v argumentu shellu rozpadne. Soubor leží mimo strom, takže ho není nutné po
sobě mazat.

Skončí-li zápis chybou, postupuj podle forge: na GitHubu podle
`git-scripts.md` — kód `7` znamená chybějící nebo nepřihlášené `gh`, kód `2`
chybný argument (over hodnoty a zkus znovu jednou), jiný nenulový kód
neopakuj naslepo. Na Gitea reaguj na chybu **404 při zápisu** podle nástrah
v `forge-recipes.md` — skoro vždy jde o chybějící oprávnění účtu, ne
o špatný název; jiný repozitář nezkoušej. V žádném z těchto případů
nepokládej přepis za proběhlý — ohlas to variantou „Zápis selhal". Jdi na
krok 5.

### 4b. Precedent neexistuje → okomentuj a nech Poznámkou

Tělo issue **nepřepisuj**. Okomentuj issue receptem „Okomentuj issue":
pojmenuj krátce, co jsi hledal a nenašel, a řekni, že práce vyžaduje napřed
spárovanou implementační session (rozhraní a neúplná implementace, doladěná
interaktivně) — tenhle skill sám architekturu nezakládá. Issue nezavírej,
název ani labely neměň.

Na GitHubu text komentáře zapiš stejně jako v kroku 4a — nástrojem `Write`
do dočasného souboru mimo pracovní strom a předej ho přes `--body-file`;
`gh/issue-comment.sh` tělo jinak nepřijme.

Skončí-li zápis komentáře chybou, reaguj stejně jako v kroku 4a a nepokládej
komentář za zapsaný. Jdi na krok 5.

### 5. Vypiš výsledek

Podle toho, kterou větví jsi prošel, vypiš výsledek podle Formátu výstupu.

## Formát výstupu

**Nedotčeno (krok 2):**

```
Issue #<n>: nedotčeno — <„už je Zadání ukotvené v kódu" | „je rozpracované, má zaškrtnuté kritérium">.
```

**Povýšeno na Zadání (krok 4a):**

```
Issue #<n>: povýšeno na Zadání.
Precedent: <cesta k souboru/vzoru>
Kritérií: <počet>
Poznámka k názvu/labelům: <„bez rozporu", nebo co neodpovídá>
```

**Zůstává Poznámkou (krok 4b):**

```
Issue #<n>: zůstává Poznámkou, okomentováno.
Chybí precedent pro: <stručně, co jsi hledal>
Doporučení: spárovaná implementační session, pak nové triage.
```

**Zápis selhal (kroky 4a/4b):**

```
Issue #<n>: triage neproběhlo, zápis do trackeru selhal.
Chyba: <kód a výstup skriptu nebo nástroje>
```

**Předčasný konec (Vstupní kontext a krok 1):**

```
Triage neproběhlo: <důvod — chybějící konfigurace/sekce, chybějící číslo, issue neexistuje/je zavřené/je PR>.
```

## Zásady

- **Skill nevymýšlí architekturu.** Nenajde-li precedent, nezakládá
  kritéria narychlo — to je přesně vada, kterou má tenhle skill eliminovat,
  ne reprodukovat.
- **Reference vždy kód, ne próza — i proti obecné šabloně issue.** Obecná
  `issue-template.md` popisuje Reference jako odkaz na sekci dokumentu;
  tenhle skill se od ní vědomě odchyluje, protože kritérium ukotvené jen
  v próze nejde ukázat na nic ověřitelného v kódu. V tomhle jednom bodě
  platí tenhle postup, ne obecná věta o přednosti sdíleného kontraktu výše.
- **Přepisuje jen to, co je opravdu Poznámka** (krok 2), a jen tělo, nikdy
  název ani labely. Stav zaškrtávátek nemění nikdy — `- [ ]` nepřepisuje
  na `- [x]` ani naopak.
- **Běží neinteraktivně vždy.** Nejasnost nebo chybějící vstup znamenají
  hlášení a konec, ne dopyt — skill musí jít volat i bez přítomného člověka.
- **Neuzavírá issue.** To je práce `verify-issue`/`close-milestone`
  po implementaci, ne tady.
- **Sdílený kontrakt má přednost**, mimo výjimku u Reference popsanou výš.
  Odporuje-li tenhle postup šabloně issue jinde, konfiguraci nebo receptům,
  platí ony.
