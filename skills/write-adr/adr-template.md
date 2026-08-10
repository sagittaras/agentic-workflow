# Šablona ADR

> **Rozsah:** Referenční soubor skillů `write-adr` a `review-adr`. Kostra dokumentu
> pro nově zakládaný log ADR. Pravidla okolo — umístění, číslování, stavy, otevřené
> otázky — nese [adr-conventions.md](adr-conventions.md) a při rozporu platí ono.
> Má-li log v projektu už vlastní ustálený tvar, **přednost má on**, ne tahle šablona
> (kapitola 2 konvencí).

## Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď obsahem a závorky odstraň. Text uvnitř
  je pokyn, co do místa patří — ne text k opsání.
- **Povinné jádro** je pět sekcí: Stav, Kontext, Rozhodnutí, Zvažované alternativy,
  Důsledky. Vyplň je vždy, i kdyby jednou větou.
- Sekce označené `(volitelné)` vynech **celé** i s nadpisem, pokud pro dané rozhodnutí
  nedávají smysl. Značku `(volitelné)` v hotovém ADR nikdy nenechávej. Drobné rozhodnutí
  zabere pět sekcí a je to v pořádku — prázdné nadpisy jenom ředí to podstatné.
- Instrukční komentáře `<!-- … -->` v hotovém dokumentu nezůstávají.

---

## Kostra

````markdown
# ADR-[NNNN]: [Název rozhodnutí — pojmenuj předmět, ne „ADR o X"]

| | |
| --- | --- |
| **Stav** | [Navrženo — dokud běží review; po schválení Přijato] |
| **Datum** | [YYYY-MM-DD, kdy ADR vznikl] |
| **Rozhodli** | [kdo se na rozhodnutí podílel — volitelný řádek, vynech i s ním] |

## Souhrn (volitelné)

[2–3 věty: jaký problém se řeší a co bylo rozhodnuto. Pojmenuj součást, problém
i zvolený přístup — souhrn slouží k rychlému skenování logu, aniž by bylo nutné
otevřít celý dokument. Vyplň u rozhodnutí, jehož dokument přesáhne obrazovku.]

## Dotčené součásti (volitelné)

