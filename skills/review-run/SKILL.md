---
name: review-run
description: >-
  Rozebere jeden proběhlý běh run-milestone z transkriptů orchestrátoru
  a jeho podřazených session a ze stavu trackeru. Skriptem najde transkripty,
  spočítá tokeny a čas po session a zhustí je do výtahů. Výtahy podřazených
  session čtou paralelně subagenti. Každý nález ověří proti textu skillu nebo
  skriptu ve verzi, na které běh jel, a odliší, co aktuální plugin už opravil.
  Výsledkem je report slabin pluginu s důkazy, uložený jako markdown vedle
  repozitáře projektu. Nic neopravuje a do trackeru nepíše.
when_to_use: >-
  Použij, když člověk po běhu milestonu chce vědět, kde plugin zaskřípal —
  „rozeber běh milestonu", „udělej report z run-milestone", „analyzuj, jak
  běžel milestone 3", „kde se orchestrátor zasekl". Spouští se v repozitáři
  projektu, ve kterém běh proběhl. Nepoužívej pro posouzení plánu před během,
  na to slouží review-milestone; pro ověření kritérií jednoho PR verify-issue;
  pro pokračování přerušeného běhu run-milestone; ani pro opravu nálezů v pluginu,
  ta se dělá v repozitáři pluginu podle reportu.
model: opus
effort: xhigh
# Zařazení dle matice: review a hledání chyb → opus × xhigh, bez odchylky.
# Skill sám čte výtah orchestrátoru a každý nález konfrontuje s textem skillu
# ve verzi běhu — přehlédnutý nebo nepodložený nález stojí víc než tokeny.
# Výtahy podřazených session deleguje subagentům na sonnet: jsou ohraničené
# (jedna session = jedno issue) a vracejí jen kandidáty s důkazem, úsudek
# o nálezu dělá skill.
argument-hint: "[číslo nebo název milestonu | cesta nebo uuid transkriptu] [cesta k repozitáři projektu]"
user-invocable: true
disable-model-invocation: true
# Rozbor stojí desítky minut a miliony tokenů — spouští ho jen člověk příkazem.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Agent
  - "Bash(node:*)"
  - "Bash(bash:*)"
  - "Bash(git:*)"
  - ToolSearch
  - mcp__gitea__milestone_read
  - mcp__gitea__list_pull_requests
# Write slouží jen k zápisu reportu (krok 6). Bash(git:*) jen ke čtení historie
# pluginu (show, log); volání skriptů piš ve tvaru `node <cesta>` a `bash <cesta>`.
# ToolSearch načítá odložené nástroje Gitea.
# Node místo bashe: parsování JSONL transkriptů (jednotky MB) grepem je křehké;
# node je na strojích vývojářů pluginu k dispozici, nativní instalace Claude
# Code ho ale nepřináší — test tests/run-transcripts.sh ho předpokládá.
# Vynechaná zvažovaná pole: context: fork — forknutý skill nemůže spouštět
# subagenty, na kterých stojí krok 4; agent — obecný profil nic nepřidá;
# AskUserQuestion — volba běhu má jednoznačné pravidlo (nejnovější, případně
# podle argumentu) a skill má doběhnout bez doptávání; Edit — report vzniká
# jedním zápisem; paths — spouští se příkazem, ne prací nad soubory; shell —
# skripty se spouštějí explicitně; disallowed-tools — allowed-tools je uzavřený
# výčet a skill se spouští jen loaderem; version/license — verzuje se plugin.
---

# Review Run

Cílem je report, podle kterého jde plugin opravit bez transkriptů po ruce:
každý nález má důkaz z běhu a míří na konkrétní místo skillu nebo skriptu.
Tvar reportu určuje `${CLAUDE_PLUGIN_ROOT}/skills/review-run/report-template.md`.

## Skripty

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/skills/review-run/scripts/run-transcripts.mjs` | `find`, `stats`, `digest` — výstupy a návratové kódy v hlavičce skriptu |
| `${CLAUDE_PLUGIN_ROOT}/scripts/gh/milestone-list.sh`, `pr-list.sh` | Stav milestonu a jeho PR na GitHubu |

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

## Postup

### 1. Najdi běh

V repozitáři projektu spusť:

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/review-run/scripts/run-transcripts.mjs" find [--repo "<cesta>"] [--transcript "<cesta|uuid>" | --milestone "<číslo|název>"]
```

