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
# Merge jen na schválení, které člověk napsal přímo do téhle session (issue #70):
# zprávu jiné session klasifikátor auto mode za schválení nebere a merge
# zamítne, proto v běhu milestonu merguje orchestrátor.
# Vynechaná zvažovaná pole: allowed-tools — skill píše kód v neznámém projektu,
# spouští ověřovací příkazy z jeho konfigurace a podle forge sahá buď na `gh`
# skripty, nebo na odložené `mcp__gitea__*`; uzavřený výčet by na prvním jiném
# build toolu nebo forge selhal, a to tiše uprostřed běhu. Hranice drží sekce
# Zásady, ne práva; user-invocable — výchozí `true` je žádoucí, „naimplementuj
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

Cílem je jeden issue naimplementovaný přesně v rozsahu svých akceptačních kritérií
a otevřené PR, na které se dá odkázat číslem. Skill drží proces; doménové zázemí
přináší agent, který ho spustil. Závazné jsou sdílené soubory pluginu a projektová
konfigurace — při rozporu s tímhle postupem platí ony.

Git mechaniku skill nepíše znovu: větev zakládá `sagittaras:create-branch`, zápis
a PR obstará `sagittaras:open-pr` (ten uvnitř volá `sagittaras:make-commit`).
Psát ji potřetí znamená mít tři různá chování pro jednu operaci.

