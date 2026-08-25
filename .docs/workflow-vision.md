# Vize: jak má člověk pracovat s AI okolo tohoto pluginu

> **Stav:** rozepsáno, píše se průběžně po principech — 24. 8. 2026.
> **Kontext:** po týdnu ostrého provozu řetězu `write-adr → plan-milestone →
> review-milestone → run-milestone` (popsaného v
> [`workflow-skills-plan.md`](./workflow-skills-plan.md)) se ukázalo, že nad
> delším autonomním horizontem výsledek ujíždí od ADR a issues, zatímco ruční
> práce s kódovou kostrou jako kotvou byla rychlejší i přesnější. Tenhle
> dokument se ptá od zelené louky, jak by měl optimální cyklus člověk↔AI
> okolo pluginu vypadat — `workflow-skills-plan.md` zůstává jako záznam toho,
> co bylo postaveno a proč (sdílený kontrakt, skripty, forge vrstva zůstávají
> v platnosti bez ohledu na výsledek téhle úvahy).

---

## 1. Principy

### 1.1 Kostru projektu staví člověk, ne agent

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

### 1.2 Kostra je zdroj pravdy — ne dokument vedle ní

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

### 1.3 První klíčová funkcionalita vzniká v páru, ne autonomně

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

### 1.4 write-rule běží po každém založení precedentu — obecně, ne principem po principu

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

### 1.5 ADR zaznamenává proč, ne jak — a jen tam, kde hrozí „oprava" bez kontextu

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

### 1.6 Agent se zakládá pro opakovaně dispečovanou roli; train-agent kryje mezeru po review, ne rutinu

Agent má smysl tam, kde se role bude v projektu opakovaně dispečovat — ne pro
jednorázový úkol. Hodnota nevzniká z jednoho běhu, ale z toho, že přes mnoho
vyvolání (`run-milestone` podle `area:*`, review každého PR) dostane ta samá
role pokaždé stejný nástrojový přístup, model/effort a nastřádanou zkušenost.
Pro jednorázovku stačí obecný subagent.

**Co agent přináší:**
- **Konzistence napříč vyvoláními** — stejný scope nástrojů a stejná úroveň
  modelu pokaždé, bez ohledu na to, která session ho zrovna spouští.
- **Routing** — `area:*` → agent mapa v sekci „Workflow (sagittaras)"
  `CONTRIBUTING.md` (viz § 3) funguje jen proto, že existuje pojmenovaný,
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

---

## 2. Issues a autonomní vývoj

### 2.1 Co issue stanovuje

Jakmile kód nese architekturu (1.1–1.3), konvence jsou mechanicky dostupné
(1.4) a proč je dostupné reaktivně (1.5), issue nemá — a nemělo by — nést
architektonickou interpretaci. Jeho práce se zužuje na jedinou věc: popsat
**jeden ohraničený přírůstek chování, který rozšiřuje už existující vzor na
nový případ.**

**Dva problémy starého tvaru, jedna příčina:**
- **Volná definice přes čistý odkaz na ADR.** Když akceptační kritérium jen
  cituje „viz ADR-3 §2", skutečný význam issue leží mimo issue — agent
  (i recenzent) musí dohledat a správně interpretovat prózu, aby věděl, co
  „hotovo" znamená. Přesně tohle mělo zabránit 1.5: ADR není spec, ze které
  se staví.
- **Review musí architekturu domýšlet znovu.** Když issue neukotvuje ve
  skutečném kódu, review nemá referenční bod ani ono — musí u každého issue
  nezávisle posoudit, jestli je implementace architektonicky správná, od
  nuly. Proto je review zdlouhavé a přísné: tiše dělá práci 1.1–1.3, znovu,
  u každého issue — protože to nikdo neudělal dřív.

**Co issue stanovuje:**
- **Ohraničený přírůstek, ne novou architekturu.** Pokud by práce vyžadovala
  vymyslet nový vzor místo rozšíření existujícího, nepatří to jako obyčejné
  issue — potřebuje to napřed 1.3 (spárovanou vzorovou implementaci), a issue
  může vzniknout, až tahle existuje.
- **Akceptační kritéria ukotvená v kódu, ne v próze.** „Řiď se vzorem v `X`"
  (reálný, existující soubor) místo „podle ADR-3". Odkaz na ADR zůstává jen
  pro skutečně chráněná rozhodnutí (1.5), na která si má autor issue dát
  pozor — ne jako primární zdroj zadání.
- **Pozorovatelné chování** — ověřuje se proti konkrétnímu precedentu, ne
  proti abstraktnímu popisu.

**Důsledek pro workflow:** takhle ohraničené issue zmenšuje review z „je
tohle dobrá architektura" (už vyřešeno výš v cyklu) na „rozšiřuje tohle
správně existující vzor pro tenhle konkrétní případ" — užší a rychlejší
otázka. To je páka na zdlouhavost a přísnost review — ne uvolnit review, ale
odebrat mu zátěž, kterou na něj tiše přenášela nedostatečně ohraničená
issues.

