---
name: run-milestone
description: >-
  Provede naplánovaný milestone s člověkem jako recenzentem: sestaví graf
  závislostí z issues, založí integrační větev a odblokovaná issues spouští
  v podřazených session, kolik jich člověk stačí průběžně přezkoumat. Každé
  PR protáhne branou — test ke každému kritériu a ověřovací příkaz nad
  integrační větví — a teprve pak ho předá člověku.
  Jeho připomínky předává session, která PR vystavila; na jeho schválení PR
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
  dělá close-milestone.
argument-hint: "[milestone — název, číslo nebo slug]"
model: opus
effort: xhigh
# Zařazení dle matice: orchestrace workflow → opus × xhigh, bez odchylky. Po
# přestavbě (vize 2.6, 2.8, 2.9; párová session 16. 11. 2026) orchestrátor
# nesoudí kvalitu a nečte diffy (merge je jedno volání skriptu), takže by sám
# vystačil se sonnetem —
# jenže start_session dá podřazené session model nejvýš stejné rodiny a effort
# nejvýš stejný jako orchestrátoru. Levnější orchestrátor by srazil i všechny
# implementace. Jeho vlastní objem tokenů je po přestavbě malý.
# Rozhodnutí z párové session, na kterých tělo stojí:
# - Směrování area:* → agent: start_session agenta zvolit neumí, proto ho
#   session dostane v zadání a implementaci mu deleguje; sama drží kontext pro
#   připomínky (2.8).
# - Signál od člověka jde přes orchestrátora i v desktopu: aplikace orchestrátora
#   probudí jen po kole podřazené session, které spustil on sám. Kolo, které
#   člověk spustí přímo v session, ho neprobudí a běh by se po merge zastavil.
# - Souběžné session končí v libovolném pořadí — pozorovaná chyba (16. 11. 2026):
#   orchestrátor, který si session zapsal jako kroky seznamu úkolů, čekal na
#   první, i když pozdější už skončila. Proto výslovný zákaz v kroku 4.
# - Dávka = kapacita člověka na review, ptá se na ni na startu (navrhuje 3).
# - Dvě červené brány po sobě u téhož PR → eskalace, jinak by se session
#   s orchestrátorem mohly točit donekonečna. Konflikt proti jiné špičce
#   integrační větve, než byl předchozí, se nepočítá: v běhu M1 (17. 11. 2026)
#   způsobil 7 z 8 červených bran konflikt po merge souběžného PR, ne session.
#   Proto brána vypisuje integration_sha=. Selhaný příkaz (kód 6) se počítá
#   vždy — jinak by pojistka při souběžných merge přestala fungovat.
# - Průběžný sync integrační větve s výchozí odpadl: přetahoval by se o větev
#   s merge PR do ní. Sync je v závěru, nebo na žádost člověka.
# - Merge dělá orchestrátor, ne session (issue #70, běh milestonu #4):
#   přeposlané „Schváleno" dorazí do session jako zpráva jiné session
#   a klasifikátor auto mode merge zamítne jako Merge Without Review. Allow
#   pravidlo plugin dodat nemůže (klasifikátor čte jen ~/.claude/settings.json)
#   a když sedne, obejde klasifikátor úplně. Merguje proto ten, komu člověk
#   schválení napsal. Konflikt s integrační větví dál řeší session.
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
# - Další rozhodnutí z běhu M1: výsledek session čte orchestrátor z forge, protože
#   notifikace nese recap a jen ~400 znaků zprávy (F7). start_session z turnu po
#   notifikaci aplikace odmítne a karta own_initiative zahodí name i
#   source_branch, proto se místo doplňuje v turnu merge (F6). Po merge se
#   ostatní PR kontrolují na konflikt, aby oprava běžela během review, a schválení
#   po opravě konfliktu platí dál — člověk v M1 nové nechtěl (F2). PR pro víc
#   issues ani issue mimo milestone běh nepřijímá, opravuje se tracker (F5, E1).
# - Review plánu se nehledá (vize 2.10): plán validuje člověk a spuštěním běhu
#   ho schvaluje. Jeho mechanickou část hlídá běh sám — graf a Poznámku
#   v kroku 1 u každého otevřeného issue, `area:*` v kroku 3. Poznámku dřív
#   hlídal jen krok 7 u nové vlny; první vlnu kryl review komentář.
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
  - mcp__ccd_session__start_session
  - mcp__ccd_session_mgmt__list_sessions
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
# příkaz projektu (`dotnet build`, `pnpm test`, …).
# Agent zůstává pro běh bez podřazených session (CLI); SendMessage slouží oběma
# režimům — pokračuje v session i v subagentovi s jeho kontextem.
# disable-model-invocation: false — brzdou proti omylu jsou čtecí kroky před
# první zapisovací akcí (graf, dávka) a eskalace, ne zakázané vyvolání.
# Vynechaná zvažovaná pole: disallowed-tools — allowed-tools je uzavřený výčet;
# context/agent — fork by odřízl člověka, který posílá signály a odpovídá na
# eskalace; background — běh je rozhovor s člověkem; paths — spouští se
# z konverzace nad celým repozitářem; shell — skripty se volají explicitním
# `bash`; version/license — verzuje se celý plugin.
---