| Soubor | Kdy ho otevři |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/shared/workflow-config.md` | V kroku 1, když konfigurace chybí nebo v ní nenajdeš sekci, kterou potřebuješ |
| `${CLAUDE_PLUGIN_ROOT}/shared/forge-recipes.md` | V kroku 1, dřív než sáhneš na tracker — včetně sekce s nástrahami |
| `${CLAUDE_PLUGIN_ROOT}/shared/git-scripts.md` | V kroku 1 před prvním voláním skriptu ze `scripts/` nebo `scripts/gh/` — jejich argumenty a návratové kódy |
| `${CLAUDE_PLUGIN_ROOT}/shared/issue-template.md` | V kroku 1, když tělo issue neodpovídá očekávanému tvaru |
| `${CLAUDE_PLUGIN_ROOT}/shared/precedent-test.md` | V kroku 3, dřív než posoudíš, jestli citovaná cesta je precedent k rozšíření |
| `${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md` | V kroku 3, jen když `sagittaras:read-docs` nejde spustit — postup čtení báze |

## Vstupní kontext

- Zadání (číslo issue, případně základní větev): $ARGUMENTS

Dispečuje-li tě `run-milestone`, přijde zadání v promptu agenta, ne v argumentech —
základní větev hledej i tam.

## Postup

### 1. Načti konfiguraci a přečti issue celé

Přečti sekci `## Workflow (sagittaras)` v `CONTRIBUTING.md` v kořeni projektu.
Chybí-li `CONTRIBUTING.md` nebo sekce, **nepokračuj a nedomýšlej si hodnoty**
— bez ní neznáš výchozí větev, ověřovací příkazy ani forge. Ohlas to a nabídni
`/sagittaras:init-workflow`. Když v ní chybí podsekce, kterou potřebuješ, řekni
která a nedoplňuj ji za pochodu.

Než sáhneš na tracker, vezmi volání z tabulky v receptech, ne z hlavy: sloupec podle
sekce `Forge`, na Gitea si napřed **jedním** voláním `ToolSearch` načti odložené
nástroje podle řádku „Jen čte a komentuje".

Přečti celé tělo issue: **Souhrn**, **Akceptační kritéria**, **Reference**,
**Závisí na** — a k tomu typový a `area:*` label. Typ z labelu určuje typ větve,
`area:*` vybírá ověřovací příkaz v kroku 7. Neodpovídá-li tělo očekávanému tvaru,
porovnej ho se šablonou issue; jinak nerozeznáš vadné issue od vlastního přehlédnutí.

**Nejde-li issue načíst** — neexistuje, forge vrátí 404 nebo chybí oprávnění, `gh`
není nainstalované či přihlášené — **eskaluj a neimplementuj**. Číslo issue plus
kontext promptu vypadá jako dost informací na to, aby se zadání „domyslelo"; výsledkem
je věrohodná práce na něčem, co nikdo nezadal.

### 2. Ověř, že závislosti jsou zavřené

Každé `#N` ze sekce `Závisí na` si přečti a ověř, že je **zavřené**. Není-li,
skonči a ohlas to podle formátu eskalace. Stavět na základu, který ještě neexistuje,
je práce k zahození: kód, o který se máš opřít, nikde není, a co napíšeš místo něj,
se bude po merge závislosti přepisovat.

Chybí-li sekce `Závisí na` celá, issue nezávisí na ničem a pokračuješ. Prázdná
sekce nebo „nic" je odchylka od šablony — ohlas ji, ale běh kvůli ní nezastavuj.

### 3. Otevři skutečný precedent z Reference

Sekce `Reference` je **primárně odkaz na existující soubor nebo vzor v kódu**,
který se má rozšířit — ten otevři a přečti **jako první a hlavní zdroj
zadání**. Implementuj podle vzoru, který tam skutečně je, ne podle toho, jak
si ho pamatuješ nebo jak by „asi měl" vypadat. Ne parafrázi z těla issue —
tělo issue je zkratka a implementace psaná podle zkratky projde tvojí vlastní
kontrolou a spadne až u `verify-issue`. Cesta ke kódovému precedentu je vůči
kořeni repozitáře. Nemá-li Reference žádný kódový precedent, jen odkaz na
dokument, **neimplementuj a eskaluj** s doporučením `/sagittaras:triage-issue` —
bez precedentu nezůstává primární zdroj zadání, na který by se implementace
mohla opřít.

Cituje-li Reference i ADR nebo jiný dokument, čti ho jako **doplňkové
omezení** — co nesahat, které rozhodnutí je chráněné — ne jako primární popis
toho, co postavit. Tvar implementace určuje kódový precedent, ne próza
dokumentu.

**Citovaná cesta neexistuje** (soubor, vzor i dokument) → **eskaluj**, je to
vada plánu. **Citovaná cesta existuje, ale kritérium popisuje chování, které
v ní zatím není** → to není nález — přesně tenhle přírůstek issue přináší;
implementuj ho jako rozšíření precedentu. Eskaluj až tehdy, kritérium
citovanému precedentu **odporuje** (jiné rozhraní nebo struktura, na kterou
nejde navázat), nebo citovaná cesta jen tematicky souvisí a rozšířit ji na
tenhle případ nejde (test v `shared/precedent-test.md`).

Doplňkový dokument (ADR a další) čti **skillem `sagittaras:read-docs`**
s otázkou „Co stanoví <dokument z Reference> pro <oblast> — co nesahat, která
rozhodnutí jsou chráněná?" a oblastí, kterou issue mění (precedent
z Reference). Chráněná rozhodnutí z odpovědi ber doslova.

- **Odpověď říká, že projekt bázi nemá, nebo cesta dokumentu z Reference chybí
  v řádku Přečtené stránky** → přečti dokument přímo na citované cestě; není-li
  tam, postupuj jako u citované cesty, která neexistuje. Že dokument k oblasti
  nic nestanoví, není důvod k eskalaci.
- **Odpověď ho uvede jako nahrazený** → eskaluj: Reference cituje rozhodnutí,
  které už neplatí.
- **Kritérium odkazuje na konkrétní sekci dokumentu** (číslo kapitoly UX specu)
  → tu sekci přečti sám v dokumentu na cestě z Reference (kotvu z Opory použij,
  je-li tam); read-docs vrací omezení, ne obsah, podle kterého se staví.

Nejde-li skill spustit, čti dokument postupem z § Jak najít odpověď v bázi
v `shared/docs-tree.md`. Větve výš platí obdobně: kód 1 z mapy znamená projekt
bez báze a dokument, který v mapě není, čti přímo na citované cestě.

### 4. Urči základní větev

