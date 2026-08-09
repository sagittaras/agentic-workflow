# Konvence psaní rules

> **Rozsah:** Referenční soubor skillu `write-rule`. Závazné konvence pro zakládání
> a úpravu souborů v `.claude/rules/`. Kostru souboru nese
> [rule-template.md](rule-template.md).

---

## 1. Co je rule a co do ní nepatří

Rule je **kus instrukcí, který se načte do kontextu** — buď při startu session, nebo
ve chvíli, kdy Claude sáhne na soubor odpovídající globu v `paths`. Není to
dokumentace, kterou si někdo dohledá, a není to ani vynucení: rules jsou kontext,
který model může přehlédnout, ne konfigurace, kterou klient uhlídá.

Než začneš psát, ověř, že instrukce patří právě do rule:

| Kam | Kdy tam obsah patří |
| --- | --- |
| `CLAUDE.md` | Platí pro celý projekt v každé session — build příkazy, architektura, rozvržení repozitáře, „vždy dělej X". |
| **Rule bez `paths`** | Tematicky soudržný blok, který platí pořád, ale v `CLAUDE.md` by ho utopil. Načítá se při startu se stejnou prioritou jako `.claude/CLAUDE.md`. |
| **Rule s `paths`** | Instrukce, které mají smysl jen u části repozitáře. Načtou se, až Claude sáhne na odpovídající soubor — zbytek session je nezatěžují. **Tohle je hlavní důvod, proč rules existují.** |
| Skill | Vícekrokový postup vyvolaný situací, ne vlastnostmi souboru. Načítá se na vyžádání. |
| Hook | Co musí platit bez výjimky. Rule ani `CLAUDE.md` nic nevynutí — hook ano, protože ho spouští klient. |

**Rule s `paths` je výchozí volba.** Rule bez `paths` platí za `CLAUDE.md` napsaný
jinam: sedí v kontextu každé session bez ohledu na to, čeho se práce týká. Zakládej
ji jen tehdy, když pravidla opravdu platí napříč celým repozitářem.

---

## 2. Pojmenování

Název souboru je **`<téma>.md`** — podstatné jméno nebo jmenná fráze v kebab-case.

```
typescript.md    api-design.md    test-standards.md    shader-code.md
```

**Pozor, je to opačná konvence než u skillů.** Skill se jmenuje slovesem, protože
popisuje činnost, kterou vykoná. Rule žádnou činnost nevykonává — je to sada pravidel
pro určitou oblast, a název proto pojmenovává oblast. `write-typescript.md` je špatně.

| Pravidlo | Detail |
| --- | --- |
| Tvar | `<téma>.md`, podstatné jméno; bez slovesa |
| Znaky | jen malá písmena, číslice a pomlčka |
| Rozsah | jedno téma na soubor — soubor pokrývající dvě oblasti se rozpadá na dva |
| Podsložky | u velkých repozitářů `rules/frontend/`, `rules/backend/`; `.md` soubory se hledají rekurzivně |
| Vazba na globy | název má odpovídat tomu, co matchuje `paths` — čtenář musí z názvu poznat, kdy se rule uplatní |

**Čemu se vyhnout:** `general.md`, `misc.md`, `rules.md`, `notes.md`. Název, který
neomezuje téma, je předzvěst souboru, do kterého se za půl roku sype všechno.

---

## 3. Frontmatter

