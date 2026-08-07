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
# Bash je zúžený na spouštění skriptů; git se nikdy nevolá přímo (viz Zásady).
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

Cílem je pracovní větev založená z **čerstvého** stavu výchozí větve, s názvem,
ze kterého je na první pohled patrná povaha práce. Větvení z aktuální větve se
zdá rychlejší, ale zdědí rozpracované commity i zastaralý stav — a to se pozná
až u merge, kdy je oprava drahá.

Práce s gitem jde přes skripty. Ověří tvar názvu, kolize a dostupnost výchozí
větve dřív, než cokoli změní; příkaz `git` proto nevolej přímo.

## Skripty

Cesty jsou ukotvené k `${CLAUDE_PLUGIN_ROOT}`, protože plugin může běžet nad
cizím projektem, kde relativní `scripts/…` míří někam jinam. Volej je vždy
tvarem `bash <cesta>` — bez toho nespadnou do zúžení v `allowed-tools`.

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/preflight.sh` | Stav repozitáře jako `key=value` + seznam větví a změn |
| `${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh` | Ověří název, fetchne výchozí větev, založí a přepne |

Každý skript má v hlavičce popis použití a návratových kódů. Nenulový kód vždy
vyhodnoť — `branch_exists_locally` znamená jiný postup než `default_branch_unavailable`.

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

Spusť `bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/preflight.sh"`
a vyhodnoť výstup:

- **`error=not_a_git_repository`** (kód 2) → ohlas to a skonči.
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

Seznam v sekci `[local_branches]` si nech po ruce pro krok 2 — zjevnou kolizi
názvu odhalíš dřív, než na ni narazí `--check`.

### 2. Navrhni název

Odvoď `<type>/<popis>` z toho, co uživatel popsal, nebo z rozpracovaných změn.
Ověř ho:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" --check <název>
```

Reaguj podle návratového kódu:

- **3 `invalid_branch_name`** → oprav tvar podle sekce Formát názvu větve.
- **4 `branch_exists_locally` / `branch_exists_on_remote`** → navrhni jiný název
  a ověř znovu. Nepřipojuj pořadové číslo; vymysli popis, který práci odlišuje.
- **5 `default_branch_unavailable`** → jako v kroku 1, ohlas a skonči.

Pak si název **nech potvrdit**. Název větve se špatně mění poté, co se na ni
pushne, takže jedna otázka teď je levnější než přejmenování později. Dal-li
uživatel název sám, jen ho ověř a použij; nevymýšlej lepší.

**Není-li uživatel k dispozici** — volání AskUserQuestion selže nebo odpověď
nedorazí — větev nezakládej a ohlas navržený název. Výjimka: zadal-li uživatel
název sám, potvrzení není co doplňovat a můžeš pokračovat.

### 3. Založ větev

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" <název>
```

Skript fetchne výchozí větev, založí novou z `origin/<default>` bez upstreamu
a přepne na ni. Vrátí `created=true` a `head=<hash>`.

Skončí-li s `error=checkout_failed` (kód 7), kolidují rozpracované změny
s rozdílem proti čerstvé výchozí větvi. Větev nevznikla a zůstáváš na původní —
ohlas to a nabídni buď zapsání rozpracované práce (`make-commit`), nebo její
odložení stranou.

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
