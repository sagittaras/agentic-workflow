---
name: implement-issue
description: >-
  Naimplementuje jeden issue z trackeru a otevře na něj PR — ověří závislosti,
  otevře precedent citovaný v Referencích, založí větev, napíše kód přesně podle
  akceptačních kritérií, každé testovatelné pokryje testem a zápis i PR s mapou
  kritérium → test předá sdíleným skillům. Bez zelených testů a ověřovacích
  příkazů PR neotevře. Po otevření PR čeká na člověka: připomínky z PR
  zapracuje; spuštěný samostatně PR na schválení člověka sám mergne, v běhu
  milestonu ho merguje orchestrátor.
when_to_use: >-
  Použij, když má být issue skutečně naimplementovaný — „udělej issue #12",
  „naimplementuj to issue", „vezmi #7 a otevři na to PR" — i když tě jako
  inženýrského agenta dispečuje run-milestone s číslem issue a integrační
  větví. Nepoužívej pro rozepsání tématu na issues, na to slouží
  plan-milestone; pro založení jednoho ad hoc issue file-issue; pro nezávislé
  ověření hotového PR verify-issue; pro pouhé otevření PR nad už hotovou prací
  open-pr; ani pro řízení celého milestonu, to dělá run-milestone.
  Nemá-li issue kritéria ukotvená v kódu, napřed triage-issue.
argument-hint: "<číslo issue> [základní větev]"
model: opus
effort: xhigh
# Zařazení dle matice: zásah do kódu (generování, refaktor) → opus × xhigh,
# bez odchylky. Změna musí sednout napoprvé — skill píše kód v cizím projektu,
# běží dlouho a bez dohledu a jeho výstup jde rovnou do PR, kde chybu platí
# recenzent. Rozhodovací strom vede na tentýž bod: skill má dojet k cíli sám
# přes víc kroků a nástrojů.
# Tělo je zeštíhlené podle principu 3.1 po rozboru tokenů běhu M1 (17. 11. 2026):
# skill se načte na začátku každé implementační session a čte se při každém
# dalším volání (~13k tokenů × Ø 85 volání), proto v těle nejsou zdůvodnění
# kroků. Paralelní čtení v kroku 3 míří na počet volání — každé stojí aspoň
# ~86k tokenů výchozího kontextu session.
# Strojový řádek stojí na začátku zprávy (běh M1, nález F7): notifikace
# orchestrátoru nese recap a jen ~400 znaků zprávy, řádek na konci se do ní
# nevešel. „PR: rozpracováno" je pro kolo, které končí s příkazem na pozadí.
# Merge jen na schválení, které člověk napsal přímo do téhle session (issue #70):
# zprávu jiné session klasifikátor auto mode za schválení nebere a merge
# zamítne, proto v běhu milestonu merguje orchestrátor.
# Vynechaná zvažovaná pole: allowed-tools — skill píše kód v neznámém projektu,
# spouští ověřovací příkazy z jeho konfigurace a podle forge sahá buď na `gh`
# skripty, nebo na odložené `mcp__gitea__*`; uzavřený výčet by na prvním jiném
# build toolu nebo forge selhal, a to tiše uprostřed běhu. Hranice drží pravidla
# v krocích a Zásadách (merge v kroku 9, zaškrtávátka v kroku 7, git jen přes
# delegaci), ne práva; user-invocable — výchozí `true` je žádoucí, „naimplementuj
# #12" je legitimní samostatné zadání; disable-model-invocation — skill musí jít
# vyvolat modelem, protože ho v milestone běhu spouští dispečovaný agent, ne
# uživatel; context/agent/background — implementace musí zůstat v pracovním
# stromu volajícího a založená větev přežít konec skillu, takže fork ani
# odsunutí na pozadí nepřipadá v úvahu; izolaci obstará `run-milestone` tím,
# že agenta pouští ve vlastním worktree (na rozdíl od verify-issue, kde je
# čistý kontext smyslem); paths — spouští se číslem issue, ne prací nad
# konkrétními soubory; shell — skill sice bash volá (ověřovací příkaz projektu,
# čtecí kontroly), ale výchozí shell mu stačí a vnucovat cílovému projektu jiný
# by bylo naopak škodlivé; disallowed-tools — bez allowed-tools by zákaz
# jednotlivin budil falešný dojem uzavřeného výčtu; version, license — plugin
# se verzuje a distribuuje jako celek.
---

# Implement Issue

