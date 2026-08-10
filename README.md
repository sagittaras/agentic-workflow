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

| Skill | K čemu |
| --- | --- |
| `sagittaras` | Rozcestník — řekne, co plugin nabízí, a podle rozdělané práce navede na správný skill. Volá se jako `/sagittaras`, bez namespace |
| `create-branch` | Založí pracovní větev z čerstvé výchozí větve remotu, název ve tvaru `<type>/<popis>` si nechá potvrdit |
| `make-commit` | Zapíše rozdělanou práci podle Conventional Commits, rozdělí ji do logických celků a pushne; větev bez upstreamu rovnou publikuje |
| `write-skill` | Vytvoří nebo upraví skill podle konvencí pluginu a nechá ho zrevidovat subagentem |
| `review-skill` | Nezávislé review skillu s čistým kontextem — vrátí verdikt a nálezy, neopravuje |
| `write-agent` | Vytvoří nebo upraví agenta v cílovém projektu podle matice model × effort × maxTurns |
| `review-agent` | Nezávislé review agenta s čistým kontextem — vrátí verdikt a nálezy, neopravuje |
| `train-agent` | Nechá agenta nastudovat zadaný vstup a zapsat si z něj do vlastní trvalé paměti, co se týká jeho role |
| `write-claude-md` | Sepíše nebo zeštíhlí CLAUDE.md cílového projektu — cíl ~80 řádků, hlubší dokumentaci odkazuje místo opisování |
| `write-rule` | Vytvoří nebo upraví pravidlo v `.claude/rules/` cílového projektu, ověří `paths` globy a nechá ho zrevidovat subagentem |
| `review-rule` | Nezávislé review rule s čistým kontextem — ověří globy proti repozitáři, vrátí verdikt a nálezy, neopravuje |
| `update-plugin` | Stáhne poslední stav do instalace, vypíše co se změnilo a poradí, jestli stačí reload, nebo je nutný restart |

Skripty, na které se skilly odkazují, si cesty kotví přes `${CLAUDE_PLUGIN_ROOT}`,
protože plugin běží nad cizími projekty, kde relativní cesty míří jinam.

## Vývoj

Ostrá instalace v `~/.claude/skills/sagittaras` a vývojová kopie jsou dva
oddělené klony téhož repozitáře. Je to záměr: vývojová kopie leží mimo
`.claude`, takže se její skilly nenačítají a rozdělaná práce neovlivňuje běžící
session. Změny se do ostré instalace dostanou až pushem a aktualizací výše.

`SKILL.md` v kořeni není součástí `skills/` — do pluginu ho zapojuje položka
`"skills": ["./"]` v `.claude-plugin/plugin.json` a bez ní se nenačte. Slouží
jako rozcestník `/sagittaras`. Přejmenovat ho podle konvence
`<činnost>-<předmět>` nejde: `name` se musí shodovat s názvem pluginu, jinak
se změní i příkaz, kterým se volá.
