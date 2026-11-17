---
name: write-docs
description: >-
  Založí znalostní bázi `.docs/` v projektu, který ji nemá — vstupní index
  s pravidly struktury a odkaz na něj z CLAUDE.md —, nebo do existující báze
  přidá či v ní upraví stránku nebo sekci: místo najde sestupem stromem
  indexů, stránku odkáže z nadřazeného indexu a doplní odkazy na související
  stránky. Po každém zápisu spustí kontrolu struktury, nálezy opraví a nechá
  zápis nezávisle zrevidovat subagentem s čistým kontextem.
when_to_use: >-
  Použij, když má v projektu vzniknout dokumentace nebo se rozšířit — „založ
  dokumentaci", „udělej .docs", „zapiš to do dokumentace", „přidej stránku
  o…", „uprav sekci o…" — i když jiný skill ohlásí, že projekt bázi nemá.
  Nepoužívej pro hledání odpovědi v bázi, na to slouží read-docs; pro
  CLAUDE.md samotný write-claude-md; pro záznam architektonického rozhodnutí
  write-adr; pro závazný popis vzhledu write-art-bible; pro popis jedné
  obrazovky nebo flow write-ux-spec; pro pravidlo vázané na část repozitáře
  write-rule; ani pro zápis do paměti agenta, na to je train-agent.
argument-hint: "[téma stránky nebo „nová báze"]"
model: sonnet
effort: high
# Zařazení dle matice: ohraničené zadání se známým tvarem výstupu (index,
# stránka, řádek v indexu) → sonnet (bod 2 rozhodovacího stromu), effort high
# podle řádku „copywriting podle zadaného briefu" — stejně jako
# write-claude-md, jehož tok osnova → potvrzení → zápis skill přebírá.
# Nikoli medium: výběr sekce a věta u odkazu jsou úsudek, který rozhoduje,
# jestli stránku někdo najde. Nikoli opus: mechaniku struktury hlídá skript
# docs-check.sh, ne model.
# Přestavba nabobtnalého dokumentu na strom (princip 1.8) sem zatím nepatří,
# přijde v další vlně. Úsudkovou část (věty u odkazů, duplicita, umístění)
# posuzuje review-docs na opus × xhigh, spuštěný stejně, jako write-rule
# spouští review-rule.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Write
  - Edit
  - AskUserQuestion
  - Agent
  - "Bash(bash:*)"
# Bash je zúžený na spouštění skriptu kontroly struktury tvarem `bash <cesta>`.
# Agent spouští review-docs v kroku 6.
# Vynechaná zvažovaná pole: Grep — místo se hledá sestupem stromem, ne
# hledáním řetězce (shared/docs-tree.md); disable-model-invocation — skill má jít zřetězit za
# ohlášení „projekt nemá bázi" z jiného skillu, brzdou je potvrzená osnova;
# context/agent/background — osnovu potvrzuje uživatel v hlavním kontextu;
# paths — spouští se z konverzace, ne prací nad konkrétními soubory; shell —
# skript se spouští explicitním `bash`; disallowed-tools — allowed-tools je
# uzavřený výčet; version/license — verzuje se celý plugin.
---

# Write Docs

Cílem je stránka znalostní báze, ke které vede strom indexů od `CLAUDE.md`.
Pravidla struktury, umístění báze a postup hledání místa drží
`${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md` — otevři ho v kroku 1 a při rozporu
s tímto postupem platí on.

