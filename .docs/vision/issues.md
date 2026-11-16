# Issues a autonomní vývoj

Principy 2.1–2.5: co issue stanovuje, dvě roviny issue (Poznámka a Zadání), proč
je povýšení Poznámky samostatný krok, proč se plánuje po vlnách a jak úzce je
ohraničené review. Stavějí na [principech spolupráce](principles.md) — kde text
cituje 1.x, míří tam.

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

Review se historicky dělo jako jedna ukecaná, běžně až moc přísná a
kolikrát vyčerpávající fáze. Ve skutečnosti jde o dvě oddělené role
s různým mandátem ([původní plán sady](../milestone-workflow/index.md) je už
rozlišuje jako
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