**Kódové ukotvení platí pro celý řetěz, ne jen pro plánování.** Sekci
`Reference` čtou čtyři skilly a všechny ji musí číst stejně: zakládá ji
`plan-milestone` a `triage-issue`, posuzuje `review-milestone`, staví na ní
`implement-issue` a **ověřuje proti ní `verify-issue`**. Ověřovatel, který
Referenci pořád hledá mezi dokumenty, nedohledá cestu vedoucí do kódu
a kritérium spadne falešně na `Neověřitelné` — tedy `Blokuje merge: ano` na
PR, se kterým nic není. Právě proto tvar `Reference` popisuje **sdílená
`issue-template.md`**, ne každý skill zvlášť: lokální výjimka v jednom skillu
je jen odložený rozpor, ne řešení.

### 2.2 Dvě roviny: Poznámka a Zadání

Issue může vstupovat do cyklu ve dvou různých stavech a je důležité je
nezaměňovat:

- **Poznámka.** Zachycuje záměr nebo pozorování, ještě nemá hranici
  k realizaci — „bylo by fajn", „chtěl bych mít", „asi je tam něco špatně,
  mělo by se to ověřit". Působí jako report nebo požadavek od uživatele či
  třetí osoby. Není přímo akceschopná.
- **Zadání.** Má explicitní hranice (co to dělá / nedělá), **podklad, podle
  kterého se to dělá** (vzor či precedent v kódu — 2.1), a explicitní
  checklist dokončení. Příklad: „Implementuj nový AI use-case" s jasně
  stanovenými hranicemi, vzorem, podle kterého se staví, a checklistem, podle
  kterého je issue hotové.

Jen Zadání je způsobilé pro autonomní dispatch (`implement-issue` /
`run-milestone`). Poznámka autonomní dispatch nesmí spustit — chybí jí
přesně to, co 2.1 vyžaduje.

### 2.3 Povýšení Poznámky na Zadání je samostatný krok

Přechod z Poznámky na Zadání není „přidat víc detailu" — je to rozhodnutí:
zapadá tohle do existujícího vzoru (→ vzniká Zadání ukotvené v kódu, podle
2.1), nebo to ve skutečnosti vyžaduje novou architekturu (→ nejde to ještě
issue-izovat, potřebuje to napřed spárovanou session podle 1.3, než vůbec
něco vznikne jako issue)?

Tohle musí být samostatný, explicitní krok — ne tiché chování uvnitř jiného
skillu. Tiché povýšení poznámky na zadání (např. tak, že by ho dělal skill,
který má primárně jen zaznamenat poznámku) je přesně ta nezasloužená
přesnost, se kterou tenhle dokument od začátku bojuje: vynutí akceptační
kritéria dřív, než jsou opřená o cokoli reálného, buď vymyslí detail, který
nahlašovatel nedal, nebo kritéria zůstanou vágní.

**Otevřená implikace pro existující skilly** (řeší se až na úrovni konkrétní
implementace, ne v tomhle dokumentu): `file-issue` dnes podle svého popisu
míří vždycky rovnou na úroveň Zadání — sestaví akceptační kritéria hned při
založení. To je v napětí s 2.2/2.3 a bude potřeba zohlednit, až se tahle
vize bude promítat zpátky do konkrétních skillů.

### 2.4 Plánování je vlnové, gatované dostupností vzoru — ne jednorázová dávka

Starý `plan-milestone` odvozoval celou sadu issues milestonu najednou z ADR
či UX-spec prózy, v jednom interview+draft kroku. Podle 2.1–2.3 ale Zadání
může vzniknout, jen když už existuje precedent v kódu, který rozšiřuje —
takže doslova nejde navrhnout všechna issues na začátku milestonu, pokud
část práce potřebuje vzor, který v kódu ještě neexistuje.

- **Hrubý rozsah zůstává upfront.** Rozhodnutí „co v tomhle milestonu
  stavíme" nepotřebuje precedent v kódu — je to směrový záměr, podobně jako
  starý krok interview rozsahu. Tahle část se nemusí měnit.
- **Zadání se navrhuje po vlnách, ne najednou.** Pro každou položku backlogu
  se použije klasifikace z 2.3: rozšiřuje existující vzor? Ano → navrhne se
  jako Zadání hned, kritéria ukotvená v kódu (2.1). Ne → není připravená;
  buď potřebuje napřed spárovanou session podle 1.3, nebo zůstává Poznámkou
  na pozdější vlnu.
- **„Připravenost" mění význam.** Starý readiness check se ptal „má
  ADR/spec dost detailu?" — dokumentová úplnost. Nový se ptá „existuje
  v kódu precedent k rozšíření?" — přítomnost kódu, ne úplnost textu.
