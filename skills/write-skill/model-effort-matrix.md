# Matice model × effort

> **Rozsah:** Referenční soubor skillu `write-skill`. Platí **výhradně pro skilly** — pro
> volbu `model:` a `effort:` ve frontmatteru zakládaného `SKILL.md`. Na agenty, commandy
> ani jiné artefakty se nevztahuje; ty mají svá vlastní pravidla.

Rozhodovací mapa pro volbu modelu a hloubky uvažování při zakládání nového skillu.

```yaml
---
name: nazev-skillu
description: …
model: sonnet     # z Tabulky 1
effort: high      # z Tabulky 2
---
```

**Model i effort definuj vždy explicitně.** Nespoléhej na dědění z volajícího kontextu:
běh skillu se má optimalizovat podle toho, co skill dělá, ne podle toho, kdo ho náhodou
zavolal. Bez explicitního nastavení se tentýž skill chová pokaždé jinak podle toho,
odkud byl spuštěn.

**Rozhoduj podle nejtěžší práce, kterou skill dělá sám** — ne podle své nejsložitější
věty v instrukcích. Pokud skill těžkou část deleguje subagentům, jeho vlastní model
a effort můžou být nižší, než by se z popisu zdálo.

---

## Tabulka 1 — Volba modelu

| Model | Sáhni po něm, když… | Typický profil úkolu | Cena (in/out za 1M) | Nevol, když |
| --- | --- | --- | --- | --- |
| **`haiku`** | Úkol je mechanický, jednoznačný a jde o rychlost nebo objem. Rozhodnutí je „přečti a zařaď“, ne „rozmysli si“. | Klasifikace, extrakce polí, jednořádkové shrnutí, kontrola formátu, hromadné jednoduché operace. | $1 / $5 | Úkol vyžaduje úsudek, víc kroků, nebo práci s nástroji v cyklu. **Nepodporuje `effort:`** — nastavení hodí chybu. |
| **`sonnet`** | Potřebuješ solidní kvalitu za rozumnou cenu u dobře definované práce. Dnes zvládá i většinu agentic a kódových úloh blízko úrovni Opusu. | Průzkum a mapování, rutinní implementace, review dobře ohraničené změny, generování textu podle jasného zadání. | $3 / $15 | Úkol je otevřený, dlouhoběžný, nebo cena chyby výrazně převyšuje cenu tokenů. |
| **`opus`** | Práce je otevřená, vícekroková a autonomní — skill má dojet k výsledku sám a rozhodovat se cestou. | Orchestrace workflow, architektura, refaktory přes víc souborů, hledání netriviálních chyb, dlouhé agentic běhy. | $5 / $25 | Úkol je jednoduchý (plýtvání), nebo jde o čistě mechanickou operaci. |
| **`fable`** | Úkol je za hranicí toho, co Opus zvládne na první dobrou — nejtěžší nevyřešené problémy. Vědomé rozhodnutí, ne upgrade „pro jistotu“. | Nejnáročnější reasoning, mnohahodinové autonomní běhy, práce, kde je odpověď sama o sobě hodnotná. | $10 / $50 | Kdykoliv Opus stačí. Navíc: dlouhé odezvy (jednotky až desítky minut na požadavek), citlivější bezpečnostní klasifikátory (cyber/bio témata mohou skončit odmítnutím). |

### Poznámky ke schopnostem

- **Kontext:** Haiku 200K, ostatní 1M. Pokud skill čte velké množství souborů nebo pracuje
  s dlouhou historií, Haiku je limit.
- **Výstup:** Haiku 64K, ostatní 128K tokenů.
- **`fable`:** starší dokumentace `plugin-dev` ho u frontmatteru ještě neuvádí. Před nasazením
  ověř na jednom skillu, že hodnota zabere.

---

## Tabulka 2 — Volba effortu

Effort řídí hloubku uvažování **i celkovou útratu tokenů** — ne jen délku přemýšlení,
ale i počet volání nástrojů a míru sebeověřování. Výchozí hodnota je `high`.

