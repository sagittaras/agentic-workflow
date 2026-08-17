# Šablona agenta

> **Rozsah:** Referenční soubor skillu `write-agent`. Kostra, podle které se píše každý
> nový agent. Pravidla a jejich odůvodnění nese [agent-conventions.md](agent-conventions.md),
> volbu `model` × `effort` × `maxTurns` [agent-model-matrix.md](agent-model-matrix.md) —
> při rozporu mají tyto dokumenty přednost před šablonou.

Šablona míří na **role-agenty** — do `.claude/agents/` cílového projektu i do složky
`agents/` pluginu: agent drží obor, běží ve vlastním kontextu a vrací report.
Pro jednorázový postup, který nevyžaduje úsudek, se agent nepíše — patří to do skillu.

## Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď skutečným obsahem a závorky odstraň.
  Text uvnitř závorek je pokyn, co do místa patří — ne text k opsání.
- Sekce označené `(volitelné)` vynech, pokud pro daného agenta nedávají smysl. Značku
  `(volitelné)` v hotovém agentovi nikdy nenechávej.
- Ostatní sekce vyplň vždy, i kdyby jen dvěma větami.
- **Kostru reportu neměň** — je závazná napříč všemi agenty a definuje ji konvence.
  Přizpůsobuje se jen volná část uvnitř ní.
- Obsah piš česky, identifikátory anglicky.

---

## Kostra

````markdown
---
name: [<obor>-<role>, kebab-case, shodné s názvem souboru, bez dvojtečky]
description: >-
  [Trojdílně, každý díl jednou větou: (1) co agent vlastní — obor a výstup,
  třetí osoba; (2) kdy ho zavolat — konkrétní situace; (3) kdy ne — negativní
  vymezení vůči sousednímu agentovi nebo skillu. Třetí díl je povinný.]
model: [tier dle matice: haiku | sonnet | opus | fable]
effort: [úroveň dle matice: low | medium | high | xhigh | max; u haiku pole vynech]
maxTurns: [strop dle matice; vynech u orchestrátorů a dlouhoběžných rolí]
tools: [explicitní výčet toho, co role skutečně potřebuje — práva musí sedět
  na mandát z těla; agent, který má delegovat, nesmí mít Write a Edit]
# Zařazení dle matice: [typ role] → [model] × [effort] × [maxTurns],
# frekvence spouštění [jak často], [bez posunu | posun o stupeň, protože…].
# Vynechaná zvažovaná pole: [pole — důvod; pole — důvod]. [Vypiš každé
# netriviální pole, které jsi nepoužil, i s důvodem — memory, maxTurns,
# background, isolation, color, skills, disallowedTools a další. Čtenář
# se tak za rok dozví, že šlo o rozhodnutí, ne o opomenutí.]
[Zvažovaná pole, která agent skutečně používá — memory, background, isolation,
color, skills, disallowedTools, initialPrompt a další.]
---

# [Název Role Title Case]

[2–4 věty ve druhé osobě, které zakládají identitu: kým jsi na tomto projektu,
jaký obor vlastníš a čí slovo platí, když se názory rozejdou. Identita
rozhoduje v situacích, které postup nepokrývá — proto ji nepiš jako popis
schopností, ale jako mandát. Pojmenuj, co má při rozporu přednost před tímto
souborem, ale **druhem, ne jménem souboru** („zadání od volajícího“, „co máš
v paměti o tomto projektu“) — na konkrétní dokumenty repozitáře se agent
neodkazuje, ty patří do jeho paměti přes skill `train-agent`.]

## Vstupní kontrakt

[Co dostaneš v promptu, kterým tě volající spustil — a co uděláš, když to
nedostaneš. Startuješ s čistým kontextem: co ti volající nepředá, pro tebe
neexistuje, a domýšlet si to je horší než to pojmenovat.

Vyjmenuj konkrétně, co zadání obsahuje, a u každé chybějící položky řekni,
jestli se dá dopočítat z projektu, nebo je sama o sobě důvodem skončit
a zapsat to do reportu.]

## Postup

[Číslované fáze v pořadí provádění, rozkazovacím způsobem. Každá fáze je jeden
soudržný celek, ne jeden příkaz. U instrukcí, které nejsou samozřejmé,
**vysvětli proč** — instrukci s důvodem model dodrží spolehlivěji než holý
příkaz.

Postup, který už existuje jako skill, nepřepisuj — zavolej ho a řekni kdy.
Dvě kopie téhož postupu se rozejdou a nikdo si toho nevšimne.]

### 1. [Název fáze]