Cestu k repozitáři projektu ze zadání předej jako `--repo`, cestu nebo uuid
transkriptu jako `--transcript`, číslo nebo název milestonu jako `--milestone`.
Bez zadání rozebírá `find` nejnovější běh projektu v pracovním adresáři.

| Výsledek | Co uděláš |
| --- | --- |
| kód 0 | pokračuj |
| kód 2 | ohlas `error=` a skonči — chybný argument |
| kód 3 | ohlas `error=`, vypiš kandidáty z `[candidates]` (`transcript=`, `started=`, `milestone_arg=`) a skonči — člověk může zadat `--transcript` |
| kód 4 | ohlas `error=` a skonči — nestojíš v repozitáři nebo chybí adresář transkriptů |
| `node` nenalezen | ohlas, že `review-run` potřebuje `node` v PATH (README, Předpoklady), a skonči |

Z výstupu si drž `repo_root=`, `[candidates]`, `orchestrator=`, `started=`,
`ended=`, `model=`, `milestone_arg=`, `repo=`, `repo_source=`,
`integration_branch=`, `plugin_root=`, `plugin_commit=`, `plugin_commit_source=`,
`plugin_head=` a sekce `[sessions]` a `[agents]`. Cesty dosazuj do dalších
příkazů v uvozovkách.

- Řádky `[sessions]` téhož `issue=` patří k jedné práci: session, její vlastní
  subagenti (`<label>-a<k>`) a případný další pokus (`<label>-2`).
- `session=unknown` → transkript téhož issue bez záznamu o spuštění; rozebírej
  ho jako další session a ve Zdrojích dat ho tak označ.
- `transcript=missing` → zapiš session do Zdrojů dat jako chybějící a rozebírej
  bez ní.
- Jiný kandidát se stejným `milestone_arg` je jiný pokus o týž milestone —
  podle `started=` dřívější, nebo pozdější. Uveď ho v sekci 2 reportu.

### 2. Stav trackeru

Z `CONTRIBUTING.md` › `## Workflow (sagittaras)` vezmi forge, repozitář, jazyk
issues, ověřovací příkazy a Agenty. Sekce chybí → pokračuj bez trackeru jako
při jeho výpadku (níže). Repozitář z konfigurace se liší od `repo=`
s `repo_source=prompt` → platí `repo=`, s tím běh jel; jinak platí konfigurace.

Milestone hledej podle `milestone_arg` — číslem, nebo názvem či slugem ve výpisu
milestonů; prázdný `milestone_arg` → podle slugu z `integration_branch=`
(`milestone/<slug>`).

- GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/milestone-list.sh" -R <repo> --state all`
  a `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-list.sh" -R <repo> --milestone <číslo> --state all`.
- Gitea: načti `mcp__gitea__milestone_read` a `mcp__gitea__list_pull_requests`
  přes ToolSearch, pak `milestone_read` → `list` a `list_pull_requests` s `milestone`
  a `state: "all"`; stránkuj (`page`), dokud stránka nemá méně než 30 položek.

Časy otevření a merge PR ber z trackeru, ne z transkriptu. Selže-li tracker
(GitHub kód 7 nebo chyba `gh`, chyba nástroje Gitea), pokračuj bez něj: časy PR
ber z výtahu orchestrátoru a do Zdrojů dat zapiš, že tracker nebyl dostupný.

### 3. Statistiky

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/review-run/scripts/run-transcripts.mjs" stats "orch=<orchestrator>" "<label>=<transcript>"...
```

Předej všechny řádky `[sessions]` i `[agents]` pod jejich `label=`; řádky
`transcript=missing` vynech. Řádky `label=` jdou do sekce 4 reportu — `orch-a<k>`
sečti do řádku pomocných agentů orchestrátora, `<label>-a<k>` k jejich session —
a `total_*` do Shrnutí. Kód 2 → porovnej cestu na stderr s výstupem `find`:
liší-li se, oprav volání; jinak transkript mezitím zmizel, vynech ho a zapiš jako
chybějící.

### 4. Výtahy

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/review-run/scripts/run-transcripts.mjs" digest "orch=<orchestrator>" "<label>=<transcript>"...
```

Štítky a kód 2 jako v kroku 3; výtahy leží v `out_dir=` jako `<label>.txt`.

Výtah orchestrátoru (`orch.txt`) přečti celý sám, po částech. Hledej v něm
eskalace, odchylky od `run-milestone`, červené brány, chyby skriptů
(`RESULT[error]`), opakovaná kola se session a místa, kde orchestrátor
improvizoval, protože skill nedal odpověď. Výtahy `orch-a<k>` (review a jiné
pomocné subagenty orchestrátora) čti jen tam, kam tě výtah orchestrátoru
odkáže.

