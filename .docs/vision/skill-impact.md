# Dopad na existující skilly

Mapa slouží jako most mezi principy ([spolupráce](principles.md),
[issues](issues.md) a [tvaru skillů](skill-design.md)) a konkrétní úpravou
jednotlivých `SKILL.md`. Řadí skilly
podle toho, jak moc se mění — od beze změny po nový. Princip, který se do skillů
promítá samostatně a později než ostatní, má vlastní tabulku. Skilly, kterých se
žádný princip netýká, jsou vynechané záměrně, ne přehlédnuté — viz [Mimo
rozsah](#mimo-rozsah).

## Principy 1.1–2.5

| Skill | Stav | Co se mění | Princip |
| --- | --- | --- | --- |
| `init-workflow` | Zásadní změna | Přestává zakládat bespoke `.claude/workflow.md` (viz poznámka pod tabulkou). | 1.2, 1.5 |
| `plan-milestone` | Zásadní změna | Z jednorázového dávkového draftu celého milestonu z ADR/UX-spec prózy na vlnový postup gatovaný dostupností vzoru. Readiness check mění kritérium z „má dokument dost detailu" na „existuje precedent v kódu". Akceptační kritéria se ukotvují v kódu, ne v dokumentu. | 2.1, 2.4 |
| `review-milestone` | Změna kritéria | Kontroluje „je Zadání ukotvené v existujícím precedentu v kódu", ne „je kritérium ukotvené v citované sekci dokumentu". Musí akceptovat nedopsaný, vlnově rostoucí milestone jako platný stav, ne ho hlásit jako chybu. | 2.1, 2.4 |
| `run-milestone` | Zásadní změna | Review dispatch musí dodržet mandát rolí A/B (`qa-engineer`/`verify-issue` jen kritéria, `tech-lead` jen code review dle rules dané cesty). Orchestrace musí počítat s tím, že se milestone za běhu rozšiřuje o nová Zadání z dalších vln, ne jen dispečovat fixní graf issues založený na startu. | 1.4, 1.6, 2.4, 2.5 |
| `implement-issue` | Menší úprava | Sekce Reference v issue teď primárně cituje kód (soubor/vzor), ne dokument — skill se jí má řídit přednostně. | 2.1 |
| `verify-issue` | Zpřísnění mandátu + změna kritéria | Mechanika (mutation test kritérií, neopravuje) zůstává — nově explicitní zákaz čehokoli navíc nad shodu/neshodu s kritérii. Zároveň musí Referenci číst jako precedent v kódu (cesta vůči kořeni repozitáře), ne jako dokument pod kořeny ze Zdrojů pravdy, a porovnávat změnu proti němu; neexistenci cesty potvrzovat až ve worktree PR, protože v milestone běhu bývá precedent jen v integrační větvi. | 2.1, 2.5 |
| `open-pr` | Beze změny | Mechanika PR se principy netýká. | — |
| `file-issue` | Zásadní změna | Dnes vždy cílí na Zadání (sestaví akceptační kritéria hned). Nově vždy zachytává jen Poznámku — žádná rychlá cesta na Zadání, tu přebírá `triage-issue`. Jednodušší skill, žádná duplicitní logika. | 2.2, 2.3 |
| `triage-issue` *(nový)* | Nový skill | Povyšuje Poznámku na Zadání: hledá v kódu existující precedent, buď issue přepíše do tvaru Zadání (hranice, kódový precedent, checklist), nebo nahlásí, že to potřebuje napřed spárovanou session (1.3). Volaný samostatně po `file-issue` i uvnitř `plan-milestone`'s vlnového kroku (2.4) — sdílená mechanika stejně jako `open-pr`, ne duplikovaná logika ve dvou skillech. | 1.3, 2.1, 2.3, 2.5 |
| `close-milestone` | Beze změny | Kontrola uzavřenosti issues a merge PR se principy netýká. | — |
| `write-adr` | Změna interview kritéria | Interview má nově filtrovat na „hrozí, že by tohle někdo bez kontextu 'opravil'?", ne dokumentovat vše, co ADR-konvence umožňují. | 1.5 |
| `train-agent` | Změna spouštěče | Spouští se ne „kdykoli je vstup relevantní k roli agenta" obecně, ale specificky po vyřešené review/retry smyčce, ze záznamu v trackeru. ADR jako vstup je vyloučený. | 1.5, 1.6 |
| `write-rule` | Změna frekvence volání | Mechanika beze změny — nově se ale volá po **každém** založení precedentu (kostra, každá vzorová implementace), ne jen jednou na startu projektu. | 1.2, 1.4 |
| `write-agent` | Beze změny (potvrzeno) | Konvence zákazu odkazů na dokumenty v definici agenta už je v souladu s 1.5 — sloužila mu dokonce jako precedens. | 1.5 |

**`init-workflow` bez bespoke configu.** Tenhle repozitář sám měl ve svém
`.claude/workflow.md` (do přesunu konfigurace do `CONTRIBUTING.md` 16. 11. 2026)
přesně ten příznak, na který tahle úvaha naráží:

```
| oblast | implementuje |
| --- | --- |
| area:skills | — |
```

Vynucená sekce, prázdný pomlčkový placeholder — protože delegace na víc
specializovaných agentů se pro tenhle projekt nehodí. V novém modelu:

- **Žádný zvláštní bespoke soubor.** Mechanika (forge, větvení, merge
  strategie, ověřovací příkazy, area→agent mapa) patří do `CONTRIBUTING.md`
  — konvenční, i lidmi čitelný dokument, ne plugin-specifický formát. Pevné
  sekce si drží jen tam, kde je jiné skilly (`run-milestone`, `verify-issue`)
  opravdu potřebují strojově číst.
- **Zdroje pravdy se neduplikují**, pokud je už nese CLAUDE.md — stejná
  logika jako 1.5 (dvě kopie stejné pravdy driftují).
- **Sekce jako area→agent mapa se interviewují, jen když se projektu
  skutečně hodí** — ne vždy, s prázdnou pomlčkou jako výchozí stav.

**`triage-issue`: proč samostatný skill, ne fáze `plan-milestone`.**
Promotion logika je potřeba na dvou různých místech: ad hoc po `file-issue`
(mimo milestone, kdykoli později) a uvnitř `plan-milestone`'s vlnového kroku
(2.4, pro každou položku backlogu). Kdyby žila jen jako fáze
v `plan-milestone`, Poznámky z `file-issue` by neměly cestu k povýšení jinak
než přes vtažení do milestone-planning session — to odporuje tomu, že
`file-issue` je záměrně mimo milestone. Stejný vzorec plugin už řeší jinde:
`open-pr` je sdílená mechanika volaná z `implement-issue` i `run-milestone`,
ne duplikovaná v obou.

Mandát je stejně přísný jako 2.5: klasifikuje a přepisuje do tvaru Zadání,
architekturu nevymýšlí sám — to zůstává vyhrazené člověku v 1.3. Vedlejší
efekt: díky tomu `file-issue` nepotřebuje žádnou rychlou cestu na Zadání
(viz jeho řádek výš) — zůstává čistě jednoduchý, `triage-issue` je jednotný
další krok, ať se zavolá hned po založení, nebo o týden později.

## Princip 1.7

Navigace stromem indexů ([1.7](principles.md#17-dokumentace-se-dohledává-stromem-indexů-od-claudemd-ne-registrem-cest))
zasahuje dvě skupiny skillů: ty, které dokumenty zakládají, a ty, které je
čtou. První přestávají dokument registrovat a místo toho ho odkazují z indexu;
druzí přestávají číst registr a sestupují stromem.

| Skill | Stav | Co se mění |
| --- | --- | --- |
| `init-workflow` | Menší úprava | Podsekci `Zdroje pravdy` přestává interviewovat i zakládat. V už nastaveném projektu ji při aktualizaci nabídne odstranit, nepřepíše ji tiše. |
| `write-claude-md` | Změna obsahu | Odkaz na vstupní index dokumentace se stává povinnou součástí orientace — místo výčtu jednotlivých dokumentů, s větou, kdy ho otevřít. Konvence práce nesou pravidlo, že znalosti patří do stromu, ne do `CLAUDE.md`, a že nová stránka se odkazuje z nadřazeného indexu ve stejné změně. Strom sám nezakládá — to dělá `write-docs` (1.8). |
| `write-adr` | Změna umístění | Log ADR je sekce stromu: umístění odvodí z indexu, Glob kandidátních složek nanejvýš jako dočasný fallback. Nový ADR odkáže z indexu logu ve stejném PR; zakládaný log odkáže z nadřazeného indexu. Zázemí čte sestupem od `CLAUDE.md`, ne ze Zdrojů pravdy. |
| `review-adr` | Nová kontrola | Zázemí čte sestupem od `CLAUDE.md` místo Zdrojů pravdy. ADR, na který index logu neodkazuje, je nález — dokument, který nikdo nenajde. |
| `write-art-bible` | Změna hledání | Existující dokument o vzhledu hledá nejdřív ve stromu — index ho popíše větou, i když se nejmenuje `art-bible`. Novou art bible odkáže z nadřazeného indexu ve stejné změně. |
| `write-ux-spec` | Změna předání | Umístění specu odvodí z indexu sekce rozhraní. Místo registrace mezi Zdroje pravdy (dnešní navazující krok v předání) odkáže spec z nadřazeného indexu ve stejné změně. |
| `review-ux-spec` | Nová kontrola | Art bible, kterou zadání nepředá, dohledá ve stromu. Spec, na který index neodkazuje, je nález. |
| `plan-milestone`, `implement-issue`, `verify-issue`, `review-milestone` | Menší úprava | Doplňkový dokument citovaný v `Reference` (ADR, UX spec) dohledávají sestupem od `CLAUDE.md`, ne ve Zdrojích pravdy; `review-milestone` tím ztrácí i Glob `.docs/adr/` pro ADR citované bez cesty. Kódový precedent se nemění (2.1). |

**Sdílený kontrakt.** `shared/workflow-config.md` ztrácí podsekci `Zdroje
pravdy` — i její řádek v tabulce „Co která podsekce znamená" a výklad hodnoty
`— viz CLAUDE.md`. `shared/issue-template.md` přestává cesty k dokumentům
v `Reference` vázat na Zdroje pravdy: dokument se cituje cestou vůči kořeni
repozitáře, stejně jako kód.

## Princip 1.8

Znalostní báze jako samostatný artefakt
([1.8](principles.md#18-znalostní-báze-docs-je-graf-stránek-a-plugin-ji-zakládá-a-udržuje-vlastními-skilly))
přidává tři skilly a sdílený kontrakt, a mění skilly, které do báze dnes
píšou po svém.

| Skill | Stav | Co se mění |
| --- | --- | --- |
| `write-docs` *(nový)* | Nový skill | Založí bázi (vstupní index, odkaz z `CLAUDE.md`), přidá nebo upraví stránku či sekci — místo najde sestupem stromem, stránku odkáže z nadřazeného indexu, doplní odkazy na související témata — a přestaví nabobtnalý dokument na strom. Po každé změně spustí skript kontroly struktury. |
| `review-docs` *(nový)* | Nový skill | Nezávislé review s čistým kontextem nad úsudkovou částí: věty u odkazů, duplicita s `CLAUDE.md` a mezi stránkami, umístění tématu v sekci. Mechanickou část nechává skriptu a neopravuje. |
| `read-docs` *(nový)* | Nový skill | Najde v bázi odpověď na otázku postupem čtení ze sdíleného kontraktu, v jednorázovém kontextu na levném modelu; volajícímu vrátí odpověď s citacemi, chráněná rozhodnutí doslova a mezery báze. Kód nečte. |
| `write-claude-md` | Změna rozsahu | Znalost, která do `CLAUDE.md` nepatří, nabídne přesunout do báze přes `write-docs` — dnes ji jen škrtá, nebo eskaluje, protože „co odsunout do vlastní dokumentace" není jeho volba. |
| `write-adr`, `write-art-bible`, `write-ux-spec` | Menší úprava | Umístění a odkázání dokumentu berou ze `shared/docs-tree.md`, ne každý po svém; po zápisu spustí skript kontroly struktury. |
| `implement-issue` | Menší úprava | Zneplatní-li změna zdokumentované chování, upraví stránku báze ve stejném PR. |
| `init-workflow` | Menší úprava | Nabídne zařadit skript kontroly struktury mezi ověřovací příkazy, aby strukturu báze hlídala i brána nad každým PR. |
| `implement-issue`, `plan-milestone`, `write-adr`, `write-ux-spec` | Menší úprava | Bázi čtou skillem `read-docs`: doplňkový dokument z `Reference` jako omezení, ADR a UX spec k citaci, zázemí rozhodnutí, invarianty a stavy obrazovky. Dokument, který potřebují celý (log a existující ADR, art bible, sousední specy), čtou dál přímo. `implement-issue` běžící jako subagent má náhradní postup podle kontraktu. |

**Sdílený kontrakt.** Přibývá `shared/docs-tree.md` — pravidla struktury
z 1.7 na jednom místě, odkud je čtou `write-docs`, `review-docs`
i specializované skilly — a skript kontroly struktury ve `scripts/` (bash,
jako ostatní skripty pluginu): sirotci, indexy bez odkazu na vlastní stránky,
mrtvé odkazy a kotvy, `CLAUDE.md` bez odkazu na vstupní index. Kontrakt nese
i postup čtení (§ Jak najít odpověď v bázi), který stojí na skriptu
`docs-map.sh` — mapě celého stromu s větami u odkazů. Skilly, které samy
běží ve forku (`verify-issue`, `review-milestone`, `review-adr`,
`review-ux-spec`), `read-docs` nevolají: úspora kontextu u nich odpadá, review
ověřuje citace proti zdroji, ne proti odpovědi, a vnoření forku do forku není
zdokumentované. Sestup si zatím parafrázují po svém; na kontrakt odkážou, až se
na ně bude sahat (3.1).

## Principy 2.6–2.9

Lidské review ([2.6](issues.md#26-review-výsledného-kódu-dělá-člověk-ne-agent)),
velikost issue podle přezkoumatelnosti PR
([2.7](issues.md#27-issue-je-velké-nanejvýš-tak-aby-jeho-pr-šlo-přezkoumat-ručně)),
orchestrace přes podřazené session
([2.8](issues.md#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech))
a testy ke kritériím potvrzené orchestrátorem
([2.9](issues.md#29-každé-akceptační-kritérium-kryje-test-session-ho-napíše-orchestrátor-potvrdí)).
Řádky `run-milestone` a `verify-issue` v tabulce 1.1–2.5 stály na mandátu rolí
z 2.5 — kde se s touhle tabulkou rozcházejí, platí tahle.

| Skill | Stav | Co se mění | Princip |
| --- | --- | --- | --- |
| `run-milestone` | Zásadní změna | Odblokovaná issues spouští v podřazených session místo subagentů. Nedispečuje review role ani je nečte: review gate je lidské schválení PR a na schválení, které mu člověk napíše, orchestrátor PR sám mergne do integrační větve — přeposlané schválení by session neuznala (issue #70). Před merge zopakuje integrační bránu; červenou vrací session a opravené PR jde ke schválení znovu. Integrační bránu přesouvá z konce před lidské review: potvrdí, že PR mapuje každé kritérium na test, že ty testy ve změně jsou a že ověřovací příkazy prochází; červenou vrací session signálem a potvrzená kritéria v issue odškrtne. Dávku dimenzuje podle kapacity člověka na review, ne podle počtu agentů. Bez podřazených session spouští subagenty a signál „má připomínky" jim předává pokračováním přes jejich id; obsah připomínek nečte (2.8). | 2.6, 2.8, 2.9 |
| `implement-issue` | Změna konce | Ke každému testovatelnému kritériu napíše nebo rozšíří test — „přečíst v kódu" v kroku 7 přestává pro takové kritérium stačit — a PR bez zelených testů neotevře; mapu kritérium → test předá do těla PR. Běží v podřazené session (bez ní jako subagent, na kterého orchestrátor navazuje) a po otevření PR zůstává k dispozici: připomínky člověka i červenou bránu od orchestrátoru zapracuje ve stejném kontextu. Spuštěný samostatně PR na schválení člověka sám mergne do cílové větve, a pohnula-li se mezitím, zopakuje před tím bránu; v běhu milestonu nemerguje, merge provede orchestrátor, a schválení ve zprávě od jiné session za schválení nebere (issue #70). Spuštěný samostatně, bez orchestrátoru a bez CI, v PR přizná, že bránu spustil jen sám. | 2.6, 2.8, 2.9 |
| `open-pr` | Menší úprava | Tělo PR nese mapu kritérium → test, kterou mu předá `implement-issue`. | 2.9 |
| `verify-issue` | Z brány na nástroj | Přestává být povinná brána před merge; spouští ho člověk nad konkrétním PR, když chce nezávislé ověření kritérií — mutační test je jediná kontrola, jestli test kritérium kryje *dobře*. Mechanika i mandát role A zůstávají. | 2.6, 2.9 |
| `plan-milestone` | Nové kritérium rozpadu | Při návrhu Zadání posuzuje signály příliš velkého issue a rozpadá ho na samostatně mergovatelné kroky; nerozdělí ho na kusy, které samy nic nedělají. Žádný číselný práh (řádky, soubory) — jen signály. Kritéria píše testovatelně; které test pokrýt nejde, označí „ověří člověk". | 2.7, 2.9 |
| `triage-issue` | Nové kritérium | Při povýšení Poznámky hlídá velikost — Poznámku, ze které by vzniklo nereálně velké PR, navrhne rozdělit na víc Zadání. Kritéria píše testovatelně stejně jako `plan-milestone`. | 2.7, 2.9 |
| `review-milestone` | Nová kontrola | Issue se signály příliš velkého PR je nález; stejně tak kritérium, které test pokrýt nejde, a přitom není označené „ověří člověk". | 2.7, 2.9 |
| `train-agent` | Změna vstupu | Vstupem jsou připomínky člověka v PR a jejich zapracování, ne report agentního review. Spouštěč (vyřešená review/retry smyčka) zůstává. | 1.6, 2.6 |
| `init-workflow` | Menší úprava | Podsekce Agenti přestává interviewovat role recenzentů (kvalita kódu, akceptační kritéria); zůstává jen mapa `area:*` → implementující agent. | 2.6 |

**Sdílený kontrakt.** `shared/workflow-config.md` ztrácí v podsekci Agenti
řádky rolí recenzentů a jejich fallback. Strojově čtený řádek „Blokuje merge"
zůstává jen ve výstupu ručně spuštěného `verify-issue`; `run-milestone` se jím
neřídí. `shared/issue-template.md` mění dvě pravidla: kritérium je ve
výchozím stavu testovatelné a netestovatelné nese značku „ověří člověk"; a
zaškrtávátka odškrtává orchestrátor podle potvrzeného testu (ručně spuštěný
`verify-issue` dál podle toho, co sám ověřil), ne výhradně `verify-issue`.

## Princip 2.10

Plán milestonu schvaluje člověk
([2.10](issues.md#210-plán-milestonu-schvaluje-člověk-ne-agentní-review)):
`review-milestone` vypadává z řetězu mezi `plan-milestone` a `run-milestone`
a zůstává nástrojem na vyžádání, stejně jako `verify-issue` po 2.6.

| Skill | Stav | Co se mění |
| --- | --- | --- |
| `run-milestone` | Odebraná kontrola | Nehledá review komentář na nejnižším issue ani po nové vlně; chybějící nebo nepříznivé review přestává být důvod k eskalaci. Poznámku (prázdná kritéria nebo chybějící `Reference`) kontroluje při sestavení grafu u každého otevřeného issue, ne jen u nové vlny. |
| `plan-milestone` | Změna konce | Draft vlny ukazuje i kritéria každého Zadání — je to jediné review plánu. Jako další krok doporučuje `run-milestone`, ne `review-milestone`. |
| `review-milestone` | Z článku řetězu na nástroj | Spouští ho člověk, když chce druhý pohled na plán. Mechanika, okruhy i komentář v trackeru zůstávají; komentář už není doklad pro orchestrátora. |
| `file-issue` | Menší úprava | Poznámka zařazená do milestonu se nevrací verdiktem review, ale eskalací `run-milestone`. |

**Sdílený kontrakt.** `shared/issue-template.md` přestává jmenovat
`review-milestone` jako toho, kdo rozpory v issue hlásí — rozpor mezi názvem
a typovým labelem odnese `implement-issue`, který z labelu odvozuje typ větve
i commitu. Kontrakt „komentář s review reportem" z [původního
plánu](../milestone-workflow/index.md) zaniká.

## Princip 3.1

Štíhlé skilly ([3.1](skill-design.md#31-skill-je-základní-linie-postupu-ne-podnět-k-úvaze-co-jde-příkazem-je-příkaz))
se týkají každého skillu, ale nepromítají se jednorázovým přepisem. Napřed se
mění skilly, které píšou a posuzují instrukce; ostatní se zeštíhlí, když se na
ně sahá z jiného důvodu.

| Skill | Stav | Co se mění |
| --- | --- | --- |
| `write-skill` | Změna konvencí | `skill-conventions.md` § 3 dostane test každé věty, pravidlo „co jde příkazem, je příkaz" a tabulku spouštěčů úvahy; „vysvětlené proč" se zužuje na místa úsudku, jednou větou. Zdůvodnění pro vývojáře patří do komentářů frontmatteru nebo do `.docs/`. Šablona: sekce Zásady nesmí opakovat postup a skill s deterministickými kroky má tabulku skriptů jako `make-commit`. Kontrolní seznam se doplní. |
| `review-skill` | Nová kritéria | Nálezem je krok popsaný prózou, který jde nahradit příkazem; spouštěč úvahy z tabulky 3.1; věta, která neprojde testem; zdůvodnění pro vývojáře v těle místo v komentáři. Stejně přísně jako dnešní kontrola kvality instrukcí. |
| `write-agent`, `review-agent` | Nové kritérium | Test každé věty a spouštěče úvahy platí i pro definici agenta — čte se při každém vyvolání. |
| `write-rule`, `review-rule` | Nové kritérium | Totéž pro rules — čtou se při každém dotyku pokryté cesty, tedy nejčastěji ze všech instrukcí. |
| Ostatní skilly | Zeštíhlení při dotyku | Audit podle testu každé věty, když se skill mění z jiného důvodu. Kroky, které jdou nahradit příkazem, dostanou skript (plugin `scripts/` nebo `scripts/` skillu, výstup `key=value`). Nejdřív nejdelší skilly, kterých se dotknou přepisy podle 1.7, 1.8 a 2.6–2.9: `run-milestone`, `verify-issue`, `write-adr`, `review-milestone`, `open-pr`. Převedeno: stav větve a kontrolu původu drží `scripts/branch-state.sh` (`open-pr`, `implement-issue`), hledání PR z head větve `gh/pr-for-branch.sh` (`open-pr`, `verify-issue`), připomínky k PR a úpravu jeho těla `gh/pr-reviews.sh` a `gh/pr-update.sh` (`implement-issue`), mutační test `scripts/mutation-check.sh` (`verify-issue`) a kontrast barev `write-art-bible/scripts/contrast.sh`. Těla jdou `gh/` skriptům ze stdin (`--body-file -`), takže skilly zakládající issues a komentáře (`file-issue`, `plan-milestone`, `triage-issue`, `review-milestone`, `review-adr`) přišly o `Write`, který měly jen kvůli dočasnému souboru. Po rozboru tokenů běhu M1 ([měření u 3.1](skill-design.md#změřeno-v-provozu)) zeštíhleny skilly, které se načítají do každé implementační session — `implement-issue`, `open-pr`, `make-commit`, `create-branch` — a bránu před review v `run-milestone` drží jedním voláním `gh/pr-gate.sh`. |

## Mimo rozsah

Principy 1.x a 2.x se netýkají `create-branch`, `make-commit` (git mechanika
— principy se netýkají obsahu, jen ho používají) a `update-plugin` (distribuce
pluginu). Tvar jejich textu hlídá jen 3.1, a ty první dva jsou pro něj spíš
vzorem: práci s gitem už celou drží skripty. `write-claude-md`,
`write-art-bible`, `write-ux-spec` a `review-ux-spec` do téhle skupiny patřily
až do 1.7, `write-skill`, `review-skill`, `review-agent` a `review-rule` až do
3.1.