- **V milestone běhu** jsi dostal integrační větev `milestone/<slug>`. Větvi z ní:
  je v ní kód issues, které doběhly před tebou, a bez nich stavíš na neúplném základu.
- **Samostatně** větvi z výchozí větve podle sekce `Větvení` konfigurace.

Nedomýšlej si. Přišla-li základní větev v zadání i v konfiguraci a liší se, nebo
mluví-li zadání o milestonu, ale větev nejmenuje, zeptej se — špatný základ se pozná
až u merge, kdy je oprava dražší než jedna otázka.

### 5. Založ větev

Název odvoď z **práce**, ne z čísla issue (`feat/issue-42` je za rok nečitelné),
typ vezmi z typového labelu. Tvar i kolize si nech ověřit dřív, než větev vznikne:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/create-branch/scripts/create-branch.sh" --check <název>
```

Návratové kódy tenhle skript popisuje ve **vlastní hlavičce** — `git-scripts.md` platí
pro `scripts/` a `scripts/gh/`, ne pro skripty jednotlivých skillů.

- **kód 2** → nejde o git repozitář nebo chybí argument; eskaluj.
- **kód 3** → typ nebo popis neprošel tvarem. Přípustné typy vypíše skript v hintu;
  typový label mimo tenhle výčet mapuj na nejbližší přípustný a mapování uveď ve
  výstupu. Nejde-li namapovat jednoznačně, eskaluj — typ větve se propisuje do commitu
  i do názvu PR.
- **kód 4** → větev už existuje. Vymysli popis, který práci odlišuje; nepřilepuj
  pořadové číslo.
- **kód 5** → remote neodpověděl na dotaz po **výchozí** větvi. Větvíš-li z výchozí
  větve, eskaluj; u nevýchozího základu se to tvého základu netýká a běh nezastavuj.

Pak zjisti, **kde základní větev z kroku 4 skutečně leží**. Nepředpokládej remote:
integrační větev `milestone/<slug>` zakládá `run-milestone` lokálně a publikuje ji až
sync po zmergování první dávky, takže v první dávce milestonu `origin/milestone/<slug>`
neexistuje. Agenti běží ve worktree téhož repozitáře, takže lokální ref k dispozici mají.

```bash
git fetch origin <základní větev> 2>/dev/null || true
git show-ref --verify --quiet "refs/remotes/origin/<základní větev>"   # je na remotu?
git show-ref --verify --quiet "refs/heads/<základní větev>"            # je lokálně?
```

Základní ref (dál `<base-ref>`) je `origin/<základní větev>`, existuje-li; jinak lokální
`<základní větev>`. **Neexistuje-li ani jeden, eskaluj** — základ, který v repozitáři
nikde není, znamená jiné zadání, než jaké repozitář zná.

Větev zakládej vždy přes `sagittaras:create-branch` (nástroj `Skill`) a **předej mu
hotový název** — bez názvu si ho nechá potvrdit uživatelem a v autonomním běhu se
zastaví.

- **Základ je výchozí větev** → stačí název; skill větví z `origin/<výchozí větev>`.
- **Základ je integrační nebo jiná nevýchozí větev** → řekni mu základ výslovně,
  aby zavolal skript s `--base <základní větev>`. Bez toho by větev vyšla z výchozí
  větve, přišla by o kód, na kterém issue stojí, a chyba by se ukázala až u review.

Ve výstupu ověř řádek `base=` — je to jediné místo, kde se pozná, že se větvilo
odjinud, než jsi zamýšlel. Skončí-li skript s `error=base_branch_not_found` (kód 5),
**eskaluj**; nezakládej větev náhradně z výchozí větve.

Ať jsi větev založil jakkoli, ověř, že opravdu vyšla ze základu:

```bash
git merge-base --is-ancestor <base-ref> HEAD
```

Porovnávej **právě ten ref, ze kterého se větvilo** — u výchozí větve tedy
`origin/<výchozí větev>`, ne její lokální kopii: ta bývá zastaralá a kontrola by prošla,
aniž by cokoli ověřila. Nenulový kód → **eskaluj**, neimplementuj.

### 6. Implementuj

Tvar implementace vychází z precedentu přečteného v kroku 3 — to je vzor, který
rozšiřuješ. Okolní kód si přečti navíc kvůli tomu, co precedent sám neurčuje:
jak se v projektu pojmenovává, kde leží testy, jak vypadá obdobná už hotová věc.
Vlastní vzor zavedený vedle zavedeného je nález pro recenzenta, ne přínos.

Implementuj **přesně to, co říkají akceptační kritéria**. Žádné rozšiřování rozsahu,
žádné vylepšení navíc, žádný refaktor okolí „když už jsem tady": co není v kritériích,
nikdo neposoudil a nikdo to nečeká.

Vypadá-li kritérium při implementaci podspecifikovaně, protiřečí si s jiným nebo je
zjevně špatně, **zastav a ohlas to**. Je to signál, že se má vrátit `plan-milestone` —
domyšlené kritérium vypadá jako hotová práce a rozdíl se najde až v produkci.

### 7. Pokryj každé kritérium testem a spusť bránu

Než otevřeš PR, projdi kritéria jedno po druhém, v pořadí, v jakém stojí v issue:

- **Kritérium bez značky `(ověří člověk)` kryje test, který jsi v téhle změně
  napsal nebo rozšířil.** Test patří tam, kde má projekt testy (zjistil sis to
  v kroku 6). Ověřuje-li se kritérium příkazem — „`bash scripts/lint.sh` projde",
  „`grep …` nic nevrátí" — a projekt pro takovou kontrolu testy nemá, obal příkaz
  testovým skriptem, který při selhání skončí nenulovým kódem. Existující test,
  na který jsi nesáhl, kritérium nekryje: orchestrátor přijme jen test, který PR
  mění, a pro člověka je to tvrzení bez důkazu. „Přečetl jsem to v kódu" tady
  nestačí — po merge už nic nehlídá.
- **Kritérium se značkou `(ověří člověk)`** test nemá. Přečti v kódu, kde je
  naplněné, a v mapě ho tak označ.
- **Kritérium bez značky, na které test napsat nejde**, je vada plánu, ne výjimka,
  kterou si uděláš sám: **zastav a eskaluj** — značku přidává plánování.

Zapiš si mapu kritérium → test, jeden řádek na kritérium; předáš ji v kroku 8:

```markdown
| # | Kritérium | Test |
| --- | --- | --- |
| 1 | <zkrácené znění kritéria> | `cesta/k/testu` — `název testu` |
| 2 | <zkrácené znění kritéria> | ověří člověk |
```

Číslo je pořadí kritéria v issue; cesta je vůči kořeni repozitáře.

Pak **spusť všechny testy z mapy a ověřovací příkaz** pro `area:*` label issue ze
sekce `Ověřovací příkazy` konfigurace:

- **Všechno prošlo** → pokračuj krokem 8.
- **Selže kvůli tvé změně** → oprav ji a spusť znovu. Nepodaří-li se to,
  **PR neotvírej a eskaluj** — PR s červenou bránou spotřebuje čas recenzenta na to,
  co jsi věděl už předtím.
- **Selže z příčiny, která s issue nesouvisí** (rozbitý build už před tvou změnou)
  → neopravuj, je to cizí rozsah; ale ani PR neotvírej a eskaluj. Bez zelené brány
  nejde poznat, jestli tvoje změna funguje.

Zjisti taky, **kdo bránu potvrdí po tobě**. V milestone běhu je to orchestrátor
(`run-milestone`, který tě dispečoval). Spuštěný samostatně se podívej, jestli
projekt má CI, které na PR běží (`.github/workflows/`, `.gitea/workflows/`
a obdobné). Nemá-li ani jedno, je tvůj běh jediné spuštění brány a PR to musí
říct — jinak recenzent bere zelenou za nezávisle potvrzenou.

**Zaškrtávátka v těle issue nech prázdná** — tvoje kontrola je self-report a do
issue ho nezapisuješ.

### 8. Zapiš práci a otevři PR

Zavolej nástrojem `Skill` skill `sagittaras:open-pr` a předej mu:

- že **jsi už na své větvi** — má ji použít a novou nezakládat,
- **základní větev PR** = ta z kroku 4,
- **`Closes #N`** do těla,
- **milestone issue**, patří-li do nějakého, aby `close-milestone` PR dohledal,
- **mapu kritérium → test** z kroku 7, doslova, k vložení do těla PR pod nadpis
  `## Testy kritérií` — orchestrátor ji tam čte strojově,
