---
name: run-milestone
description: >-
  Provede naplánovaný milestone s člověkem jako recenzentem: sestaví graf
  závislostí z issues, založí integrační větev a odblokovaná issues spouští
  v subagentech (výchozí sonnet × high), kolik jich člověk stačí průběžně
  přezkoumat; issue zakládající precedent předá člověku k párové session.
  Každé PR protáhne branou — test ke každému kritériu a ověřovací příkaz nad
  integrační větví — a teprve pak ho předá člověku. Jeho připomínky, psané
  orchestrátorovi nebo do PR, předává agentovi, který PR vystavil; na jeho schválení PR
  sám mergne do integrační větve. Po merge zavře issue, odblokuje další práci,
  přijme novou vlnu z plan-milestone a na konci předloží jedno PR do výchozí
  větve. Sám neimplementuje ani nerecenzuje.
when_to_use: >-
  Použij, když je milestone naplánovaný a má se začít implementovat —
  „spusť milestone", „proveď ten milestone", „rozjeď issues z milestonu" —
  nebo když se má dokončit přerušený běh milestonu. Spuštěním člověk plán
  schvaluje, review plánu se nevyžaduje.
  Nepoužívej pro sestavení plánu a založení issues, na to slouží
  plan-milestone; pro agentní posouzení plánu na vyžádání review-milestone;
  pro jediné issue implement-issue, ten si spusť přímo; pro nezávislé
  ověření kritérií konkrétního PR verify-issue. Zavření milestonu po merge
  dělá close-milestone, rozbor proběhlého běhu review-run.
