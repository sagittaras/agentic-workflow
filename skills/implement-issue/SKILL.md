---
name: implement-issue
description: >-
  Naimplementuje jeden issue z trackeru a otevře na něj PR — ověří závislosti,
  otevře dokumenty citované v Referencích, založí větev, napíše kód přesně podle
  akceptačních kritérií, sám si je projde a zápis i PR předá sdíleným skillům.
  Výstupem je číslo a odkaz PR; merge nechává na tom, kdo skill spustil.
when_to_use: >-
  Použij, když má být issue skutečně naimplementovaný — „udělej issue #12",
  „naimplementuj to issue", „vezmi #7 a otevři na to PR" — i když tě jako
  inženýrského agenta dispečuje run-milestone s číslem issue a integrační
  větví. Nepoužívej pro rozepsání tématu na issues, na to slouží
  plan-milestone; pro založení jednoho ad hoc issue file-issue; pro nezávislé
  ověření hotového PR verify-issue; pro pouhé otevření PR nad už hotovou prací
  open-pr; ani pro řízení celého milestonu a merge PR, to dělá run-milestone.
argument-hint: "<číslo issue> [základní větev]"
model: opus
effort: xhigh
# Zařazení dle matice: zásah do kódu (generování, refaktor) → opus × xhigh,
# bez odchylky. Změna musí sednout napoprvé — skill píše kód v cizím projektu,
# běží dlouho a bez dohledu a jeho výstup jde rovnou do PR, kde chybu platí
# recenzent. Rozhodovací strom vede na tentýž bod: skill má dojet k cíli sám
# přes víc kroků a nástrojů.
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

## Vstupní kontext

- Zadání (číslo issue, případně základní větev): $ARGUMENTS

Dispečuje-li tě `run-milestone`, přijde zadání v promptu agenta, ne v argumentech —
základní větev hledej i tam.

## Postup

### 1. Načti konfiguraci a přečti issue celé

Přečti `.claude/sagittaras/workflow.md` v kořeni projektu. Když soubor chybí,
**nepokračuj a nedomýšlej si hodnoty** — bez něj neznáš výchozí větev, ověřovací
příkazy ani forge. Ohlas to a nabídni `/sagittaras:init-workflow`. Když v něm chybí
sekce, kterou potřebuješ, řekni která a nedoplňuj ji za pochodu.

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

### 3. Otevři skutečné dokumenty z Reference

Každý dokument citovaný v sekci `Reference` **otevři a přečti uvedenou sekci**.
Ne parafrázi z těla issue, ne vzpomínku na to, co tam nejspíš je. Kritérium je
v dokumentu ukotvené právě proto, že tělo issue je zkratka — implementace psaná
podle zkratky projde tvojí vlastní kontrolou a spadne až u `verify-issue`.

Cesty ke zdrojům pravdy drží sekce `Zdroje pravdy` v konfiguraci. Neexistuje-li
dokument nebo sekce, nebo neříká-li to, co kritérium tvrdí, **eskaluj** — je to
vada plánu, ne mezera k domyšlení.

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

Nejdřív si přečti okolní existující kód — jak se v projektu pojmenovává, kde leží
testy, jak vypadá obdobná už hotová věc. Vlastní vzor zavedený vedle zavedeného je
nález pro recenzenta, ne přínos.

Implementuj **přesně to, co říkají akceptační kritéria**. Žádné rozšiřování rozsahu,
žádné vylepšení navíc, žádný refaktor okolí „když už jsem tady": co není v kritériích,
nikdo neposoudil a nikdo to nečeká.

Vypadá-li kritérium při implementaci podspecifikovaně, protiřečí si s jiným nebo je
zjevně špatně, **zastav a ohlas to**. Je to signál, že se má vrátit `plan-milestone` —
domyšlené kritérium vypadá jako hotová práce a rozdíl se najde až v produkci.

### 7. Projdi si každé kritérium sám

Než otevřeš PR, projdi kritéria jedno po druhém:

- **Co jde spustit, spusť.** Ověřovací příkaz pro `area:*` label issue je v sekci
  `Ověřovací příkazy` konfigurace.
  - Selže-li **kvůli tvé změně**, oprav ji a spusť znovu. Nepodaří-li se to,
    **PR neotvírej a eskaluj** — PR se známým nesplněným kritériem spotřebuje čas
    dvou recenzentů na to, co jsi věděl už předtím.
  - Selže-li z příčiny, která s issue nesouvisí (rozbitý build už před tvou změnou),
    ohlas to a neopravuj — je to cizí rozsah.