## Skripty

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/scripts/docs-check.sh` | Ověří strukturu báze v repozitáři, ve kterém běží; řádky `fail=<soubor> reason=<důvod>`, nebo `result=pass`. Kódy: 0 v pořádku, 1 nález, 2 nejde o git repozitář |

Volej ho z kořene cílového projektu tvarem `bash ${CLAUDE_PLUGIN_ROOT}/scripts/docs-check.sh`.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

## Postup

### 1. Urči režim

Přečti `${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md` a spusť skript kontroly
struktury. Výstup si uschovej jako výchozí stav pro krok 5.

| Výstup | Režim |
| --- | --- |
| kód 2 | Ohlas, že nejde o git repozitář, a skonči |
| `reason=missing_claude_md` | Skonči a doporuč `/sagittaras:write-claude-md` — `CLAUDE.md` tenhle skill nezakládá |
| `reason=missing_entry_index_link` | **Nová báze** (krok 2) |
| cokoli jiného | **Stránka nebo sekce** (krok 3) |

Žádá-li uživatel novou bázi a skript vstupní index najde, bázi nezakládej
a pokračuj režimem stránky nebo sekce — druhá báze vedle první je sirotek.

### 2. Nová báze: osnova vstupního indexu

Umístění vyber podle § Umístění báze v `docs-tree.md`: existuje-li v kořeni
dokumentační složka (`docs/`, `wiki/`…), navrhni ji, jinak `.docs/`.

Předlož osnovu podle Formátu výstupu a nech si ji potvrdit. **Bez potvrzení
nezapisuj** — strukturu báze bude každý další skill rozvíjet jako závaznou.
Záměr báze (pro koho je a co z kódu vyčíst nejde) zjisti otevřenou otázkou
v konverzaci, nevymýšlej ho z kódu.

Po potvrzení:

1. Zapiš vstupní index podle šablony ve Formátu výstupu. Sekce `Pravidla
   struktury` v něm převypráví body 2–5 z § Pravidla struktury
   `docs-tree.md` jazykem projektu.
2. Do `CLAUDE.md` (nebo `.claude/CLAUDE.md`, podle toho, kde už je) přidej
   Editem odkaz na vstupní index s větou, kdy ho otevřít. Zbytek souboru
   neměň. Existují-li oba soubory, přidej odkaz do obou — skript kontroluje
   každý zvlášť.
3. Má-li vzniknout i první stránka, pokračuj krokem 3; jinak krokem 5.

### 3. Stránka nebo sekce: najdi místo

Místo hledej sestupem stromem podle § Jak najít místo pro nový dokument
v `docs-tree.md`, od indexu, na který odkazuje `CLAUDE.md`. Glob kandidátních
složek ani hledání podle názvu souboru nepoužívej.

- Pokrývá-li téma existující stránka, **uprav ji**; novou nezakládej.
- Nepokrývá-li téma žádná sekce, navrhni novou sekci uvnitř té, pod kterou
  věcně spadá.

Před zápisem předlož uživateli jednou větou: cestu stránky, řádek, který
přibude v nadřazeném indexu, a stránky, na které bude odkazovat. Bez
potvrzení nezapisuj.

### 4. Zapiš stránku a odkazy

1. Zapiš nebo uprav stránku. Upravuješ-li existující, měň jen to, co se týká
   zadání.
2. Novou stránku nebo sekci odkaž z nadřazeného indexu řádkem podle § Jak
   dokument odkázat — věta říká, co tam čtenář najde, ne jak se soubor jmenuje.
3. Doplň relativní odkazy na související stránky, na konkrétní místo
   s kotvou. Odkaz přidej i opačným směrem, má-li související stránka místo,
   kde se o tématu mluví.

### 5. Ověř strukturu

Spusť skript kontroly struktury znovu a porovnej s výchozím stavem z kroku 1:

- **`result=pass`** → pokračuj krokem 6.
- **Nový nález** (není ve výchozím stavu) → oprav ho a spusť skript znovu.
  Neskonči, dokud nový nález zůstává.
- **Nález z výchozího stavu** → neopravuj ho, je mimo zadání; uveď ho v reportu.

Bez nového nálezu pokračuj krokem 6. Nedaří-li se nový nález opravit ani na
třetí pokus, eskaluj podle kroku 7.

### 6. Nezávislé review

1. Nástrojem Agent spusť subagenta **synchronně** (`run_in_background: false`)
   se zadáním podle šablony ve Formátu výstupu. Typ agenta a model vezmi
   z frontmatteru `${CLAUDE_PLUGIN_ROOT}/skills/review-docs/SKILL.md` a předej
   je parametry nástroje; effort parametrem předat nejde, napiš ho do zadání.
   Všechny cesty v zadání dosaď rozvinuté a absolutní — subagent si proměnnou
   nerozvine.
2. **Vráceno k dopracování** → oprav blokující nálezy, doporučení zvaž, spusť
   znovu krok 5 a pak další kolo s **novým** subagentem.
3. **Schváleno** → vydej report.

Nález, který zpochybňuje umístění nebo obsah potvrzený uživatelem v kroku 2
nebo 3, neodmítej mlčky — uveď ho v reportu.

### 7. Eskalace

Přeruš postup a obrať se na uživatele, když:

- na otázku po záměru báze nebo na osnovu nedorazí odpověď — nezapisuj nic;
- téma by patřilo do dvou sekcí stejně a sestup nerozhodne — polož otázku se
  dvěma kandidáty;
- nový nález skriptu se nedaří opravit — ocituj řádek `fail=` a co jsi zkusil;
- nález review zpochybňuje umístění nebo obsah, který uživatel potvrdil;
- stejný blokující nález review přetrvá dvě kola, nebo proběhnou tři kola bez
  schválení — ocituj sporný nález a polož konkrétní otázku.

## Formát výstupu

### Osnova nové báze (krok 2)

```
Báze: [cesta ke vstupnímu indexu] — [nová složka | existující složka X]
Odkaz z: [CLAUDE.md a/nebo .claude/CLAUDE.md] — „[věta, kdy index otevřít]"

Úvod indexu: [pro koho báze je a co v ní je, 1–2 věty]
Sekce: [název — co pokrývá; nebo „zatím žádné"]
První stránka: [cesta — téma; nebo „žádná"]
```

### Vstupní index

```markdown
# [Projekt] — dokumentace

[Pro koho báze je a co v ní najde: znalost, kterou nejde vyčíst z kódu.
Navigace začíná tady a vede stromem indexů.]

## Pravidla struktury

[Body 2–5 z § Pravidla struktury v shared/docs-tree.md jazykem projektu.]

## Sekce

- [Název sekce](sekce/index.md) — [co sekce pokrývá].
```

### Zadání pro reviewera (krok 6)

```
Přečti si soubor `<kořen pluginu>/skills/review-docs/SKILL.md` a proveď přesně
jeho postup. Pracuj s effortem <effort z frontmatteru review-docs>.

Zadání pro tvůj běh:
- Kořen pluginu: <absolutní cesta, rozvinutá — ne proměnná>
- Repozitář: <absolutní cesta ke kořeni cílového projektu>
- Posuzované stránky: <nové i upravené soubory včetně indexů a CLAUDE.md>
- Výstup docs-check.sh po zápisu: <řádky z posledního běhu kroku 5>
- Výchozí stav docs-check.sh: <řádky z kroku 1>
- Číslo kola: <N>
- Nevyřešené nálezy z minulého kola: <žádné, jde o první kolo | nálezy
  i s tím, jak jsi je řešil>

Vrať verdikt přesně ve struktuře, kterou review-docs předepisuje v sekci
„Formát výstupu".
```

### Závěrečný report

```
Režim: [nová báze | stránka nebo sekce]
Zapsáno: [cesty nových a upravených souborů]
Odkázáno z: [index, případně CLAUDE.md]
Kontrola struktury: [result=pass | nálezy z výchozího stavu, které zůstávají: …]
Kol review: [N]
Odmítnuté nálezy: [nález → důvod, nebo „žádné"]
```

## Zásady

- **Pravidla struktury se čtou ze `shared/docs-tree.md`**, neopisují se do
  postupu ani do paměti — jediné místo, které se mění.
- **Skill píše jen do báze a jediný řádek do `CLAUDE.md`.** Zeštíhlení nebo
  přepis `CLAUDE.md` je práce `write-claude-md`.
