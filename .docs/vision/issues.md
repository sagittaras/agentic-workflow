# Issues a autonomní vývoj

Principy 2.1–2.11: co issue stanovuje, dvě roviny issue (Poznámka a Zadání), proč
je povýšení Poznámky samostatný krok a proč se plánuje po vlnách; dál kdo
přezkoumává výsledný kód (člověk, ne agent — 2.6 nahrazuje agentní review z 2.5),
jak velké smí issue být, aby šlo jeho PR přezkoumat, jak orchestrátor issues
spouští, jaké pevné kritérium musí PR splnit, než ho člověk uvidí, a kdo
schvaluje plán milestonu (člověk, ne `review-milestone` — 2.10). 2.11 vrací
spouštění issues k subagentům se zvoleným modelem a práci zakládající precedent
posílá do párové session. Stavějí na [principech spolupráce](principles.md) — kde text cituje 1.x,
míří tam.

## 2.1 Co issue stanovuje

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

## 2.2 Dvě roviny: Poznámka a Zadání

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

## 2.3 Povýšení Poznámky na Zadání je samostatný krok

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

## 2.4 Plánování je vlnové, gatované dostupností vzoru — ne jednorázová dávka

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

## 2.5 Review Zadání: dvě úzké role, žádná nesmí přesáhnout svůj mandát

