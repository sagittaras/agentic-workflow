# Šablona SKILL.md

> **Rozsah:** Referenční soubor skillu `write-skill`. Kostra, podle které se píše každý
> nový skill. Pravidla a jejich odůvodnění nese [skill-conventions.md](skill-conventions.md),
> volbu `model` × `effort` [model-effort-matrix.md](model-effort-matrix.md) — při rozporu
> mají tyto dokumenty přednost před šablonou.

Šablona míří na **procedurální skilly** (skill = činnost). Čistě znalostní nebo referenční
skill, který žádnou činnost neprovádí, se touto kostrou neřídí.

## Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď skutečným obsahem a závorky odstraň.
  Text uvnitř závorek je pokyn, co do místa patří — ne text k opsání.
- Sekce označené `(volitelné)` vynech, pokud pro daný skill nedávají smysl. Značku
  `(volitelné)` v hotovém skillu nikdy nenechávej.
- Ostatní sekce vyplň vždy, i kdyby jen jednou větou.
- Obsah piš česky, identifikátory anglicky.

---

## Kostra

````markdown
---
name: [<činnost>-<předmět>, kebab-case, shodné s názvem složky]
description: >-
  [Co skill dělá — věcně, třetí osoba, bez trigger frází. Musí dávat smysl
  i vytržené z kontextu, v katalogu skillů.]
when_to_use: >-
  [Kdy skill spustit: konkrétní situace a fráze, které uživatel reálně řekne.
  Povinnou součástí je negativní vymezení — „Nepoužívej pro…, na to slouží…" —
  vůči každému sousednímu skillu, se kterým by mohl kolidovat.
  Pozor: description a when_to_use sdílejí rozpočet 1 536 znaků.]
model: [tier dle matice: haiku | sonnet | opus | fable]
effort: [úroveň dle matice: low | medium | high | xhigh]
# Zařazení dle matice: [kategorie úlohy] → [model] × [effort], [bez odchylky |
# odchylka o stupeň, protože…].
# Vynechaná zvažovaná pole: [pole — důvod; pole — důvod]. [Vypiš každé
# netriviální pole, které jsi nepoužil, i s důvodem. Čtenář se tak za rok
# dozví, že šlo o rozhodnutí, ne o opomenutí.]
[Zvažovaná pole, která skill skutečně používá — argument-hint, allowed-tools,
user-invocable, disable-model-invocation, context, paths, shell a další.]
---

# [Název Skillu Title Case]

[1–3 věty: co je cílem skillu a podle čeho se řídí. Pojmenuj závazný kontrakt
(konvence pluginu) a řekni, že má při rozporu přednost. Nepopisuj, co model
umí sám od sebe.]

## Vstupní kontext (volitelné)

[Hodnoty, které se injektují automaticky při spuštění — zadání uživatele
a výstupy bezpečných, deterministických příkazů (aktuální větev, stav
pracovního stromu, existující artefakty). Syntaxi injektáže opiš z existujícího
skillu; nikdy ji nepiš doslovně do instrukcí ani do inline kódu — loader ji
vyhodnocuje kdekoli v textu a pokusil by se ji spustit.

Sekci vynech, když skill nemá co injektovat.]

## Postup

[Číslované kroky v pořadí, ve kterém se provádějí. Každý krok je jedna
soudržná fáze — ne jeden příkaz. Piš rozkazovacím způsobem a u instrukcí,
které nejsou samozřejmé, **vysvětli proč**: instrukci s důvodem model dodrží
spolehlivěji než holý příkaz, a rigidní příkaz bez vysvětlení je signál
slabého návrhu.]

### 1. [Název kroku]

[Co se v kroku děje. Kde formát výstupu není zřejmý, dej doslovnou ukázku
nebo šablonu. Kde hrozí typická chyba, pojmenuj ji i s důsledkem.]

### 2. [Název kroku]

[…]

### N. Eskalace (volitelné)

[U skillů, které běží autonomně: kdy postup přerušit a obrátit se na uživatele.
Vyjmenuj konkrétní podmínky — ne „když si nejsi jistý". Připoj pokyn, že
eskalace shrne stav a položí konkrétní otázku.

Sekci vynech u skillů, které běží plně interaktivně.]

## Formát výstupu (volitelné)

[Doslovná šablona výstupu, když má pevný tvar — commit message, tělo PR,
struktura generovaného dokumentu, komentář. Placeholdery ve stejné notaci
jako tady.

Sekci vynech, když výstupem je jen odpověď v konverzaci.]

## Zásady

[3–6 invariantů, které platí napříč celým postupem a nepatří do žádného
konkrétního kroku: co má přednost při rozporu, kde jsou hranice skillu, co
se nikdy nedělá. Ne shrnutí kroků — to, co by šlo při čtení postupu shora
dolů přehlédnout.]
````

---

## Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| Frontmatter | ✅ | Konfigurace běhu + komentáře nesoucí rozhodnutí | Vynechané zvažované pole bez zdůvodnění |
| `# Nadpis` + úvod | ✅ | Cíl skillu a závazný kontrakt, 1–3 věty | Rozepsaný úvod opakující `description` |
| `## Vstupní kontext` | ⬜ | Automaticky injektované hodnoty | Doslovný zápis injektážní syntaxe v textu |
| `## Postup` | ✅ | Číslované fáze v pořadí provádění | Kroky bez zdůvodnění; jeden krok = jeden příkaz |
| `### N. Eskalace` | ⬜ | Konkrétní podmínky přerušení u autonomních skillů | Mlhavé „když si nejsi jistý" |
| `## Formát výstupu` | ⬜ | Doslovná šablona výstupu s pevným tvarem | Popis tvaru místo ukázky |
| `## Zásady` | ✅ | Invarianty napříč postupem | Shrnutí kroků místo invariantů |

### Rozsah a odkazy

- **Tělo drž stručné.** Objemný materiál — šablony, referenční tabulky, skripty — patří
  do vedlejších souborů, na které se odkážeš. Načítá se pak jen to, co je potřeba.
- **Každý odkaz musí říct, kdy soubor otevřít**, ne jen že existuje. „Podrobnosti
  v `references/api.md`" je slabý odkaz; „Před psaním dotazu si přečti
  `references/api.md`" je pokyn.
- **Jedna odpovědnost.** Když se `## Postup` rozpadá na dva nesouvisející sledy kroků,
  jsou to dva skilly.