| Pole | Hodnota |
|------|---------|
| **Součásti** | [konkrétní cesty, např. `src/backend`, nebo „celý repozitář" u průřezových rozhodnutí] |
| **Rozsah** | [Lokální — jedna součást / Průřezové — mění konvenci napříč repozitářem] |

## Závislosti ADR (volitelné)

| Pole | Hodnota |
|------|---------|
| **Navazuje na** | [ADR-NNNN, na jehož rozhodnutí tohle staví] |
| **Nahrazuje** | [ADR-NNNN, jehož rozhodnutí tohle zvrací — tomu překlop Stav] |
| **Blokuje** | [práce, která nemůže začít, dokud tohle neplatí] |

## Kontext

[Proč se to musí rozhodnout teď a co nás stojí nerozhodnout. Popiš současný stav
a co je na něm špatně; u nové součásti napiš, že předchozí stav není.

Co už fixovala jiná ADR, CLAUDE.md nebo dokumentace projektu, **pojmenuj a odkaž** —
nerozporuj znovu uzavřenou půdu, stav na ní.

Pojmenuj síly, které jsou proti sobě — jednoduchost proti budoucí pružnosti,
konzistence proti ceně. Právě ony dělají z tohohle rozhodnutí rozhodnutí.]

### Omezení a požadavky (volitelné)

- [Technická, časová a provozní omezení, kompatibilita s existujícími součástmi]
- [Požadavky, které musí zvolené řešení splnit — nefunkční konkrétně a měřitelně]

## Rozhodnutí

[Co se rozhodlo — konkrétně natolik, aby to šlo implementovat bez doptávání.
Má-li rozhodnutí víc oddělených částí, rozděl je do krátkých podsekcí s nadpisy;
jeden dlouhý odstavec se hůř čte i cituje.

Fixuje-li rozhodnutí tvar rozhraní, typu nebo struktury, vlož ho jako fenced blok
přímo do podsekce, které se týká — viz „Kód jako rozhodnutí" v konvencích. Próza
kolem něj zůstává: kód říká „co", ne „proč".]

### Pokyny k implementaci (volitelné)

[Co má vědět ten, kdo rozhodnutí bude realizovat — člověk i agent.]

## Zvažované alternativy

### [Název alternativy]

- **Popis**: [jak by ten přístup fungoval]
- **Klady**: [co je na něm dobré — pokud nic, nebyla to reálná alternativa]
- **Zápory**: [co je na něm špatné]
- **Důvod zamítnutí**: [proč neobstál; věcně, ne formálně]

### [Název další alternativy]

[Stejná struktura. Vypiš jen alternativy, které byly skutečně ve hře — vymyšlený
slaměný panák zdůvodnění neposílí, jen prodlouží.]

## Důsledky

### Pozitivní

- [Co rozhodnutí přináší]

### Negativní

- [Cena a kompromisy, které vědomě přijímáme. Aspoň jeden bod tu musí být:
  rozhodnutí, které nic nestojí, nebylo pořádně prozkoumané.]

### Neutrální (volitelné)

- [Změny, které nejsou ani dobré, ani špatné — jen jiné]

## Rizika (volitelné)

| Riziko | Pravděpodobnost | Dopad | Mitigace |
|--------|-----------------|-------|----------|
| [Popis] | [Nízká/Střední/Vysoká] | [Nízký/Střední/Vysoký] | [Jak ho snížíme] |

## Dopady na provoz (volitelné)

[Co rozhodnutí znamená pro nasazení, monitoring, náklady a údržbu — nová
infrastruktura, nové externí závislosti, nároky na zálohování.]

## Migrační plán (volitelné)

[Mění-li rozhodnutí existující součásti, rozepiš postup po krocích.]

1. [Krok — co se mění, co se rozbije, jak ověříme]

**Plán návratu**: [jak se vrátit, ukáže-li se rozhodnutí jako špatné]

## Kritéria validace (volitelné)

[Podle čeho po implementaci poznáme, že rozhodnutí bylo správné. Měřitelně —
„bude to fungovat dobře" není kritérium.]

- [ ] [Kritérium]

## Otevřené otázky (volitelné)

[Co tohle rozhodnutí vědomě nechává nedořešené — skutečné, nerozhodnuté kompromisy,
ne spekulace o vzdálené budoucnosti. Přijaté ADR takový výčet mít smí; je to přiznání,
ne nedodělek. Nezůstává-li nic, vynech sekci celou.]

- [Otázka a co ji rozhodne — čí je to volba, nebo co se musí napřed zjistit]

## Související (volitelné)

- [Odkazy na související ADR, dokumentaci, issue nebo externí zdroje]
````

---

## Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| Hlavička se Stavem | ✅ | Stav, datum, kdo rozhodl | Stav `Přijato` u dokumentu, který jde teprve na review |
| `## Souhrn` | ⬜ | 2–3 věty pro skenování logu | Obecné „řeší architekturu backendu" bez pojmenované součásti |
| `## Dotčené součásti` | ⬜ | Konkrétní cesty a rozsah | „Celý projekt" u rozhodnutí, které se týká jednoho modulu |
| `## Závislosti ADR` | ⬜ | Vazby na jiná ADR | Nepřiznané nahrazení staršího rozhodnutí |
| `## Kontext` | ✅ | Problém, současný stav, síly v napětí | Obhajoba předem hotového řešení místo popisu problému |
| `## Rozhodnutí` | ✅ | Co se rozhodlo, implementovatelně | Zopakovaný kontext nebo obecný princip bez závazku |
| `## Zvažované alternativy` | ✅ | Reálné varianty a věcné důvody zamítnutí | Jediná alternativa „nedělat nic" |
| `## Důsledky` | ✅ | Zisky i cena | Samé klady — nepřiznaná cena |
| `## Rizika` … `## Kritéria validace` | ⬜ | Podle povahy rozhodnutí | Vyplněné „pro úplnost" prázdnými frázemi |
| `## Otevřené otázky` | ⬜ | Vědomě nedořešené kompromisy | Otázka, kterou dokument o dva odstavce výš zodpověděl |