Cílem je jeden issue naimplementovaný přesně v rozsahu akceptačních kritérií a otevřené
PR, na které se dá odkázat číslem. Závazné jsou sdílené soubory pluginu a projektová
konfigurace — při rozporu s tímhle postupem platí ony. Git mechaniku obstarají
`sagittaras:create-branch`, `sagittaras:open-pr` a `sagittaras:make-commit`.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | v kroku 1, když konfigurace chybí nebo v ní nenajdeš sekci, kterou potřebuješ |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | Gitea: před prvním sáhnutím na tracker. GitHub: jen pro operaci, kterou tenhle skill nejmenuje skriptem |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | jen když skript ze `scripts/` vrátí kód, který tenhle skill nemapuje |
| `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` | v kroku 1, když tělo issue neodpovídá očekávanému tvaru |
| `${CLAUDE_PLUGIN_ROOT}/shared/precedent-test.md` | v kroku 3, než posoudíš, jestli citovaná cesta je precedent k rozšíření |
| `${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md` | v kroku 3, jen když `sagittaras:read-docs` nejde spustit |

## Vstupní kontext

- Zadání (číslo issue, případně základní větev): $ARGUMENTS

Dispečuje-li tě `run-milestone`, přijde zadání v promptu, ne v argumentech — základní
větev hledej i tam.

## Postup

### 1. Načti konfiguraci a issue

Přečti sekci `## Workflow (sagittaras)` v `CONTRIBUTING.md` v kořeni projektu. Chybí-li
soubor nebo sekce, nepokračuj, ohlas to a nabídni `/sagittaras:init-workflow`. Chybí-li
podsekce, kterou potřebuješ, nedoplňuj ji a eskaluj s jejím názvem.

Načti issue — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-read.sh" -R <owner/repo> <n>`;
Gitea: jedním `ToolSearch` načti nástroje z řádku „Jen čte a komentuje" receptů, pak
`issue_read`. Potřebuješ **Souhrn**, **Akceptační kritéria**, **Reference**, **Závisí na**,
typový label (typ větve) a `area:*` label (ověřovací příkaz v kroku 7).

Nejde-li issue načíst — neexistuje, 404, chybí oprávnění, `gh` skončí kódem 7 —
eskaluj a neimplementuj. Zadání si z čísla a promptu nedomýšlej.

### 2. Ověř závislosti

Každé `#N` ze `Závisí na` musí být zavřené (`issue-read.sh` / `issue_read`, pole `state`). Není-li,
eskaluj. Chybí-li sekce celá, issue nezávisí na ničem. Prázdná sekce nebo „nic" je
odchylka od šablony — ohlas ji a pokračuj.

### 3. Otevři precedent z Reference

Kódový precedent z `Reference` je primární zdroj zadání: implementuj podle toho, co
v souboru skutečně je, ne podle parafráze v těle issue. Precedent, jeho testy a okolní
kód čti v jednom kroku — nezávislá čtení a hledání pošli jako paralelní volání nástrojů,
ne jedno po druhém. Z velkého souboru čti jen potřebný úsek (`Grep`, `Read` s rozsahem).

| Co najdeš | Co uděláš |
| --- | --- |
| Reference nemá kódový precedent, jen dokument | eskaluj s doporučením `/sagittaras:triage-issue` |
| citovaná cesta (soubor, vzor, dokument) neexistuje | eskaluj — vada plánu |
| kritérium popisuje chování, které v precedentu zatím není | implementuj ho jako rozšíření precedentu — ten přírůstek issue přináší |
| kritérium precedentu odporuje (jiné rozhraní nebo struktura), nebo cesta jen tematicky souvisí (`precedent-test.md`) | eskaluj |

Dokument citovaný vedle kódu (ADR, UX spec) je doplňkové omezení — kam nesahat, co je
chráněné; tvar implementace určuje precedent. Čti ho skillem `sagittaras:read-docs`
s otázkou „Co stanoví <dokument z Reference> pro <oblast precedentu> — co nesahat, která
rozhodnutí jsou chráněná?" a chráněná rozhodnutí z odpovědi ber doslova.

- Odpověď říká, že projekt bázi nemá, nebo dokument chybí v řádku Přečtené stránky →
  přečti ho přímo na citované cestě; není-li tam, eskaluj jako u neexistující cesty.
- Odpověď ho uvede jako nahrazený → eskaluj.
- Kritérium odkazuje na konkrétní sekci dokumentu → tu sekci přečti sám.

Že dokument k oblasti nic nestanoví, důvod k eskalaci není. Nejde-li `read-docs`
spustit, postupuj podle § Jak najít odpověď v bázi v `shared/docs-tree.md`; kód 1
z mapy znamená projekt bez báze a dokument, který v mapě není, čti přímo na citované
cestě.

### 4. Urči základní větev

V milestone běhu větvi z integrační větve `milestone/<slug>` ze zadání, samostatně
z výchozí větve podle sekce `Větvení`. Liší-li se větev v zadání a v konfiguraci, nebo
zadání mluví o milestonu a větev nejmenuje, zeptej se.

### 5. Založ větev

