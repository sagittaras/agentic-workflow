# Matice model × effort × maxTurns

> **Rozsah:** Referenční soubor skillu `write-agent`. Platí **výhradně pro agenty** —
> pro volbu `model:`, `effort:` a `maxTurns:` ve frontmatteru zakládaného
> `.claude/agents/<role>.md`. Na skilly se nevztahuje; ty mají vlastní matici.
>
> Fakta o modelech (ceny, kontext, výstup) jsou vědomě duplikovaná ze skillové matice —
> `write-agent` má být použitelný bez `write-skill`. **Při změně ceníku uprav oba soubory.**

```yaml
---
name: qa-lead
description: …
model: opus       # z Tabulky 1
effort: xhigh     # z Tabulky 2
maxTurns: 30      # z Tabulky 3
tools: Read, Grep, Glob, Bash
---
```

**Všechny tři hodnoty definuj vždy explicitně.** Výchozí chování je „zděď po volajícím“,
což znamená, že se tentýž agent chová pokaždé jinak podle toho, kdo ho zavolal. Role
má běžet podle toho, co dělá, ne podle toho, odkud přišla.

**Rozhoduj podle nejtěžší práce, kterou agent dělá sám.** Orchestrátor, který těžkou
část deleguje subagentům, může běžet níž než jeho podřízení — jeho vlastní práce
je rozdělit zadání a složit výsledky.

---

## Tři vstupy rozhodnutí

Než sáhneš do tabulek, odpověz si na tři věci. Každá posouvá volbu jinam a **frekvence
umí přebít náročnost**.

| Vstup | Otázka | Co ovlivňuje |
| --- | --- | --- |
| **Náročnost role** | Kolik úsudku práce vyžaduje, když se nikdo nedívá? | Především `model` |
| **Frekvence spouštění** | Poběží jednou za sprint, nebo po každé změně? | `model` a `effort` směrem dolů |
| **Ohraničenost běhu** | Umíš dopředu odhadnout, kolik kroků to zabere? | `maxTurns` |

---

## Tabulka 1 — Volba modelu

| Model | Sáhni po něm, když… | Typická role | Cena (in/out za 1M) | Nevol, když |
| --- | --- | --- | --- | --- |
| **`haiku`** | Role je mechanická a jednoznačná — „přečti a zařaď“, ne „rozmysli si“. | Štítkovač, inventurník, kontrolor formátu, extraktor polí. | $1 / $5 | Role vyžaduje úsudek nebo práci s nástroji v cyklu. **Nepodporuje `effort:`** — pole vynech. Kontext jen 200K. |
| **`sonnet`** | Role je dobře ohraničená a víš dopředu, jak výsledek vypadá. Zvládne i většinu agentic práce blízko úrovni Opusu. | Průzkumník, specialista v úzké doméně, posuzovatel volaný často. | $3 / $15 | Cena chyby výrazně převyšuje cenu tokenů, nebo je zadání otevřené. |
| **`opus`** | Role má dojet k výsledku sama, přes víc kroků, a rozhodovat se cestou. | Posuzovatel, vykonavatel, orchestrátor. | $5 / $25 | Práce je mechanická (plýtvání), nebo agent běží tak často, že se náklad znásobí. |
| **`fable`** | Opus na téhle roli opakovaně selhal. Vědomé rozhodnutí, ne upgrade „pro jistotu“. | Nejnáročnější reasoning, mnohahodinové autonomní běhy. | $10 / $50 | Kdykoli Opus stačí. Navíc: odezvy v jednotkách až desítkách minut a citlivější bezpečnostní klasifikátory. |

### Poznámky ke schopnostem

- **Kontext:** Haiku 200K, ostatní 1M. Agent, který prochází velkou část repozitáře,
  na Haiku nedojede.
- **Výstup:** Haiku 64K, ostatní 128K tokenů.
- **Agent běží ve vlastním kontextu**, takže limit se počítá jen na jeho práci —
  ne na historii volajícího.

---

## Tabulka 2 — Volba effortu