Jediné dokumentované pole je **`paths`** — seznam globů. Cokoli dalšího loader ignoruje,
takže to nepřidávej: pole jako `description` nebo `name` v rule nic neudělají a jen
matou čtenáře.

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "tests/**/*.test.ts"
---
```

**Rule bez `paths` frontmatter nemá vůbec** — prázdný `---` blok nepiš.

### Jak se `paths` chová

- Rule s `paths` se do kontextu dostane, **až když Claude čte soubor odpovídající
  globu** — ne při každém volání nástroje a ne při startu.
- Rule bez `paths` se načítá při startu se stejnou prioritou jako `.claude/CLAUDE.md`.
- User-level rules v `~/.claude/rules/` se načítají **před** projektovými, takže
  projektová rule má vyšší prioritu.
- Po `/compact` se path-scoped rules **znovu neinjektují** — vrátí se, až Claude
  příště sáhne na odpovídající soubor. Nespoléhej proto na rule u instrukce, která
  musí platit i uprostřed dlouhé session bez doteku daných souborů; ta patří
  do `CLAUDE.md`.

### Psaní globů

| Vzor | Matchuje |
| --- | --- |
| `**/*.ts` | všechny TypeScript soubory kdekoli |
| `src/**/*` | vše pod `src/` |
| `*.md` | markdown v kořeni projektu |
| `src/components/*.tsx` | komponenty v jedné konkrétní složce |
| `src/**/*.{ts,tsx}` | složené závorky expandují na víc vzorů |

- **Vol nejužší glob, který téma pokryje.** Široký glob znamená rule tažené do kontextu
  u práce, které se netýká — což je přesně to, čemu se path-scopingem vyhýbáš.
- **Složené závorky mají rozpočet.** Celý seznam `paths` jedné rule sdílí limit
  1 000 expandovaných vzorů; vzor, který by ho překročil, se použije neexpandovaný
  a jeho doslovné závorky pak nematchují nic. Vzory bez závorek se do rozpočtu nepočítají.
- **Hranatá závorka je speciální znak.** `[` zahajuje výraz typu `[abc]`; vzor
  s nepárovou `[` nematchuje nic. Doslovnou závorku v názvu escapuj: `photos \[2024/**`.
- **Glob vždy ověř proti reálné struktuře repozitáře.** Vzor, který nematchuje žádný
  soubor, je rule, která se nikdy nenačte — a nepozná se to, protože nic nespadne.

---

## 4. Tělo rule

- **Odrážky, ne odstavce.** Rule je seznam pravidel; každá odrážka nese právě jedno
  pravidlo, které jde ověřit pohledem na kód.
- **Konkrétnost je jediné, co rozhoduje o dodržení.** „Odsazuj čtyřmi mezerami" model
  dodrží, „formátuj kód pořádně" ne. Pravidlo, u kterého nejde říct, jestli je porušené,
  do rule nepatří.
- **Normativní tvar.** „Každý veřejný endpoint validuje vstup", „Nikdy neindexuj
  dvakrát totéž" — ne „bylo by dobré" a ne popis, jak to v projektu chodí.
- **Proč připoj u pravidel, která nejsou samozřejmá.** Pravidlo s důvodem model dodrží
  spolehlivěji a hlavně ho správně aplikuje na situaci, kterou autor nepředvídal.
- **Ukázky správně/špatně** patří k pravidlům, jejichž tvar se slovy popisuje hůř než
  kódem — pojmenování souborů, struktura dat, tvar API. Ukázka musí být z tohohle
  projektu, ne obecná.
- **Nepopisuj, co model umí sám.** Rule přidává, co je specifické pro tenhle projekt.
  Obecné rady o čistém kódu jen zabírají kontext.
- **Drž se krátce.** Rule se načítá celá; u rule bez `paths` platí každý řádek daň
  v každé session. Nad zhruba padesát řádků se ptej, jestli to není dvě témata.
- **Žádné duplicity a žádné konflikty.** Když si dvě instrukce v `CLAUDE.md` a v rules
  odporují, model si jednu vybere a nedá se předvídat kterou. Před zápisem projdi
  `CLAUDE.md` i sousední rules a rozpory vyřeš, ne přidej.
- **Jazyk převezmi z cílového projektu.** Rule čtou lidé z týmu vedle stávajících
  rules a `CLAUDE.md`; dvojjazyčná složka `rules/` se čte hůř než kterákoli z variant.
  Nejsou-li tam zatím žádné rules, řiď se jazykem `CLAUDE.md`. Identifikátory,
  názvy souborů a ukázky kódu jsou anglicky vždy.

---

## 5. Kontrolní seznam před dokončením

- [ ] Obsah patří do rule, ne do `CLAUDE.md`, skillu nebo hooku (kapitola 1)
- [ ] Název je `<téma>.md`, podstatné jméno, jedno téma na soubor
- [ ] `paths` je přítomné, pokud pravidla neplatí pro celý repozitář
- [ ] Každý glob byl ověřen proti reálné struktuře repozitáře a něco matchuje
- [ ] Ve frontmatteru není jiné pole než `paths`
- [ ] Každá odrážka nese jedno vymahatelné pravidlo, u neintuitivních je uvedené proč
- [ ] Ukázky správně/špatně jsou z tohoto projektu, ne obecné
- [ ] Rule nekoliduje ani neduplikuje `CLAUDE.md` a sousední rules
- [ ] Jazyk odpovídá stávajícím rules cílového projektu, identifikátory a kód anglicky
