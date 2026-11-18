---
name: create-branch
description: >-
  Založí novou pracovní větev z čerstvé výchozí větve remotu — nebo ze základu,
  který volající výslovně určí — a přepne na ni.
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
effort: medium
# Zařazení dle matice: dobře ohraničené zadání se známým výsledkem → sonnet ×
# medium (bod 2 rozhodovacího stromu). Nikoli low: postup má čtyři kroky a pět
# rozlišovaných chybových stavů, což je přesně to, před čím matice u low varuje.
# Nikoli haiku: odvodit z kontextu výstižný type a popis je jazyková úloha,
# ne šablonovitá transformace.
user-invocable: true
allowed-tools:
  - Read
  - AskUserQuestion
  - "Bash(bash:*)"
# Bash je zúžený na spouštění skriptů; git se nikdy nevolá přímo (viz sekce Skripty).
# Proto každé volání píš ve tvaru `bash <cesta>` — jinak nespadne do povolení.
# Vynechaná zvažovaná pole: disable-model-invocation — založení lokální větve
# je vratná operace a automatické vyvolání z jiného flow je žádoucí; Glob/Grep —
# vstupem je zadání uživatele a výpis z preflightu, prohledávat soubory není
# proč; Write/Edit — skill nezapisuje soubory; context/agent/background — název
# si nechává potvrdit uživatelem a přepíná větev ve sdíleném pracovním stromu,
# fork by obojí rozbil; paths — spouští se z konverzace, ne prací nad soubory;
# shell — skripty se spouští explicitním `bash`; disallowed-tools —
# allowed-tools je uzavřený výčet, není co zakazovat navíc.
---

# Create Branch

Cílem je pracovní větev založená z **čerstvého** stavu výchozí větve remotu, s názvem,
ze kterého je patrná povaha práce.

## Skripty

Git jen přes skripty, volané tvarem `bash "<cesta>"`; `git` přímo nevolej.

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/preflight.sh` | Stav repozitáře jako `key=value` + seznam větví a změn |
| `${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh` | Ověří název, fetchne základ, založí a přepne; `--check <název>` jen ověří, `--base <ref>` větví z jiného základu |

Návratové kódy popisuje hlavička každého skriptu; nenulový kód vždy vyhodnoť.

`--base <ref>` použij, jen když volající základ výslovně určil (typicky `implement-issue`
nad `milestone/<slug>`). Sám základ neměň a z aktuální větve nevětvi.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

Zadání je hotový název větve, nebo popis práce, ze kterého název odvodíš.

## Formát názvu větve

```
<type>/<popis-v-kebab-case>
```

- **type** ze slovníku Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `test`,
  `chore`, `ci`, `build`, `perf`, `style`.
- **popis** anglicky, kebab-case, dvě až čtyři slova; popisuje práci, ne zadání —
  `feat/branch-creation-skill`, ne `feat/issue-42`.

## Postup

### 1. Zjisti stav

Spusť `bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/preflight.sh"`:

| Výstup | Co uděláš |
| --- | --- |
| `error=not_a_git_repository` (kód 2) | ohlas a skonči |
| `detached=true` | ohlas a zastav se |
| `default_branch_source=unavailable` | remote neodpověděl — ohlas to a nabídni práci na aktuální větvi |
| nenulové `staged_count`, `unstaged_count` nebo `untracked_count` | řekni, že rozpracované změny přejdou na novou větev |

Sekci `[local_branches]` použij v kroku 2 ke zjevné kolizi názvu.

### 2. Navrhni název

Odvoď `<type>/<popis>` z popisu práce nebo z rozpracovaných změn a ověř ho:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" --check <název>
```

| Kód | Co uděláš |
| --- | --- |
| 3 `invalid_branch_name` | oprav tvar podle Formátu názvu větve |
| 4 `branch_exists_locally` / `branch_exists_on_remote` | zvol jiný popis, který práci odlišuje (ne pořadové číslo), a ověř znovu |
| 5 `default_branch_unavailable` | ohlas a skonči |

Dal-li název uživatel nebo volající, jen ho ověř a použij. Jinak si ho nech potvrdit
nástrojem AskUserQuestion; selže-li volání nebo odpověď nedorazí, větev nezakládej
a ohlas navržený název.

### 3. Založ větev

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" [--base <ref>] <název>
```

Skript vrátí `base=`, `created=true` a `head=<hash>`. S `--base` ověř `base=`
v odpovědi.

| Chyba | Co uděláš |
| --- | --- |
| `error=base_branch_not_found` (kód 5) | ohlas; nezakládej náhradně z výchozí větve |
| `error=checkout_failed` (kód 7) | větev nevznikla, zůstáváš na původní — ohlas a nabídni zapsání práce (`make-commit`) nebo její odložení stranou |

### 4. Shrň výsledek

Uveď název větve, ze kterého bodu vznikla a jestli nesla rozpracované změny,
a připomeň, že zatím nemá upstream. Sám ho nezakládej — publikuje ji první commit
přes `make-commit`.

## Zásady

- **Nic nepřepisuj.** Větev nepřejmenovávej ani nemaž.