| Effort | Sáhni po něm, když… | Jak se model chová | Nevol, když |
| --- | --- | --- | --- |
| **`low`** | Skill je krátký, ohraničený a inteligence není úzké hrdlo. Typicky pomocné a servisní skilly. | Méně a sloučenějších volání nástrojů, žádná preambule, stručná potvrzení. Drží se přesně zadání a nedělá nic navíc. | Úloha má víc kroků nebo skryté nástrahy — hrozí, že model nedomyslí. |
| **`medium`** | Chceš ušetřit tokeny a čas, ale úkol není triviální. Rozumný kompromis pro rutinní práci. | Uvažuje, ale nerozvíjí alternativy nad rámec zadání. | Jde o rozhodnutí, které se těžko vrací zpět. |
| **`high`** | **Výchozí.** Práce je citlivá na kvalitu úsudku, ale ne extrémně náročná. | Vyvážený poměr kvalita/tokeny — u většiny úloh sladké místo. | — (je to bezpečná volba) |
| **`xhigh`** | Kódování a agentic práce. **Nejlepší volba pro tuhle třídu úloh** a zároveň výchozí nastavení Claude Code. | Hlubší plánování, víc práce s nástroji, důslednější sebeověření. | Úkol je jednoduchý — investice se nevrátí. |
| **`max`** | Správnost je vzácnější než tokeny a latence nehraje roli. Používej výjimečně. | Maximální hloubka. Může mít klesající výnosy a u jednodušších úloh sklouzává k přemýšlení navíc. | Cokoliv, co běží často nebo interaktivně. |

### Poznámky k effortu

- **Haiku effort nepodporuje** — u `model: haiku` klíč `effort:` vynech.
- **Vyšší effort ≠ vždy dražší celkově.** U dlouhých agentic běhů vyšší effort často
  sníží počet kol a tím i celkovou útratu; u krátkých skillů ji jen zvýší.
- **Effort neřídí délku výstupu.** Když je výstup skillu ukecaný, řeš to instrukcí
  v těle `SKILL.md`, ne snižováním effortu.
- **`xhigh`/`max` potřebují prostor** — přemýšlení se započítává do stejného rozpočtu
  jako odpověď.

---

## Rychlý rozhodovací strom

1. **Dělá skill mechanickou, jednoznačnou operaci?** → `haiku`, bez effortu.
2. **Je zadání dobře ohraničené a víš dopředu, jak výsledek vypadá?** → `sonnet` + `medium`/`high`.
3. **Má skill dojet k cíli sám, přes víc kroků a nástrojů?** → `opus` + `xhigh`.
4. **Selhal Opus na tomhle typu skillu opakovaně?** → teprve pak `fable` + `high`/`xhigh`.

Pokud si nejsi jistý mezi dvěma sousedními stupni, vol ten nižší a nech si zpětnou vazbu
z reálného běhu — zvednout model nebo effort je levnější oprava než platit ho zbytečně od začátku.

---

## Osvědčené kombinace

| Typ skillu | Model | Effort | Proč |
| --- | --- | --- | --- |
| Orchestrace workflow, řídí víc fází | `opus` | `xhigh` | Dlouhý běh, deleguje, drží kontext přes celou úlohu. |
| Průzkum a mapování kódu | `sonnet` | `medium` | Šířka záběru za rozumnou cenu; není třeba hluboký úsudek. |
| Review / hledání chyb | `opus` | `xhigh` | Cena přehlédnuté chyby výrazně převyšuje cenu tokenů. |
| Zásah do kódu (generování, refaktor) | `opus` | `xhigh` | Změna musí sedět napoprvé. |
| Inventura, klasifikace, štítkování | `haiku` | — | Mechanická operace, rozhoduje rychlost. |
| Copywriting podle zadaného briefu | `sonnet` | `high` | Kvalita textu ano, hluboký reasoning ne. |
| Strategie / koncepční návrh | `opus` | `high` | Otevřené zadání, ale ne dlouhoběžná exekuce. |
| Formátování, převod, šablonování | `haiku` | — | Deterministická transformace bez úsudku. |

---

## Časté chyby

- **Volba `opus` „pro jistotu“ u každého skillu.** Většina pomocných skillů je na `sonnet`
  stejně dobrá za zlomek ceny.
- **Vynechaný `model:`/`effort:` ve frontmatteru `SKILL.md`.** Skill pak dědí nastavení
  volajícího a chová se pokaždé jinak. Vždy je uveď explicitně.
- **Volba podle složitosti instrukcí místo podle vykonávané práce.** Dlouhý `SKILL.md`
  neznamená těžký běh — rozhoduj podle toho, co skill reálně dělá.
- **`effort: max` jako výchozí.** Vede k přemýšlení navíc u triviálních úloh.
- **`effort:` u `haiku`.** Chyba při běhu.
- **Snaha řídit ukecanost přes effort.** Nefunguje spolehlivě — patří to do promptu.
- **`fable` jako „lepší opus“.** Je to jiná třída nasazení, ne upgrade — dvojnásobná cena,
  výrazně delší odezvy a přísnější klasifikátory.