# Run Milestone

Řídíš běh milestonu: spouštíš issues v podřazených session, hlídáš bránu, předáváš
připomínky člověka a na jeho schválení merguješ. **Kód nepíšeš a kvalitu nesoudíš**
— implementuje session, kód přezkoumává člověk.

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
milestone". GitHub → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/milestone-list.sh" -R
"<owner/repo>" --state open`; kód 7 ohlas hned. `-R owner/repo` patří do každého
`gh` volání.

**Session.** Jedním `ToolSearch` načti `mcp__ccd_session__start_session`, `SendMessage`
a `mcp__ccd_session_mgmt__list_sessions`. Bez `start_session` poběžíš v režimu
subagentů (krok 3).

**Milestone** urči ze zadání. Sedí na víc otevřených milestonů nebo na žádný → zeptej se.

**Issues.** Vypiš všechna issues milestonu, otevřená i zavřená. GitHub:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-list.sh" -R "<owner/repo>" --milestone "<název>" --state all`.
Gitea: podle receptu, včetně stránkování po 30 a filtru na PR. Nesedí-li počet
s `open_issues` + `closed_issues`, eskaluj.

**Graf** sestav ze sekce `Závisí na` každého těla. Cyklus nebo odkaz na otevřené issue
mimo milestone → eskaluj. Otevřené issue, které je Poznámka — `Akceptační kritéria` jsou
prázdná nebo `Reference` chybí —, nespouštěj a eskaluj s odkazem na
`/sagittaras:triage-issue`. Nadpisy čti doslova: issue s přeloženým nadpisem šablony
(`## Acceptance criteria`) brána nepřečte — nespouštěj ho a navrhni opravu (krok 9).