- **poznámku o bráně**, běžíš-li bez orchestrátoru a projekt nemá CI: „Bránu
  (testy kritérií a ověřovací příkaz) spustila jen session, která PR otevřela;
  nezávisle ji nepotvrdil orchestrátor ani CI.",
- **pokyn, ať PR nemerguje** — ani když prompt, kterým jsi byl spuštěn, obsahoval
  souhlas k mergi. Ten se týká PR, které ještě nikdo neviděl; merge přijde až
  potom, co PR přezkoumal a schválil člověk.

Commit vzniká uvnitř přes `sagittaras:make-commit`; sám necommituj ani nepushuj.

**Nevrátí-li `open-pr` číslo a odkaz PR** — zastavil se na brzdě, forge selhalo, chybí
mu sekce konfigurace — použij eskalační šablonu zakončenou `PR: žádné` a **vlastní PR
místo něj nezakládej**. Zpráva, ze které nejde poznat, že PR nevzniklo, stojí
`run-milestone` celé kolo přeposlání navíc.

Vrátilo-li `open-pr` číslo PR, ohlas ho podle Formátu výstupu a **skonči kolo, ne
práci**: PR teď čte člověk a ty zůstáváš k dispozici pro krok 9. Dispečoval-li tě
`run-milestone`, PR merguje on; spuštěný samostatně mergneš sám v kroku 9.