argument-hint: "[milestone — název, číslo nebo slug] [model × effort agentů]"
model: opus
effort: high
# Zařazení dle matice: orchestrace workflow → opus × xhigh; odchylka o stupeň
# na high (26. 11. 2026). Orchestrátor nesoudí kvalitu a nečte diffy (merge je
# jedno volání skriptu) a xhigh držel jen proto, že start_session dával
# podřazené session effort nejvýš orchestrátorův. Subagenti dostávají model
# i effort parametrem nástroje Agent, nezávisle na orchestrátoru. Sonnet
# uživatel nechtěl: běh je dlouhý, se souběhem issues, a v M1 se od postupu
# odchýlil i opus (D1–D7).
# Rozhodnutí, na kterých tělo stojí:
# - Subagenti místo podřazených session (vize 2.11, 26. 11. 2026): start_session
#   neumí zvolit model, effort ani agenta, takže session běžela na modelu
#   orchestrátoru a agenta z mapy si musela delegovat sama. Issue nese zadání
#   ukotvené v kódu a autonomního uvažování potřebuje málo → výchozí sonnet ×
#   high. Pořadí volby je rozhodnutí uživatele: jeho preference > model a effort
#   z definice agenta z mapy Agenti > sonnet × high.
# - Model z frontmatteru implement-issue (opus × xhigh) subagenta nepřepne:
#   v transkriptech běhů z 20. 8. 2026 zůstali subagenti na sonnetu i po
#   vyvolání implement-issue. Dvojici proto drží parametr nástroje Agent.
# - Agenta jde spustit z kteréhokoli turnu; odpadlo omezení start_session
#   v turnu po notifikaci (M1, F6) i hlášení „spustím po tvé další zprávě".
# - Issue s labelem precedent orchestrátor nespouští (vize 1.3, 2.11): zakládá
#   vzor, a ten vzniká v páru. Párovou session si člověk založí sám — s modelem
#   a effortem podle velikosti práce, což start_session neuměl.
# - Připomínky: do subagenta člověk v desktopu psát nemůže. Píše je sem
#   (orchestrátor je přepošle doslova), nebo do PR. PR hlídá gh/pr-watch.sh na
#   pozadí: v M1 šlo všech 22 kol review přímo do session a signál přes
#   orchestrátora se nepoužil ani jednou — člověk píše tam, kde práce leží.
#   Hlídač stojí jeden GraphQL dotaz za minutu a žádné tokeny. Gitea ho nemá.
#   Merge hlásí podle mergedAt, ne podle toho, jestli PR viděl otevřené — jinak
#   by se ztratilo PR z párové session otevřené a mergnuté mezi spuštěními.
#   Hotové precedent issue přesto kryje i signál člověka „#D hotové" a kontrola
#   forge u každé jeho zprávy: hlídač bez otevřeného PR skončí idle.
# - Odpověď na eskalaci agenta jde signálem Rozhodnutí: se session zmizel
#   kanál, kterým člověk odpovídal přímo tam, kde se agent zastavil.
# - Zadání pro agenta žádá příkazy v popředí: že doběhnutí příkazu na pozadí
#   subagenta znovu probudí, ověřené není (u session ano), a „PR: rozpracováno"
#   by pak viselo do další zprávy člověka.
# - Definici agenta hledá scripts/agent-model.sh podle name: rekurzivně, jako
#   ji zapisuje init-workflow; nenalezenou ohlásí, ať sonnet × high nepřebije
#   dvojici z definice potichu. Agent z mapy teď sám provádí implement-issue
#   (dřív ho session jen pověřila implementací), takže potřebuje Skill a Bash;
#   definice z write-agent mají explicitní tools, a bez nich by agent u každého
#   issue oblasti skončil eskalací — proto can_run_skills a general-purpose.
# - Agenti končí v libovolném pořadí — pozorovaná chyba (16. 11. 2026, ještě
#   se session): orchestrátor, který si je zapsal jako kroky seznamu úkolů,
#   čekal na první, i když pozdější už skončil. Proto výslovný zákaz v kroku 4.
# - Dávka = kapacita člověka na review, ptá se na ni na startu (navrhuje 3).
# - Dvě červené brány po sobě u téhož PR → eskalace, jinak by se agent
#   s orchestrátorem mohl točit donekonečna. Konflikt proti jiné špičce
#   integrační větve, než byl předchozí, se nepočítá: v běhu M1 (17. 11. 2026)
#   způsobil 7 z 8 červených bran konflikt po merge souběžného PR, ne session.
#   Proto brána vypisuje integration_sha=. Selhaný příkaz (kód 6) se počítá
#   vždy — jinak by pojistka při souběžných merge přestala fungovat.
# - Průběžný sync integrační větve s výchozí odpadl: přetahoval by se o větev
#   s merge PR do ní. Sync je v závěru, nebo na žádost člověka.
# - Merge dělá orchestrátor (issue #70, běh milestonu #4): přeposlané
#   „Schváleno" klasifikátor auto mode za slovo člověka nebere a merge zamítne
#   jako Merge Without Review. Allow pravidlo plugin dodat nemůže (klasifikátor
#   čte jen ~/.claude/settings.json) a když sedne, obejde klasifikátor úplně.
#   Merguje proto ten, komu člověk schválení napsal. Konflikt řeší dál agent.
# - Brána před merge se přeskočí jen přes integration-gate.sh --same-as: skript
#   porovná SHA obou větví se zelenou branou před review v témže volání, takže
#   kontrola nestojí nic navíc (M1: #83 a #85 schválené hned po bráně).
# - Brána před review jde na GitHubu jedním skriptem gh/pr-gate.sh (rozbor tokenů
#   běhu M1, 17. 11. 2026): orchestrátor měl 216 volání s průměrným kontextem
#   221k a brána s čtením těl a zápisem do trackeru ho stála 4–5 volání na běh.
#   Skript bere hlavu PR z forge — ručně psaný název větve skončil v M1 kódem 2 —
#   a výstup ověřovacího příkazu vypisuje jen při neúspěchu.
# - Sdílené soubory se čtou podmíněně: v M1 je orchestrátor načetl hned na startu
#   (~8k tokenů) a nesl je ~200 voláními, přitom GitHubová větev má příkazy
#   přímo v těle.
# - Hlášení žádá číslo PR: klasifikátor nevidí výstupy nástrojů, takže „issue #44
#   může mergovat" s merge PR #62 spojit nemusí. Schválení číslem issue se přesto
#   bere, sedí-li na jedno PR — v M1 tak přišla většina schválení a auto mode
#   žádné nezamítl; zamítne-li, krok 6 požádá o „mergni PR #n".
# - Výsledek agenta čte orchestrátor z forge: zpráva je self-report (u session
#   v M1 navíc oříznutá na ~400 znaků, F7). Po merge se ostatní PR kontrolují
#   na konflikt, aby oprava běžela během review, a schválení po opravě
#   konfliktu platí dál — člověk v M1 nové nechtěl (F2). PR pro víc issues ani
#   issue mimo milestone běh nepřijímá, opravuje se tracker (F5, E1).
# - Review plánu se nehledá (vize 2.10): plán validuje člověk a spuštěním běhu
#   ho schvaluje. Jeho mechanickou část hlídá běh sám — graf a Poznámku
#   v kroku 1 u každého otevřeného issue, `area:*` v kroku 3.
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - ToolSearch
  - Agent
  - SendMessage
  - Skill
  - AskUserQuestion
  - mcp__gitea__milestone_read
  - mcp__gitea__issue_read
  - mcp__gitea__issue_write
  - mcp__gitea__list_issues
  - mcp__gitea__pull_request_read
  - mcp__gitea__pull_request_write
  - mcp__gitea__pull_request_review_write
  - mcp__gitea__list_pull_requests