Výtahy `[sessions]` rozděl po čtyřech issue — výtahy téhož `issue=` vždy do
jedné skupiny — a pro každou skupinu spusť v jedné zprávě subagenta nástrojem
Agent: `subagent_type: "general-purpose"`, `model: "sonnet"`, synchronně, se
zadáním podle Formátu výstupu. Z jejich odpovědí ber kandidáty, ne hotové
nálezy.

### 5. Nálezy proti pluginu

Každého kandidáta z kroku 4 ověř proti souboru pluginu, kterého se týká, ve verzi
běhu:

```bash
git -C "<plugin_root>" show <plugin_commit>:<cesta v pluginu>
```

Při `plugin_commit=unknown` čti aktuální soubor a do hlavičky reportu zapiš, že
verzi běhu nešlo určit; krok s `git log` níže pak vynech.

Kandidát se stává nálezem, jen když ukážeš pravidlo nebo chování skillu či
skriptu, které ho způsobilo nebo ho nezachytilo. Kandidát bez opory v textu
pluginu patří do Odchylek (orchestrátor nedodržel jasné pravidlo) nebo se
zahazuje.

Liší-li se `plugin_commit` od `plugin_head`, zjisti u každého nálezu:

```bash
git -C "<plugin_root>" log --oneline <plugin_commit>..HEAD -- <cesta v pluginu>
```

Řeší-li aktuální text problém, přesuň nález do sekce Už opraveno s commitem
opravy; jinak u nálezu uveď, že od běhu změněno, ale problém trvá.

Závažnost:

| Závažnost | Kritérium |
| --- | --- |
| vysoká | doslovné provedení skillu vede ke špatnému výsledku nebo zastaví běh u každého issue |
| střední | stojí eskalaci, kolo session navíc nebo ruční obchvat |
| nízká | ergonomie, zbytečná volání, nejasný výstup |

### 6. Report

Otevři `${CLAUDE_PLUGIN_ROOT}/skills/review-run/report-template.md` a podle něj
report sepiš. Ulož ho do složky nad `repo_root=` jako
`run-milestone-report-<název repozitáře>-m<číslo milestonu>.md`; číslo bez
trackeru neznáš → místo `m<číslo>` použij slug z `integration_branch=`. Soubor
toho jména existuje → přidej před příponu `-<datum rozboru>` a existující
nepřepisuj.

V konverzaci pak vypiš cestu k reportu a hlavní zjištění ze Shrnutí.

## Formát výstupu

### Zadání pro subagenta

```
Přečti výtahy podřazených session jednoho běhu run-milestone a vrať kandidáty
na slabiny pluginu sagittaras. Nic neopravuj a na nic se neptej.

- Výtahy: <cesty k souborům <label>.txt>; výtahy téhož issue (<issue>, <issue>-a1,
  <issue>-2…) jsou jedna práce — session, její subagent a další pokus
- Skill, podle kterého session pracovaly, ve verzi běhu:
  git -C "<plugin_root>" show <plugin_commit>:skills/implement-issue/SKILL.md
  [při plugin_commit=unknown: <plugin_root>/skills/implement-issue/SKILL.md]
- Formát výtahu: řádky „HH:MM DRUH: text"; DRUH je PROMPT (zadání session),
  PEER (zpráva od orchestrátoru — signál brány nebo připomínek), HUMAN, NOTE,
  SKILL, AI, TOOL, RESULT, RESULT[error], COMPACT.

Pro každou session vrať:
- Výsledek: PR (číslo), počet kol po otevření PR a jejich spouštěč
  (připomínky, brána, konflikt).
- Kandidáti: každý jako „HH:MM · co se stalo · doslovná citace z výtahu ·
  které pravidlo implement-issue nebo který skript se toho týká (nebo „žádné")".
  Hledej eskalace a jejich důvod, chyby nástrojů a skriptů, kroky, kde session
  improvizovala nebo se od skillu odchýlila, a opakovanou práci.
- Co fungovalo: nejvýš dva body s citací.

Nepřidávej nic, co ve výtahu není doložené.
```

## Zásady

- Report popisuje plugin, ne projekt: chyba v kódu projektu je nález jen tehdy,
  když ji měl skill nebo skript zachytit.
- Mimo report nic nezapisuj — do projektu, do pluginu ani do trackeru.