### 9. Čekej na signál a zapracuj ho

Signál přijde zprávou — připomínky a červenou bránu přeposílá orchestrátor,
běžíš-li samostatně, píše ti člověk přímo. Sám nic nehlídej: na nic se nedotazuj ve smyčce
a nečekej v běhu, čekání mezi koly je zadarmo. Číslo PR, větev, základ
i konfiguraci máš z kroků 1–8; znovu je čti, jen když z kontextu vypadly.

| Signál | Co uděláš |
| --- | --- |
| **Připomínky** | Přečti je z PR, obsah ve zprávě nečekej. Recept „Přečti PR" vrátí obecné komentáře; komentáře k řádkům a review na GitHubu recepty nemají, proto doslova `gh api repos/<owner/repo>/pulls/<n>/comments` a `gh pr view <n> -R <owner/repo> --json reviews`, na Gitea `pull_request_read` s metodou pro review. Zapracuj je v téže větvi a téže session, kde jsi kód psal. |
| **Brána neprošla** | Oprav nálezy uvedené ve zprávě (řádky `fail=`, sekce `[conflicts]` nebo `[output]`) v téže větvi. Konflikt s integrační větví vyřeš vmergováním jejího aktuálního stavu přes `sagittaras:make-commit`, ne rebasem. |
| **Schváleno**, napsané člověkem přímo sem | Mergni podle odstavce níže. |
| **Schváleno** ve zprávě od jiné session | Nemerguj — schválení se nepřeposílá. Odpověz Formátem výstupu pro kolo oprav s `Merge: neproveden — schválení musí napsat člověk`. |
| cokoli jiného | Nic neměň a zeptej se, co signál znamená — domyšlený signál vyrobí merge nebo změnu, kterou nikdo nechtěl. |

