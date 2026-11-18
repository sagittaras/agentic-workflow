# Projektová konfigurace workflow

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Popisuje pevné sekce uvnitř
> `CONTRIBUTING.md` v cílovém projektu — zakládá je `init-workflow`, čtou je
> všechny skilly milestone workflow. Otevři tenhle soubor, když konfiguraci
> **zakládáš** nebo když potřebuješ vědět, **kde v ní co hledat**.

Konfigurace existuje proto, aby se skilly neptaly na totéž pokaždé znovu a aby dva běhy
nad stejným projektem dopadly stejně. Detekce za běhu je nespolehlivá právě v tom, na čem
záleží nejvíc — v mapě `area:*` → agent, podle které se práce posílá specialistovi.

Bydlí v `CONTRIBUTING.md`, ne v plugin-specifickém souboru: je to konvenční, lidmi čitelný
dokument, který si projekt může mít i bez tohohle pluginu, a lidé si ho skutečně čtou.
Pevnou strukturu nese jen jedna jeho sekce; zbytek dokumentu patří projektu a tenhle
kontrakt se ho netýká.

---

## Kde sekce leží

`CONTRIBUTING.md` v kořeni cílového projektu. Fixní obsah stojí pod jediným nadpisem
druhé úrovně:

```markdown
## Workflow (sagittaras)
```

Pod ním následují pevné podsekce třetí úrovně popsané níž. Nadpis **musí znít přesně
takhle** — skilly ho hledají doslovně, ne heuristikou — a nic nad ním v souboru se
neparsuje: to je projektův vlastní obsah (úvod, jak přispívat kódem, styl commitů…) a
zůstává, jak si ho projekt napsal. **Sekce sahá od nadpisu `## Workflow (sagittaras)`
po nejbližší další nadpis druhé úrovně, nebo po konec souboru** — jako podsekce se
počítají jen nadpisy třetí úrovně v tomhle rozsahu, ne stejnojmenné nadpisy jinde
v dokumentu. Existuje-li `CONTRIBUTING.md` už teď, sekce se **přidá na konec** souboru;
založí-li `init-workflow` `CONTRIBUTING.md` sám, obsahuje jen tuhle sekci.

---

## Chybějící konfigurace

Když `CONTRIBUTING.md` neexistuje, nebo existuje, ale nemá sekci `## Workflow (sagittaras)`,
**nepokračuj a nedomýšlej si hodnoty**. Řekni uživateli, že projekt nemá workflow
konfiguraci, a nabídni `/sagittaras:init-workflow`. Milestone běh proti odhadnuté mapě
agentů pošle práci špatnému specialistovi a pozná se to až u review.

Když sekce existuje, ale chybí v ní podsekce, kterou potřebuješ, řekni která a nabídni
doplnění — nedoplňuj ji sám za pochodu. Výjimkou je podsekce **Agenti**, viz níž: její
absence je platný stav, ne mezera.

---

## Tvar sekce

Nadpisy jsou závazné a čtou se podle nich. Pořadí drž, formulace uvnitř podsekcí jsou
na projektu.

````markdown
## Workflow (sagittaras)

> Tuhle sekci spravuje `/sagittaras:init-workflow` a čtou ji ostatní skilly milestone
> workflow. Nadpisy nech beze změny; obsah pod nimi uprav, kdy chceš.

### Forge

- typ: [gitea | github]
- host: [např. gitea.zechy.cloud nebo github.com]
- repozitář: [owner/repo]

### Větvení

- výchozí větev: [main]
- issue větev: <type>/<popis>
- integrační větev: milestone/<slug>
- merge strategie: squash
- merge do výchozí větve: jen člověk, ledaže prompt, kterým byl aktuální běh
  spuštěn, obsahoval výslovný souhlas k mergi — pak smí mergnout `open-pr`

### Labely

- typové: [feat, fix, chore, docs, refactor, test]
- oblasti: [area:backend, area:frontend, ...]

### Agenti

| oblast | implementuje |
| --- | --- |
| area:backend | backend-engineer |
| area:frontend | frontend-engineer |

### Ověřovací příkazy

| oblast | příkaz |
| --- | --- |
| area:backend | [dotnet build] |
| area:frontend | [pnpm build] |

### Jazyk issues

- [čeština | angličtina]
````

---

## Co která podsekce znamená

| Podsekce | Kdo ji čte | K čemu |
| --- | --- | --- |
| **Forge** | všechny | výběr větve v `forge-recipes.md` — Gitea MCP, nebo `gh` skript |
| **Větvení** | `run-milestone`, `implement-issue`, `open-pr`, `close-milestone` | odkud se větví, kam se mergeuje, co smí jen člověk |
| **Labely** | `plan-milestone`, `file-issue`, `review-milestone` | co nasadit a co validovat |
| **Agenti** | `run-milestone` | komu poslat issue k implementaci |
| **Ověřovací příkazy** | `verify-issue`, `run-milestone`, `plan-milestone` | čím se ověří kritérium a čím se hlídá integrační brána |
| **Jazyk issues** | `plan-milestone`, `file-issue`, `triage-issue`, `review-milestone` | v jakém jazyce psát text issues; strojové nadpisy šablony zůstávají česky v každém jazyce |

**Podsekce Agenti je jediná nepovinná.** `init-workflow` ji do `CONTRIBUTING.md`
založí, právě když vznikne aspoň jeden řádek `oblast → agent` — jinak ji nezaloží
vůbec, ani prázdnou tabulku s pomlčkami: to by tvrdilo rozhodnutí, které nikdo
neudělal. Chybějící řádek pro oblast issue, hodnota `—` ve sloupci `implementuje`
i chybějící podsekce celá jsou platné stavy, ne chyba, na kterou by se mělo
eskalovat — `run-milestone` na ně má vlastní fallback (dispatch na obecného
subagenta).