[Co se ve fázi děje. Kde formát není zřejmý, dej doslovnou ukázku. Kde hrozí
typická chyba, pojmenuj ji i s důsledkem.]

### 2. [Název fáze]

[…]

## Hranice

[Co agent zásadně nedělá — a u každé položky **co udělá místo toho**. Agent
nemá koho se zeptat: „vyžádej si schválení" je nevymahatelný pokyn, který
skončí buď předstíraným souhlasem, nebo zaseknutím. Náhradou je vždy zápis
do reportu.]

| Nedělá | Místo toho |
| --- | --- |
| [zakázaná akce] | [co udělá — obvykle: zapiš do „Čeho jsem se nedotkl" a pokračuj / skonči] |

## Delegace (volitelné)

[Pouze u agenta, který má v `tools` nástroj `Agent`. U ostatních sekci vynech
celou — mapa návazností bez nástroje na delegování je fikce, kterou nemá co
vymáhat.

U každého podřízeného agenta uveď: koho voláš, s jakým zadáním a co od něj
čekáš zpět. Doplň, jestli běh čeká na výsledek, nebo pokračuje.]

## Formát výstupu

[Doslovná kostra reportu — okopíruj ji z kapitoly „Report" v konvenci beze
změny. Přizpůsob jen volnou část: buď nahraď obsah sekce „Co jsem udělal"
tvarem, který sedí roli (tabulka nálezů u posuzovatele, seznam změněných
souborů u vykonavatele), nebo za ni vlož vlastní podsekci. Ostatní sekce
kostry ani jejich pořadí neměň.]

## Zásady

[3–6 invariantů, které platí napříč celým postupem a nepatří do žádné
konkrétní fáze: co má přednost při rozporu, kde končí mandát role, co se
nikdy nedělá. Ne shrnutí kroků — to, co by šlo při čtení shora dolů
přehlédnout.]
````

---

## Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| Frontmatter | ✅ | Konfigurace běhu, hranice práv a komentáře nesoucí rozhodnutí | Zděděný `model`/`effort`; `tools` širší než mandát |
| `# Nadpis` + persona | ✅ | Mandát role ve 2. osobě, 2–4 věty | Popis osobnosti („zkušený senior s citem pro detail“) místo odpovědnosti; odkaz na konkrétní dokument projektu místo paměti |
| `## Vstupní kontrakt` | ✅ | Co přijde v promptu a co při chybějícím zadání | Předpoklad, že agent vidí historii volajícího |
| `## Postup` | ✅ | Číslované fáze rozkazovacím způsobem | Opsané kroky skillu, který už existuje |
| `## Hranice` | ✅ | Zákazy s náhradním chováním | „Zeptej se uživatele“ — agent nemá koho |
| `## Delegace` | ⬜ | Koho agent volá a co od něj čeká | Sekce u agenta bez nástroje `Agent` |
| `## Formát výstupu` | ✅ | Závazná kostra reportu s přizpůsobenou volnou částí | Změněná nebo zkrácená kostra |
| `## Zásady` | ✅ | Invarianty napříč postupem | Shrnutí kroků místo invariantů |

Proti šabloně skillu tu **přibývá persona a `## Hranice`**, `## Vstupní kontrakt`
a `## Formát výstupu` jsou povinné (u skillu volitelné) a **mizí eskalace** — agent
nemá komu eskalovat, náhradou je sekce „Čeho jsem se nedotkl“ v reportu.

### Rozsah a odkazy

- **Tělo drž stručné.** Objemný materiál — kontrolní seznamy a referenční tabulky —
  patří do doprovodných souborů nebo do skillů, na které se odkážeš. Systémový prompt
  agenta se načítá celý při každém spuštění, takže každý řádek navíc se platí pokaždé.
- **Znalost projektu do těla nepatří.** Konvence, rozhodnutí a vzorce cílového projektu
  jdou do paměti agenta, kterou plní skill `train-agent` — v definici by zastaraly
  a nešly by opravit jinak než její úpravou.
- **Neodkazuj na dokumenty repozitáře ani na `.claude/rules/`.** Dokumenty se přejmenují
  a definice o tom neví; rules se do kontextu načtou samy. Viz kapitolu „Na co se agent
  neodkazuje“ v [konvencích](agent-conventions.md).
- **Každý odkaz, který v těle zůstane, musí říct, kdy soubor otevřít**, ne jen
  že existuje.
- **Jedna role.** Když se `## Postup` rozpadá na dvě nesouvisející odpovědnosti,
  jsou to dva agenti.
