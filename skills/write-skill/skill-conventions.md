# Konvence psaní skillů

> **Rozsah:** Referenční soubor skillu `write-skill`. Závazné konvence pro zakládání
> a úpravu skillů v pluginech Sagittaras. Volbu `model:` a `effort:` řeší
> [model-effort-matrix.md](model-effort-matrix.md).

---

## 1. Přesnost pojmenování

Základní tvar je **`<činnost>-<předmět>`** — sloveso v infinitivu, pak jedno slovo označující,
na čem se pracuje.

```
write-skill      create-pr      make-commit      review-changes
```

Jméno skillu je první věc, podle které se Claude rozhoduje, jestli si ho vůbec načíst.
Substantivní název („skill-writer“, „pr-helper“) popisuje *co to je*; slovesný název
popisuje *co to udělá* — a rozhodnutí se dělá právě podle akce.

| Pravidlo | Detail |
| --- | --- |
| Tvar | `<činnost>-<předmět>`, sloveso vždy první |
| Znaky | jen malá písmena, číslice a pomlčka; začíná i končí alfanumericky |
| Délka | 3–50 znaků, ideálně dvě slova |
| Číslo | předmět v jednotném čísle — `create-pr`, ne `create-prs` |
| Shoda | název složky = hodnota `name:` ve frontmatteru |
| Unikátnost | v rámci pluginu unikátní; napříč pluginy řeší namespace `plugin:skill` |

**Vol konkrétní sloveso.** Sloveso nese většinu informace, takže na něm záleží víc než
na předmětu:

| Sloveso | Kdy |
| --- | --- |
| `write` / `create` | vzniká nový artefakt |
| `make` | vzniká výstup jako vedlejší efekt akce (`make-commit`) |
| `review` / `check` | posuzuje se existující stav, nic se nemění |
| `update` / `sync` | mění se existující artefakt |
| `run` / `build` | spouští se proces |

**Čemu se vyhnout:**

- **Obecná slovesa** — `handle-`, `process-`, `manage-`, `do-`. Nic neříkají o výsledku.
- **Substantivní tvary** — `skill-writer`, `commit-helper`, `pr-utils`.
- **Opakování názvu pluginu** — ve `sagittaras/skills/` nedává `sagittaras-write-skill` smysl,
  namespace se doplní sám.
- **Zkratky a interní žargon** — jméno čte model, ne jen ty.
- **Tři a víc slov** — obvykle znamená, že skill dělá víc věcí a patří rozdělit.

---

## 2. Frontmatter matters

Frontmatter není hlavička, je to **konfigurace běhu**. Rozhoduje o tom, jestli se skill
spustí, s jakým modelem, jakou hloubkou uvažování a s jakými právy. Špatně napsaný
frontmatter znamená skill, který se buď nespustí nikdy, nebo se spouští pořád.

### Povinné minimum

Každý skill má vždy všech pět polí. Žádné z nich není volitelné a žádné se nenechává
na dědění z volajícího kontextu.

| Pole | Účel | Pravidla |
| --- | --- | --- |
| `name` | Identifikátor a namespace | Shodné s názvem složky; viz kapitola 1 |
| `description` | **Co skill dělá** — věcný popis schopnosti | Třetí osoba, konkrétně, bez „použij když“ |
| `when_to_use` | **Kdy po něm sáhnout** — spouštěcí situace a fráze | Konkrétní situace i formulace uživatele; uveď i kdy skill *nepoužívat* |
| `model` | Který model skill obsluhuje | Explicitně, dle [matice](model-effort-matrix.md) |
| `effort` | Hloubka uvažování | Explicitně, dle [matice](model-effort-matrix.md); u `haiku` vynech |

> **Sdílený limit:** `description` a `when_to_use` se v listingu skillů spojují a dělí se
> o rozpočet **1 536 znaků**. Obě pole proto piš úsporně — každý znak navíc v jednom ubírá
> prostor druhému. Když se do limitu nevejdeš, je to signál, že skill dělá víc věcí najednou.

### `description` vs `when_to_use`

Rozdíl je v otázce, na kterou pole odpovídá:

- **`description` → „Co to je?“** Věcný popis schopnosti a výstupu. Píše se tak,
  aby dávalo smysl i vytržené z kontextu, v katalogu skillů.
- **`when_to_use` → „Kdy to zavolat?“** Situace, ve kterých je skill správná odpověď,
  včetně frází, které uživatel reálně řekne — a hranice, kde už správná odpověď není.

```yaml
description: >
  Založí nový skill v pluginu — vytvoří složku, SKILL.md s kompletním frontmatterem
  a doprovodné reference. Výstupem je skill připravený k použití, ověřený proti
  konvencím pluginu.

when_to_use: >
  Použij, když uživatel chce založit nový skill nebo upravit existující — „vytvoř skill“,
  „přidej skill na X“, „napiš mi skill“, „uprav frontmatter skillu“. Nepoužívej pro
  zakládání agentů ani commandů; ty mají vlastní pravidla.
```

**Časté chyby v obou polích:**

- **Druhá osoba a meta-formulace** — „Load this skill when…“, „Tento skill ti pomůže…“.
  Piš ve třetí osobě o tom, co se stane.
