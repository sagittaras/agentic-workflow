# Principy spolupráce

Principy 1.1–1.8: kde vzniká kotva, podle které agent pracuje (kostra, vzorová
implementace, rules), co ještě zbývá ADR, kdy má smysl zakládat agenta, jak se
v projektu dohledává dokumentace a proč je znalostní báze `.docs/` samostatný
artefakt s vlastními skilly. Kontext, ze kterého vize vychází, a přehled všech
principů drží [index vize](index.md).

## 1.1 Kostru projektu staví člověk, ne agent

Základní kostru aplikace (adresářová struktura, základní vrstva implementace,
konvence) si má postavit člověk sám — ne ji nechat vygenerovat skillem nebo
agentem podle ADR.

**Why:**
- **Kostra je jinak nejlevnější věc k udělání ručně.** Postavit ji sám zabere
  člověku řádově čtvrt hodiny. Nechat to samostatně udělat agenta trvá
  podobně dlouho (návrh, běh, kontrola výstupu) — u něčeho, co je stejně
  rychlé udělat rukama, se delegace nevyplatí. Delegace dává smysl tam, kde
  agent ušetří čas nebo dohled; u kostry ani jedno neplatí.
- **Vibecoding vs. řízený vývoj.** Pokud jde jen o výsledek bez ohledu na
  vnitřní konstrukci kódu, nechat kostru postavit agentem je v pořádku. Jakmile
  ale záleží na kvalitě a udržitelnosti kódu do budoucna, kostra od agenta je
  nevýhodná — je to přesně to místo, kde se rozhoduje o konvencích, na kterých
  bude stavět všechno další.
- **Ukotvení v ADR neobchází problém, jen ho přesouvá.** Dá se sice napsat
  ADR, které strukturu projektu předepíše, a nechat podle něj agenta kostru
  vyrobit — jenže tím se spustí review proces nad issue, a ten bývá zdlouhavý
  a přísný. I triviální kostra s samotným Hello World se v něm dokáže vracet
  klidně 3× než projde. Cena za to, že kostru nepostavil člověk, se tím
  nezruší, jen se přesune do dražšího a pomalejšího kroku.

**Důsledek pro workflow:** agent se má na projekt napojovat až ve chvíli, kdy
už existuje reálná kostra (adresáře, základní vrstva, aspoň jeden funkční
vertikální řez), ze které si konvence a záměr vypozoruje sám — místo aby se mu
konvence popisovaly textem (ADR) a nechávalo se na něm, aby je z textu správně
domyslel.

## 1.2 Kostra je zdroj pravdy — ne dokument vedle ní

Z 1.1 plyne silnější tvrzení: kostra, kterou postavil člověk, se stává
**základním zdrojem pravdy** pro to, jak se v projektu píše kód — místo textu,
který by konvence popisoval vedle ní.

Typický příklad z .NET: solution se strukturou danou solution foldery
oddělujícími vrstvy, základní projekty, `ConfigurationBuilder`, `DbContext`
s `DesignTimeDbContextFactory` pro migrace, konfigurační principy sjednocené
za jednou extension method, a na API vrstvě pevně dané `Startup`/`Program`
a první „Hello World" `Controller`. Tohle je pevný vzor a šablona, kterou
zkušený vývojář staví z paměti — a je to přesně ta informace, kterou by jinak
musel sepisovat do ADR nebo konvenční příručky, aby ji agent dodržoval.

**Co z toho plyne pro pokračování práce** — kostra se dá strojově zpracovat
dvěma různými směry, měkkým a tvrdým:

- **Měkká kotva: rules.** Z kostry se dají vytěžit `.claude/rules/` (přesně
  k tomu slouží existující `write-rule` — „vytěží konvence z repozitáře").
  Jakmile kostra existuje, konvence v ní (jak vypadá `DbContext`, jak je
  zapojená konfigurace, jak vypadá controller) se dají zapsat jako pravidla,
  která čte každá další session automaticky — místo aby se agentovi konvence
  vysvětlovaly znovu u každého issue. Rules ale zůstávají text: agent je
  dodržuje, protože je četl, ne protože by ho k tomu něco nutilo.
- **Tvrdá kotva: mechanický tooling.** `.editorconfig` (a obdobně
  analyzery/linter/formatter podle stacku) vynucuje style mechanicky — build
  nebo formatter na porušení upozorní nebo ho sám opraví, bez ohledu na to,
  jestli si to agent „pamatuje". Doplňuje rules, ne nahrazuje: rules pokrývají
  to, co linter zkontrolovat neumí (architektura, vrstvení, pojmenování se
  záměrem), tooling pokrývá všechno mechanicky ověřitelné.
  **Zdroj je zase člověk, ne agent:** `.editorconfig` se má vyexportovat
  z IDE, ve kterém má člověk konvence dlouhodobě nastavené — je to stejná
  logika jako 1.1, jen aplikovaná na style config. Agent by konvence do
  `.editorconfig` musel odněkud odhadnout; člověk je má už hotové v nastavení
  editoru.

**Praktické pořadí:** člověk postaví kostru (1.1) a jako její součást
vyexportuje `.editorconfig` z IDE → následuje `write-rule` nad výsledkem
(obecné pravidlo pro kdy spouštět `write-rule` drží 1.4, tady se neopakuje).

Tenhle rozdíl (měkké pravidlo čtené agentem vs. tvrdý kontrakt vynucený
strojem) je stejná osa, na které selhal `write-adr`→`run-milestone` řetěz —
text bez mechanického vynucení nad delším horizontem drift nezastaví. Kostra
sama je nejtvrdší kotva (typy, kompilace); rules a tooling jsou dva odvozené
kroky, které z ní tu tvrdost přenášejí dál do běžné práce na issues.

## 1.3 První klíčová funkcionalita vzniká v páru, ne autonomně

Pro první instanci nové klíčové funkcionality v dané oblasti platí obdoba 1.1
posunutá o úroveň hlouběji — nejde už o strukturu projektu, ale o první
skutečné chování. Člověk napíše rozhraní a neúplnou implementaci (stuby,
vyhozené výjimky, TODO tělo) a s AI ji v jedné session interaktivně doladí,
místo aby zadání dispečoval autonomnímu agentovi.

**Why:**
- **Tvar vstupu.** Rozhraní s neúplnou implementací je přesný střed mezi
  „nic" (prázdná stránka, kde si architekturu vymyslí AI sama) a „všechno"
  (ADR, próza, kterou musí AI zpětně interpretovat). Kód už chování *typuje*,
  aniž by ho úplně předepisoval.
- **Tvar procesu.** Doladění probíhá interaktivně, ve stejné session, ne
  dispečinkem do autonomního běhu. Odchýlení je vidět okamžitě v kódu, ne až
  za týden po autonomním běhu — stejná diagnóza jako v úvodu dokumentu (text
  bez zpětné vazby drift nezastaví), tady řešená zkrácením smyčky na nulu
  místo lepší dokumentace.
- **Tvar výstupu.** Vzniká vzorová implementace — druhá kotva vedle kostry
  (1.1/1.2). Agent má od tohoto bodu v kódu reálný precedens dané oblasti,
  ne jen pravidlo, které jeho záměr jen popisuje.

**Důsledek pro workflow:** autonomní dispečink (`implement-issue` /
`run-milestone`) dává smysl až pro práci, která už má ve své oblasti vzorovou
implementaci, na kterou navazuje. Pro *první* instanci nového vzoru v dané
oblasti je autonomní běh předčasný — přesně tam vznikl drift z týdenního
běhu popsaného v úvodu. I tahle vzorová implementace zakládá precedens →
platí pro ni 1.4.

## 1.4 write-rule běží po každém založení precedentu — obecně, ne principem po principu

Kdykoli kód poprvé založí nový precedens — konvenci, vzor, vrstvu — patří
k tomu spuštění `write-rule` nad tím, co právě vzniklo. Platí to pokaždé, ne
jen jednou na začátku projektu: po počáteční kostře (1.1/1.2), po první
vzorové implementaci klíčové funkcionality (1.3), i po jakémkoli pozdějším
bodě v životě projektu, kde poprvé vznikne nový vzor. Zapsáno tady jednou
obecně, aby se neopakovalo u každého principu, který precedens zakládá.

**Why:** `write-rule` nezakládá konvence, jen přepisuje už rozhodnutý stav
(kód) do formy, kterou čte každá další session automaticky. Spouštěč není
„dosáhli jsme kroku X v cyklu", ale „kód právě založil něco, co se bude dál
napodobovat" — a to se v životě projektu stává opakovaně, ne jen jednou na
startu.

**Důsledek pro workflow:** kdekoli dál v tomhle dokumentu (1.2, 1.3, i
budoucí principy) je krok „→ pak `write-rule`" implicitní součástí, i když
u něj není znovu vypsaný.

## 1.5 ADR zaznamenává proč, ne jak — a jen tam, kde hrozí „oprava" bez kontextu

Jakmile kód nese *jak* (1.1–1.4), ADR má jedinou zbývající, neredundantní
práci: zaznamenat *proč* — rozhodnutí, u kterých padly reálné alternativy
a jejichž zdůvodnění se ze samotného výsledného kódu zpětně nedá vyčíst.

**Kritérium: ne každé rozhodnutí, jen ohrožené.** Nemá smysl mít v ADR
popsaný každý středník v kódu — jen principy, které pro svoje udržení
potřebují kontext. Test: narazí-li na tuhle konstrukci později někdo (nebo
agent) bez kontextu, pokusí se ji věrohodně „opravit" jako zbytečnou
komplikaci? Pokud ano, patří do ADR. Pokud jde o běžnou, levně vratnou,
samovysvětlující volbu, ne.

- **Není podklad:** volba `AwesomeAssertions` jako testovací knihovny —
  obyčejná volba nástroje, nikdo ji nebude „opravovat" a výměna nic nestojí.
- **Je podklad:** vlastní abstrakce postavená z nějakého důvodu nad existující
  knihovnou místo přímého použití. Tohle vypadá jako zbytečná složitost pro
  kohokoli, kdo důvod nezná — a obecné instrukce agentů („nepřidávej
  abstrakce navíc") je aktivně tlačí k tomu takovou vrstvu odstranit. Přesně
  tenhle druh rozhodnutí je potřeba zaznamenat, jinak o něj projekt tiše
  přijde.

**Adresát: reaktivní čtení, ne paměť.** ADR log se čte on-demand, ve chvíli,
kdy se někdo chystá sáhnout na hranici, kterou už někdo vědomě stanovil — ne
jako standing context nahraný dopředu do každé session nebo do paměti agenta.

**Důsledek: `train-agent` nad ADR padá.** Zapsat obsah ADR do trvalé paměti
agenta je stejný text, jen parafrázovaný a přesunutý do druhého souboru —
nepřidá to ukotvení a vzniknou dvě kopie „proč", které se můžou tiše rozejít.
Koliduje to i s tím, co plugin nezávisle rozhodl jinde: `write-agent`
zakazuje definicím agentů odkazovat na konkrétní dokumenty repozitáře, protože
se přejmenovávají a odkaz zůstane mrtvý — zapečení ADR prózy do paměti má
stejnou vadu, jen přesunutou z „mrtvého odkazu" na „zastaralou parafrázi".
(Netýká se `train-agent` jako mechanismu obecně, jen řetězu „ADR →
`train-agent`" konkrétně.)

**Důsledek pro workflow:** ADR log není vyčerpávající dokumentace
architektury — je to registr **chráněných konstrukcí**: věcí označených
právě proto, že by jinak vypadaly jako odstranitelné.

## 1.6 Agent se zakládá pro opakovaně dispečovanou roli; train-agent kryje mezeru po review, ne rutinu

Agent má smysl tam, kde se role bude v projektu opakovaně dispečovat — ne pro
jednorázový úkol. Hodnota nevzniká z jednoho běhu, ale z toho, že přes mnoho
vyvolání (`run-milestone` podle `area:*`, review každého PR) dostane ta samá
role pokaždé stejný nástrojový přístup, model/effort a nastřádanou zkušenost.
Pro jednorázovku stačí obecný subagent.

**Co agent přináší:**
- **Konzistence napříč vyvoláními** — stejný scope nástrojů a stejná úroveň
  modelu pokaždé, bez ohledu na to, která session ho zrovna spouští.
- **Routing** — `area:*` → agent mapa v sekci „Workflow (sagittaras)"
  `CONTRIBUTING.md` (viz [mapa dopadu](skill-impact.md)) funguje jen proto,
  že existuje pojmenovaný,
  stabilní cíl, na který se dá mířit.
- **Nastřádaný úsudek přes paměť** — jiná osa než rules (1.4, konvence kódu)
  nebo ADR (1.5, proč rozhodnutí padlo). Agentova paměť nese, jak se role
  v tomhle projektu osvědčila v praxi.

**Paměť: běžně si ji píše agent sám.** Má-li agent paměť zapnutou, na konci
vlastní session ji typicky dynamicky utváří sám — reflektuje, co se naučil,
bez potřeby zvláštního skillu. Tohle je výchozí, běžný případ.

**Mezera: retry smyčka v review.** Když review najde problém, dispatch, který
opravu dostane, je úzký — „oprav tohle a tady je proč". Scope té session je
opravit konkrétní věc, ne reflektovat obecně. Durable záznam (co bylo špatně,
jak se to opravilo) leží podle sdíleného kontraktu v trackeru jako komentář
k review — to řeší auditovatelnost, ne institucionální paměť agenta pro
příště. Bez dalšího kroku poznatek v paměti agenta nezůstane, i když
v trackeru je, a stejná chyba se může zopakovat u jiného dispatche téhož
agenta.

**Role `train-agent`:** přemostit přesně tuhle mezeru. Po vyřešené
review/retry smyčce vezme záznam z trackeru a zapíše ho jako obecný princip
do paměti odpovědného agenta. Je to syntéza (poznatek z konkrétní opravy
zobecněný pro příště), ne kopie dokumentu — proto se to neváže na diagnózu
z 1.5, která zakázala jen ADR → paměť.

**Důsledek pro workflow:** `train-agent` se nevolá jako rutina po každé
session (to dělá agent sám), ale specificky po review-driven opravě — jako
most mezi durable záznamem v trackeru a trvalou pamětí agenta.

**Po 2.6 a 2.8 (16. 11. 2026):** review dělá člověk a připomínky zapracovává
podřazená session, která kód napsala. Mezera z tohoto principu trvá — session
po skončení poznatek zapomene a do paměti agenta se sám nedostane —, jen
vstupem `train-agent` jsou teď připomínky člověka v PR a jejich zapracování.
Role recenzentů (`tech-lead`, `qa-engineer`) jako důvod pro zakládání agenta
odpadají; routing implementace podle `area:*` zůstává.

## 1.7 Dokumentace se dohledává stromem indexů od CLAUDE.md, ne registrem cest

K projektové dokumentaci vede jediná cesta: `CLAUDE.md` odkazuje na vstupní index
(typicky `.docs/index.md`) a odtud pokračuje strom indexů. Každá sekce je složka
s vlastním `index.md`, který řekne, co sekce pokrývá, a odkáže na všechny její
stránky a podsekce. Stránku, na kterou žádný index neodkazuje, nikdo nenajde —
proto se nová stránka odkazuje z nadřazeného indexu ve stejné změně, ve které
vzniká.

**Why:**
- **Registr je druhá kopie struktury a driftuje.** Podsekce `Zdroje pravdy`
  v `CONTRIBUTING.md` vypisuje cesty k dokumentům odděleně od dokumentů samotných.
  Dokument se přejmenuje, rozdělí nebo přibude, a registr o tom neví, protože ho
  změna, která dokument mění, needituje. Je to stejná vada jako dvě kopie „proč"
  v 1.5 nebo Zdroje pravdy zdvojené s `CLAUDE.md` (`init-workflow` v [mapě
  dopadu](skill-impact.md)). Index leží ve stejné složce jako stránky, které
  popisuje, takže ho změna, která stránku přidává, upraví přirozeně.
- **Hledání podle tvaru je hádání.** Co registr nenese, hledají skilly dnes
  Globem v kandidátních složkách (`.docs/adr/`, `docs/`, `wiki/`) nebo podle
  názvu (`**/art-bible*.md`). Glob najde soubor, ale ne jeho význam: neřekne,
  který z nalezených dokumentů platí a který je nahrazený, a stejný obsah pod
  jiným jménem nenajde vůbec. Index tohle říká větou u každého odkazu.
- **Index dávkuje kontext.** Agent nečte dokumentaci dopředu celou — to by byl
  standing context, proti kterému stojí 1.5. Sestoupí jen do větve, které se jeho
  práce týká, a stránku otevře, až ji potřebuje. Reaktivní čtení ADR z 1.5 tím
  dostává mechanismus: na chráněné rozhodnutí narazí ten, kdo sestupuje do
  oblasti, které se týká, aniž by o něm musel vědět předem.
- **Jedna navigace pro člověka i agenta.** Strom indexů je obyčejný markdown,
  čitelný v IDE i na forge, bez formátu specifického pro plugin — stejný argument
  jako u `CONTRIBUTING.md` místo bespoke `.claude/workflow.md`.

**Ověřeno v praxi:** `sagittaras/spellborn`. `CLAUDE.md` (~100 řádků) nese
orientaci a invarianty a u invariantu, který potřebuje podrobnosti, odkazuje na
jeho stránku; všechno ostatní leží v `.docs/` ve stromu indexů po oblastech,
desítky stránek. `CONTRIBUTING.md` má ve Zdrojích pravdy jen `— viz CLAUDE.md`.
Dokumentace se mění ve stejném commitu jako kód, jehož chování popisuje, takže
index nezastarává — nikdo ho neudržuje zvlášť.

**Pravidla struktury** — minimum, které strom musí splnit, aby po něm šlo
navigovat:
- `CLAUDE.md` odkazuje na vstupní index a říká, kdy ho otevřít.
- Sekce = složka s `index.md`; podsekce stejně, do libovolné hloubky.
- Každý index odkazuje na všechny své přímé stránky a podsekce a u každého
  odkazu jednou větou řekne, co tam je.
- Nová stránka nebo sekce se odkazuje z nadřazeného indexu ve stejné změně, ve
  které vzniká. Změna, která zneplatní zdokumentované chování, upraví
  i dokumentaci.
- Stránky na sebe odkazují relativními markdown odkazy, na konkrétní místo
  s kotvou.

Dokumentace tohohle pluginu je postavená stejně — začíná ve [vstupním
indexu](../index.md).

**Co se nemění:**
- **1.2 platí dál.** *Jak* nese kód; dokumentace nese, co z kódu vyčíst nejde —
  záměr, cílový návrh, chráněná rozhodnutí. 1.7 neříká, co do dokumentace patří,
  jen jak se v ní hledá.
- **Rules z 1.4 index nenahrazuje.** Rule se do kontextu vkládá sama podle cesty
  souboru, dokumentace se čte na vyžádání; strom indexů řeší jen to druhé.
- **`Reference` v issue cituje primárně kód (2.1).** Dokument v ní jen doplňuje
  a jeho cestu agent dohledá sestupem stromem, ne v registru.
- **Zákaz odkazů na konkrétní dokumenty v definici agenta (`write-agent`) drží.**
  Agent má `CLAUDE.md` v kontextu a stromem sestoupí sám; pevná cesta v definici
  by byla jen další registr, který se se stromem rozejde.

**Důsledek pro workflow:** podsekce `Zdroje pravdy` přestává být potřeba. Vstupní
index odkazuje `CLAUDE.md`, který čte každá session, takže ukazatel
v `CONTRIBUTING.md` by byl jen další kopie téhož. Skilly, které dokumenty čtou,
je dohledávají sestupem od `CLAUDE.md`; skilly, které dokumenty zakládají,
odvodí umístění z indexu a nový dokument odkážou z nadřazeného indexu ve stejném
PR, místo aby ho registrovaly. Dopad po jednotlivých skillech drží [mapa
dopadu](skill-impact.md#princip-17).

**Projekt, který strom indexů nemá.** Kdo ho založí, řeší
[1.8](#18-znalostní-báze-docs-je-graf-stránek-a-plugin-ji-zakládá-a-udržuje-vlastními-skilly):
`write-docs`, ne `write-claude-md` — ten na vstupní index jen odkazuje. Čtecí
skilly v projektu bez báze mezeru ohlásí s odkazem na `write-docs`; jestli do té
doby smí padat zpátky na dnešní Glob, zůstává otázkou promítání do skillů.

## 1.8 Znalostní báze `.docs/` je graf stránek a plugin ji zakládá a udržuje vlastními skilly

Znalosti o projektu, které nejdou vyčíst z kódu, žijí v `.docs/` jako graf
stránek. Strom indexů z 1.7 je jeho páteř — každá stránka je dosažitelná od
`CLAUDE.md` —, odkazy mezi souvisejícími tématy jsou jeho hrany. Báze není
vedlejší produkt jiných skillů, ale samostatný artefakt pluginu, stejně jako
`CLAUDE.md`, rules nebo agenti: má vlastní skilly, které ji zakládají,
rozšiřují a hlídají.

**Why:**
- **Navigace vede ke čtení, ne k hledání.** Agent, který potřebuje něco vědět,
  sestoupí od `CLAUDE.md` přes index do sekce a odtud po odkazech na související
  stránky — a každý odkaz mu větou řekne, jestli tam jeho odpověď je. Nemusí
  grepovat ani procházet stohy textu. Grep najde řetězec, ne odpověď: trefí se do
  nesouvisejících stránek, mine synonyma, a jestli je nález relevantní, pozná
  agent teprve otevřením celého souboru. Každé takové otevření stojí kontext
  a u dlouhé práce se to sčítá.
- **Stejná navigace slouží člověku.** Wiki-style báze dává i člověku rozumný
  pohyb mezi tématy, aniž by musel vědět, ve kterém souboru co je. Jedna
  struktura pro oba čtenáře znamená, že ji oba drží při životě: člověk si
  všimne mrtvého odkazu, agent ho opraví ve stejné změně.
- **Bez vlastních skillů báze degraduje.** Dnes do `.docs/` píšou jen
  specializované skilly (`write-adr`, `write-art-bible`, `write-ux-spec`) a každý
  si umístění hledá po svém (1.7). Obecná znalost — popis oblasti, cílový návrh,
  pravidla vrstvy — skill nemá vůbec, takže vzniká ad hoc, bez indexu a bez
  odkazů, a strom se rozpadá na sirotky. Je to stejný problém, jaký plugin
  vyřešil pro `CLAUDE.md` (`write-claude-md`) a pro agenty (`write-agent`): bez
  ustanoveného postupu vzniká pokaždé jiný tvar.

**Ověřeno v praxi:** `sagittaras/spellborn`, kde báze roste s každým
commitem, který mění popsané chování, a dokumentace tohohle pluginu po
přestavbě na strom ([vstupní index](../index.md)).

**Pravidla struktury hlídá skript, ne úsudek.** Sirotek, index, který
neodkazuje na svou stránku, mrtvý odkaz nebo kotva, `CLAUDE.md` bez odkazu na
vstup — to všechno jde ověřit mechanicky, stejně jako testy v 2.9. Skilly báze
skript spouští po každé změně a projekt ho může zařadit mezi ověřovací příkazy,
takže strukturu hlídá i brána nad každým PR. Úsudek zbývá na to, co skript
neumí: jestli věta u odkazu říká, co na stránce je, jestli stránka nedubluje
`CLAUDE.md` nebo jinou stránku, a jestli téma leží ve správné sekci.

**Skilly báze:**
- **`write-docs`** — založí bázi v projektu, který ji nemá (vstupní index,
  odkaz z `CLAUDE.md`); přidá nebo upraví stránku či sekci — místo najde
  sestupem stromem, stránku odkáže z nadřazeného indexu a doplní odkazy na
  související témata; a přestaví nabobtnalý dokument na strom, jako se to stalo
  s vizí tohohle pluginu.
- **`review-docs`** — nezávislé review s čistým kontextem nad úsudkovou částí;
  mechanickou část nechává skriptu. Stejný tok jako u `write-skill`
  a `write-agent`: interview → návrh → zápis → review subagentem.
- **Sdílený kontrakt `shared/docs-tree.md`** s pravidly struktury na jednom
  místě a **skript kontroly struktury** ve `scripts/`. Čtou a spouští je
  i specializované skilly, když dokument zakládají — umístění a odkázání tak
  přestává být mechanika, kterou si každý řeší po svém. Kontrakt nese i postup
  čtení: kdy sestup skončí, kdy jít po odkazu dál a co dělat, když báze
  odpověď nemá. Bez něj by sestup říkal jen kudy jít, ne kdy přestat, a čtenář
  by buď četl do šířky pro jistotu, nebo se vrátil ke grepu. Indexy po jednom
  neotevírá: skript `docs-map.sh` vypíše celý strom s větami u odkazů jedním
  voláním. Mapa je obsah báze, ne její text — stránky se dál otevírají až
  podle potřeby, takže dávkování kontextu z 1.7 platí.
- **`read-docs`** — tentýž postup čtení v jednorázovém kontextu (fork na
  levném modelu). Volajícímu vrátí odpověď s citacemi `cesta#kotva`
  a chráněná rozhodnutí doslova; mapu, výběr i zamítnuté stránky zaplatí fork.
  Doslovná citace místo shrnutí je pojistka proti parafrázi, před kterou
  varuje 1.5.

Výchozí umístění je `.docs/`. Projekt, který už má vlastní dokumentační
složku, si ji ponechá — pravidla struktury platí stejně.

**Co se nemění:** 1.2 (*jak* nese kód, báze nese, co z kódu vyčíst nejde),
1.4 (rules se vkládají samy podle cesty, báze se čte na vyžádání) a 1.5 (ADR
log je jedna ze sekcí báze, ne její náhrada).

**Důsledek pro workflow:** změna kódu, která zneplatní zdokumentované
chování, upraví stránku ve stejném PR — `implement-issue` to dělá jako součást
práce, ne jako další issue. Specializované skilly zůstávají, jen mechaniku
umístění a odkázání berou ze sdíleného kontraktu. Dopad po skillech drží
[mapa dopadu](skill-impact.md#princip-18).