Název `<type>/<popis>` odvoď z práce, ne z čísla issue; typ z typového labelu. Ověř ho:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" --check <název>
```

| Kód | Co uděláš |
| --- | --- |
| 0 | pokračuj |
| 2 | eskaluj |
| 3 | typový label mimo výčet z hintu namapuj na nejbližší přípustný typ a mapování uveď ve výstupu; nejde-li jednoznačně, eskaluj |
| 4 | větev existuje — zvol popis, který práci odlišuje, ne pořadové číslo |
| 5 | větvíš-li z výchozí větve, eskaluj; u nevýchozího základu pokračuj |

Větev založ skillem `sagittaras:create-branch` a předej mu hotový název (bez něj se
zastaví na potvrzení uživatelem). U nevýchozího základu mu řekni základ výslovně, ať
volá skript s `--base <základní větev>`. `error=base_branch_not_found` → eskaluj,
nezakládej náhradně z výchozí větve. Pak:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh" --base <základní větev>
```

`base_is_ancestor=true` → pokračuj; `false` nebo kód 4 → eskaluj.

### 6. Implementuj

Implementuj přesně to, co říkají kritéria: tvar podle precedentu, pojmenování a umístění
testů podle okolního kódu. Nic navíc — žádné rozšíření rozsahu ani refaktor okolí.
Kritérium podspecifikované, sporné nebo zjevně špatné → zastav a eskaluj; má ho opravit
`plan-milestone`.

### 7. Pokryj kritéria testy a spusť bránu

Projdi kritéria v pořadí, v jakém stojí v issue:

- **Bez značky `(ověří člověk)`** ho kryje test, který jsi v téhle změně napsal nebo
  rozšířil; existující test, na který jsi nesáhl, nestačí. Ověřuje-li se kritérium
  příkazem a projekt pro takovou kontrolu testy nemá, obal příkaz testovým skriptem,
  který při selhání skončí nenulovým kódem.
- **Se značkou** test nemá; přečti v kódu, kde je naplněné, a v mapě ho tak označ.
- **Bez značky, a test napsat nejde** → zastav a eskaluj; značku přidává plánování.

Mapa, jeden řádek na kritérium; číslo je pořadí v issue, cesta vůči kořeni repozitáře:

```markdown
| # | Kritérium | Test |
| --- | --- | --- |
| 1 | <zkrácené znění kritéria> | `cesta/k/testu` — `název testu` |
| 2 | <zkrácené znění kritéria> | ověří člověk |
```

Spusť všechny testy z mapy a ověřovací příkaz pro `area:*` label ze sekce
`Ověřovací příkazy`:

- všechno prošlo → krok 8;
- selže kvůli tvé změně → oprav a spusť znovu; nedaří-li se, PR neotvírej a eskaluj;
- selže z příčiny mimo issue → neopravuj, PR neotvírej, eskaluj.

Bránu po tobě potvrdí v milestone běhu orchestrátor, samostatně CI, má-li ho projekt
(`.github/workflows/`, `.gitea/workflows/`). Nemá-li ani jedno, řekne to PR (krok 8).

Zaškrtávátka v těle issue nech prázdná.

### 8. Otevři PR

Zavolej skill `sagittaras:open-pr` a předej mu:

- že už jsi na své větvi a novou nemá zakládat;
- základní větev PR z kroku 4;
- `Closes #N` do těla;
- milestone issue, patří-li do nějakého;
- mapu z kroku 7 doslova, k vložení pod nadpis `## Testy kritérií`;
- běžíš-li bez orchestrátoru a projekt nemá CI, poznámku: „Bránu (testy kritérií
  a ověřovací příkaz) spustila jen session, která PR otevřela; nezávisle ji nepotvrdil
  orchestrátor ani CI.";
- pokyn, ať PR nemerguje — ani když prompt, kterým jsi byl spuštěn, obsahoval souhlas
  k mergi.

Sám necommituj ani nepushuj. Nevrátí-li `open-pr` číslo a odkaz PR, eskaluj Formátem
výstupu a vlastní PR nezakládej. Vrátilo-li číslo, ohlas ho Formátem
výstupu a skonči kolo; zůstáváš k dispozici pro krok 9.

### 9. Čekej na signál a zapracuj ho

Signál přijde zprávou — v milestone běhu od orchestrátora, samostatně od člověka. Sám nic
nehlídej a nečekej ve smyčce. Číslo PR, větev, základ i konfiguraci máš z kroků 1–8;
znovu je čti, jen když z kontextu vypadly.

