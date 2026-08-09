# Projektová konfigurace workflow

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Popisuje soubor
> `.claude/sagittaras/workflow.md` v cílovém projektu — zakládá ho `init-workflow`,
> čtou ho všechny skilly milestone workflow. Otevři tenhle soubor, když konfiguraci
> **zakládáš** nebo když potřebuješ vědět, **kde v ní co hledat**.

Konfigurace existuje proto, aby se skilly neptaly na totéž pokaždé znovu a aby dva běhy
nad stejným projektem dopadly stejně. Detekce za běhu je nespolehlivá právě v tom, na čem
záleží nejvíc — v mapě `area:*` → agent, podle které se práce posílá specialistovi.

---

## Kde soubor leží

`.claude/sagittaras/workflow.md` v kořeni cílového projektu. Složku `sagittaras/` vlastní
plugin, takže nekoliduje s ničím jiným v `.claude/`.

---

## Chybějící konfigurace

Když soubor neexistuje, **nepokračuj a nedomýšlej si hodnoty**. Řekni uživateli, že
projekt nemá workflow konfiguraci, a nabídni `/sagittaras:init-workflow`. Milestone běh
proti odhadnuté mapě agentů pošle práci špatnému specialistovi a pozná se to až u review.

Když soubor existuje, ale chybí v něm sekce, kterou potřebuješ, řekni která a nabídni
doplnění — nedoplňuj ji sám za pochodu.

---

## Tvar souboru

Nadpisy jsou závazné a čtou se podle nich sekce. Pořadí drž, formulace uvnitř sekcí jsou
na projektu.

````markdown
# Workflow konfigurace

## Forge

- typ: gitea | github
- host: [např. gitea.zechy.cloud nebo github.com]
- repozitář: [owner/repo]

## Větvení

- výchozí větev: [main]
- issue větev: <type>/<popis>
- integrační větev: milestone/<slug>
- merge strategie: squash
- merge do výchozí větve: jen člověk

## Labely

- typové: [feat, fix, chore, docs, refactor, test]
- oblasti: [area:backend, area:frontend, ...]

## Agenti

| oblast | implementuje |
| --- | --- |
| area:backend | backend-engineer |
| area:frontend | frontend-engineer |

- kvalita kódu: [tech-lead | — ]
- akceptační kritéria: [qa-engineer | — ]

## Zdroje pravdy

- [cesta k dokumentaci, o kterou se opírají akceptační kritéria]

## Ověřovací příkazy

| oblast | příkaz |
| --- | --- |
| area:backend | [dotnet build] |
| area:frontend | [pnpm build] |

## Jazyk issues

- [čeština | angličtina]
````

---

## Co která sekce znamená

| Sekce | Kdo ji čte | K čemu |
| --- | --- | --- |
| **Forge** | všechny | výběr větve v `forge-recipes.md` — Gitea MCP, nebo `gh` skript |
| **Větvení** | `run-milestone`, `implement-issue`, `open-pr`, `close-milestone` | odkud se větví, kam se mergeuje, co smí jen člověk |
| **Labely** | `plan-milestone`, `file-issue`, `review-milestone` | co nasadit a co validovat |
| **Agenti** | `run-milestone` | komu poslat issue a kdo posoudí PR |
| **Zdroje pravdy** | `plan-milestone`, `file-issue`, `review-milestone`, `implement-issue`, `verify-issue` | kde se ukotvují a ověřují akceptační kritéria |
| **Ověřovací příkazy** | `verify-issue`, `run-milestone` | čím se ověří kritérium a čím se hlídá integrační brána |
| **Jazyk issues** | `plan-milestone`, `file-issue` | aby milestone nebyl dvojjazyčný |

**Prázdná role recenzenta (`—`) je platný stav**, ne chyba konfigurace. `run-milestone`
v takovém případě sáhne po fallbacku popsaném ve svém postupu; nesmí to brát jako důvod
běh odmítnout.
