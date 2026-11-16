# Dopad na existující skilly

Mapa slouží jako most mezi principy ([spolupráce](principles.md)
a [issues](issues.md)) a konkrétní úpravou jednotlivých `SKILL.md`. Řadí skilly
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

**`init-workflow` bez bespoke configu.** Tenhle repozitář sám má ve svém
`.claude/workflow.md` přesně ten příznak, na který tahle úvaha naráží:

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
| `write-claude-md` | Změna obsahu | Odkaz na vstupní index dokumentace se stává povinnou součástí orientace — místo výčtu jednotlivých dokumentů, s větou, kdy ho otevřít. Konvence práce nesou pravidlo, že znalosti patří do stromu, ne do `CLAUDE.md`, a že nová stránka se odkazuje z nadřazeného indexu ve stejné změně. Přirozený kandidát na založení stromu v projektu, který ho nemá (otevřená implikace 1.7). |
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

## Principy 2.6–2.8

Lidské review ([2.6](issues.md#26-review-výsledného-kódu-dělá-člověk-ne-agent)),
velikost issue podle přezkoumatelnosti PR
([2.7](issues.md#27-issue-je-velké-nanejvýš-tak-aby-jeho-pr-šlo-přezkoumat-ručně))
a orchestrace přes podřazené session
([2.8](issues.md#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech)).
Řádky `run-milestone` a `verify-issue` v tabulce 1.1–2.5 stály na mandátu rolí
z 2.5 — kde se s touhle tabulkou rozcházejí, platí tahle.

| Skill | Stav | Co se mění | Princip |
| --- | --- | --- | --- |
| `run-milestone` | Zásadní změna | Odblokovaná issues spouští v podřazených session místo subagentů. Nedispečuje review role ani je nečte a sám nemerguje: review gate je lidské schválení PR, merge do integrační větve provede session na signál člověka a orchestrátor jen sleduje stav PR a odblokovává graf. Dávku dimenzuje podle kapacity člověka na review, ne podle počtu agentů. Integrační brána (mechanické ověření) zůstává. Bez podřazených session spouští subagenty a signály člověka („má připomínky", „schváleno") jim předává pokračováním přes jejich id; obsah připomínek nečte (2.8). | 2.6, 2.8 |
| `implement-issue` | Změna konce | Běží v podřazené session (bez ní jako subagent, na kterého orchestrátor navazuje) a po otevření PR zůstává k dispozici: připomínky člověka si přečte z PR a zapracuje ve stejném kontextu, nepředává je dál. Na signál člověka PR sám mergne do cílové větve — recenzent schvaluje, realizátor merguje. PR neotevře bez zelených ověřovacích příkazů. | 2.6, 2.8 |
| `verify-issue` | Z brány na nástroj | Přestává být povinná brána před merge; spouští ho člověk nad konkrétním PR, když chce nezávislé ověření kritérií. Mechanika i mandát role A zůstávají. | 2.6 |
| `plan-milestone` | Nové kritérium rozpadu | Při návrhu Zadání posuzuje signály příliš velkého issue a rozpadá ho na samostatně mergovatelné kroky; nerozdělí ho na kusy, které samy nic nedělají. Žádný číselný práh (řádky, soubory) — jen signály. | 2.7 |
| `triage-issue` | Nové kritérium | Při povýšení Poznámky hlídá velikost — Poznámku, ze které by vzniklo nereálně velké PR, navrhne rozdělit na víc Zadání. | 2.7 |
| `review-milestone` | Nová kontrola | Issue se signály příliš velkého PR je nález. | 2.7 |
| `train-agent` | Změna vstupu | Vstupem jsou připomínky člověka v PR a jejich zapracování, ne report agentního review. Spouštěč (vyřešená review/retry smyčka) zůstává. | 1.6, 2.6 |
| `init-workflow` | Menší úprava | Podsekce Agenti přestává interviewovat role recenzentů (kvalita kódu, akceptační kritéria); zůstává jen mapa `area:*` → implementující agent. | 2.6 |

**Sdílený kontrakt.** `shared/workflow-config.md` ztrácí v podsekci Agenti
řádky rolí recenzentů a jejich fallback. Strojově čtený řádek „Blokuje merge"
zůstává jen ve výstupu ručně spuštěného `verify-issue`; `run-milestone` se jím
neřídí.

## Mimo rozsah

Záměrně vynechané, protože se jich žádný princip netýká: `create-branch`,
`make-commit` (git mechanika — principy se netýkají obsahu, jen ho používají),
`write-skill`, `review-skill`, `review-agent`, `review-rule` (posuzují nebo
píšou artefakty, jejichž tvar žádný princip nemění; `write-rule`
a `write-agent` jsou v tabulce výš) a `update-plugin` (distribuce pluginu).
`write-claude-md`, `write-art-bible`, `write-ux-spec` a `review-ux-spec` do
téhle skupiny patřily až do 1.7 — strom indexů se jich týká, protože zakládají
nebo čtou dokumenty, ke kterým se má dát dojít.