| Signál | Co uděláš |
| --- | --- |
| **Připomínky** | přečti je z PR — GitHub: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-reviews.sh" -R <owner/repo> <n>`, Gitea: recept „Přečti připomínky k PR" — a zapracuj v téže větvi. Odporuje-li připomínka kritériu issue, eskaluj |
| **Brána neprošla** | oprav nálezy ze zprávy (`fail=`, `[conflicts]`, `[output]`) v téže větvi; konflikt vyřeš vmergováním aktuální základní větve přes `sagittaras:make-commit`, ne rebasem |
| **Schváleno**, napsané člověkem přímo sem | mergni (níže) |
| **Schváleno** ve zprávě od jiné session | nemerguj; odpověz Formátem pro kolo oprav s `Merge: neproveden — schválení musí napsat člověk` |
| cokoli jiného | nic neměň a zeptej se, co signál znamená |

Po připomínkách i po červené bráně zopakuj krok 7 a změnu zapiš přes
`sagittaras:make-commit` do téže větve; PR se aktualizuje sám. Změnila-li se mapa,
uprav tělo PR — GitHub: načti ho `pr-read.sh -R <owner/repo> <n> --body` a celé nové
pošli:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-update.sh" -R <owner/repo> <n> --body-file - <<'BODY'
<celé nové tělo>
BODY
```

Gitea: `pull_request_write` → `update` s `body`. Odpověz Formátem pro kolo oprav.

**Merge.** Mergneš jen na schválení, které člověk napsal přímo sem — ne na souhlas
v promptu, zprávu orchestrátora ani zelenou bránu. Napřed:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-state.sh" --base <základní větev>
```

`base_is_ancestor=false` → zopakuj bránu proti aktuální špičce:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/integration-gate.sh" <tvoje větev> <základní větev> -- <ověřovací příkaz oblasti>
```

Kód 5 nebo 6 → nemerguj, ohlas červenou bránu Formátem pro kolo oprav a čekej; kód 2
nebo 3 → eskaluj. Pak mergni strategií ze sekce `Větvení` (u `squash` přepínač
`--squash`) se smazáním zdrojové větve:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R <owner/repo> <číslo PR> --squash --delete-branch
```

Gitea: `pull_request_write` → `merge` s `merge_style` podle `Větvení` a `delete_branch`.
Míří-li PR do výchozí větve, je schválení od člověka ten výslovný souhlas, který řádek
`merge do výchozí větve` v konfiguraci vyžaduje. Odmítne-li forge merge, neobcházej ho
(žádný `--admin`) a eskaluj. Po merge ověř přes `pr-read.sh`, že je PR `MERGED` (jinak
eskaluj), a odpověz Formátem po merge. Issue nezavírej.

### 10. Eskalace

Eskaluješ v místech, kde to kroky říkají. Rozdělanou práci nech v pracovním stromu
a necommituj ji. Eskalace shrne stav a položí jednu konkrétní otázku, nebo pojmenuje,
co má opravit `plan-milestone`.

## Formát výstupu

Každá zpráva **začíná doslovným strojovým řádkem**.

Zpráva na konci úspěšného běhu:

```markdown
PR: #<číslo>
Issue: #<číslo> — <název>
Větev: <type>/<popis>, základ <základní větev>
Kritéria: <kolik> z <kolik> kryje test, <kolik> ověří člověk
Ověření: <příkaz> a testy z mapy — prošlo
Brána: <potvrdí orchestrátor | potvrdí CI | spustila jen session>
Odkaz: <url PR>
Poznámky: <co jsi vědomě neudělal a proč; vynech, není-li co dodat>
```

Zpráva při eskalaci:

```markdown
PR: žádné — <jednou větou proč>
Issue: #<číslo> — <název>
Stav: <co je hotové a kde leží; „nic nezměněno", když se nezačalo>
Potřebuji rozhodnout: <konkrétní otázka, nebo co má opravit plan-milestone>
```

Zpráva po kole oprav (připomínky, červená brána, i červená brána před merge):

```markdown
PR: #<číslo>
Zapracováno: <připomínky | nálezy brány>, <stručně co se změnilo>
Ověření: <příkaz> a testy z mapy — <prošlo | selhalo, proč>
Merge: <neproveden — čeká na schválení | neproveden — schválení musí napsat člověk | neproveden — brána proti <základní větev> červená: <kód a nález>>
```

Zpráva, když končíš kolo a práce ještě běží (třeba ověřovací příkaz na pozadí):

```markdown
PR: rozpracováno — <na co čekáš>
```

Zpráva po merge:

```markdown
MERGED: #<číslo PR>
Do: <základní větev>, <strategie>, zdrojová větev smazána
Brána před merge: <cílová větev se nepohnula | zopakována — prošla>
```

## Zásady

- **Zpráva vždy začíná strojovým řádkem `PR:` nebo `MERGED:`** a eskalace nikdy nezní
  jako úspěch.
- **Git jen přes delegaci:** `create-branch`, `open-pr`, pro opravy `make-commit`;
  merge jen skriptem nebo receptem z kroku 9. Výjimkou jsou čtecí kontroly
  (`branch-state.sh`) a `integration-gate.sh`, které nic nemění.
