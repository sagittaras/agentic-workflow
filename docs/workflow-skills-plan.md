# Plán sady skillů pro milestone workflow

> **Stav:** návrh odsouhlasený 9. 8. 2026, téhož dne realizovaný — všech devět skillů,
> sdílený kontrakt v `shared/` i skripty v `scripts/` existují. Proti tomuhle plánu
> se během psaní změnilo jedno: `milestone-branch.sh` integrační větev **publikuje**
> hned při založení, protože proti čistě lokální větvi nejde otevřít PR.
> **Inspirace:** `mu-online/webgame` (`.claude/skills/`) — tamní sada je zapečená do jednoho
> projektu; tenhle plán ji převádí na projektově nezávislý plugin.

Cílem je řetěz skillů, který vezme téma („uděláme UI kit"), rozepíše ho na milestone
s issues a pak ho autonomně naimplementuje — s lidským schválením na dvou místech:
před založením issues a před merge do výchozí větve.

---

## 1. Životní cyklus

```
 file-issue ──────────────────────────────────┐  (ad hoc issue kdykoli, mimo cyklus)
                                              ▼
 init-workflow → plan-milestone → review-milestone → run-milestone → close-milestone
   (jednorázově      (interview,       (fork, čistý       (orchestrátor)   (kontrola
    na projekt)       založí M+issues)   kontext)               │           + zavření)
                                                                ├─→ implement-issue → open-pr
                                                                └─→ verify-issue (fork)
```

Každý článek je použitelný i samostatně. Řetěz drží pohromadě **kontrakt v trackeru**,
ne stav v session — proto se dá kdykoli přerušit, pokračovat v jiné session a po pádu
navázat.

---

## 2. Kontrakt: jak spolu skilly mluví

Tohle je jádro návrhu. Skilly si nepředávají nic v paměti; předávají si **artefakty
v trackeru a v gitu**, z nichž dva se čtou strojově.

| Kontrakt | Kdo píše | Kdo čte |
| --- | --- | --- |
| **Tělo issue** — Souhrn / Akceptační kritéria / Reference / Závisí na | `plan-milestone`, `file-issue` | `review-milestone`, `implement-issue`, `verify-issue` |
| **`area:*` label** — jeden na issue, určuje routing | `plan-milestone` | `run-milestone` (výběr agenta), `review-milestone` (validace) |
| **Typový label** — Conventional Commit typ, shodný s názvem issue | `plan-milestone` | `implement-issue` (typ větve i commitu) |
| **Integrační větev `milestone/<slug>`** | `run-milestone` | `implement-issue` (odkud větví), `close-milestone` (ověří merge) |
| **`Závisí na: #N`** — strojově parsovaný graf | `plan-milestone` | `run-milestone` (co je odblokované), `implement-issue` (odmítne rozpracovaný základ) |
| **`Blokuje merge: ano/ne`** — strojově čtený verdikt | `verify-issue`, recenzující agent | `run-milestone` (merge vs. retry) |
| **Komentář s review reportem** na nejnižším issue milestonu | `review-milestone` | `run-milestone` (důkaz, že review proběhlo) |

Dvě zásady převzaté z webgame beze změny, protože řeší reálná selhání:

- **Review běží ve forku s čistým kontextem.** Recenzent sdílející kontext s autorem si
  odkývá vlastní úvahu. `review-milestone` i `verify-issue` proto mají `context: fork`.
- **Durable záznam patří do trackeru, ne do odpovědi.** `run-milestone` si existenci
  review ověřuje čtením komentáře, ne z tvrzení uživatele ani z vlastní paměti.

---

## 3. Projektový kontrakt: `.claude/sagittaras/workflow.md`

Zakládá ho `init-workflow`, čtou ho všechny ostatní. Když chybí, skill se nespustí
a nabídne `init-workflow` — hádat forge a mapu agentů za běhu znamená, že se každý běh
rozhodne jinak.

Obsah (pevné sekce, aby se daly číst bez parsování prózy):

1. **Forge a repozitář** — `gitea` | `github`, host, `owner/repo`. Vyplní se detekcí
   z `git remote`, uživatel jen potvrdí.
2. **Větvící politika** — výchozí větev, tvar issue větve (`<type>/<popis>`, sdíleno
   s `create-branch`), integrační větev `milestone/<slug>`, merge strategie (squash),
   a explicitně: **do výchozí větve mergeuje jen člověk**.
3. **Taxonomie labelů** — typové labely podle Conventional Commits, výčet `area:*`.
4. **Mapa `area:*` → agent** — tabulka. Plus role recenzentů (`tech-lead`, `qa-engineer`)
   nebo poznámka, že v projektu nejsou.
5. **Zdroje pravdy** — kde leží dokumenty, o které se opírají akceptační kritéria
   (ADR, specifikace, konvence). Bez nich `plan-milestone` nemá co citovat.
6. **Ověřovací příkazy** — build / lint / test, per `area:*`. Používá je `verify-issue`
   (ověřuje kritéria) i `run-milestone` (integrační brána před merge).
7. **Jazyk issues** — čeština/angličtina, ať se milestone nerozpadne na dvojjazyčný.

---

## 4. Forge: dvě cesty, jeden postup

Skilly popisují **postup**, ne API. Konkrétní volání jsou vyčleněná ven:

| Vrstva | Gitea | GitHub |
| --- | --- | --- |
| Git plumbing (větve, sync, merge, worktree) | společné skripty v `scripts/` | tytéž skripty |
| Tracker (issues, milestony, labely, PR) | Gitea MCP — tabulka receptů ve sdílené referenci | `scripts/gh/*.sh` nad `gh api` |

**Asymetrie je vědomá a nejde obejít:** MCP nástroj se ze shellu zavolat nedá, takže
gitea stranu nelze schovat do skriptu. Náhradou je **tabulka receptů** ve sdíleném
referenčním souboru — pro každou logickou operaci („přečti issue", „založ milestone",
„okomentuj PR") jeden řádek s konkrétním nástrojem a parametry, včetně `ToolSearch`
selectu, kterým se odložené `mcp__gitea__*` nástroje načtou. Skill se na řádek odkáže,
místo aby volání vymýšlel.

Kdyby se asymetrie ukázala jako problém, řešením je `scripts/gitea/*.sh` nad `curl`
a `GITEA_TOKEN` — pak by obě strany byly skripty. Teď to nedělám: token má MCP server
a duplikovat správu přihlášení kvůli symetrii se nevyplatí.

### Inventář skriptů

Konvence stejná jako u `make-commit`: `set -euo pipefail`, výstup `key=value` na stdout,
návratové kódy nesou stav, skript nikdy nerozhoduje — jen zjistí a ohlásí.

| Skript | Co dělá | Volá |
| --- | --- | --- |
| `forge-detect.sh` | z `git remote` určí forge, host, `owner/repo` | `init-workflow`, preflighty ostatních |
| `milestone-branch.sh` | založí nebo checkoutne `milestone/<slug>` z výchozí větve | `run-milestone` |
| `sync-branch.sh` | merge výchozí větve do integrační, rozliší fast-forward od reálného konfliktu | `run-milestone` |
| `integration-gate.sh` | merge špičky integrační větve do PR větve + ověřovací příkaz z configu | `run-milestone` |
| `gh/*.sh` | tracker operace přes `gh api` (issue, milestone, label, PR, review comment) | všechny, na GitHub projektech |

---

## 5. Skilly

Sedm nových (`init-workflow` je osmý, konfigurační). Model × effort podle matice pluginu,
odchylky od webgame jsou zdůvodněné.

### `init-workflow` — `sonnet` × `high`
Jednorázově vyzpovídá projekt a založí `.claude/sagittaras/workflow.md`; doplní chybějící
labely v trackeru. Ohraničené zadání se známým tvarem výstupu, ale s interview — proto
`high`, ne `medium`.
**Vstup:** projekt. **Výstup:** config + labely. **Navazuje:** `plan-milestone`.

### `plan-milestone` — `opus` × `high`
1. **Readiness check** — přečte zdroje pravdy z configu a oddělí **blokující mezery**
   (nerozhodnutá architektura → nelze napsat kritérium) od **otevřených otázek**, které
   dokument sám odkládá. Mezery neřeší sám, hlásí je.
2. **Interview rozsahu** přes `AskUserQuestion` — s doporučenou variantou a vysvětleným
   kompromisem.
3. **Draft issues** v pořadí závislostí, každé akceptační kritérium ukotvené v konkrétní
   sekci dokumentu. Kritérium se píše jako **pozorovatelné chování**, ne jako tvrzení
   o implementaci.
4. **Předložení draftu uživateli** — povinná brzda, ne volitelná. Zároveň se potvrdí
   labely.
5. **Založení**: chybějící labely → milestone → issues **sekvenčně** (číslo předchozího
   issue musí existovat, než se na něj další odkáže v `Závisí na`).

Odchylka od webgame (`sonnet` × `medium`): tady je otevřené zadání, ukotvování kritérií
a scope rozhodnutí, které se špatně vrací zpět — to je opusová práce.

### `review-milestone` — `opus` × `high`, `context: fork`
Nezávislá validace plánu: struktura těl issues, **ukotvení kritérií** (opravdu ta sekce
existuje a říká to?), graf závislostí bez cyklů, žádné překryvy ani díry proti popisu
milestonu, právě jeden `area:*` label na issue. **Neopravuje** — vrací verdikt
Sound / Needs attention / Not ready a report ukládá jako komentář na nejnižší issue.

### `run-milestone` — `opus` × `xhigh`
Orchestrátor. Sám neimplementuje, nerecenzuje, nesoudí — dispečuje.

- **Před startem:** rozpozná milestone, sestaví graf z `Závisí na`, **ověří existenci
  review komentáře**; když chybí, řekne to a zeptá se, jestli pokračovat.
- **Smyčka:** najde odblokované issues → dispečuje agenta podle `area:*` v paralelních
  izolovaných worktree (`Agent` s `isolation: "worktree"`, ne `Skill` — forkovaný skill
  běží synchronně a serializoval by práci) → čeká na notifikace, nepolluje.
- **Validace výsledku, ne statusu:** dispatch může hlásit „completed" a nic neudělat.
  Výsledek platí, jen když jmenuje číslo PR a to PR opravdu existuje. Jinak jde
  o **selhaný dispatch** — jedno přeposlání, retry budget issue se nečerpá.
- **Review:** `tech-lead` (kvalita) a `qa-engineer` (kritéria) paralelně; rozhoduje řádek
  `Blokuje merge`, ne próza. Neshoda → vyhrává přísnější. Chybí-li v projektu agenti,
  fallback: `verify-issue` jako forkovaný skill + obecná kontrola generickým subagentem.
- **Retry:** jednou. Retry prompt vyžaduje **mutation test** nového regresního testu —
  dočasně vrátit chybu, ověřit že test spadne, opravit, ověřit že projde. Podruhé už ne:
  PR zůstane otevřené, eskaluje se, ostatní issues běží dál.
- **Integrační brána:** před merge se špička integrační větve vmerguje do PR větve
  a spustí ověřovací příkaz. Dvě nezávisle zelená PR se umí rozbít sémanticky bez
  textového konfliktu.
- **Merge do integrační větve je autonomní** (uživatel ho autorizoval v configu),
  **merge do výchozí větve nikdy** — na konci vznikne jedno PR a skill se zastaví.

Odchylka od webgame (`sonnet` × `medium`): dlouhý autonomní běh s retry rozpočtem
a ověřováním poctivosti dispatchů — matice pro orchestraci říká `opus` × `xhigh`.

### `implement-issue` — `opus` × `xhigh`
Jeden issue → větev → kód → PR. Sdílený postup za inženýrskými agenty: agent přidává
doménové zázemí, skill drží proces.
- Ověří, že závislosti jsou zavřené; jinak nezačne.
- Přečte **skutečné** dokumenty z Reference, ne parafráze.
- Základní větev: v milestone běhu ta, kterou dostal; samostatně výchozí větev.
- Implementuje přesně to, co říkají kritéria — podspecifikované kritérium se hlásí, ne
  domýšlí; to je signál, že chybu má opravit `plan-milestone`.
- Git mechaniku **nedělá sám** — deleguje na `create-branch` a `make-commit`, PR na
  `open-pr`. Nepíše se potřetí.

### `verify-issue` — `opus` × `high`, `context: fork`
Ověří, že PR opravdu splňuje kritéria — spustí příkazy, přečte kód, nedůvěřuje
odškrtnutému boxu. Kritérium opřené o nový regresní test **mutation-testuje**. Read-only:
nic neopravuje. Odškrtne v těle issue, co ověřil. Report jde jako PR review komentář
a **vždy** obsahuje řádek `Blokuje merge: ano/ne` — bez něj `run-milestone` nemá podle
čeho rozhodnout a považuje běh za selhaný dispatch.

### `open-pr` — `sonnet` × `medium`
Sdílená mechanika: dokončí commit (přes `make-commit`), pushne, otevře PR proti zadané
základní větvi, do těla dá `Closes #N`. Na GitHubu přes `gh` skript, na Gitea přes MCP
recept. Existuje proto, aby `implement-issue` ani `run-milestone` neskládaly PR ručně.

### `file-issue` — `sonnet` × `medium`
Jeden ad hoc issue mimo milestone, ve stejném tvaru těla. Vstupní bod i pro nálezy, které
vypadnou během běhu.

### `close-milestone` — `haiku` (bez `effort`)
Poslední krok. Ověří, že **všechny** issues jsou zavřené (s paginací a křížovou kontrolou
proti počtům na milestonu) a že integrační PR je opravdu `merged`. Cokoli jiného → nahlásí
a **nezavře**. Prázdný milestone se nezavírá tiše.
Pozn.: webgame má u tohoto skillu `haiku` × `medium`, což je podle naší matice chyba —
haiku `effort` nepodporuje.

---

## 6. Pořadí psaní

Topologicky, každý přes `/sagittaras:write-skill` (ten si sám vyžádá `review-skill`):

1. **Sdílené základy** — `scripts/`, tabulka forge receptů, šablona těla issue.
2. `init-workflow` — bez configu nemá zbytek co číst.
3. `file-issue` — nejmenší konzument šablony, ověří ji v malém.
4. `plan-milestone` → 5. `review-milestone`.
6. `open-pr` → 7. `implement-issue`.
8. `verify-issue` — poslední článek, který `run-milestone` potřebuje.
9. `run-milestone` — integruje všechno.
10. `close-milestone`.

Po každém článku je smysluplné zkusit ho nad reálným projektem (webgame nebo titan) —
sada se ladí za běhu, ne od stolu.

---

## 7. Vědomě odloženo

- **`write-post-mortem` / `analyze-post-mortem`** — webgame je má a `run-milestone` u nich
  končí. Dává to smysl, ale je to samostatná dvojice s vlastním cyklem; přidat až sada
  poběží.
- **Formální issue dependencies v trackeru** — zůstáváme u textového `Závisí na: #N`,
  které si obě forge samy prolinkují.
- **`scripts/gitea/*.sh` nad `curl`** — viz kapitola 4.
