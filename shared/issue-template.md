# Šablona issue

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Závazný tvar názvu a těla issue pro
> celý milestone workflow. Otevři ho vždy, když issue **zakládáš** (`plan-milestone`,
> `file-issue`), **povyšuješ** (`triage-issue`), **posuzuješ** (`review-milestone`),
> **implementuješ** (`implement-issue`) nebo **ověřuješ** (`verify-issue`).

Tvar není kosmetika — tři místa v těle se čtou strojově a při odchylce se řetěz rozpadne:
sekce `Závisí na` je zdroj grafu závislostí pro `run-milestone`, kritéria
v `Akceptační kritéria` i jejich značku `(ověří člověk)` čte brána `run-milestone`, která
zaškrtávátka i přepisuje, a sekce `Reference` je jediné, podle
čeho `implement-issue` pozná, který precedent v kódu má rozšířit.

---

## Název

```
<type>(<scope>): <popis v rozkazovacím způsobu, malé písmeno na začátku>
```

- `<type>` je typ podle Conventional Commits a **musí se shodovat s typovým labelem**,
  který je na issue nasazený — `implement-issue` z labelu odvozuje typ větve i commitu.
- `<scope>` je oblast v kódu, ne téma milestonu.
- Jazyk popisu určuje sekce `Jazyk issues` v projektové konfiguraci.

**Strojové prvky se nepřekládají.** `Jazyk issues` platí pro popis v názvu a pro text
pod nadpisy. Doslova česky, v jakémkoli jazyce issues, zůstávají:

- nadpisy těla issue: `## Souhrn`, `## Akceptační kritéria`, `## Reference`,
  `## Závisí na`;
- značka `(ověří člověk)` za kritériem;
- nadpis `## Testy kritérií` v těle PR.

---

## Tělo

````markdown
## Souhrn

[Jedna až dvě věty: co tenhle issue dodá. Ne jak, to patří do kritérií.]

## Akceptační kritéria

- [ ] [Pozorovatelné chování — co vrátí požadavek, co dokáže test, co vypíše příkaz.]
- [ ] [Další kritérium, každé ukázatelné na precedentu ze sekce Reference.]
- [ ] [Kritérium, které test pokrýt nejde — třeba vizuální podoba obrazovky.] (ověří člověk)

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
implementace určuje precedent v kódu, ne próza dokumentu. Dokument se cituje
cestou vůči kořeni repozitáře, stejně jako kód.

**Reference bez kódového precedentu je vada zadání**, ne varianta tvaru: takový
issue se neimplementuje a patří do `triage-issue` (a nenajde-li precedent ani ten,
zůstává Poznámkou do příští vlny). Výjimkou je issue s labelem `precedent`, viz
§ Issue zakládající precedent.

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

**Kritérium má být ověřitelné bez doptávání.** Kritérium, které jde přečíst dvěma způsoby,
zdrží celý řetěz až u `verify-issue`, kde už stojí čas inženýra i recenzenta.

**Kritérium je ve výchozím stavu kryté testem.** Piš ho tak, aby ho implementující
session dokázala pokrýt testem, který napíše nebo rozšíří — výsledek příkazu, návratový
kód, výstup testu. Kritérium, které test pokrýt nejde, nese na konci řádku značku
`(ověří člověk)`: typicky vizuální podoba, dokumentace nebo nastavení prostředí.
Značka je výjimka, ne úleva — kritérium, které test pokrýt jde, ji nedostane, a v lidském
review jsou kritéria se značkou jediná, která tam patří. Značku čte strojově brána
`criteria-tests.sh`, proto ji piš doslova; důvod, proč test nejde, smíš připsat
za pomlčku: `(ověří člověk — důvod)`.

**Zaškrtávátka zakládej prázdná.** Odškrtává je orchestrátor (`run-milestone`)
u kritéria, jehož test potvrdil, a ručně spuštěný `verify-issue` podle toho, co sám
ověřil — ne autor a ne implementující agent.

---

## Issue zakládající precedent

Práce, pro kterou v kódu precedent k rozšíření není (`precedent-test.md` vyšel ne),
nemůže být Zadání. Chce-li ji člověk mít v milestonu, vzniká jako issue s pevným
labelem **`precedent`**: zakládá vzor, a ten vzniká v párové session s člověkem,
ne autonomně. `run-milestone` takové issue nespustí, jen ho člověku ohlásí;
`implement-issue` ho odmítne.

- **Label:** název `precedent`, barva `5319e7`, popis „Zakládá vzor — implementuje
  se v párové session, ne orchestrátorem". Je pevný v každém projektu a do výčtu
  `Labely` konfigurace nepatří. Zakládá ho `init-workflow`, chybí-li při
  zakládání issue, `plan-milestone`.
- **Nasazuje ho** `plan-milestone` na přání člověka a `triage-issue`, když precedent
  nenajde; `triage-issue` ho zase sundá, když issue povýší na Zadání. Vedle něj
  nese issue typový a `area:*` label jako každé jiné.
- **Tělo:** stejné nadpisy jako Zadání. `Souhrn` nese i hranice; `Reference`
  smí citovat jen dokument nebo kód, který s prací souvisí, protože precedent
  k rozšíření není; `Akceptační kritéria` smí být prázdná nebo psaná záměrem —
  bránu `run-milestone` tohle issue neprochází. `Závisí na` platí beze změny.
- **Hotové** je, když je PR s `Closes #N` v těle zmergované do integrační větve
  milestonu; issue pak zavře `run-milestone`. Na nový vzor navazuje další vlna
  `plan-milestone`.