- **Co jde přečíst v kódu, přečti** a ukaž si, kde je kritérium naplněné.

Nenahrazuje to nezávislé ověření `verify-issue`; znamená to jen, že nepředáváš
zjevně rozbitou práci. **Zaškrtávátka v těle issue nech prázdná** — odškrtává je
`verify-issue` podle toho, co skutečně ověřil.

### 8. Zapiš práci a otevři PR

Zavolej nástrojem `Skill` skill `sagittaras:open-pr` a předej mu:

- že **jsi už na své větvi** — má ji použít a novou nezakládat,
- **základní větev PR** = ta z kroku 4,
- **`Closes #N`** do těla,
- **milestone issue**, patří-li do nějakého, aby `close-milestone` PR dohledal.

Commit vzniká uvnitř přes `sagittaras:make-commit`; sám necommituj ani nepushuj.

**Nevrátí-li `open-pr` číslo a odkaz PR** — zastavil se na brzdě, forge selhalo, chybí
mu sekce konfigurace — použij eskalační šablonu zakončenou `PR: žádné` a **vlastní PR
místo něj nezakládej**. Zpráva, ze které nejde poznat, že PR nevzniklo, stojí
`run-milestone` celé kolo přeposlání navíc.

### 9. Eskalace

Přeruš postup a ohlas stav, když:

- chybí konfigurace nebo sekce, kterou potřebuješ (krok 1),
- issue nejde načíst — neexistuje, 404, chybějící oprávnění nebo `gh` (krok 1),
- kterýkoli issue ze `Závisí na` není zavřený (krok 2),
- dokument nebo sekce z `Reference` neexistuje či neříká, co kritérium tvrdí (krok 3),
- základní větev je skutečně nejednoznačná (krok 4),
- typ z labelu nejde jednoznačně namapovat na přípustný typ větve (krok 5),
- základní větev neexistuje ani na remotu, ani lokálně (krok 5),
- větev nevyšla ze základního refu (krok 5),
- kritérium je podspecifikované, sporné nebo špatné (krok 6),
- ověřovací příkaz selhává kvůli tvé změně a nedaří se to opravit (krok 7),
- `open-pr` PR nezaložilo nebo jeho výsledek nejde ověřit (krok 8).

Rozdělanou práci **nech v pracovním stromu a necommituj ji** — polovičatý PR vypadá
zvenčí jako hotový a někdo ho zreviduje. Eskalace shrne stav a položí jednu konkrétní
otázku, nebo pojmenuje, co má opravit `plan-milestone`.

## Formát výstupu

Zpráva na konci úspěšného běhu. Poslední řádek je **doslovný** — `run-milestone`
podle něj pozná, že dispatch skutečně něco dodal:

```markdown
Issue: #<číslo> — <název>
Větev: <type>/<popis>, základ <základní větev>
Kritéria: <kolik> z <kolik> prošlo vlastní kontrolou
Ověření: <příkaz> — <prošlo | selhalo, proč>
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

## Zásady

- **Zpráva vždy končí řádkem `PR:`.** Dispečoval-li tě `run-milestone`, čte ji
  orchestrátor, ne uživatel, a bez toho řádku ji vyhodnotí jako selhaný dispatch.
  Proto eskalaci nikdy neformuluj tak, aby zněla jako úspěch.
- **Vlastní PR nikdy nemergeuj.** Merge do integrační větve dělá `run-milestone`
  po review, do výchozí větve jen člověk.
- **Kritéria jsou zadání, ne inspirace.** Nic navíc, nic míň; podspecifikované
  kritérium se hlásí, nedomýšlí.
- **Git jen přes delegaci.** `create-branch` a `open-pr`; jedinou výjimkou jsou
  čtecí kontroly vyjmenované v kroku 5, které nic nemění.
- **Zaškrtávátka patří `verify-issue`.** Neodškrtávej je, ani když sis kritérium
  ověřil — jinak recenzent posuzuje tvoje tvrzení místo skutečnosti. Nástroj na zápis
  do issue přitom po kroku 1 načtený máš; hranici drží tahle zásada, ne práva.
- **Reference se otevírají, ne parafrázují.** Tělo issue je zkratka dokumentu,
  ne jeho náhrada.
