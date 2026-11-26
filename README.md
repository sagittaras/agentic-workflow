# sagittaras

Plugin pro [Claude Code](https://claude.com/claude-code), který přináší skills
a agentic workflow studia Sagittaras do libovolného projektu — podle vlastních
konvencí, ne podle výchozích.

Instaluje se jednou do uživatelské konfigurace a platí pak nad všemi projekty,
se kterými Claude Code pracuje.

## Předpoklady

| Co | Proč |
| --- | --- |
| Claude Code | Prostředí, ve kterém plugin běží |
| `git` v PATH | Instalace i samotné skilly `create-branch` a `make-commit` |
| `bash` v PATH | Skilly volají doprovodné `.sh` skripty. Na Windows stačí **Git for Windows** (Git Bash) |
| Přístup k repozitáři | Repozitář je **privátní** — je potřeba nahraný SSH klíč, nebo přihlášené [`gh`](https://cli.github.com/) pro HTTPS |
| Přístup k trackeru | Jen pro milestone workflow: na GitHubu přihlášené `gh`, na Gitei připojený Gitea MCP server |
| `node` v PATH | Jen pro `review-run` — parsuje transkripty orchestrátoru a jeho subagentů |

## Instalace

### Skriptem (doporučeno)

Skript je součástí repozitáře, takže první instalace vychází z klonu kdekoli na
disku — třeba z vývojové kopie:

```bash
git clone git@github.com:sagittaras/agentic-workflow.git && cd agentic-workflow
```

Pak podle platformy:

```powershell
./install.ps1
```

```bash
bash install.sh
```

Skript naklonuje plugin do `~/.claude/skills/sagittaras`, ověří, že se načte
(existující `plugin.json`, nalezené skilly), a upozorní na chybějící `bash`
nebo `claude` v PATH.

Užitečné přepínače — v obou skriptech se jmenují stejně:

| Přepínač | K čemu |
| --- | --- |
| `-Https` / `--https` | Klonování přes HTTPS místo SSH — pro stroje bez SSH klíče |
| `-Ref <větev>` / `--ref <větev>` | Instalace z jiné větve než `main` |
| `-Target <cesta>` / `--target <cesta>` | Jiná cílová složka, například instalace jen do jednoho projektu |

Skript **nikdy nic nemaže**. Najde-li v cíli něco cizího nebo rozpracovaného,
ohlásí to a skončí s nenulovým kódem — úklid je na tobě.

### Ručně

Instalace je ve skutečnosti jediný `git clone` na správné místo:

```bash
git clone git@github.com:sagittaras/agentic-workflow.git ~/.claude/skills/sagittaras
```

```powershell
git clone git@github.com:sagittaras/agentic-workflow.git "$HOME\.claude\skills\sagittaras"
```

Skript navíc jen kontroluje předpoklady a umí se pustit opakovaně jako
aktualizace.

> Máš-li Claude Code nasměrovaný jinam přes `CLAUDE_CONFIG_DIR`, klonuj do
> `$CLAUDE_CONFIG_DIR/skills/sagittaras`. Skripty tuto proměnnou respektují.

## Ověření

Restartuj Claude Code a v `/help` zkontroluj sekci skillů — mají být vidět pod
prefixem `sagittaras:`, tedy `sagittaras:make-commit` a spol. Výjimkou je
rozcestník: ten se hlásí jako holé `sagittaras` a volá se `/sagittaras`. Plugin
se v konfiguraci hlásí jako `sagittaras@skills-dir`.

## Aktualizace

Obvyklá cesta je skill — z běžící session:

```
/sagittaras:update-plugin
```

Stáhne poslední stav, vypíše které skilly se změnily a řekne, jestli stačí
`/reload-plugins`, nebo je potřeba restart. Skripty níž zůstávají jako záložní
cesta pro situace, kdy Claude Code neběží.

Stejný skript, který instaluje, i aktualizuje:

```powershell
& "$HOME\.claude\skills\sagittaras\install.ps1"
```

```bash
bash ~/.claude/skills/sagittaras/install.sh
```

Nebo rovnou přes git:

```bash
git -C ~/.claude/skills/sagittaras pull --ff-only
```

## Odinstalace

Smaž složku instalace — plugin nikde jinde nic nezanechává:

```bash
rm -rf ~/.claude/skills/sagittaras
```

```powershell
Remove-Item -Recurse -Force "$HOME\.claude\skills\sagittaras"
```

## Co plugin obsahuje

Tenhle výčet se udržuje ručně a může za instalací zaostávat. Aktuální přehled
dá vždycky `/sagittaras` — rozcestník ho sestavuje z frontmatterů na disku.

**Rozcestník**

| Skill | K čemu |
| --- | --- |
| `sagittaras` | Řekne, co plugin nabízí, a podle rozdělané práce navede na správný skill. Volá se jako `/sagittaras`, bez namespace |

**Práce s gitem**

| Skill | K čemu |
| --- | --- |
| `create-branch` | Založí pracovní větev z čerstvé výchozí větve remotu, název ve tvaru `<type>/<popis>` si nechá potvrdit |
| `make-commit` | Zapíše rozdělanou práci podle Conventional Commits, rozdělí ji do logických celků a pushne; větev bez upstreamu rovnou publikuje |
| `open-pr` | Otevře pull request pro práci na aktuální větvi — název, tělo i `Closes #N`; commit deleguje na `make-commit`, merge nechává člověku, ledaže prompt výslovně žádal i merge |

**Milestone workflow**

Konkrétní práci dělá AI, výsledný kód přezkoumává člověk. Obvyklý průchod je
`plan-milestone` → `run-milestone` → `close-milestone`: plán schvaluješ
potvrzením draftu a spuštěním běhu, každé PR dostaneš k review až poté, co má
každé akceptační kritérium test a ověřovací příkazy nad integrační větví
prošly. Issues implementují subagenti, ve výchozím stavu na sonnet × high —
jinou dvojici řekneš orchestrátorovi. Připomínky píšeš orchestrátorovi, nebo
k PR, kde si je na GitHubu všimne sám; schválené PR merguje orchestrátor.
Issue, které zakládá nový vzor (label `precedent`), orchestrátor nespouští —
naimplementuješ ho v párové session, kterou si založíš sám. Kód Unity projektu
(podsekce Sériové oblasti v konfiguraci) běží po jednom issue přímo v hlavním
checkoutu otevřeném v Editoru — `run-milestone` pak spusť v něm, ne ve worktree. Finální merge do výchozí větve patří tobě.
`review-milestone` a `verify-issue` jsou nástroje na vyžádání, ne povinné
kroky. Po běhu ho můžeš rozebrat `review-run` — report slabin pluginu je
vstupem pro jeho další opravy.

| Skill | K čemu |
| --- | --- |
| `init-workflow` | Jednorázově nastaví projekt pro milestone workflow do sekce „Workflow (sagittaras)" v `CONTRIBUTING.md` — forge, větvení, labely, ověřovací příkazy, případně mapu `area:*` → agent |
| `plan-milestone` | Naplánuje milestone po vlnách — Zadání zakládá jen pro položky s precedentem v kódu a rozpadá je tak, aby PR každého šlo přezkoumat ručně; ostatní nechá v backlogu, nebo je na přání založí jako issue s labelem `precedent` k párové session |
| `triage-issue` | Povýší jeden issue bez ukotvených kritérií (Poznámku) na Zadání s precedentem nalezeným v kódu; bez precedentu nebo u příliš velkého issue jen vysvětlí v komentáři proč |
| `run-milestone` | Provede milestone s člověkem jako recenzentem — odblokovaná issues spouští v subagentech (výchozí sonnet × high), issues zakládající precedent předá tobě k párové session, PR protáhne branou (test ke každému kritériu, ověřovací příkazy) a na schválení člověka je mergne do integrační větve; na konci otevře jedno PR do výchozí větve |
| `implement-issue` | Naimplementuje jedno issue přesně v rozsahu jeho akceptačních kritérií, každé testovatelné pokryje testem a otevře PR s mapou kritérium → test; zapracuje připomínky z review a spuštěný samostatně PR na schválení mergne |
| `close-milestone` | Zavře milestone, u kterého ověřil, že všechna issues jsou zavřená a integrační PR opravdu zmergované |
| `file-issue` | Založí jeden ad hoc issue mimo plánování milestonu jako Poznámku, v závazném tvaru pluginu a se správnými labely |
| `review-milestone` | Na vyžádání: nezávislé review naplánovaného milestonu — kódové ukotvení kritérií, graf závislostí, velikost issues, překryvy a rozpory; report uloží do trackeru |
| `verify-issue` | Na vyžádání: ověří, že PR splňuje kritéria svého issue — spustí ověřovací příkazy a testy kritérií mutačně otestuje; report uloží k PR |
| `review-run` | Jen příkazem `/sagittaras:review-run`: rozebere proběhlý běh `run-milestone` z transkriptů orchestrátoru a jeho subagentů — tokeny, čas, eskalace, odchylky, nálezy ověřené proti verzi pluginu, na které běh jel; report uloží jako markdown vedle repozitáře. Spouštěj v čerstvé session |

**Projektová dokumentace**

| Skill | K čemu |
| --- | --- |
| `write-docs` | Založí znalostní bázi `.docs/` s odkazem z CLAUDE.md, nebo v ní přidá či upraví stránku — místo najde sestupem stromem indexů a strukturu ověří skriptem a zápis nechá zrevidovat subagentem |
| `review-docs` | Nezávislé review znalostní báze s čistým kontextem — věty u odkazů, duplicita s CLAUDE.md a mezi stránkami, umístění v sekci; mechaniku nechává skriptu, neopravuje |
| `read-docs` | Najde v bázi odpověď na otázku — v odděleném kontextu projde mapu stromu, přečte jen stránky, jejichž věta téma pokrývá, a vrátí odpověď s citacemi, doslovná chráněná rozhodnutí a mezery |
| `write-adr` | Sepíše architektonické rozhodnutí (ADR) — interview, dokument podle šablony, větev a PR, nezávislé review |
| `review-adr` | Nezávislé review ADR — konkrétnost rozhodnutí, reálné alternativy, přiznaná cena; verdikt uloží do PR |
| `write-art-bible` | Sepíše nebo aktualizuje art bible projektu — vytěží z repozitáře, co o vzhledu platí, kontrastní poměry počítá |
| `write-ux-spec` | Sepíše UX spec jedné obrazovky nebo flow a nechá ho zrevidovat subagentem |
| `review-ux-spec` | Nezávislé review UX specu — konkrétnost layoutu a stavů, věrnost art bible a ADR; každou citaci ověří ve zdroji |

**Instrukce pro Claude v projektu**

| Skill | K čemu |
| --- | --- |
| `write-claude-md` | Sepíše nebo zeštíhlí CLAUDE.md cílového projektu — cíl ~80 řádků, hlubší dokumentaci odkazuje místo opisování |
| `write-rule` | Vytvoří nebo upraví pravidlo v `.claude/rules/` cílového projektu, ověří `paths` globy a nechá ho zrevidovat subagentem |
| `review-rule` | Nezávislé review rule s čistým kontextem — ověří globy proti repozitáři, vrátí verdikt a nálezy, neopravuje |
| `write-agent` | Vytvoří nebo upraví agenta v cílovém projektu podle matice model × effort × maxTurns |
| `review-agent` | Nezávislé review agenta s čistým kontextem — vrátí verdikt a nálezy, neopravuje |
| `train-agent` | Nechá agenta zapsat si do vlastní trvalé paměti zobecněný poznatek ze zadaného vstupu — typicky z připomínek člověka k PR a commitů, které je zapracovaly |

**Rozšiřování a údržba pluginu**

| Skill | K čemu |
| --- | --- |
| `write-skill` | Vytvoří nebo upraví skill podle konvencí pluginu a nechá ho zrevidovat subagentem |
| `review-skill` | Nezávislé review skillu s čistým kontextem — vrátí verdikt a nálezy, neopravuje |
| `update-plugin` | Stáhne poslední stav do instalace, vypíše co se změnilo a poradí, jestli stačí reload, nebo je nutný restart |

Skripty, na které se skilly odkazují, si cesty kotví přes `${CLAUDE_PLUGIN_ROOT}`,
protože plugin běží nad cizími projekty, kde relativní cesty míří jinam.

## Vývoj

Ostrá instalace v `~/.claude/skills/sagittaras` a vývojová kopie jsou dva
oddělené klony téhož repozitáře. Je to záměr: vývojová kopie leží mimo
`.claude`, takže se její skilly nenačítají a rozdělaná práce neovlivňuje běžící
session. Změny se do ostré instalace dostanou až pushem a aktualizací výše.

Proč skilly vypadají, jak vypadají, a podle jakých principů se mění, popisuje
dokumentace vývoje — vstupem je [.docs/index.md](.docs/index.md), odkud se
pokračuje stromem indexů. Směr, kterým se plugin aktuálně přestavuje (člověk
přezkoumává kód, issues běží v subagentech a nový vzor v párové session, testy ke kritériím), shrnuje
[vize](.docs/vision/index.md).

Plugin se vyvíjí vlastním milestone workflow — konfiguraci nese
[CONTRIBUTING.md](CONTRIBUTING.md). Ověřovací příkaz pro změny skillů:

```bash
bash scripts/lint-skills.sh && bash scripts/docs-check.sh
```

`lint-skills.sh` hlídá, že každý `SKILL.md` má čitelný frontmatter s `name`
a `description`, `docs-check.sh` strukturu
znalostní báze (sirotci, mrtvé odkazy, kotvy). Testy akceptačních kritérií
jednotlivých issues leží v `tests/issue-<číslo>.sh`, testy doprovodných skriptů
v `tests/<název-skriptu>.sh`. Některé běží proti živému repozitáři a potřebují
síť a přihlášené `gh`.

`SKILL.md` v kořeni není součástí `skills/` — do pluginu ho zapojuje položka
`"skills": ["./"]` v `.claude-plugin/plugin.json` a bez ní se nenačte. Slouží
jako rozcestník `/sagittaras`. Přejmenovat ho podle konvence
`<činnost>-<předmět>` nejde: `name` se musí shodovat s názvem pluginu, jinak
se změní i příkaz, kterým se volá.