- **Vágnost** — „pomáhá s prací se soubory“ nespustí nic. Konkrétní sloveso, konkrétní výstup.
- **Chybějící spouštěcí fráze** — bez formulací, které uživatel reálně použije,
  se skill nenačte, i když by byl správný.
- **Chybějící negativní vymezení** — pokud existují dva podobné skilly, každý musí
  ve `when_to_use` říct, kde končí jeho pole působnosti.
- **Vlepení celého návodu do `description`** — popis není tělo skillu.

### Ostatní parametry — vždy zvaž

Nejsou povinné, ale u každého skillu se má vědomě rozhodnout, jestli je potřeba.
Nezvážené vynechání je stejná chyba jako špatná hodnota.

| Pole | Kdy nastavit |
| --- | --- |
| `allowed-tools` | Skill má mít užší práva než session. **Zvaž vždy** — zejména u skillů, které nic nemění (`Read, Grep, Glob`), a u těch, které naopak sahají na systém. |
| `disallowed-tools` | Skill práva nezužuje výčtem, **nebo** drží invariant, který musí platit i tam, kde se `allowed-tools` neuplatní. Rozhoduje způsob spuštění — viz níže. |
| `user-invocable` | Skill má/nemá být volatelný přes `/nazev`. Nastav `false` u servisních skillů, které volají jiné skilly a uživatel je nemá vidět v nabídce. |
| `disable-model-invocation` | Skill smí spustit jen uživatel explicitně, ne model sám. Pro drahé, dlouhé nebo nevratné operace. |
| `argument-hint` | Skill přijímá argumenty — napovídá jejich tvar při volání. |
| `version` | Skill se verzuje a je na něj závislost odjinud. |
| `license` | Skill se distribuuje mimo interní použití. |

#### `disallowed-tools` vedle uzavřeného `allowed-tools`

Obojí najednou vypadá jako duplicita a většinou jí je: nástroj, který není ve výčtu,
stejně k dispozici není. Rozhoduje ale to, **kdo skill spouští**:

- **Skill se vždy spouští loaderem** (nástroj `Skill`, `/název`) → frontmatter se
  uplatní celý. `disallowed-tools` vynech a vynechání zdůvodni komentářem.
- **Skill si může načíst subagent jako soubor** — typicky reviewery ve smyčce
  `write-skill` a `write-agent` — → na uplatnění `allowed-tools` nespoléhej.
  Vypiš do `disallowed-tools` ten jeden invariant, který musí platit vždycky;
  u recenzentů je to `AskUserQuestion`, protože doptávat se nemá koho.

Nikdy tam nevypisuj celý zbytek katalogu nástrojů. Pole nese invariant, ne zrcadlo
`allowed-tools` — dva výčty téhož se dřív nebo později rozejdou a platit bude ten,
o kterém se zapomnělo, že existuje.

---

## 3. Tělo skillu

Strukturu těla nese **[skill-template.md](skill-template.md)** — kostra k okopírování
včetně frontmatteru, s pokyny v placeholderech a s tabulkou povinných a volitelných sekcí.
Šablonu otevři vždy, než začneš psát; tato kapitola jen shrnuje principy, na kterých stojí.

- **Instrukce, ne dokumentace.** Skill říká, co má Claude udělat, ne co daná technologie je.
  Vynech všechno, co model už umí sám od sebe.
- **Rozkazovací způsob a vysvětlené proč.** „Načti konfiguraci, ověř formát“ — ne „měl bys
  načíst“. U instrukcí, které nejsou samozřejmé, připoj důvod: instrukci s důvodem model
  dodrží spolehlivěji než holý příkaz.
- **Progresivní odkrývání.** Do `SKILL.md` patří postup a rozhodování, objemný materiál
  do vedlejších souborů. Každý odkaz musí říct, **kdy** se má soubor otevřít.
- **Jedna odpovědnost.** Když se postup rozpadá na dva nesouvisející sledy kroků,
  jsou to dva skilly.

---

## 4. Kontrolní seznam před dokončením

- [ ] Název ve tvaru `<činnost>-<předmět>`, sloveso konkrétní, složka i `name:` se shodují
- [ ] `description` odpovídá na „co to je“, `when_to_use` na „kdy to zavolat“ — nepřekrývají se
- [ ] `when_to_use` obsahuje reálné uživatelské fráze i negativní vymezení
- [ ] `description` + `when_to_use` se dohromady vejdou do 1 536 znaků
- [ ] `model` a `effort` nastavené explicitně podle matice, `effort` vynechaný u `haiku`
- [ ] Ostatní parametry vědomě zvážené — hlavně `allowed-tools` a `user-invocable`
- [ ] Tělo odpovídá [šabloně](skill-template.md): povinné sekce vyplněné, značky
      `(volitelné)` odstraněné, placeholdery nahrazené
- [ ] Tělo v rozkazovacím způsobu, bez obecné dokumentace, u neobvyklých instrukcí
      vysvětlené proč
- [ ] Detaily odsunuté do referencí, každý odkaz říká, kdy soubor otevřít
- [ ] Skill má jednu odpovědnost