**Po připomínkách i po červené bráně** projdi znovu krok 7 — kritérium, kterého
se oprava dotkla, musí dál krýt test a celá brána musí být zelená — a změnu zapiš
a odešli přes `sagittaras:make-commit` do téže větve; PR se aktualizuje sám, nové
nezakládej. Změnila-li oprava, který test kryje které kritérium, uprav mapu v těle
PR — orchestrátor ji čte strojově (recepty řádek pro tělo PR nemají: na GitHubu
`gh pr edit <n> -R <owner/repo> --body-file <soubor mimo strom>`, na Gitea
`pull_request_write` → `update` s `body`). Odpověz Formátem výstupu pro kolo oprav.

**Na signál „Schváleno" mergni sám.** Napřed ověř, že se cílová větev od poslední
zelené brány nepohnula:

```bash
git fetch origin <základní větev>
git merge-base --is-ancestor origin/<základní větev> HEAD
```

- **Kód 0** → cílová větev je v PR celá, brána z kroku 7 platí.
- **Nenulový kód** → cílová větev se pohnula; zopakuj integrační bránu proti její
  aktuální špičce:

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/integration-gate.sh" <tvoje větev> <základní větev> -- <ověřovací příkaz oblasti>
  ```

  Kód 0 → pokračuj mergem. Kód 5 (konflikt) nebo 6 (příkaz selhal) → **nemerguj**,
  ohlas červenou bránu podle Formátu výstupu a čekej na další signál; schválení
  platilo pro kód, který brána neviděla. Kód 2 nebo 3 je výpadek, ne nález —
  nemerguj a eskaluj.

Pak PR mergni podle řádku „Mergni PR" v receptech, **strategií ze sekce `Větvení`**
konfigurace (u `squash` přepínač `--squash`) a se smazáním zdrojové větve:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh/pr-merge.sh" -R <owner/repo> <číslo PR> --squash --delete-branch
```

Na Gitea `pull_request_write` → `merge` s `merge_style` podle `Větvení`
a `delete_branch`. Mířilo-li PR do výchozí větve, je signál schválení od člověka
právě ten výslovný souhlas, který řádek `merge do výchozí větve` v konfiguraci
vyžaduje. Odmítne-li forge merge (ochrana větve, konflikt), **neobcházej ho** —
žádný `--admin`, žádný jiný recept — a eskaluj.

Po merge ověř přes recept „Přečti PR", že je PR ve stavu `MERGED`, a odpověz
Formátem výstupu pro merge. Issue nezavírej — `Closes #N` mimo výchozí větev
nezabírá a zavření vlastní ten, kdo issue spustil (v milestone běhu
`run-milestone`).

### 10. Eskalace

Přeruš postup a ohlas stav, když:

- chybí konfigurace nebo sekce, kterou potřebuješ (krok 1),
- issue nejde načíst — neexistuje, 404, chybějící oprávnění nebo `gh` (krok 1),
- kterýkoli issue ze `Závisí na` není zavřený (krok 2),
- citovaný soubor, vzor nebo dokument z `Reference` neexistuje, kritériu odporuje,
  Reference nemá žádný kódový precedent, nebo citovaný dokument `read-docs`
  uvede jako nahrazený (krok 3),
- základní větev je skutečně nejednoznačná (krok 4),
- typ z labelu nejde jednoznačně namapovat na přípustný typ větve (krok 5),
- základní větev neexistuje ani na remotu, ani lokálně (krok 5),
- větev nevyšla ze základního refu (krok 5),
- kritérium je podspecifikované, sporné nebo špatné (krok 6),
- kritérium bez značky `(ověří člověk)` nejde pokrýt testem (krok 7),
- testy kritérií nebo ověřovací příkaz neprochází a nedaří se to opravit, nebo
  selhávají z příčiny mimo issue (krok 7),
- `open-pr` PR nezaložilo nebo jeho výsledek nejde ověřit (krok 8),
- připomínku nejde zapracovat, aniž by odporovala kritériu issue (krok 9),
- integrační brána před merge skončila kódem 2 nebo 3, forge merge odmítlo, nebo
  PR po merge není ve stavu `MERGED` (krok 9).