Effort řídí hloubku uvažování **i celkovou útratu** — počet volání nástrojů a míru
sebeověřování, ne jen délku přemýšlení. Výchozí hodnota je `high`.

| Effort | Sáhni po něm, když… | Jak se agent chová | Nevol, když |
| --- | --- | --- | --- |
| **`low`** | Role je krátká, ohraničená a inteligence není úzké hrdlo. | Málo a sloučených volání nástrojů, stručná potvrzení. Drží se přesně zadání. | Role má víc kroků nebo skryté nástrahy — agent nedomyslí a nikdo ho neopraví. |
| **`medium`** | Chceš ušetřit, ale role není triviální. Rozumný kompromis pro rutinu. | Uvažuje, ale nerozvíjí alternativy nad rámec zadání. | Rozhodnutí agenta se těžko vrací zpět. |
| **`high`** | **Výchozí.** Role je citlivá na kvalitu úsudku, ale ne extrémně náročná. | Vyvážený poměr kvalita/tokeny. | — (bezpečná volba) |
| **`xhigh`** | Kódování a agentic práce. Nejlepší volba pro tuhle třídu rolí. | Hlubší plánování, víc práce s nástroji, důslednější sebeověření. | Role je jednoduchá nebo běží velmi často. |
| **`max`** | Správnost je vzácnější než tokeny a na latenci nezáleží. Výjimečně. | Maximální hloubka. | Cokoli, co běží opakovaně. |

### Poznámky k effortu

- **`haiku` effort nepodporuje** — u `model: haiku` klíč `effort:` vynech.
- **Vyšší effort ≠ vždy dražší celkově.** U dlouhých agentic běhů vyšší effort často
  sníží počet kol, a tím i útratu.
- **Effort neřídí ukecanost reportu.** Když je report rozvláčný, řeš to šablonou
  v těle agenta, ne snižováním effortu.
- **Nízký effort a přísný `maxTurns` se sčítají.** Agent, který málo přemýšlí a má
  málo kroků, skončí nedodělaný — a ty se to dozvíš až z jeho reportu.

---

## Tabulka 3 — Volba maxTurns

`maxTurns` je **pojistka proti zacyklení, ne rozpočet**. Agent běží bez dohledu, takže
zacyklení nikdo nezastaví; zároveň agent, který na strop narazí, se **zastaví
uprostřed práce** a jeho report je neúplný. Strop proto nastavuj s rezervou nad
reálnou potřebu.

| Strop | Pro jakou roli | Znak |
| --- | --- | --- |
| **5–10** | Jednorázová mechanická operace nad známým vstupem | Víš předem, kolik souborů agent otevře |
| **15–30** | Posuzovatel a průzkumník — čte, hodnotí, sepisuje | Rozsah se odvíjí od velikosti změny, ale má strop |
| **30–60** | Vykonavatel — mění soubory a ověřuje si výsledek | Každá oprava stojí několik kol navíc |
| **bez stropu** | Orchestrátor a dlouhoběžná role | Počet kol závisí na tom, co agent cestou najde |

**„Bez stropu“ je platná volba, ale ne výchozí.** Vynechání `maxTurns` zdůvodni
komentářem ve frontmatteru stejně jako každé jiné vynechané pole.

Doplňkově: u role, kde strop reálně hrozí, napiš do těla agenta pokyn **udělat
podstatné nejdřív a průběžně shrnovat** — useknutý běh pak aspoň něco vrátí.

---

## Frekvence spouštění

Táž role vyjde jinak podle toho, jak často běží. Vezmi hodnoty z tabulek výše
a posuň je podle tohoto řádku:

| Frekvence | Typický spouštěč | Posun |
| --- | --- | --- |
| **Jednorázově / zřídka** | Audit, migrace, jednorázové posouzení | Žádný — vol podle náročnosti, klidně `opus` × `xhigh` |
| **Na vyžádání** | Uživatel agenta zavolá, když ho potřebuje | Žádný |
| **Po každé změně** | Orchestrátor volá agenta v každém kole | O stupeň dolů v modelu **nebo** v effortu, ne v obou |
| **Automaticky** | Hook, CI, plánovaný běh | O stupeň dolů v modelu i effortu; zvaž `haiku`, jde-li práci zmechanizovat |