- **Milestone smí legitimně začít nedopsaný.** Nemusí mít všechna issues
  hotová při založení. Jak se během běhu milestonu ustanovují nové vzory
  (přes 1.3), přibývají další Zadání z backlogu Poznámek — plánování a běh
  se prolínají, nejsou to ostře oddělené fáze.

**Důsledek pro `review-milestone`:** místo „je kritérium ukotvené v citované
sekci dokumentu" kontroluje „je Zadání opravdu ukotvené v existujícím
precedentu v kódu" (2.1).

**Proč tohle strukturálně řeší i původní diagnózu z úvodu:** týdenní drift
vznikl tím, že se plán na týden dopředu napsal z prózy a pak běžel autonomně
bez doteku s realitou. Vlnový model tohle vynucuje strukturálně — nová vlna
je gatovaná na reálný precedent, takže dotek s realitou (1.3 session) je
vestavěná součást cyklu, ne přidaný proces navíc.

### 2.5 Review Zadání: dvě úzké role, žádná nesmí přesáhnout svůj mandát

Review se historicky dělo jako jedna ukecaná, běžně až moc přísná a
kolikrát vyčerpávající fáze. Ve skutečnosti jde o dvě oddělené role
s různým mandátem (`workflow-skills-plan.md` je už rozlišuje jako
`qa-engineer` / kritéria a `tech-lead` / kvalita) — a obě musí zůstat přísně
ohraničené na to, co mají dělat, nic navíc.

**Role A — ověření akceptačních kritérií** (`qa-engineer`, fallback
`verify-issue`). Kritéria z checklistu Zadání (2.2) slouží dvakrát: jako
checklist pro implementujícího agenta samotného a jako nezávislé ověření po
něm. Job: projít kritéria, každé prakticky ověřit — spustit, ne věřit
odškrtnutému boxu — a vydat verdikt shody. **Mandát je přísně ohraničený:**
za žádnou cenu nic navíc. Žádné architektonické poznámky, žádné styling
připomínky, žádné „když už tu jsem" — jen shoda nebo neshoda s kritérii,
která issue samo stanovilo.

**Role B — code review** (`tech-lead`). Na rozdíl od role A není univerzální
— je to seznam principů, které si člověk pro projekt sám stanoví: někdy
stačí jistota, že kód drží code style; jindy sledovat zbytečně náročné
úseky; jindy konvence API volání. Řídí se podle oblasti, ve které se kód
nachází — a bez zvláštního kroku navíc: rules (1.4) vstupují do kontextu
automaticky podle cesty souboru, který se recenzuje. Instrukce pro code
review je proto jednoduchá — „sleduj pravidla, která jsou už v kontextu" —
ne obecný univerzální seznam, ani ruční dohledávání, co pro tuhle oblast
platí. Kde je to možné, „jistota code style" znamená potvrdit,
že prošel mechanický tooling z 1.2 (tvrdá kotva), ne o stylu znovu subjektivně
soudit — role B soudí, co tooling soudit neumí. **Stejná disciplína jako
role A:** žádné rozepisování, jen konkrétní adresný pokyn — „oprav tenhle
řádek", „oprav tenhle blok".

**Proč to dosavadní řešení nestačilo.** `run-milestone` už dnes má
mechanismus proti ukecanosti — rozhoduje strojově čtený řádek „Blokuje
merge: ano/ne", ne próza. V praxi to nestačilo: mechanismus existoval, ale
mandát obou rolí nebyl ohraničený, takže se do reportu vešlo cokoli navíc
i s tím rozhodujícím řádkem. Ohraničení mandátu (tenhle princip) doplňuje
mechanismus (existující řádek verdiktu) — samotný mechanický verdikt bez
ohraničeného mandátu na to nestačí.

---

## 3. Dopad na existující skilly

Mapa slouží jako most mezi principy 1.1–2.5 a konkrétní úpravou jednotlivých
`SKILL.md`. Řadí skilly podle toho, jak moc se mění — od beze změny po nový.
Skilly mimo životní cyklus milestonu (git mechanika, psaní jiných skillů/
agentů/rules) nejsou principy 1.x/2.x zasažené a jsou vynechané záměrně, ne
přehlédnuté — viz poznámka na konci.

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

**Mimo rozsah, záměrně:** `create-branch`, `make-commit` (git mechanika,
principy 1.x/2.x se netýkají obsahu, jen ho používají), `write-skill`,
`write-rule` už zmíněno výš, `write-claude-md`, `write-art-bible`,
`write-ux-spec` a příslušné `review-*` skilly nad nimi (psaní jiných
artefaktů pluginu, ne milestone/issue cyklus samotný), `update-plugin`
(distribuce pluginu).

---

*(pokračuje dalším principem)*