> **Nahrazeno** principy [2.6](#26-review-výsledného-kódu-dělá-člověk-ne-agent)
> a [2.8](#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech)
> (16. 11. 2026): agentní review z běžného průchodu issue vypadává, kód
> přezkoumává člověk. Mandát role A platí dál pro `verify-issue` spuštěný ručně.
> Zbytek zůstává jako záznam, proč úzký mandát sám nestačil — omezil, *co* agent
> posuzuje, ale ne *jak důsledně*, ani kolik to stojí.

Review se historicky dělo jako jedna ukecaná, běžně až moc přísná a
kolikrát vyčerpávající fáze. Ve skutečnosti jde o dvě oddělené role
s různým mandátem ([původní plán sady](../milestone-workflow/index.md) je už
rozlišuje jako `qa-engineer` / kritéria a `tech-lead` / kvalita) — a obě musí
zůstat přísně ohraničené na to, co mají dělat, nic navíc.

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

## 2.6 Review výsledného kódu dělá člověk, ne agent

Konkrétní práci na issue vykoná AI: implementaci, ověřovací příkazy, otevření
PR. Výsledný kód ale přezkoumává člověk — projde PR a připomínky píše přímo
k němu. Agentní review (obě role z 2.5) z běžného průchodu issue vypadává.

**Why:**
- **Review je nejdražší část průchodu issue — ne implementace.** Pozorování
  z provozu (16. 11. 2026): soustavná práce přes několik session, ve kterých je
  hlavní kontrolou člověk, se v limitech skoro neprojeví; jedno spuštění
  `run-milestone` zvedne týdenní limit o několik procent. Rozdíl dělají review
  procesy — dvě role nad každým PR a k tomu retry kola, každé s vlastním čtením
  kontextu.
- **Důslednost agentního review nejde nadirigovat.** 2.5 se snažila review
  zúžit mandátem: jen kritéria, jen pravidla dané cesty, nic navíc. Mandát ale
  omezí, *co* agent posuzuje, ne *s jakou mírou*. Prompt, který agentovi řekne,
  jak moc být důsledný, napsat nejde — buď je zbytečně přísný a vrací PR kvůli
  věcem, které nevadí, nebo pustí to, co člověk chtěl jinak. Člověk tu míru má:
  ví, které odchylky mu vadí.
- **Lidské review je dotek s realitou u každého issue.** Úvodní diagnóza vize:
  týdenní drift vznikl, protože se autonomní běh nikde nedotkl člověka. 1.3 to
  řeší pro první instanci vzoru, 2.4 pro plánování; lidské review to uzavírá
  i pro každé další issue — odchylka je vidět po jednom PR, ne po milestonu.
- **Přezkoumaný kód člověk zná.** Plně autonomní běh vyrábí kód, který nikdo
  nečetl; udržovat ho pak znamená ho číst dodatečně, bez kontextu.

**Co z agentní kontroly zůstává:**
- **Mechanická brána.** Každé kritérium kryje test, implementující session
  bez zelených testů PR neotevře a orchestrátor zelenou bránu potvrdí dřív,
  než PR uvidí člověk — podrobně
  [2.9](#29-každé-akceptační-kritérium-kryje-test-session-ho-napíše-orchestrátor-potvrdí).
  Je levná a nesubjektivní — stejná osa jako tvrdá kotva z 1.2.
- **`verify-issue` na vyžádání.** Nástroj, který si člověk spustí nad
  konkrétním PR, když chce nezávislé ověření kritérií — ne povinná brána před
  každým merge. Spuštěný ručně se drží mandátu role A z 2.5.

**Posun cíle pluginu.** Původní záměr byl úplná autonomizace práce v Claude
Code. 2.6 ho mění na kompromis: AI vykonává, člověk kontroluje. Plugin má
zlevnit a zrychlit tu část práce, kde AI šetří čas (rozpad, implementace,
mechanika gitu a PR), ne nahradit tu, kde je člověk levnější a přesnější.

**Recenzent schvaluje, merguje ten, komu schválení napsal.** Práce člověka
v review končí schválením — připomínkou, nebo signálem „hotovo". Merge zařídí
session, které člověk schválení napsal přímo: samostatně spuštěná implementace
tedy sama, v běhu milestonu orchestrátor. Konflikt s integrační větví, která se
mezitím pohnula, řeší dál ten, kdo PR vystavil — má větev i kontext, recenzent
ne. Je to stejný vzor, jaký projektová konfigurace už drží pro výchozí větev —
merge jen na výslovný souhlas člověka —, jen zobecněný na každé PR.

**Schválení se mezi agenty nepřeposílá.** Původně mergovala vždy session, která
PR vystavila, a orchestrátor jí schválení přeposílal. V běhu milestonu #4
(16. 11. 2026, [issue #70](https://github.com/sagittaras/agentic-workflow/issues/70))
to selhalo u každého PR: zpráva od jiné session není slovo člověka a klasifikátor
auto mode merge zamítl jako merge bez schválení. Allow pravidlo to neřeší —
plugin ho do `~/.claude/settings.json` uživatele dodat nemůže, a když sedne,
obejde klasifikátor úplně, i bez jakéhokoli schválení. Klasifikátor tu ale
chrání vlastnost, kterou chceme i my: schválení nejde podvrhnout zprávou jiného
agenta.

**Důsledek pro workflow:** review gate je lidské schválení PR, ne verdikt
agentů, a merge do integrační větve následuje až po něm. Retry kolo vzniká
z připomínek člověka v PR — a ty jsou zároveň nejlepší vstup pro `train-agent`
(1.6): poznatek, který člověk musel napsat, je přesně ten, který se nemá
opakovat.

## 2.7 Issue je velké nanejvýš tak, aby jeho PR šlo přezkoumat ručně

Z 2.6 plyne nové kritérium rozpadu: velikost issue neurčuje jen ohraničenost
přírůstku (2.1), ale i to, jestli výsledné PR zvládne člověk projít. Plánování
proto rozpadá práci tak, aby nevzniklo nereálně velké PR.

**Why:**
- **Velké PR se ručně kontroluje špatně.** Pozornost recenzenta s velikostí
  diffu neroste. Od určité velikosti se z review stává prolétnutí — a to je
  horší než žádné review, protože vypadá jako schválení.
- **Rozpad patří do plánování, ne do review.** Když přijde nereálně velké PR,
  je pozdě: vrátit ho k rozdělení znamená zahodit implementační session
  a rozdělit hotovou práci stojí víc, než ji rozdělit předem.

**Signály příliš velkého issue** — posuzuje je plánování, ne slepý počet
řádků:
- issue zasahuje víc vrstev najednou (rozhraní, implementace, napojení,
  persistence) a každá z nich by šla mergovat samostatně;
- akceptační kritéria popisují víc nezávislých chování, z nichž každé by
  obstálo jako vlastní issue;
- rozšíření precedentu nejde popsat jednou větou „jako `X`, jen pro `Y`".

Do velikosti se nepočítá generovaný nebo mechanický obsah (migrace vygenerované
nástrojem, lock soubory, snapshoty) — ten recenzent nečte řádek po řádku.

**Vztah k 2.4:** menší issues znamenají víc hran v grafu závislostí, a s tím
vlnové plánování počítá. Rozdělení ale nesmí vyrobit issue, které samo nic
nedělá (rozhraní bez jediného použití) — každé PR má být samostatně
smysluplný a mergovatelný krok.

**Žádný číselný práh.** Velikost se posuzuje jen podle signálů výš, ne podle
počtu řádků diffu nebo souborů — ani jako konfigurační hodnota projektu. Řádky
jsou stejně neurčité měřítko jako kdysi placení programátorů za napsaný řádek:
co se jimi měří, začne se optimalizovat, a výsledek je horší na všech stranách.
Soudržná změna se rozseká jen proto, aby se vešla pod limit, nebo se kód
zhustí, aby se do něj vešel — a recenzentovi to nepomůže ani v jednom případě.
Signály se ptají na to, na čem review doopravdy stojí: kolik nezávislých věcí
musí recenzent v jednom PR udržet v hlavě.

## 2.8 Orchestrátor spouští issues v podřazených session, ne v subagentech

> **Nahrazeno** principem [2.11](#211-orchestrátor-spouští-issues-v-subagentech-se-zvoleným-modelem-nový-precedent-jde-do-párové-session)
> (26. 11. 2026): podřazené session nejde nadirigovat model, effort ani agenta,
> takže se issues spouští zase v subagentech. Předávání obsahu přes PR, merge
> orchestrátorem a dávka podle kapacity člověka platí dál. Zbytek zůstává jako
> záznam, proč se session zkoušely a co se od nich čekalo.

`run-milestone` přestává dispečovat issues subagentům, kteří doběhnou
a zmizí. Každé odblokované issue spustí v podřazené session Claude Code —
s vlastním worktree, větví a PR. Člověk otevře PR, připomínky napíše k němu
a session je zapracuje.

**Why:**
- **Připomínky potřebují adresáta, který si pamatuje.** Subagent po otevření
  PR skončí; retry pak znamená nového agenta, který si celý kontext načítá
  znovu. Podřazená session zůstává a připomínku zapracuje ve stejném
  kontextu, ve kterém kód napsala — levněji i přesněji.
- **Člověk řídí každé issue zvlášť.** Session je vidět a dá se otevřít,
  nasměrovat i zastavit na úrovni jednoho issue, bez zásahu do orchestrátoru
  a ostatních rozběhnutých issues.
- **Orchestrátor zůstává tenký.** Drží graf závislostí a stav PR, nečte diffy
  ani review, takže jeho kontext neroste s počtem issues.

**Důsledek pro workflow:** orchestrátor spustí session na odblokovaná issues
a předává jejich PR člověku k review. Na jeho schválení PR sám mergne (2.6:
merguje ten, komu schválení napsal) a odblokuje další část grafu. Paralelismus
tím neomezuje počet agentů, ale kapacita člověka na review — dávka se
dimenzuje podle toho, kolik PR člověk zvládne projít, ne kolik session jde
spustit.

**Obsah přes PR, přes orchestrátora jen signál.** Platí v obou režimech —
s podřazenými session i bez nich. Podřazené session jsou schopnost prostředí
(desktopová aplikace Claude Code), ne skillu; kde chybí (CLI), zbývají
subagenti. Cesta pro předávání připomínek je v obou případech stejná:

- Připomínky člověk píše do PR — tam, kam patří a kde zůstanou jako záznam.
- Orchestrátorovi pošle jen krátký signál („#12 má připomínky", „#12
  schváleno").
- Orchestrátor naváže na konkrétní session nebo subagenta s jeho kontextem —
  pokračováním přes jeho id, ne novým spuštěním — a předá mu jen ten signál.
  Ten si připomínky přečte z PR sám, zapracuje je a vrátí jednořádkový
  výsledek.
- Schválení orchestrátor nepřeposílá — na něj PR mergne sám (2.6).

V desktopu by člověk mohl psát i přímo do podřazené session, ale pak se běh
zastaví: aplikace orchestrátora probudí jen po kole podřazené session, které
spustil on sám. Signál přes orchestrátora proto není jen fallback pro CLI —
díky němu orchestrátor ví, kdy má mergnout a odblokovat další issue.

Proti dvěma přímočarým cestám:

- **Připomínky přímo přes PR, bez signálu** — běžící subagent by si musel sám
  hlídat, jestli už přišla reakce. Takové hlídání stojí běh a obrací výhodu,
  kterou má podřazená session: ta čeká zadarmo.
- **Připomínky celé přes orchestrátora** — nikdo nic nehlídá, ale každé kolo
  review plevelí historii hlavní session a zvedá její kontext, přesně to, čemu
  má tenký orchestrátor předcházet.

Zvolená cesta bere z každé to levnější: obsah teče přes PR jako v první,
spouštěč přes orchestrátora jako ve druhé — hlavní session nese jen signál
a jednořádkový výsledek, ne obsah review.

**Ověří se v provozu, ne předem.** Je to směr, kterým se pohneme, a podle
skutečného použití se upraví. Sledovat se má hlavně: jak dlouho subagent
s kontextem vydrží (konec hlavní session, zkracování historie), jestli
hlavní session přes signály opravdu neroste, a jestli cena za issue klesne
k úrovni podřazených session, nebo se jen zmenší.

**Upřesnění z párové session nad `run-milestone` (16. 11. 2026):**
- **Session končí v libovolném pořadí.** Orchestrátor zpracuje tu, kterou
  jmenuje notifikace, a na konkrétní session nečeká. Pozorovaná chyba:
  orchestrátor, který si session zapsal jako kroky seznamu úkolů, čekal na
  první spuštěnou, i když pozdější už skončila.
- **Směrování podle `area:*` přechází do session.** Session při spuštění
  agenta zvolit nejde, proto ho dostane v zadání a implementaci mu deleguje;
  sama drží kontext pro připomínky (1.6).
- **Orchestrátor zůstává na silném modelu.** Podřazená session dostane model
  nejvýš stejné rodiny a effort nejvýš stejný jako orchestrátor. Levnější
  orchestrátor by srazil i implementace, přestože sám po přestavbě spotřebuje
  málo.
- **Dávka se ptá člověka.** Kolik issues běží souběžně, určí na začátku běhu
  člověk podle své kapacity na review.

## 2.9 Každé akceptační kritérium kryje test; session ho napíše, orchestrátor potvrdí

Než session pošle práci na PR, musí splnit pevné kritérium: každé akceptační
kritérium issue je pokryté testem, který napsala nebo rozšířila, a testy
prochází. Session si to ale nehlídá jen sama — orchestrátor její tvrzení
potvrdí: spustí ověřovací příkazy nad větví PR a teprve se zelenou bránou jde
PR člověku k review.

**Why:**
- **Lidské review nemá ověřovat, jestli to funguje.** 2.6 vrací review
  člověku kvůli úsudku, který agent neumí dávkovat — návrh, záměr, odchylky od
  toho, co člověk chtěl. Jestli kód dělá, co říkají kritéria, je otázka
  s binární odpovědí a patří stroji. Pozornost spotřebovaná na PR, které ani
  neprojde testy, je přesně ta drahá věc, kterou 2.6 šetří.
- **Tvrzení session je self-report.** „Testy prochází" od session je totéž co
  odškrtnutý box, kterému už 2.5 zakázala věřit (role A: spustit, ne věřit).
  Nezávislé spuštění chytí testy, které nikdo nespustil, běh nad zastaralým
  stavem i rozdíl mezi worktree session a integrační větví.
- **Je to levné.** Spuštění testů na rozdíl od agentního review skoro nestojí
  tokeny — skript vrátí výsledek a výpis selhání, orchestrátor nečte diff ani
  nesoudí kvalitu. Tenký orchestrátor z 2.8 tím zůstává tenký.
- **Test zůstává jako tvrdá kotva.** Kritérium kryté testem hlídá i každé
  další issue, stejně jako typy a kompilace v 1.2. Kritérium ověřené jen
  přečtením kódu po merge už nic nehlídá.

**Co orchestrátor potvrzuje — a co ne:**
- **Potvrzuje:** session v PR ke každému kritériu uvedla test, který ho kryje
  (kritérium → test); uvedené testy ve změně opravdu jsou; a ověřovací
  příkazy oblasti prochází nad větví PR sloučenou s integrační větví
  (integrační brána).
- **Nepotvrzuje,** jestli test kritérium kryje *dobře*. To je úsudek: udělá
  ho člověk při review, nebo si ho vyžádá ručním `verify-issue`, který
  kritéria opřená o test mutačně testuje.

**Kritérium, které test pokrýt nejde** (vizuální podoba, dokumentace,
nastavení prostředí), je výjimka, ne mezera: plánování ho tak označí už
v issue („ověří člověk") a v lidském review je to jediné kritérium, které
tam patří. Výchozí požadavek ale je, aby plánování kritéria psalo
testovatelně — šablona issue to dnes jen naznačuje („co dokáže test").

**Bez orchestrátoru** (`implement-issue` spuštěný samostatně) platí pevné
kritérium session beze změny; potvrzení přebírá CI projektu, má-li ho. Nemá-li,
session v PR přizná, že bránu spustila jen sama.

**Důsledek pro workflow:** integrační brána se v `run-milestone` přesouvá
z konce (po review, těsně před merge) před lidské review. Červená brána jde
zpátky session stejnou cestou jako připomínky (2.8, signál) a člověk ji
nevidí. Před merge na schválení (2.6) zopakuje bránu orchestrátor; červenou
vrací session a opravené PR jde ke schválení znovu — kromě opravy konfliktu
po merge souběžného PR, po které schválení platí dál (běh M1, viz [mapa
dopadu](skill-impact.md#nálezy-z-provozu-běh-m1)). A protože
`verify-issue` přestal být povinnou bránou, zaškrtávátka v těle issue by
nikdo neodškrtal: odškrtne je orchestrátor u kritérií, jejichž test potvrdil
— znamená to „kryto testem, který prošel", nic víc.

## 2.10 Plán milestonu schvaluje člověk, ne agentní review

Plán milestonu validuje člověk — stejně jako PR z jeho issues (2.6). Potvrzuje
draft vlny v `plan-milestone`, kde vidí názvy, závislosti, precedent i kritéria
každého Zadání, a spuštěním `run-milestone` plán schvaluje. Orchestrátor proto
v trackeru nehledá review komentář a `review-milestone` vypadává z řetězu:
zůstává jako nástroj, který si člověk spustí, když chce na plán druhý pohled.

**Why:**
- **Stejná diagnóza jako u review kódu.** Agentní review plánu má tutéž vadu
  jako agentní review PR ve 2.6: mandát omezí, *co* agent posuzuje, ne *s jakou
  důsledností*. Míru, se kterou na plán sáhnout, má člověk.
- **Platilo se za každou vlnu znovu.** Review běželo jako opus × high ve forku,
  který čte všechna issues milestonu i jejich precedenty — a `run-milestone`
  ho vyžadoval po každé vlně (2.4) znovu, protože komentář starší než nová
  issues se počítal jako chybějící. Čím víc vln, tím víckrát se přečetl celý
  milestone.
- **Člověk plán stejně čte.** Kdo přezkoumává každé PR, zná i issues, ze
  kterých vzniklo. Chyba v plánu, kterou nezachytí u draftu, se mu ukáže
  nejpozději u prvního PR — po jednom issue, ne po milestonu. Draft vlny je
  přitom nejlevnější místo k opravě: v trackeru ještě nic neleží.
- **Mechanickou část review hlídá běh.** Co review hlásilo jako blokující,
  skončí za běhu eskalací dřív, než vznikne práce: cyklus nebo závislost mimo
  milestone a Poznámka mezi otevřenými issues (při sestavení grafu),
  chybějící `area:*` label (před spuštěním issue), neexistující cesta v `Reference`
  (`implement-issue`), netestovatelné kritérium bez značky „ověří člověk"
  (brána z [2.9](#29-každé-akceptační-kritérium-kryje-test-session-ho-napíše-orchestrátor-potvrdí)).
  Úsudek — ukotvení v precedentu, velikost
  ([2.7](#27-issue-je-velké-nanejvýš-tak-aby-jeho-pr-šlo-přezkoumat-ručně)),
  překryvy, rozsah — patří člověku.

**Co se mění:**
- **Draft vlny nese kritéria.** Dokud plán četl agent, stačil člověku přehled
  názvů, závislostí a precedentů. Teď je draft jediné review plánu, a tak
  ukazuje všechno, co půjde do běhu.
- **Poznámku hlídá orchestrátor u každého issue.** Dřív ji kontroloval jen
  u nové vlny; issues první vlny kryl review komentář.
- **Žádný doklad v trackeru.** Spuštění běhu je schválení samo o sobě;
  komentář „Review milestonu" přestává být kontrakt mezi skilly. Ručně
  spuštěný `review-milestone` report do trackeru ukládá dál — pro člověka, ne
  pro orchestrátora.

**Proč nástroj na vyžádání, ne smazání.** Vzorem je `verify-issue` po 2.6,
jen s jiným důvodem: `verify-issue` zůstal kvůli mutačnímu testu, který
člověk levně neudělá. U `review-milestone` takový důvod chybí, ale u velkého
milestonu může člověk chtít druhý pohled na překryvy a rozpory napříč issues.
Ukáže-li provoz, že ho nikdo nespouští, smaže se.

**Důsledek pro workflow:** řetěz je `plan-milestone → run-milestone`. Člověk
schvaluje draft vlny, každé PR a nakonec integrační PR do výchozí větve;
`review-milestone` i `verify-issue` jsou nástroje mimo řetěz, které si spustí,
když chce.

## 2.11 Orchestrátor spouští issues v subagentech se zvoleným modelem; nový precedent jde do párové session

Nahrazuje [2.8](#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech)
(26. 11. 2026). `run-milestone` se vrací k subagentům: každé odblokované issue
spustí nástrojem Agent ve vlastním worktree, s modelem a effortem předanými
parametrem — ve výchozím stavu sonnet × high. Issue, které zakládá nový precedent
(label `precedent`), automaticky neorchestruje: ohlásí ho člověku a ten si pro něj
založí párovou session.

**Why:**
- **Podřazenou session nejde nadirigovat.** `start_session` neumí zvolit model,
  effort ani agenta. Session běžela na modelu orchestrátoru — proto orchestrátor
  zůstával na opus × xhigh, i když by sám vystačil s méně — a agenta z mapy si
  musela delegovat sama, s další vrstvou kontextu. Nástroj Agent bere model
  i effort parametrem. Model z frontmatteru skillu, který subagent vyvolá, ho
  nepřepíše: v transkriptech běhů z 20. 8. 2026 zůstali subagenti na sonnetu
  i po vyvolání `implement-issue` (opus × xhigh).
- **Zadání nepotřebuje tolik autonomního uvažování.** Issue podle
  [2.1](#21-co-issue-stanovuje) říká, jak se práce realizuje, a ukazuje na
  precedent v kódu. Implementace je rozšíření vzoru, ne návrh — na to stačí
  sonnet × high za zlomek ceny. Jinou dvojici řekne člověk orchestrátorovi;
  agent z mapy, který má dvojici ve své definici, dostane tu — volila ji matice
  `write-agent` vědomě.
- **Nový precedent je jiná práce.** První instance vzoru vzniká v páru
  ([1.3](principles.md#13-první-klíčová-funkcionalita-vzniká-v-páru-ne-autonomně)).
  Autonomní běh na levném modelu je pro ni přesně špatně, a v párové session si
  člověk zvolí model i effort podle velikosti problému sám. Issue s labelem drží
  párovou práci v grafu milestonu: co na ní závisí, čeká, a po merge orchestrátor
  pokračuje.
- **Spouštění kdykoli.** `start_session` aplikace odmítá v turnu, který nezačal
  zprávou člověka — v běhu M1 proto orchestrátor nemohl doplnit dávku po
  notifikaci ([mapa dopadu](skill-impact.md#nálezy-z-provozu-běh-m1)). Agenta
  spustí z kteréhokoli turnu.

**Co se ztrácí a čím se to nahrazuje:**
- **Psaní přímo do session.** V M1 šlo všech 22 kol review rovnou do session
  a signál přes orchestrátora se nepoužil ani jednou — člověk píše tam, kde
  práce leží. Do subagenta v desktopu psát nejde. Připomínky proto píše
  orchestrátorovi, který je agentovi přepošle doslova — za cenu kontextu
  orchestrátoru, který 2.8 chtěla šetřit —, nebo do PR. Na GitHubu PR hlídá skript
  na pozadí (`gh/pr-watch.sh`): jeden GraphQL dotaz za minutu, žádné tokeny,
  orchestrátor se probudí až s novou připomínkou nebo s PR mergnutým ve forge.
- **Issue jako samostatně řiditelná session.** Agent je vidět v panelu úloh
  a jde zastavit; řídí se přes orchestrátora.
- **Kontext pro připomínky zůstává.** Orchestrátor na agenta navazuje přes
  `SendMessage` s celou jeho historií — to, kvůli čemu 2.8 sáhla po session, umí
  subagent taky. Agenta předchozího, přerušeného běhu oslovit nejde; k jeho PR
  orchestrátor spustí nového, který převezme větev.

**Co z 2.8 platí dál:** orchestrátor obsah připomínek z PR nečte, agent si je
přečte sám; schválení se nepřeposílá a merguje orchestrátor
([2.6](#26-review-výsledného-kódu-dělá-člověk-ne-agent)); dávku určuje kapacita
člověka na review; agenti končí v libovolném pořadí a orchestrátor na žádného
konkrétního nečeká. Orchestrátor sám klesá na opus × high — xhigh držel jen
kvůli stropu, který `start_session` kladl na podřazené session.

**PR pod aplikací — ověřeno 26. 11. 2026, směr čeká na schválení.** PR zakládá
agent pod účtem člověka a GitHub autorovi neumožní schválit vlastní PR, takže
formální Approve nejde a schválení se píše orchestrátorovi. Ověření na testovacím
repozitáři `sagittaras/agentic-sandbox` (Claude Code 2.1.306; klasifikátor
zkoušený v čerstvých headless session v auto mode s výchozími pravidly) říká:

- **`claude[bot]` jen v GitHub Actions.** `anthropics/claude-code-action` získá
  token aplikace Claude výměnou OIDC tokenu z Actions u Anthropicu
  (`src/github/token.ts`). Mimo runner OIDC token není, lokální běh potřebuje
  vlastní aplikaci.
- **Vlastní aplikace funguje.** Aplikace s právy Contents, Pull requests a Issues
  (čtení i zápis) je nainstalovaná jen na repozitáři. `scripts/gh/as-app.sh`
  vyrobí z app id a klíče JWT (openssl v Git Bash), vymění ho za installation token
  a pustí příkaz s `GH_TOKEN`. Stávající `pr-create.sh` pod ním založil PR
  s autorem `<aplikace>[bot]` a člověk na něm dal formální Approve i Request
  changes. Push větve pod účtem člověka na autorovi PR nic nemění. Token skript
  nevypisuje, protože vypsaný token klasifikátor blokuje (Credential
  Materialization).
- **Schválení z forge klasifikátor nevidí, rozhoduje instrukce ve zprávě
  člověka.** Klasifikátor vidí zprávy uživatele a volání nástrojů, výstupy nástrojů
  nevidí. Merge PR se stavem APPROVED pustil, když merge nařizoval skill vyvolaný
  člověkem, a to i v turnu, který spustila notifikace hlídače na pozadí. Tentýž
  merge zamítl, když stejná instrukce ležela jen v systémovém promptu a člověk
  napsal „Zpracuj PR #3". Schválení ve forge samo nic neváží. Váží text skillu ve
  zprávě, kterou člověk běh spustil — stejně jako dnes „mergni PR #n".
- **Auto-merge forge je slabší náhrada.** Výchozí pravidlo Merge Without Review
  vyjímá `gh pr merge --auto` na repozitáři s povinným review, protože bránu drží
  server. Klasifikátor ale `--auto` pustil i na větvi bez rulesetu a GitHub tam PR
  mergnul hned, bez review — ochranu větve neověřuje. Navíc se ztrácí brána před
  merge: GitHub mergne v okamžiku schválení a `integration-gate.sh --same-as`
  nikdo nespustí. Volbu „branch up to date" bez povinné kontroly GitHub nevynucuje:
  PR o dva merge pozadu se mergnulo dvě sekundy po schválení. Bránu by udržela jen
  povinná kontrola stavu — z CI, nebo zapsaná orchestrátorem. Tu druhou nejspíš
  zamítne výchozí pravidlo Self-Approval („marks the agent's own PR's required
  checks as passed"); neověřeno.

**Návrh:** PR zakládá agent pod vlastní aplikací projektu (`as-app.sh`), člověk
dává formální review a orchestrátor merguje dál sám. Hlídač mu ohlásí
`review:APPROVED`, orchestrátor zopakuje bránu před merge a mergne. Instrukci
„na schválení ve forge mergni" nese tělo `run-milestone`, takže ji klasifikátor
vidí ve zprávě, kterou člověk běh spustil. Ruleset ani auto-merge forge nejsou
potřeba. Cena: jednorázově aplikace v organizaci a privátní klíč na každém stroji
(kdo má klíč, píše jménem aplikace do všech repozitářů s instalací); v pluginu
`as-app.sh` u skriptů, které zakládají PR a píšou do něj, identita v konfiguraci
workflow a krok 6 `run-milestone`, kde `review:APPROVED` přestane znamenat
připomínky. Komentáře agentů pod botem navíc odliší člověka v hlídači, který
autory `[bot]` přeskakuje. Neověřené zůstává, jestli instrukci ze skillu
klasifikátor uvidí i po kompakci dlouhého běhu. Pojistkou je dnešní cesta:
zamítne-li merge, člověk napíše „mergni PR #n".

**Důsledek pro workflow:** `run-milestone` spouští subagenty se dvojicí
z preference člověka, z definice agenta, nebo sonnet × high; issue s labelem
`precedent` jen ohlásí a po merge jeho PR zavře. `plan-milestone` smí položku bez
precedentu založit jako takové issue a `triage-issue` mu label připne, když
precedent nenajde. Připomínky tečou přes orchestrátora nebo přes PR s hlídačem.
