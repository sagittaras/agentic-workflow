# Šablona rule

> **Rozsah:** Referenční soubor skillu `write-rule`. Kostra, podle které se píše každý
> soubor v `.claude/rules/`. Pravidla a jejich odůvodnění nese
> [rule-conventions.md](rule-conventions.md) — při rozporu má přednost ono.

## Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď skutečným obsahem a závorky odstraň.
  Text uvnitř závorek je pokyn, co do místa patří — ne text k opsání.
- Sekce označené `(volitelné)` vynech, pokud pro danou rule nedávají smysl. Značku
  `(volitelné)` v hotovém souboru nikdy nenechávej.
- Jazyk obsahu převezmi z cílového projektu; identifikátory a ukázky kódu anglicky.

---

## Kostra

````markdown
---
paths:
  - "[glob, nejužší, který téma pokryje]"
  - "[další glob, pokud téma leží ve víc místech]"
---

# [Téma v nadpisu — odpovídá názvu souboru]

[Volitelně jedna věta, když z názvu není zřejmé, čeho se pravidla týkají
a proč existují. Nepiš úvod, který jen opakuje nadpis.]

- [Pravidlo — normativně, konkrétně, ověřitelně pohledem na kód]
- [Pravidlo, u kterého není důvod zřejmý — a proto: proč]
  - [Upřesnění nebo výčet hodnot, když pravidlo samo o sobě nestačí]
- [Pravidlo]

## Příklady (volitelné)

**Správně** — [čeho se ukázka týká]:

```[jazyk]
[Kód z tohoto projektu, ne obecný. Krátký: ukazuje jednu věc.]
```

**Špatně**:

```[jazyk]
[Tentýž případ porušující pravidlo.]
```

[Jedna věta: co konkrétně je porušené a co se tím rozbije.]
````

---

## Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| `paths` ve frontmatteru | ⬜ | Globy vymezující, kdy se rule načte | Široký glob typu `**/*`; neověřený vzor, který nematchuje nic |
| `# Nadpis` | ✅ | Téma, shodné s názvem souboru | Nadpis obecnější než obsah |
| Úvodní věta | ⬜ | Proč pravidla existují, když to není zřejmé | Odstavec vysvětlující, co je daná technologie |
| Odrážky s pravidly | ✅ | Jedno vymahatelné pravidlo na odrážku | Vágní formulace, u níž nejde poznat porušení |
| `## Příklady` | ⬜ | Dvojice správně/špatně u pravidel popsatelných hůř slovy než kódem | Obecná ukázka odjinud; ukázka na pravidlo, které je slovy jasné |

### Rozsah

- **Kratší je lepší.** Rule bez `paths` sedí v kontextu každé session; rule s `paths`
  v každé session, která sáhne na odpovídající soubor. Nad zhruba padesát řádků
  se ptej, jestli nejde o dvě témata a tedy dva soubory.
- **Bez frontmatteru se rule načítá vždy.** Chybějící `paths` je rozhodnutí, ne
  vynechání — a musí odpovídat tomu, že pravidla platí napříč celým repozitářem.
