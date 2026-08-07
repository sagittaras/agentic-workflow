# Konvence paměti agenta

> **Rozsah:** Referenční soubor skillu `train-agent`. Závazný tvar trvalé paměti agenta —
> kde leží, jak je členěná a co do ní patří. Platí pro agenty psané podle
> [agent-conventions.md](../write-agent/agent-conventions.md); doplňuje je o to, co se
> do statické definice nevejde.

---

## 1. Kde paměť leží a odkud se bere přístup

Paměť je složka pojmenovaná po agentovi. Kterou z nich agent dostane, určuje hodnota
`memory:` v jeho frontmatteru:

| `memory:` | Složka | Kdy |
| --- | --- | --- |
| `project` | `.claude/agent-memory/<agent>/` | Výchozí volba — znalost je vázaná na projekt a má se verzovat |
| `local` | `.claude/agent-memory-local/<agent>/` | Znalost je projektová, ale nemá jít do repozitáře |
| `user` | `~/.claude/agent-memory/<agent>/` | Agent není vázaný na jeden projekt |

**Bez pole `memory:` agent žádnou paměť nemá** a zápis do těch složek mu neprojde.
Doplnit ho je úprava definice agenta — patří do `write-agent`, ne sem.

Zápisové právo navíc platí **jen tehdy, když skutečně běží jako ten agent** — tedy
když ho někdo spustil nástrojem Agent s `subagent_type` rovným jeho jménu. Načtení
jeho definice do cizího kontextu právo nezakládá. Proto paměť plní agent sám a nikdo
za něj.

---

## 2. `MEMORY.md` je index, ne úložiště

`MEMORY.md` se agentovi načítá do kontextu **při každém spuštění**. Je to tedy rozpočet,
ne skladiště: každý řádek se platí pokaždé, i když se téma nikdy neotevře.

```markdown
# <Role> memory

## <Tematická skupina>

- [Titulek záznamu](nazev-souboru.md) — háček: co se z něj dozvím a kdy to potřebuju
- [Další záznam](jiny-soubor.md) — háček
```

- **Jeden řádek na záznam.** Háček musí říct, *kdy* soubor otevřít — „detaily o testech“
  je slabý háček, „kdy test patří do behaviour a kdy do paradigm“ je dobrý.
- **Seskupuj do sekcí**, jakmile záznamů přibude nad deset. Bez sekcí se index čte hůř
  než složka.
- **Strop je ~200 řádků / 25 KB.** Blížíš-li se k němu, neškrtej záznamy — přesuň detail
  z indexu do souborů a zkrať háčky.
- **Do indexu nikdy nepiš obsah záznamu.** Index odkazuje, soubor nese.

---

## 3. Tematický soubor

Jeden soubor = jedno téma, které jde otevřít samostatně a dává smysl bez zbytku paměti.

```markdown
---
name: <kebab-case, shodné s názvem souboru bez přípony>
description: <jedna věta — podle ní se agent rozhoduje, jestli soubor otevřít>
metadata:
  type: decision | convention | pitfall | reference
---

<Jádro: co platí. Konkrétně, s doslovnými názvy, cestami a čísly — obecná
formulace se za půl roku nedá použít.>

<Doklad: kde se to vzalo nebo kde se to projevilo. „Viděno na PR #74, kolo 3"
váží víc než tvrzení bez původu.>

**Why:** <proč to tak je — bez důvodu se pravidlo při první kolizi poruší>

**How to apply:** <kdy přesně na to sáhnout, a čeho se to netýká>
```

Typy záznamů:

| `type` | Co nese |
| --- | --- |
| `decision` | Co bylo rozhodnuto a platí — typicky z ADR nebo specifikace |
| `convention` | Jak se to na tomhle projektu dělá, i když to nikde není rozhodnuté |
| `pitfall` | Co se snadno pokazí, a jak to poznat dřív než po havárii |
| `reference` | Kde co leží — cesty, nástroje, odkazy |

**Odkazy mezi záznamy piš `[[nazev-souboru]]`** a odkazuj štědře. Odkaz na záznam,
který ještě neexistuje, není chyba — je to poznámka, že téma za sepsání stojí.

---

## 4. Co do paměti patří

Paměť je pro to, **co agentovi změní chování příště**. Nic jiného.

**Patří tam:**

- rozhodnutí, která platí a agent se jimi má řídit;
- vzorce, na které opakovaně naráží — chyby, které dělá, i pasti, které přehlíží;
- konvence projektu, které z kódu nejsou zřejmé;
- ukazatele na místa, která by jinak hledal znovu.

**Nepatří tam:**

- **převyprávění vstupu.** Paměť není souhrn dokumentu; dokument zůstává v repu a dá se
  přečíst. Do paměti jde jen to, co se týká role toho agenta.
- **otevřené otázky a návrhy.** Dokud není rozhodnuto, není co si pamatovat — zapsaná
  varianta se čte jako platná.
- **co agent zjistí přečtením kódu.** Paměť má nést to, co v kódu není.
- **co už v paměti je.** Viz kapitola 5.
- **domněnky.** Nevymýšlej a nedoplňuj, co ve vstupu nestojí.

---

## 5. Konsolidace

Paměť se nejen plní, ale i udržuje — jinak naroste duplicitami a agent začne jednat
podle nepravdy. Před každým zápisem projdi, co už v paměti je, a rozhodni:

| Situace | Co udělat |
| --- | --- |
| Téma je nové | Založ soubor a přidej řádek do indexu |
| Záznam existuje a vstup ho **zpřesňuje** | Uprav existující soubor, nezakládej druhý |
| Vstup existující záznam **vyvrací** | Přepiš ho tak, aby platil — nebo smaž a odeber z indexu |
| Vstup jen potvrzuje, co už tam je | Nedělej nic. Zápis „pro jistotu“ je duplikát |
| Dva záznamy říkají totéž jinak | Slouč do jednoho, druhý smaž a index sjednoť |

**Nadbytečný záznam je horší než chybějící.** Chybějící znalost agent dohledá; dvě
verze téže znalosti ho postaví před volbu, kterou nemá jak rozhodnout.

---

## 6. Kontrolní seznam

- [ ] `MEMORY.md` je index — odkazy a háčky, žádný obsah, pod ~200 řádky
- [ ] Každý háček říká, **kdy** soubor otevřít
- [ ] Každý tematický soubor má frontmatter `name`, `description` a `metadata.type`
- [ ] `name` se shoduje s názvem souboru
- [ ] Tělo nese doklad původu a řádky **Why** a **How to apply**
- [ ] Záznam je konkrétní — doslovné názvy, cesty, čísla
- [ ] Nic z toho není převyprávění vstupu ani otevřená otázka
- [ ] Existující záznamy jsou zpřesněné nebo sloučené, ne zdvojené
- [ ] Co vstup vyvrátil, je opravené nebo smazané — včetně řádku v indexu