# Výčet mcp__gitea__* odpovídá řádku „Orchestruje celý milestone" ve sdílených
# receptech; pull_request_write nese merge, pull_request_review_write komentář
# s výsledkem brány.
# Chybějící Write/Edit je hranice: orchestrátor nemá jak začít opravovat cizí
# PR. Těla pro criteria-tests.sh vznikají přesměrováním výstupu skriptů, na
# Gitea heredocem v Bash.
# Bash je nezúžený, protože integration-gate.sh dostává libovolný ověřovací
# příkaz projektu (`dotnet build`, `pnpm test`, …); na pozadí v něm běží hlídač
# PR. Agent spouští implementaci, SendMessage na agenta navazuje s jeho
# kontextem. start_session a list_sessions vypadly se subagenty (2.11).
# disable-model-invocation: false — brzdou proti omylu jsou čtecí kroky před
# první zapisovací akcí (graf, dávka) a eskalace, ne zakázané vyvolání.
# Vynechaná zvažovaná pole: disallowed-tools — allowed-tools je uzavřený výčet;
# context/agent — fork by odřízl člověka, který posílá signály a odpovídá na
# eskalace; background — běh je rozhovor s člověkem; paths — spouští se
# z konverzace nad celým repozitářem; shell — skripty se volají explicitním
# `bash`; version/license — verzuje se celý plugin.
---

# Run Milestone

Řídíš běh milestonu: spouštíš issues v subagentech, hlídáš bránu, předáváš připomínky
člověka a na jeho schválení merguješ. **Kód nepíšeš a kvalitu nesoudíš** — implementuje
agent, kód přezkoumává člověk.

| Soubor | Kdy ho otevřít |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | v kroku 1, jen když v konfiguraci nenajdeš sekci, kterou potřebuješ |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | Gitea: před prvním sáhnutím na tracker. GitHub: jen pro operaci, kterou tenhle skill nejmenuje skriptem |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | jen když skript vrátí kód, který tenhle skill nemapuje |
| `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` | v kroku 1, nejsi-li si jistý čtením `Závisí na` |

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

## Postup

Kroky 1 a 2 běží jednou. Kroky 3–7 běží souběžně pro všechna rozběhnutá issues,
dokud nejsou všechna zavřená nebo eskalovaná. Pak krok 8. Krok 9 platí po celou dobu.

### 1. Před startem

**Konfigurace.** Ze sekce `## Workflow (sagittaras)` v `CONTRIBUTING.md` potřebuješ
`Forge`, `Větvení` a `Ověřovací příkazy`. Chybí-li soubor, sekce nebo některá z nich,
řekni která, odkaž na `/sagittaras:init-workflow` a skonči. `Agenti` je nepovinná.

**Forge.** Gitea → jedním `ToolSearch` načti nástroje z řádku „Orchestruje celý
milestone" a k nim `SendMessage`. GitHub → `ToolSearch` jen na `SendMessage`, pak
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/milestone-list.sh" -R "<owner/repo>" --state open`;
kód 7 ohlas hned. `-R owner/repo` patří do každého `gh` volání.

**Milestone** urči ze zadání. Sedí na víc otevřených milestonů nebo na žádný → zeptej se.

**Issues.** Vypiš všechna issues milestonu, otevřená i zavřená. GitHub:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-list.sh" -R "<owner/repo>" --milestone "<název>" --state all`.
Gitea: podle receptu, včetně stránkování po 30 a filtru na PR. Nesedí-li počet
s `open_issues` + `closed_issues`, eskaluj.

