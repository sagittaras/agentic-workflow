---
name: create-branch
description: >-
  Založí novou pracovní větev z čerstvé výchozí větve remotu a přepne na ni.
  Název odvodí z povahy práce ve tvaru <type>/<popis> a nechá si ho potvrdit.
  Veškeré operace nad gitem provádí přes připravené skripty, které ověří tvar
  názvu, kolize a stav repozitáře dřív, než cokoli změní.
when_to_use: >-
  Použij na začátku práce, která má vzniknout mimo výchozí větev — „založ
  větev", „udělej novou větev na…", „chci to dělat zvlášť" — nebo když
  uživatel začíná úkol a stojí na výchozí větvi. Nepoužívej pro zápis
  hotové práce, na to slouží make-commit; ani pro přepnutí na už existující
  větev, což je prostý checkout, ne úloha pro skill.
argument-hint: "[popis práce nebo rovnou název větve]"
model: sonnet
effort: low
# Zařazení dle matice: krátká ohraničená operace, inteligence není úzké hrdlo
# → sonnet × low. Haiku ne: jediné rozhodnutí skillu je odvodit z kontextu
# výstižný type a popis, což je jazyková úloha, ne šablonovitá transformace.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - "Bash(bash:*)"
# Bash je zúžený na spouštění skriptů; git se nikdy nevolá přímo (viz Zásady).
# Vynechaná zvažovaná pole: Write/Edit — skill nezapisuje soubory;
# context/agent/background — název si nechává potvrdit uživatelem a přepíná
# větev ve sdíleném pracovním stromu, fork by obojí rozbil; paths — spouští se
# z konverzace, ne prací nad soubory; disallowed-tools — allowed-tools je
# uzavřený výčet, není co zakazovat navíc.
---

# Create Branch

Cílem je pracovní větev založená z **čerstvého** stavu výchozí větve, s názvem,
ze kterého je na první pohled patrná povaha práce. Větvení z aktuální větve se
zdá rychlejší, ale zdědí rozpracované commity i zastaralý stav — a to se pozná
až u merge, kdy je oprava drahá.

Práce s gitem jde přes skripty v `scripts/`. Skripty ověří tvar názvu, kolize
a dostupnost výchozí větve dřív, než cokoli změní; příkaz `git` proto nevolej
přímo.

## Skripty

| Skript | Co dělá |
| --- | --- |
| `scripts/preflight.sh` | Stav repozitáře jako `key=value` + seznam větví a změn |
| `scripts/create-branch.sh` | Ověří název, fetchne výchozí větev, založí a přepne |

`create-branch.sh` umí `--check <název>` — ověří tvar i kolize a nic nezmění.
Používej ho, než název předložíš uživateli k potvrzení; ušetří to kolo,
ve kterém by se ukázalo, že větev už existuje.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

Zadání může být hotový název větve, nebo jen popis práce, ze kterého název
odvodíš.

## Formát názvu větve

```
<type>/<popis-v-kebab-case>
```

- **type** je ze stejného slovníku jako Conventional Commits: `feat`, `fix`,
  `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`, `style`. Z názvu
  větve tak rovnou plyne typ prvního commitu.
- **popis** anglicky, kebab-case, dvě až čtyři slova. Popisuje **práci, ne
  zadání**: `feat/branch-creation-skill` je čitelné i za rok, `feat/issue-42`
  ne.

Příklady: `feat/create-branch-skill`, `fix/stale-default-branch-ref`,
`docs/commit-conventions`.

## Postup

### 1. Zjisti stav

Spusť `scripts/preflight.sh` a vyhodnoť výstup:

- **`detached=true`** → ohlas to a zastav se. Zakládat větev z odpojené HEAD
  jde, ale skoro vždy to znamená, že uživatel je uprostřed rebase a chtěl něco
  jiného.
- **`default_branch_source=unavailable`** → remote neodpověděl. Bez znalosti
  výchozí větve skript větev nezaloží; ohlas to a nabídni práci na aktuální
  větvi.
- **rozpracované změny** (`staged_count`, `unstaged_count`, `untracked_count`
  nenulové) → upozorni, že přejdou s uživatelem na novou větev. To bývá záměr,
  když se přišlo na to, že se pracuje na špatné větvi — ale řekni to nahlas,
  ať to není překvapení.

### 2. Navrhni název

Odvoď `<type>/<popis>` z toho, co uživatel popsal, nebo z rozpracovaných změn.
Ověř ho přes `scripts/create-branch.sh --check <název>` a **nech si ho
potvrdit**. Název větve se špatně mění poté, co se na ni pushne, takže jedna
otázka teď je levnější než přejmenování později.

Dal-li uživatel název sám, jen ho ověř a použij; nevymýšlej lepší.

### 3. Založ větev

```bash
bash scripts/create-branch.sh <název>
```

Skript fetchne výchozí větev, založí novou z `origin/<default>` bez upstreamu
a přepne na ni. Vrátí `created=true` a `head=<hash>`.

Skončí-li s `error=checkout_failed`, kolidují rozpracované změny s rozdílem
proti čerstvé výchozí větvi. Nic se nezměnilo — ohlas to uživateli a nabídni
buď zapsání rozpracované práce (`make-commit`), nebo její odložení stranou.

### 4. Shrň výsledek

Uveď název větve, ze kterého bodu vznikla, a jestli s sebou nesla rozpracované
změny. Připomeň, že větev zatím nemá upstream — publikuje se až prvním pushem.

## Zásady

- **Git jen přes skripty.** Přímé volání obchází ověření názvu i kolizí.
- **Vždy z čerstvé výchozí větve.** Skill nevětví z aktuální větve, i kdyby to
  bylo pohodlnější — zděděné commity v nové větvi jsou tichý problém.
- **Upstream nezakládej.** Nová větev je lokální, dokud ji uživatel nepublikuje.
  Publikování je viditelné navenek a patří jemu.
- **Název si nech potvrdit**, pokud ho uživatel nezadal sám.
- **Nic nepřepisuj.** Skill neumí přejmenovat ani smazat větev; obojí je zásah
  do cizí práce, pokud už je větev publikovaná.
