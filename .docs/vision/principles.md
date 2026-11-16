# Principy spolupráce

Principy 1.1–1.7: kde vzniká kotva, podle které agent pracuje (kostra, vzorová
implementace, rules), co ještě zbývá ADR, kdy má smysl zakládat agenta a jak se
v projektu dohledává dokumentace. Kontext, ze kterého vize vychází, a přehled všech
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

**Otevřená implikace** (řeší se až při promítání do skillů, ne tady): projekt,
který strom indexů nemá. Kdo ho založí — přirozeně `write-claude-md`, protože
odkaz na vstupní index patří do `CLAUDE.md` — a jestli smí čtecí skilly do té
doby padat zpátky na dnešní Glob, nebo mají mezeru jen ohlásit.