**Graf** sestav ze sekce `Závisí na` každého těla. Cyklus nebo odkaz na otevřené issue
mimo milestone → eskaluj. Otevřené issue, které je Poznámka — `Akceptační kritéria` jsou
prázdná nebo `Reference` chybí —, nespouštěj a eskaluj s odkazem na
`/sagittaras:triage-issue`; issue s labelem `precedent` z téhle kontroly vynech. Nadpisy
čti doslova: issue s přeloženým nadpisem šablony (`## Acceptance criteria`) brána
nepřečte — nespouštěj ho a navrhni opravu (krok 9).

**Rozpracovanost.** Ke každému otevřenému issue najdi PR podle těla, nikdy podle názvu
větve — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-issue.sh" -R "<owner/repo>"
<issue> --base <integrační větev>`, Gitea: recept „Najdi PR patřící k issue".

| Stav | Kam |
| --- | --- |
| bez PR | krok 3 |
| otevřené PR, issue bez labelu `precedent` | krok 5 — bránu pusť znovu, je levná |
| otevřené PR, issue s labelem `precedent` | čeká na párovou session (krok 3) |
| zmergované PR | krok 7 |

**Dávka.** Zeptej se, kolik issues má běžet souběžně — tolik, kolik PR člověk stačí
průběžně přezkoumat. Navrhni 3. Hodnota platí, dokud ji člověk nezmění.

**Model agentů.** Dvojici model × effort urči pro každého agenta zvlášť; platí první
zdroj, který hodnotu má:

1. preference člověka ze zadání nebo z pozdější zprávy („agenty pusť na opus × xhigh",
   i jen pro konkrétní issue) — platí pro agenty spuštěné po ní;
2. agent z mapy `Agenti`: `model=` a `effort=` z jeho definice —
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/agent-model.sh" <jméno>
   ```
   `found=false` ohlas v Hlášení („definice <jméno> nenalezena") a pokračuj bodem 3;
3. `sonnet` × `high`.

Prázdnou hodnotu doplň z dalšího bodu. U `haiku` effort nepředávej.
`can_run_skills=false` (agent nemá `Skill` nebo `Bash`, implement-issue by neprovedl)
→ issues té oblasti spouštěj jako `"general-purpose"` se stejnou dvojicí a ohlas to
v Hlášení.

### 2. Integrační větev

Slug odvoď z názvu milestonu vždy stejně: malá písmena, bez diakritiky, každý znak
mimo `a-z0-9` → pomlčka, opakované pomlčky slouč, krajní ořízni. Existuje-li už větev
`milestone/*` k tomuhle milestonu, použij ji.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/milestone-branch.sh" <slug>
```

`created=false` → navazuješ na přerušený běh. Kód 2, 3 nebo 4 → eskaluj.

### 3. Spuštění issues

Spusť každé issue ve stavu „bez PR", jehož závislosti jsou všechny zavřené — dokud
počet rozběhnutých issues (agent běží, brána, čeká na člověka) nedosáhne dávky.
Eskalované issue místo nezabírá; vrátí-li ho člověk do práce, zabírá ho znovu. Chybí-li
na issue `area:*` label, nespouštěj a eskaluj.

**Issue s labelem `precedent`** nespouštěj: zakládá vzor, a ten vzniká v párové
session, kterou si člověk založí sám. Jakmile má zavřené závislosti, ohlas ho Hlášením;
místo v dávce nezabírá. Hotové je, až ve forge najdeš jeho PR zmergované do integrační
větve — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-issue.sh" -R "<owner/repo>"
<issue> --base <integrační větev> --state all`, Gitea: recept „Najdi PR patřící k issue".
Kontroluj to při každé zprávě člověka a při `event=merged` hlídače; zmergované → krok 7.

Ostatní spusť nástrojem `Agent`, každé zvlášť:

| Parametr | Hodnota |
| --- | --- |
| `description` | `Issue #<číslo>` |
| `subagent_type` | agent z mapy `Agenti` pro oblast issue; chybí-li řádek nebo celá podsekce, `"general-purpose"` |
| `model`, `effort` | podle Modelu agentů z kroku 1 |
| `isolation` | `"worktree"` |
| `prompt` | Zadání pro agenta (Formát výstupu) |

Veď si přehled issue → id agenta → PR → stav → model × effort. Totéž issue nespouštěj
podruhé, dokud jeho agent existuje.

**Otevřené PR bez agenta** (běh navazuje na přerušený): signál z kroků 5–7 mu pošli
tak, že spustíš nového agenta stejnými parametry se Zadáním pro navázání.

### 4. Výsledek agenta

Čekej na notifikace, nepolluj. **Agenti končí v libovolném pořadí.** Každá notifikace
jmenuje, kdo skončil — zpracuj právě tenhle výsledek a čekej dál. Na konkrétního agenta
nečekej a souběžná issues nezapisuj jako kroky seznamu úkolů, které se plní po pořadí:
issue, které skončí dřív, by čekalo na to, které jsi spustil první.

O výsledku agenta i o jeho odpovědi na signál rozhoduje forge, zpráva je jen podnět.
U každé notifikace najdi otevřené PR issue —
GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-issue.sh" -R "<owner/repo>"
<issue> --base <integrační větev> --state open`, Gitea: recept „Najdi PR patřící k issue".
Rozhoduje první řádek tabulky, který sedí:

| Zpráva a forge | Co uděláš |
| --- | --- |
| zpráva má řádek `PR: rozpracováno — …` | pošli agentovi signál „Dokonči" (`SendMessage`); podruhé po sobě eskaluj |
| zpráva má řádek `PR: žádné — <důvod>` | eskaluj, neposílej znovu |
| forge vrátí otevřené PR | krok 5 |
| PR není | pošli totéž zadání jednou znovu (`SendMessage` na id agenta); podruhé eskaluj |

### 5. Brána před review

Pro PR z kroku 4, i pro každé, které agent po připomínkách aktualizoval:

GitHub — jedno volání; skript přečte těla, hlavu PR vezme z forge, pustí testy
kritérií i integrační bránu a při úspěchu zapíše odškrtnutá kritéria a komentář
„Brána prošla". Nemá-li oblast ověřovací příkaz, vynech `--` i příkaz.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-gate.sh" -R "<owner/repo>" <číslo PR> \
  --issue <issue> --base <integrační větev> -- <ověřovací příkaz oblasti>
```

Gitea — v jednom volání Bash založ `d="$(mktemp -d)"`, vypiš `echo "dir=$d"`, zapiš
těla z `issue_read` a `pull_request_read` do `$d/issue.md` a `$d/pr.md` (heredoc,
ukončovač v uvozovkách) a spusť
`criteria-tests.sh --issue-body "$d/issue.md" --pr-body "$d/pr.md" --base <integrační
větev> --head <head větev PR> --ticked-body "$d/ticked.md"`; při kódu 0
`integration-gate.sh <head větev PR> <integrační větev> -- <příkaz>` (bez příkazu
vynech `--`). Prošlo-li obojí,
nahraj `ticked.md` jako tělo issue a pošli komentář podle Formátu výstupu; cestu
z řádku `dir=` piš v dalších voláních doslova a adresář pak smaž.

| Výsledek | Co uděláš |
| --- | --- |
| kód 0 | → krok 6 |
| kód 1, 5 nebo 6 | pošli agentovi signál „Brána neprošla" s řádky `fail=`, nebo se sekcí `[conflicts]` či `[output]`; po jeho odpovědi krok 4 |
| druhá červená brána po sobě u téhož PR | eskaluj. Konflikt (kód 5) ale eskaluj, jen když i předchozí brána skončila konfliktem se stejným `integration_sha=`; jinak se počítá jako první červená |
| kód 2, 3, 4 nebo 7 | eskaluj — vadné issue, výpadek nebo nezapsaný výsledek, ne chyba agenta |

`check=skipped` znamená, že pro oblast není ověřovací příkaz: uveď to v hlášení.

### 6. Předání člověku a merge

Platí-li pro PR schválení (níže), mergni. Jinak ohlas, že PR čeká na člověka
(Hlášení), a na GitHubu spusť hlídač PR, neběží-li (níže).

| Signál od člověka | Co uděláš |
| --- | --- |
| „PR #N má připomínky" | pošli agentovi signál „Připomínky" (`SendMessage`); obsah nečti, agent si ho přečte z PR. Po jeho odpovědi krok 4 |
| připomínky k PR #N napsané sem | pošli je agentovi doslova signálem „Připomínky ze zprávy"; po jeho odpovědi krok 4 |
| odpověď na eskalaci agenta | pošli ji agentovi doslova signálem „Rozhodnutí"; po jeho odpovědi krok 4 |
| „#N hotové", „PR #N zmergované" u issue s labelem `precedent` | ověř merge ve forge (krok 3); zmergované → krok 7, jinak řekni, co ve forge vidíš |
| „mergni PR #N", „PR #N schváleno", i jinými slovy | mergni sám (níže) |

Běží-li agent toho PR, signál mu pošli až po jeho výsledku (krok 4). Agent, který
už neexistuje, dostane signál v novém agentovi (krok 3): s PR přes Zadání pro
navázání, bez PR přes Zadání pro agenta se signálem připojeným na konec.

Schválení smí jmenovat číslo issue místo PR („34 může být zmergované"): platí, sedí-li
na právě jedno PR v přehledu, které prošlo branou; jinak se zeptej, které PR myslí.
Schválení předem („až projde, mergni") uplatni, jakmile brána poprvé projde.
Schválení, které přišlo po zelené bráně, přežije jen kola s opravou konfliktu
(kód 5); po kódu 1 nebo 6 jde PR ke schválení znovu. Jmenuje-li schválení jiný cíl
než integrační větev („pošli na main"), zeptej se — merguješ jen do integrační větve.

Schválení agentovi nepřeposílej: zprávu od orchestrátoru klasifikátor auto mode
za schválení člověka nebere a merge v ní zamítne.

**Hlídač PR** (jen GitHub; na Gitea připomínky v PR ohlásí člověk signálem). Spusť ho
v Bash s `run_in_background: true`, poprvé bez `--since`, pak vždy s `next_since=`
z jeho posledního výstupu:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-watch.sh" -R "<owner/repo>" --base <integrační větev> --since <next_since>
```

Když skončí, zpracuj každý řádek `event=`:

| Výstup | Co uděláš |
| --- | --- |
| `event=feedback` u PR z přehledu | jako signál „PR #N má připomínky" |
| `event=merged` u PR, které jsi nemergoval ty | krok 7 |
| `event=closed` u PR z přehledu | eskaluj — zavřené bez merge |
| `event=feedback` nebo `event=closed` u PR mimo přehled, `event=merged` u tvého merge | nic |
| `event=idle` | znovu ho nespouštěj, dokud nějaké PR nebude čekat na člověka |
| `event=timeout` | spusť ho znovu |
| kód 2, 3 nebo 7 | eskaluj |

Pak ho spusť znovu, čeká-li na člověka aspoň jedno PR. Navazuješ-li na přerušený
běh, požádej v Hlášení člověka, ať připomínky napsané do PR během přerušení zopakuje
signálem — hlídač začíná od času spuštění.

**Merge.** Napřed zopakuj bránu proti aktuální špičce integrační větve. Větev PR vezmi
z řádku `head=` a SHA z řádků `pr_sha=` a `integration_sha=` poslední zelené brány
před review (krok 5) — ne z kontroly konfliktu v kroku 7. Nepohnula-li se od ní ani
jedna větev, skript bránu znovu nespustí a vrátí `reused=true`. Nemáš-li SHA v kontextu,
`--same-as` vynech:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/integration-gate.sh" <head větev PR> <integrační větev> \
  --same-as <pr_sha> <integration_sha> -- <ověřovací příkaz oblasti>
```

| Brána | Co uděláš |
| --- | --- |
| kód 0 | mergni |
| kód 5 nebo 6 | nemerguj; pošli agentovi signál „Brána neprošla", po jeho odpovědi krok 4 |
| kód 2 nebo 3 | eskaluj |

Mergni receptem „Mergni PR" se strategií ze sekce `Větvení` a se smazáním zdrojové
větve. GitHub (u `squash` přepínač `--squash`):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R "<owner/repo>" <číslo PR> --squash --delete-branch
```

Gitea: `pull_request_write` → `merge` s `merge_style` podle `Větvení` a `delete_branch`.
Odmítne-li merge forge, neobcházej ho (žádný `--admin`) a eskaluj. Zamítne-li ho
auto mode, požádej člověka, ať napíše „mergni PR #<n>". Po merge krok 7.

Dokud je v dávce místo, spouštěj mezitím další odblokovaná issues (krok 3).

### 7. Po merge

Ověř ve forge, že PR je zmergované do integrační větve, a issue zavři — GitHub:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-update.sh" -R "<owner/repo>" <issue> --state closed`,
Gitea: recept „Zavři issue". `Closes #N` mimo výchozí větev nezabírá. U PR mimo
přehled (párová session, merge člověkem ve forge) vezmi issue z `Closes #N` v těle PR
(GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-read.sh" -R "<owner/repo>" <číslo PR> --body`);
nevede-li na issue milestonu, nic nezavírej.

Hned potom:

1. Spusť issues, která merge odblokoval, a doplň uvolněné místo v dávce (krok 3).
2. Ostatní otevřená PR, která prošla branou, zkontroluj jen na konflikt s novou
   špičkou. Postupně v jednom volání Bash, ne paralelně — souběžné fetche se
   zamknou:

   ```bash
   for h in <head větve PR>; do echo "head=$h"; bash "${CLAUDE_PLUGIN_ROOT}/scripts/integration-gate.sh" "$h" <integrační větev>; echo "exit=$?"; done
   ```

   `exit=5` → pošli agentovi toho PR signál „Brána neprošla" se sekcí `[conflicts]`;
   po jeho odpovědi krok 4. `exit=2` nebo `3` → eskaluj.

**Nová vlna.** Po každém merge vypiš issues milestonu znovu a nová zařaď do grafu jako
v kroku 1, včetně kontroly Poznámky.

Nesedí-li počet issues s milestonem, přečti znovu po další notifikaci; eskaluj až při
druhé shodné neshodě.

Všechna issues zavřená nebo eskalovaná → krok 8. Něco zůstává otevřené, ale nic
neběží, nic nečeká na člověka (ani issue s labelem `precedent`) a nic není odblokované
→ eskaluj jako deadlock.

### 8. Závěr

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-branch.sh" <integrační větev>`; kód 5 →
   eskaluj, kódy 2–4 → eskaluj.
2. Integrační PR založ skillem `sagittaras:open-pr`. Předej mu základní větev
   (výchozí z konfigurace), milestone, hotový název a tělo podle šablony, pokyn, ať
   je znovu neodvozuje, a výslovný souhlas k mergi doslova — jen pokud stál
   v promptu, kterým tenhle běh začal. Ověř v jeho souhrnu přiřazený milestone.
3. Zůstalo-li PR otevřené, předlož ho člověku a skonči. Před doporučením
   `/sagittaras:close-milestone` (až po merge) se zeptej, jestli přijde další vlna.

### 9. Eskalace

Eskaluj, když:

- chybí konfigurace nebo potřebná sekce; `gh` vrátí kód 7, nebo forge 404 na zápisu;
- issue nemá `area:*` label, je Poznámka bez labelu `precedent` nebo má přeložené
  nadpisy šablony; nástroj odmítl spustit agenta;
- graf má cyklus nebo odkaz na otevřené issue mimo milestone; počet issues nesedí
  (v kroku 7 až podruhé);
- agent ohlásil věcnou překážku, nebo selhal dvakrát stejně;
- brána neprošla podruhé po sobě (u konfliktu jen proti stejné špičce, krok 5); brána
  před review skončila kódem 2, 3, 4 nebo 7;
- brána před merge skončila kódem 2 nebo 3; forge merge odmítl, nebo PR po merge
  podle forge zmergované není; hlídač PR ohlásil PR z přehledu zavřené bez merge,
  nebo skončil kódem 2, 3 nebo 7;
- `milestone-branch.sh` nebo `sync-branch.sh` skončil nenulovým kódem;
- nic neběží, nic nečeká na člověka a nic není odblokované.

Eskalace shrne stav — co je zmergované, co běží, co čeká na člověka, co blokuje —
a položí jednu konkrétní otázku. Issues, která na blokovaném nezávisí, běží dál.

Rozejde-li se plán s realitou, navrhni opravu trackeru, ne výjimku z pravidel běhu,
a proveď ji až na souhlas člověka. PR dál uzavírá jedno issue a běh spouští jen issues
milestonu.

| Situace | Návrh |
| --- | --- |
| závislost na otevřeném issue mimo milestone | přesunout ho do milestonu — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-update.sh" -R "<owner/repo>" <issue> --milestone "<název>"`, Gitea: `issue_write` → `update` s `milestone`; pak krok 1 pro něj |
| dvě issues se navzájem blokují — třeba ověřovací příkaz oblasti projde až s oběma | sloučit: kritéria a Reference druhého připsat do těla prvního, závislým issues přepsat v `Závisí na` #<druhé> na #<první>, druhé zavřít s komentářem „Sloučeno do #<první>"; agentovi prvního odpověz, ať issue přečte znovu a pokračuje |
| issue s přeloženými nadpisy šablony | přejmenovat nadpisy v těle issue na doslovné podle `shared/issue-template.md` — GitHub: `issue-update.sh … --body-file -`, Gitea: `issue_write` → `update` s `body` |

## Formát výstupu

### Zadání pro agenta

```
Naimplementuj issue #<číslo> (<název>) v repozitáři <owner/repo> skillem
sagittaras:implement-issue, se základní větví <integrační větev>. Issue patří
do milestonu „<název>"; kód přezkoumává člověk a na jeho schválení PR merguje
orchestrátor run-milestone. Kritéria, Reference a závislosti jsou v těle issue.

Příkazy spouštěj v popředí. Po otevření PR skonči. Pokračovat budeš na signál:
- Připomínky — přečti je z PR; nese-li signál text připomínek, zapracuj i ten.
- Brána neprošla — oprav uvedené nálezy.
- Rozhodnutí — odpověď člověka na tvou eskalaci; pokračuj podle ní.
Opravy v téže větvi. PR nemerguj.

Každou svou zprávu začni jedním z řádků:
PR: #<číslo>
PR: žádné — <věcný důvod>
PR: rozpracováno — <na co čekáš>
```

### Zadání pro navázání

```
Naimplementuj issue #<číslo> (<název>) v repozitáři <owner/repo> skillem
sagittaras:implement-issue, se základní větví <integrační větev>. PR #<n> na
větvi <head> už existuje: navaž na něj a zpracuj signál.

<signál ze Signálů pro agenta>

[Zbytek jako v Zadání pro agenta, od „Příkazy spouštěj v popředí."]
```

### Signály pro agenta

```
Připomínky: člověk napsal k PR #<n> připomínky. Přečti je z PR a zapracuj.
Připomínky ze zprávy: člověk k PR #<n> napsal: <text doslova>. Zapracuj je i s připomínkami v PR, jsou-li tam.
Rozhodnutí: na tvou otázku „<řádek Potřebuji rozhodnout: z eskalace doslova>" člověk k issue #<číslo> rozhodl: <text doslova>. Pokračuj podle něj.
Dokonči: dokonči rozdělanou práci; příkazy spouštěj v popředí a kolo ukonči až s PR nebo s eskalací.
Brána neprošla: <řádky fail=, nebo sekce [conflicts] či [output] doslova>
```

### Komentář k PR po bráně (Gitea; na GitHubu ho píše `pr-gate.sh`)

```markdown
## Brána prošla

- Testy kritérií: <tested> z <criteria>, <human> ověří člověk
- Ověřovací příkaz: `<příkaz>` — prošel | přeskočen, pro oblast není příkaz
```

### Tělo integračního PR

```markdown
Milestone: <název>

Zahrnuje:
- #<číslo> — <název issue>

Eskalované a nezahrnuté: <#číslo — důvod, nebo „žádné">
```

### Hlášení

```
Spuštěno: #A (sonnet × high), #B (backend-engineer, opus × xhigh).
#A: PR #<n> prošlo bránou — čeká na tebe; připomínky piš sem nebo do PR, schválíš-li ho, napiš „mergni PR #<n>".
   [Gitea: … připomínky piš sem, nebo do PR a pak mi napiš „PR #<n> má připomínky"; …]
#A: brána neprošla (<důvod>) — vráceno agentovi.
#A: zmergováno, issue zavřené; odblokováno #C.
#D zakládá precedent — založ si pro něj párovou session nad <integrační větev> a PR směř do ní s „Closes #D" v těle; až ho mergneš, napiš mi „#D hotové" — issue zavřu a pustím, co na něm závisí.
Eskalace: <co se stalo, co to blokuje> — <otázka>.
```

## Zásady

- **Nepíšeš kód a nesoudíš kvalitu.** Merguješ jen na schválení, které člověk
  napsal sem: do integrační větve sám (krok 6), do výchozí větve jen `open-pr`
  se souhlasem v promptu.
- **Rozhoduje forge a strojový řádek** (`PR:`, `result=`, `event=`, návratový kód), ne próza.
- **Status není výsledek.** PR, merge i zavřené issue ověř ve forge.
- **Stav drží tracker, ne tvoje paměť** — proto jde běh přerušit a navázat.