**Rozpracovanost.** Ke každému otevřenému issue najdi PR podle těla, nikdy podle názvu
větve — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-issue.sh" -R "<owner/repo>"
<issue> --base <integrační větev>`, Gitea: recept „Najdi PR patřící k issue" — a session
podle jména `issue-<číslo>` (`list_sessions`).

| Stav | Kam |
| --- | --- |
| bez PR, bez session | krok 3 |
| session běží, PR zatím není | krok 4 |
| otevřené PR | krok 5 — bránu pusť znovu, je levná |
| zmergované PR | krok 7 |

**Dávka.** Zeptej se, kolik issues má běžet souběžně — tolik, kolik PR člověk stačí
průběžně přezkoumat. Navrhni 3. Hodnota platí, dokud ji člověk nezmění.

### 2. Integrační větev

Slug odvoď z názvu milestonu vždy stejně: malá písmena, bez diakritiky, každý znak
mimo `a-z0-9` → pomlčka, opakované pomlčky slouč, krajní ořízni. Existuje-li už větev
`milestone/*` k tomuhle milestonu, použij ji.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/milestone-branch.sh" <slug>
```

`created=false` → navazuješ na přerušený běh. Kód 2, 3 nebo 4 → eskaluj.

### 3. Spuštění issues

Spusť každé issue ve stavu „bez PR, bez session", jehož závislosti jsou všechny
zavřené — dokud počet rozběhnutých issues (session běží, brána, čeká na člověka)
nedosáhne dávky. Eskalované issue místo nezabírá; vrátí-li ho člověk do práce, zabírá
ho znovu. Chybí-li na issue `area:*` label, nespouštěj a eskaluj.

**S podřazenými session** zavolej pro každé issue `mcp__ccd_session__start_session`:

| Parametr | Hodnota |
| --- | --- |
| `initiation` | `"user_asked"` |
| `context` | `"fresh"` |
| `title` | `#<číslo> <název issue>` |
| `name` | `issue-<číslo>` |
| `use_worktree` | `true` |
| `source_branch` | integrační větev |
| `prompt` | Zadání pro session (Formát výstupu) |
| `background` | Kontext pro session (Formát výstupu) |

Je-li pro oblast issue v mapě `Agenti` agent, uveď ho v zadání; jinak zadání bez agenta.

**Bez podřazených session** spusť `Agent` s `subagent_type` z mapy `Agenti`
(chybí-li řádek nebo celá podsekce, `"general-purpose"`), `isolation: "worktree"`,
`run_in_background: true` a promptem podle Zadání pro session v podobě bez agenta.

Veď si přehled issue → id session nebo agenta → PR → stav. Totéž issue nespouštěj
podruhé, dokud jeho session nebo agent existuje.

Odmítne-li `start_session` spuštění, protože turn nezačal zprávou člověka (typicky po
notifikaci), jiný `initiation` nezkoušej. Ohlas, že místo v dávce je volné (Hlášení), a issue spusť na začátku další zprávy
člověka. Jiné odmítnutí → eskaluj s chybou nástroje.

### 4. Výsledek session

Čekej na notifikace, nepolluj. **Session a agenti končí v libovolném pořadí.** Každá
notifikace jmenuje, kdo skončil — zpracuj právě tenhle výsledek a čekej dál. Na
konkrétní session nečekej a souběžná issues nezapisuj jako kroky seznamu úkolů, které
se plní po pořadí: issue, které skončí dřív, by čekalo na to, které jsi spustil první.

O výsledku session i o její odpovědi na signál rozhoduje forge, zpráva je jen podnět.
U každé notifikace najdi otevřené PR issue —
GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-for-issue.sh" -R "<owner/repo>"
<issue> --base <integrační větev> --state open`, Gitea: recept „Najdi PR patřící k issue".
Rozhoduje první řádek tabulky, který sedí:

| Zpráva a forge | Co uděláš |
| --- | --- |
| zpráva má řádek `PR: rozpracováno — …` | nic neposílej, čekej na další notifikaci; nepřijde-li, zkontroluj PR ve forge při další zprávě člověka |
| zpráva má řádek `PR: žádné — <důvod>` | eskaluj, neposílej znovu |
| forge vrátí otevřené PR | krok 5 |
| PR není | pošli totéž zadání jednou znovu (`SendMessage` na její id); podruhé eskaluj |

### 5. Brána před review

Pro PR z kroku 4, i pro každé, které session po připomínkách aktualizovala:

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
| kód 1, 5 nebo 6 | pošli session signál „Brána neprošla" s řádky `fail=`, nebo se sekcí `[conflicts]` či `[output]`; po její odpovědi krok 4 |
| druhá červená brána po sobě u téhož PR | eskaluj. Konflikt (kód 5) ale eskaluj, jen když i předchozí brána skončila konfliktem se stejným `integration_sha=`; jinak se počítá jako první červená |
| kód 2, 3, 4 nebo 7 | eskaluj — vadné issue, výpadek nebo nezapsaný výsledek, ne chyba session |

`check=skipped` znamená, že pro oblast není ověřovací příkaz: uveď to v hlášení.

### 6. Předání člověku a merge

Platí-li pro PR schválení (níže), mergni. Jinak ohlas, že PR čeká na člověka (Hlášení).
Připomínky píše člověk do PR, signál sem:

| Signál od člověka | Co uděláš |
| --- | --- |
| „PR #N má připomínky" | pošli session signál „Připomínky" (`SendMessage`); obsah nečti ani nepřeposílej, session si ho přečte z PR. Po její odpovědi krok 4 |
| „mergni PR #N", „PR #N schváleno", i jinými slovy | mergni sám (níže) |

Schválení smí jmenovat číslo issue místo PR („34 může být zmergované"): platí, sedí-li
na právě jedno PR v přehledu, které prošlo branou; jinak se zeptej, které PR myslí.
Schválení předem („až projde, mergni") uplatni, jakmile brána poprvé projde.
Schválení, které přišlo po zelené bráně, přežije jen kola s opravou konfliktu
(kód 5); po kódu 1 nebo 6 jde PR ke schválení znovu. Jmenuje-li schválení jiný cíl
než integrační větev („pošli na main"), zeptej se — merguješ jen do integrační větve.

Schválení session nepřeposílej: zprávu od jiné session klasifikátor auto mode
za schválení člověka nebere a merge v ní zamítne.

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
| kód 5 nebo 6 | nemerguj; pošli session signál „Brána neprošla", po její odpovědi krok 4 |
| kód 2 nebo 3 | eskaluj |

Mergni receptem „Mergni PR" se strategií ze sekce `Větvení` a se smazáním zdrojové
větve. GitHub (u `squash` přepínač `--squash`):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R "<owner/repo>" <číslo PR> --squash --delete-branch
```

Gitea: `pull_request_write` → `merge` s `merge_style` podle `Větvení` a `delete_branch`.
Odmítne-li merge forge, neobcházej ho (žádný `--admin`) a eskaluj. Zamítne-li ho
auto mode, požádej člověka, ať napíše „mergni PR #<n>". Po merge krok 7.

Napíše-li člověk přímo do podřazené session, nic nepřeposílej. Stav pak přečti
z trackeru při jeho další zprávě sem.

Dokud je v dávce místo, spouštěj mezitím další odblokovaná issues (krok 3).

### 7. Po merge

Ověř ve forge, že PR je zmergované do integrační větve, a issue zavři — GitHub:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-update.sh" -R "<owner/repo>" <issue> --state closed`,
Gitea: recept „Zavři issue". `Closes #N` mimo výchozí větev nezabírá.

Ve stejném turnu jako merge:

1. Spusť issues, která merge odblokoval, a doplň uvolněné místo v dávce (krok 3).
2. Ostatní otevřená PR, která prošla branou, zkontroluj jen na konflikt s novou
   špičkou. Postupně v jednom volání Bash, ne paralelně — souběžné fetche se
   zamknou:

   ```bash
   for h in <head větve PR>; do echo "head=$h"; bash "${CLAUDE_PLUGIN_ROOT}/scripts/integration-gate.sh" "$h" <integrační větev>; echo "exit=$?"; done
   ```

   `exit=5` → pošli session toho PR signál „Brána neprošla" se sekcí `[conflicts]`;
   po její odpovědi krok 4. `exit=2` nebo `3` → eskaluj.

**Nová vlna.** Po každém merge vypiš issues milestonu znovu a nová zařaď do grafu jako
v kroku 1, včetně kontroly Poznámky.

Nesedí-li počet issues s milestonem, přečti znovu po další notifikaci; eskaluj až při
druhé shodné neshodě.

Všechna issues zavřená nebo eskalovaná → krok 8. Něco zůstává otevřené, ale nic
neběží, nic nečeká na člověka a nic není odblokované → eskaluj jako deadlock.

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
- issue nemá `area:*` label, je Poznámka nebo má přeložené nadpisy šablony; nástroj
  odmítl spustit session nebo agenta (odmítnutí v turnu po notifikaci řeší krok 3);
- graf má cyklus nebo odkaz na otevřené issue mimo milestone; počet issues nesedí
  (v kroku 7 až podruhé);
- session ohlásila věcnou překážku, nebo selhala dvakrát stejně;
- brána neprošla podruhé po sobě (u konfliktu jen proti stejné špičce, krok 5); brána
  před review skončila kódem 2, 3, 4 nebo 7;
- brána před merge skončila kódem 2 nebo 3; forge merge odmítl, nebo PR po merge
  podle forge zmergované není;
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
| dvě issues se navzájem blokují — třeba ověřovací příkaz oblasti projde až s oběma | sloučit: kritéria a Reference druhého připsat do těla prvního, závislým issues přepsat v `Závisí na` #<druhé> na #<první>, druhé zavřít s komentářem „Sloučeno do #<první>"; session prvního odpověz, ať issue přečte znovu a pokračuje |
| issue s přeloženými nadpisy šablony | přejmenovat nadpisy v těle issue na doslovné podle `shared/issue-template.md` — GitHub: `issue-update.sh … --body-file -`, Gitea: `issue_write` → `update` s `body` |

## Formát výstupu

### Zadání pro session

```
Naimplementuj issue #<číslo> (<název>) v repozitáři <owner/repo> skillem
sagittaras:implement-issue, se základní větví <integrační větev>.
[Je-li agent: Implementaci deleguj agentovi <jméno> nástrojem Agent
(subagent_type: "<jméno>") s tímhle zadáním; připomínky a signály mu předávej
přes SendMessage s jeho id. Sám kód nepiš.]

Po otevření PR skonči a čekej na signál:
- Připomínky — přečti je z PR, zapracuj v téže větvi.
- Brána neprošla — oprav uvedené nálezy v téže větvi.
PR nemerguj: merge provede orchestrátor, až ho člověk schválí.

Každou svou zprávu začni jedním z řádků:
PR: #<číslo>
PR: žádné — <věcný důvod>
PR: rozpracováno — <na co čekáš>
```

### Kontext pro session

```
Issue #<číslo> patří do milestonu „<název>" v repozitáři <owner/repo>. Běh řídí
run-milestone: ty implementuješ, kód přezkoumává člověk a na jeho schválení PR
merguje orchestrátor. Integrační větev: <integrační větev>. Kritéria, Reference
a závislosti jsou v těle issue.
```

### Signály pro session

```
Připomínky: člověk napsal k PR #<n> připomínky. Přečti je z PR a zapracuj.
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
Spuštěno: #A, #B.
#A: PR #<n> prošlo bránou — čeká na tebe; schválíš-li ho, napiš „mergni PR #<n>".
#A: brána neprošla (<důvod>) — vráceno session.
#A: zmergováno, issue zavřené; odblokováno #C.
Místo v dávce je volné, #C spustím po tvé další zprávě.
Eskalace: <co se stalo, co to blokuje> — <otázka>.
```

## Zásady

- **Nepíšeš kód a nesoudíš kvalitu.** Merguješ jen na schválení, které člověk
  napsal sem: do integrační větve sám (krok 6), do výchozí větve jen `open-pr`
  se souhlasem v promptu.
- **Obsah připomínek teče přes PR.** Ty předáváš jen signál.
- **Rozhoduje forge a strojový řádek** (`PR:`, `result=`, návratový kód), ne próza.
- **Status není výsledek.** PR, merge i zavřené issue ověř ve forge.
- **Stav drží tracker, ne tvoje paměť** — proto jde běh přerušit a navázat.