Posun dolů dělej v tom rozměru, který roli bolí míň: u posuzovatele radši sniž effort
než model (úsudek je jádro role), u průzkumníka radši model než effort (šířka záběru
je jádro role).

---

## Rychlý rozhodovací strom

1. **Je práce mechanická a jednoznačná?** → `haiku`, bez effortu, `maxTurns: 5–10`.
2. **Je role ohraničená a víš, jak výsledek vypadá?** → `sonnet` + `medium`/`high`,
   `maxTurns: 15–30`.
3. **Má role dojet k cíli sama, přes víc kroků a nástrojů?** → `opus` + `xhigh`,
   `maxTurns` podle toho, jestli mění soubory (30–60), nebo jen posuzuje (20–30).
4. **Deleguje role těžkou část subagentům?** → o stupeň níž v effortu, `maxTurns`
   vynech.
5. **Poběží po každé změně nebo automaticky?** → aplikuj posun z tabulky frekvence.
6. **Selhal Opus na téhle roli opakovaně?** → teprve pak `fable` + `high`/`xhigh`.

Nejsi-li si jistý mezi dvěma sousedními stupni, vol nižší a nech si zpětnou vazbu
z reálného běhu. Zvednout model je levnější oprava než platit ho zbytečně od začátku.

---

## Osvědčené kombinace podle typu role

| Typ role | Co dělá | Model | Effort | maxTurns | Proč |
| --- | --- | --- | --- | --- | --- |
| **Posuzovatel** | Review, audit, QA — vrací verdikt, nic nemění | `opus` | `xhigh` | 20–30 | Cena přehlédnuté chyby převyšuje cenu tokenů |
| **Posuzovatel na každou změnu** | Totéž, ale volaný v každém kole | `sonnet` | `high` | 15–20 | Frekvence přebíjí náročnost |
| **Vykonavatel** | Implementuje, refaktoruje, opravuje | `opus` | `xhigh` | 40–60 | Změna musí sednout napoprvé; ověřování stojí kola |
| **Orchestrátor** | Rozdělí zadání, deleguje, složí výsledky | `opus` | `high` | — | Těžkou práci dělají subagenti; sám drží kontext |
| **Průzkumník** | Hledá, mapuje, shrnuje — nic nemění | `sonnet` | `medium` | 15–25 | Šířka záběru za rozumnou cenu |
| **Specialista — mechanický** | Úzká doména, deterministická operace | `haiku` | — | 5–10 | Rozhoduje rychlost, ne úsudek |
| **Specialista — s úsudkem** | Úzká doména, ale rozhoduje se v ní | `sonnet` | `high` | 20–30 | Hloubka jen v jedné doméně, ne napříč projektem |

---

## Časté chyby

- **`opus` „pro jistotu“ u každé role.** Průzkumník a většina specialistů je na
  `sonnet` stejně dobrá za zlomek ceny.
- **Vynechaný `model:`/`effort:`.** Agent pak dědí po volajícím a chová se pokaždé
  jinak — přesně to, čemu má vlastní role zabránit.
- **Volba podle délky systémového promptu.** Dlouhé tělo neznamená těžký běh;
  rozhoduj podle práce, kterou agent reálně dělá.
- **`maxTurns` jako rozpočet.** Strop není nástroj na šetření. Šetří se modelem
  a effortem; strop jen brání zacyklení.
- **Ignorovaná frekvence.** Agent na `opus` × `max`, který běží po každém commitu,
  je nejdražší řádek na účtu a nikdo neví proč.
- **`effort:` u `haiku`.** Chyba při běhu.
- **`fable` jako „lepší opus“.** Jiná třída nasazení, ne upgrade — dvojnásobná cena,
  výrazně delší odezvy a přísnější klasifikátory.