Rozdělanou práci **nech v pracovním stromu a necommituj ji** — polovičatý PR vypadá
zvenčí jako hotový a někdo ho zreviduje. Eskalace shrne stav a položí jednu konkrétní
otázku, nebo pojmenuje, co má opravit `plan-milestone`.

## Formát výstupu

Zpráva na konci úspěšného běhu. Poslední řádek je **doslovný** — `run-milestone`
podle něj pozná, že dispatch skutečně něco dodal:

```markdown
Issue: #<číslo> — <název>
Větev: <type>/<popis>, základ <základní větev>
Kritéria: <kolik> z <kolik> kryje test, <kolik> ověří člověk
Ověření: <příkaz> a testy z mapy — prošlo
Brána: <potvrdí orchestrátor | potvrdí CI | spustila jen session>
Odkaz: <url PR>
Poznámky: <co jsi vědomě neudělal a proč; vynech, není-li co dodat>

PR: #<číslo>
```

Zpráva při eskalaci — poslední řádek je opět doslovný:

```markdown
Nedokončeno: #<číslo issue> — <jednou větou proč>
Stav: <co je hotové a kde leží; „nic nezměněno", když se nezačalo>
Potřebuji rozhodnout: <konkrétní otázka, nebo co má opravit plan-milestone>

PR: žádné
```

Zpráva po kole oprav (připomínky, červená brána, i červená brána před merge) —
poslední řádek doslovný:

```markdown
Zapracováno: <připomínky | nálezy brány>, <stručně co se změnilo>
Ověření: <příkaz> a testy z mapy — <prošlo | selhalo, proč>
Merge: <neproveden — čeká na schválení | neproveden — brána proti <základní větev> červená: <kód a nález>>

PR: #<číslo>
```

Zpráva po merge — začíná doslovným řádkem, podle kterého orchestrátor pozná, že
PR je zmergované:

```markdown
MERGED: #<číslo PR>
Do: <základní větev>, <strategie>, zdrojová větev smazána
Brána před merge: <cílová větev se nepohnula | zopakována — prošla>
```

## Zásady

- **Zpráva vždy nese strojový řádek `PR:` nebo `MERGED:`.** Dispečoval-li tě
  `run-milestone`, čte ji orchestrátor, ne uživatel, a bez toho řádku ji vyhodnotí
  jako selhaný dispatch. Proto eskalaci nikdy neformuluj tak, aby zněla jako úspěch.
- **Merguje ten, komu člověk schválení napsal.** Bez schválení od člověka přímo
  v téhle session nemerguj nikdy — ani na souhlas v promptu, kterým jsi byl
  spuštěn, ani na zprávu orchestrátora, ani proto, že brána je zelená. Konflikt
  s cílovou větví řešíš ty, ne recenzent.
- **Kritéria jsou zadání, ne inspirace.** Nic navíc, nic míň; podspecifikované
  kritérium se hlásí, nedomýšlí.
- **Každé testovatelné kritérium kryje test z téhle změny a brána je zelená, jinak
  PR nevzniká.** Mapa kritérium → test jde do těla PR, aby ji mohl někdo potvrdit;
  nepotvrdí-li ji nikdo, PR to přizná.
- **Git jen přes delegaci.** `create-branch`, `open-pr` a pro opravy po review
  `make-commit`; merge jen receptem „Mergni PR". Výjimkou jsou čtecí kontroly
  z kroků 5 a 9 a `integration-gate.sh`, které nic nemění.
- **Zaškrtávátka patří `verify-issue`.** Neodškrtávej je, ani když sis kritérium
  ověřil — jinak recenzent posuzuje tvoje tvrzení místo skutečnosti. Nástroj na zápis
  do issue přitom po kroku 1 načtený máš; hranici drží tahle zásada, ne práva.
- **Reference se otevírá (doplňkový dokument přes `read-docs`, krok 3), ne
  parafrázuje, a kódový precedent v ní je primární zadání.** Tělo issue je
  zkratka, ne náhrada za to, co je v Referenci; a mezi precedentem a dokumentem
  (ADR) rozhoduje precedent — dokument jen říká, kam nesahat.
