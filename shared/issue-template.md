# Šablona issue

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Závazný tvar názvu a těla issue pro
> celý milestone workflow. Otevři ho vždy, když issue **zakládáš** (`plan-milestone`,
> `file-issue`), **povyšuješ** (`triage-issue`), **posuzuješ** (`review-milestone`),
> **implementuješ** (`implement-issue`) nebo **ověřuješ** (`verify-issue`).

Tvar není kosmetika — tři místa v těle se čtou strojově a při odchylce se řetěz rozpadne:
sekce `Závisí na` je zdroj grafu závislostí pro `run-milestone`, zaškrtávátka
v `Akceptační kritéria` přepisuje `verify-issue`, a sekce `Reference` je jediné, podle
čeho `implement-issue` pozná, který precedent v kódu má rozšířit.

---

## Název

```
<type>(<scope>): <popis v rozkazovacím způsobu, malé písmeno na začátku>
```

- `<type>` je typ podle Conventional Commits a **musí se shodovat s typovým labelem**,
  který je na issue nasazený. Rozpor mezi názvem a labelem je nález pro `review-milestone`.
- `<scope>` je oblast v kódu, ne téma milestonu.
- Jazyk popisu určuje sekce `Jazyk issues` v projektové konfiguraci.

---

## Tělo

````markdown
## Souhrn

[Jedna až dvě věty: co tenhle issue dodá. Ne jak, to patří do kritérií.]

## Akceptační kritéria

- [ ] [Pozorovatelné chování — co vrátí požadavek, co dokáže test, co vypíše příkaz.]
- [ ] [Další kritérium, každé ukázatelné na precedentu ze sekce Reference.]

## Reference

- [Cesta k souboru nebo vzoru v kódu, který se rozšiřuje — vůči kořeni repozitáře.]
- [Nepovinně dokument (ADR § sekce) jako doplňkové omezení, nikdy místo kódu.]

## Závisí na

- #N — [krátce čím blokuje]
````

**Sekci `Závisí na` vynech celou**, když issue na ničem nezávisí. Prázdná sekce
s pomlčkou nebo „nic" je horší než žádná: parser `run-milestone` řeší jen dva stavy —
sekce je, nebo není.

---

## Reference je precedent v kódu

`Reference` cituje **konkrétní soubor nebo vzor v kódu, který issue rozšiřuje** —
cestou vůči kořeni repozitáře. To je primární zdroj zadání: podle něj se
implementuje (`implement-issue`, krok 3) i ověřuje (`verify-issue`, krok 3), a bez
něj nemá kritérium na co ukázat.

Jestli citovaná cesta jako precedent obstojí, rozhoduje `precedent-test.md` — ten
otevři, kdykoli ten test provádíš, ať už při zakládání, povýšení nebo posuzování.
Vzdálená tematická podobnost precedent není.

**Dokument (ADR, UX spec) smí `Reference` citovat vedle kódu, nikdy místo něj** —
a čte se jako doplňkové omezení: kam nesahat, které rozhodnutí je chráněné. Tvar
implementace určuje precedent v kódu, ne próza dokumentu. Cesty k dokumentům drží
sekce `Zdroje pravdy` projektové konfigurace; cesta ke kódu je vůči kořeni
repozitáře.

**Reference bez kódového precedentu je vada zadání**, ne varianta tvaru: takový
issue se neimplementuje a patří do `triage-issue` (a nenajde-li precedent ani ten,
zůstává Poznámkou do příští vlny).

**Chování, které v precedentu ještě není, není rozpor** — přesně ten přírůstek
issue přináší. Rozpor je až jiné rozhraní nebo struktura, na kterou nejde navázat.

---

## Jak psát akceptační kritéria

Tohle je nejdůležitější část celé šablony a nejčastější místo selhání.

**Kritérium popisuje pozorovatelné chování, ne mechanismus.** Špatně: „porovnávání
nezávislé na velikosti písmen je vlastnost typu sloupce, ne kódu v tomhle repozitáři."
Takové kritérium implicitně odrazuje od testu právě toho kódu, který tu vlastnost může
zrušit. Správně: „registrace `zechy` při existujícím `Zechy` ohlásí konflikt."
Mechanismus patří do `Reference`; kritérium říká, co musí platit.

**Každé kritérium jde ukázat na precedentu.** Když neumíš říct, který soubor nebo
vzor z `Reference` kritérium rozšiřuje, nepatří do issue — chybí mu ukotvení.
Věrohodně znějící parafráze bez opory v kódu je nález pro `review-milestone`.

**Kritérium má být ověřitelné bez doptávání.** Kritérium, které jde přečíst dvěma způsoby,
zdrží celý řetěz až u `verify-issue`, kde už stojí čas inženýra i recenzenta.

**Zaškrtávátka zakládej prázdná.** Odškrtává je až `verify-issue` podle toho, co skutečně
ověřil — ne autor a ne implementující agent.
