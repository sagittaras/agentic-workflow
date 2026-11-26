---
name: train-agent
description: >-
  Nechá agenta nastudovat zadaný vstup a zapsat si z něj do vlastní trvalé
  paměti zobecněný poznatek k jeho roli. Kanonický případ je vyřešená
  review/retry smyčka nad PR — připomínky člověka, které našly problém,
  i commity, které je zapracovaly, ne jen finální stav. Zapisuje sám agent
  spuštěný jako subagent, protože právo do paměti plyne z jeho `memory:`;
  skill vstup načte, určí cílové agenty a ověří, co vzniklo. Paměť přidává
  i konsoliduje — co vstup vyvrací, mizí.
when_to_use: >-
  Použij po vyřešené review/retry smyčce nad PR — člověk připomínkoval,
  session nebo subagent připomínky zapracovali — aby poučení nezůstalo jen
  v PR nebo v konverzaci s orchestrátorem, ale přešlo do paměti agenta, který
  kód napsal; spustí tě ten, kdo smyčku řídil, nebo uživatel: „natrénuj agenta
  na připomínkách v PR #N".
  I jako závěrečný krok skillu, který vytvořil dokument v doméně agenta —
  „ať si agent zapíše závěry z art bible" — kromě ADR: ten se do paměti
  nezapisuje, log se čte on-demand, ne jako standing paměť. Nepoužívej pro
  úpravu definice agenta, na to slouží write-agent; pro pravidlo vázané na
  část repozitáře write-rule; pro projektové instrukce write-claude-md; pro
  sepsání architektonického rozhodnutí write-adr; ani pro paměť vlastní
  session, ta má vlastní mechanismus.
argument-hint: "[jméno agenta] [PR číslo nebo vložené připomínky z PR či přeposlané orchestrátorem a jejich zapracování; jinak cesta, odkaz či text]"
model: sonnet
effort: high
# Zařazení dle matice: vlastní práce je načíst vstup, odvodit cílové agenty,
# dispatchnout je a ověřit výsledek — těžení znalostí dělá dispatchnutý agent
# na svém vlastním modelu. Matice na takhle ohraničenou práci má sonnet ×
# medium; high je odchylka o stupeň, protože odvození domény je úsudek a
# v projektu s deseti překrývajícími se agenty se na medium snadno trefí vedle.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebFetch
  - Agent
# Vynechaná zvažovaná pole: Write/Edit — skill do paměti zásadně nezapisuje sám
# (viz Zásady), zápis patří agentovi pod jeho vlastním memory:; AskUserQuestion —
# skill má jít zřetězit z jiného skillu, kde uživatel nemusí být, takže chybějící
# údaje řeší ohlášením, ne doptáváním; disable-model-invocation — naopak má být
# volatelný modelem, právě kvůli řetězení; background — volající na výsledek
# čeká, aby mohl ověřit zápis; context/agent — fork by volajícího ušetřil
# nastudovaného vstupu, ale skill se často řetězí z jiného skillu, který se
# vstupem dál pracuje, takže výhoda mizí; disallowed-tools —
# allowed-tools je uzavřený výčet, není co zakazovat navíc; paths — vstup
# přichází v zadání, ne prací nad pracovním adresářem; shell — postup je čtení,
# dispatch a ověření, ne spouštění příkazů. ToolSearch, Bash a mcp__gitea__* —
# skill záměrně nesahá na tracker sám (krok 1): kanonický vstup je smyčka, na
# kterou volající (typicky ten, kdo ji řídil) už má vlastní přístup a předává
# ji hotovou v zadání; duplicitní čtecí cesta by jen riskovala jiný snímek než
# ten, ze kterého volající usoudil, že smyčka skončila úspěchem.
---

# Train Agent

Cílem je agent, který se učí ze zkušenosti projektu, místo aby všechno nesl ve
statické definici. Definice drží trvalou identitu a hranice role; všechno
ostatní — rozhodnutí, konvence, pasti — se hromadí v paměti, kterou si agent
píše sám. Závazným kontraktem je
`${CLAUDE_PLUGIN_ROOT}/skills/train-agent/memory-conventions.md`; při rozporu
s tímto skillem má přednost on.

## Vstupní kontext

- Zadání od uživatele nebo volajícího skillu: $ARGUMENTS

## Postup

### 1. Načtení vstupu

Kanonický vstup je **vyřešená review/retry smyčka nad PR**: review dělá člověk
a připomínky zapracovává session nebo subagent, který kód napsal. Skill sám
do trackeru nesahá — `allowed-tools` na to záměrně nemá nástroj (viz
frontmatter) — takže záznam dostaneš **v zadání od toho, kdo tě spustil**, buď
jako vložený text, nebo jako odkaz. Smyčku sestav ze dvou částí:

- **připomínky člověka** — komentáře review v PR i připomínky, které člověk
  napsal orchestrátorovi a ten je agentovi přeposlal (v PR nejsou), s odpověďmi
  na ně; nesou, co bylo špatně;
- **commity, které je zapracovaly** — zprávy i diff; nesou, jak se to opravilo.

Finální stav PR ukáže výsledek, ne chybu, ze které se má agent poučit —
chybí-li ti kterákoli část, vrať se na volajícího a vyžádej si ji, nedomýšlej.
Report agentního review (`verify-issue`) kanonickým vstupem není.

Vstupem může být i cokoli jiného, co jde přečíst — soubor v repozitáři, odkaz,
výstup předchozího běhu, nebo prostý text v zadání. **Nikdy ADR** — architektonické
rozhodnutí se do paměti agenta nezapisuje (viz `when_to_use`), i kdyby ho
zadání jmenovalo jako vstup. Rozpoznej, o který případ jde, a **vstup si
přečti celý**, než začneš cokoli odvozovat.

Rozhodni zároveň, **jestli na vstup dosáhne i trénovaný agent**. Cestu v repozitáři
si otevře sám, URL přes `WebFetch`, pokud ho má v `tools`. **Záznam review/retry
smyčky mu vlož do zadání vždycky** (krok 3) — `mcp__gitea__*` ani `gh` skripty
trénovaný agent v `tools` typicky nemá, takže dostat se k trackeru sám neumí.
Totéž udělej s čímkoli, co nikde neleží nebo na co agent nemá čtecí nástroj.
Agent, který si vstup nemá jak přečíst, si vymyslí, co v něm asi bylo.

**Nejde-li vstup přečíst, ohlas to a skonči.** Trénovat z domněnky je horší než
netrénovat: špatný záznam v paměti se tváří stejně důvěryhodně jako správný
a agent podle něj bude jednat, dokud si ho někdo nevšimne.

Přečti si v tomhle kroku i `memory-conventions.md` — bez nich neumíš sestavit
zadání pro agenta v kroku 3.

### 2. Určení cílových agentů

1. **Jméno v zadání platí.** Je-li uvedené, neodvozuj nic dalšího. U kanonického
   vstupu (review/retry smyčka) je tohle běžná cesta: volající zná agenta, který
   připomínky zapracoval, a jméno rovnou předá.
2. **U review/retry smyčky bez jména v zadání** vezmi cíl **ze záznamu samotného**
   — agenta, který kód napsal a připomínky zapracoval — ne podle domény kódu,
   kterého se PR týkalo. Poučení z konkrétní chyby patří tomu, kdo ji udělal,
   ne celé oblasti kolem ní.
3. **Jinak (mimo kanonický vstup) odvoď z projektu.** Projdi `.claude/agents/*.md`
   cílového projektu **i `${CLAUDE_PLUGIN_ROOT}/agents/`** a přečti jejich
   `description` — agenty dodává obojí a v katalogu se potkají. Plugin ukotvi
   proměnnou, ne relativně: běžíš nad cizím repozitářem, kde by `agents/`
   mířilo do projektu a agenti pluginu by z odvození tiše vypadli. Cílem je
   každý agent, do jehož domény vstup spadá.
4. **Víc agentů je normální stav**, ne chyba — vstup, který mění průřezovou
   konvenci, se týká všech, kdo podle ní pracují. Nemačkej to na jednoho.
   Nepleť si to s bodem 2: poučení z jedné konkrétní chyby jednoho agenta se
   na celou oblast nerozesílá.
5. **Žádný agent** → ohlas, že vstup nespadá do domény nikoho, a skonči.
   Nedispatchuj agenta „aspoň nějakého“; paměť mimo doménu je jen šum, který
   se načítá při každém jeho spuštění.

Než kohokoli dispatchneš, ověř u každého cíle tři věci. Všechny tři selhávají
**tiše** — dispatch proběhne, agent ohlásí práci a teprve krok 4 najde prázdnou
složku:

- **Soubor agenta existuje.** Jméno ze zadání ber jako tvrzení, ne jako fakt;
  překlep by se jinak projevil až chybou nástroje Agent.
- **Agent má pole `memory:`.** Bez něj k paměti nemá přístup.
- **Agent má v `tools` `Write` a `Edit`.** Paměť se zapisuje jimi, takže
  posuzovatel s právy jen pro čtení zápis neprovede, i když `memory:` má.
  Chybí-li pole `tools` úplně, agent dědí všechny nástroje a podmínka je
  splněná — nesplněná je jen tehdy, když `tools` existuje a zápisové nástroje
  v něm nejsou.

Agenta, který některou podmínku nesplní, **vynech a ohlas v reportu** i s tím,
která podmínka chybí. Doplnění je úprava definice a patří do `write-agent`;
sám do definice agenta nesahej.

Dvě další zjištění z `tools` běh neruší, ale mění zadání v kroku 3:

- **Nemá-li agent čtecí nástroj** na daný typ vstupu (`Read` u souboru,
  `WebFetch` u odkazu), nevynechávej ho — vlož mu obsah vstupu rovnou do zadání.
  Jinak dostane cestu, kterou nemá čím otevřít, a domyslí si, co v ní bylo.
- **Nemá-li čím smazat soubor** (`Write` ani `Edit` to neumí), řekni mu
  v zadání, ať neplatný záznam místo smazání přepíše na platný a odebere jen
  jeho řádek z indexu. Konsolidace se tím dokončí i bez mazacího nástroje.

U každého cíle, který prošel, si nakonec **přečti stávající stav jeho paměti** —
`MEMORY.md` a názvy souborů ve složce. Je to jediný snímek, proti kterému půjde
v kroku 4 poznat duplicitu a odlišit první trénink od chybějícího odkazu:
po dispatchi už složka vypadá jinak a zbylo by ti jen tvrzení agenta.

### 3. Dispatch

Každého cílového agenta spusť **nástrojem Agent s `subagent_type` rovným jeho
jménu** a s krokem 4 počkej, až doběhne.

Nepoužívej nástroj Skill ani jiný způsob načtení jeho definice. Právo zapisovat
do `.claude/agent-memory/<agent>/` plyne z pole `memory:` v jeho vlastní definici
a uplatní se **jen když skutečně běží jako on**. Načteš-li jeho obsah do
generického kontextu, zápis selže — a selže tiše.

Zasahuje-li vstup víc agentů, spusť je **paralelně**: každý píše do vlastní
složky, takže se nemají o co přetahovat a sekvenční běh by jen prodloužil čekání.

Jméno v `subagent_type` ber podle původu agenta: agent cílového projektu se volá
holým jménem, agent dodávaný pluginem svým scoped tvarem `<plugin>:<agent>`.
**Odmítne-li nástroj Agent dispatch**, agenta neztrácej z reportu — uveď ho mezi
vynechanými i s chybou, kterou nástroj vrátil.

Zadání sestav podle šablony ve Formátu výstupu a **dosaď do něj rozvinuté
absolutní cesty** — ke složce paměti i ke konvenci. Placeholder ani proměnná
nemá v odeslaném zadání co dělat; agent si je nedopočítá.

Na `memory-conventions.md` uvnitř pluginu navíc trénovaný agent **dosáhnout
nemusí** — jeho `tools` bývají užší než tvoje a plugin leží mimo jeho projekt.
Nedosáhne-li, vlož mu podstatné části rovnou do zadání: tvar indexu, frontmatter
tematického souboru, **doklad původu**, řádky **Why** a **How to apply**
a tabulku hodnot `type`. Právě proto sis konvenci přečetl už v kroku 1.
Vynecháš-li z výčtu cokoli, co kontrolní seznam konvence vymáhá, označí krok 4
za nesoulad každý soubor, který agent zapsal.

**Nevíš-li jistě, vkládej vždy.** Pár set tokenů navíc je levnější než agent,
který si tvar paměti domyslí — ten pak vypadá, že si zapsal správně, a nikdo
to neodhalí, dokud paměť někdo nečte ručně.

### 4. Ověření zápisu

Po doběhnutí si **přečti složku paměti každého agenta** a porovnej ji s tím, co
agent hlásí. Agentovo tvrzení, že si něco zapsal, není důkaz — a neprovedený
zápis vypadá v reportu úplně stejně jako provedený.

**Ověřuj podle hlášené operace** — u smazaného záznamu jsou existující soubor
a odkaz v indexu příznakem selhání, ne pořádku, takže paušální kontrola by
správně provedenou konsolidaci označila za chybu a neprovedenou pustila dál:

- `založeno` / `upraveno` → soubor existuje, nese to, co agent tvrdí, `MEMORY.md`
  na něj odkazuje, a záznam neduplikuje nic, co ve snímku z kroku 2 už bylo;
- `smazáno` → soubor zmizel (nebo je přepsaný na platný, neměl-li agent čím
  mazat) **a** jeho řádek zmizel z `MEMORY.md`. Osiřelý řádek v indexu je
  nesoulad stejně jako neprovedené smazání.

U všech založených a upravených souborů navíc ověř **tvar** podle kontrolního
seznamu v závěru `memory-conventions.md` — frontmatter, doklad původu, řádky
**Why** a **How to apply**, háček říkající *kdy* soubor otevřít. Bez téhle
kontroly projde nekonformní záznam jako v pořádku a nikdo to nezjistí, protože
paměť nikdo netestuje.

**Jde-li o první trénink**, složka ani index předtím neexistovaly — to není
nesoulad, ale výchozí stav. Nesoulad je až index, který nový soubor nezmiňuje.

Nesoulad neopravuj — zapiš ho do reportu. Zápis patří agentovi.

### 5. Report

Shrň výsledek podle šablony ve Formátu výstupu. Uveď i agenty, které jsi vynechal,
i s důvodem — nenatrénovaný agent je informace, ne mlčení.

## Formát výstupu

### Zadání pro trénovaného agenta

```
Nastuduj tento vstup a zapiš si z něj do své vlastní paměti to, co se týká
tvé role.

Vstup: <cesta, odkaz, nebo celý obsah, pokud na něj trénovaný agent nedosáhne>

Postupuj takto:
1. Přečti vstup celý. Jsou-li to připomínky z review (v PR nebo přeposlané
   orchestrátorem), najdi v nich **obojí**: co připomínka vytkla (konkrétní
   chyba) a jak ji commit zapracoval.
2. Projdi svou stávající paměť ve složce <cesta ke složce paměti> — MEMORY.md
   i tematické soubory, kterých se téma dotýká. Neexistuje-li složka nebo
   MEMORY.md, je tohle tvůj první trénink: založ index podle konvencí.
3. **Zobecni, nepřepisuj.** Z konkrétního nálezu odvoď pravidlo platné pro
   příště: co se pokazilo → podle čeho to poznat dřív → co udělat místo toho.
   Zapiš to pravidlo, ne převyprávění připomínek; doklad původu (např. „PR
   #74, připomínka k parseru") u něj nech, aby šlo dohledat, odkud pravidlo
   pochází. Zapiš si jen to, co se týká tvé role — ne otevřené otázky, ne to,
   co zjistíš přečtením kódu. Pravidlo nemusí být rozhodnutí (`decision`): stejně tak
   může jít o návyk, který se v projektu osvědčil (`convention`), nebo past,
   které se má agent příště vyhnout (`pitfall`).
4. Existující záznam raději zpřesni než zdvojuj; co tenhle vstup vyvrací,
   oprav nebo smaž včetně řádku v indexu. Nemáš-li čím soubor smazat, přepiš
   ho na platný a odeber aspoň jeho řádek z indexu.
5. Drž tvar předepsaný v <rozvinutá cesta ke konvenci, nebo její podstatné
   části vložené sem>: MEMORY.md je index s háčky, detail patří do tematických
   souborů s frontmatterem name/description/metadata.type a s řádky Why
   a How to apply.

Do volné části svého reportu vlož seznam dotčených souborů, jeden na řádek
a přesně v tomhle tvaru:

<cesta> — založeno|upraveno|smazáno — <důvod>
```

Cestu ke složce paměti odvoď z pole `memory:` cílového agenta podle tabulky
v `memory-conventions.md` — u `project` je to `.claude/agent-memory/<agent>/`.

### Report uživateli

```
Vstup: <co se studovalo>

<agent> — <založeno N, upraveno N, smazáno N | bez zápisu — zdůvodnění agenta>
  <soubor> — <co nese>
  …

Vynecháno: <agent → důvod, nebo „nic">
Neověřené tvrzení: <co agent hlásil a co jsi ve složce nenašel, nebo „žádné">
Nesoulad: <soubor → v čem se rozchází s konvencí nebo co duplikuje, nebo „žádný">
```

Usoudí-li agent, že se ho vstup netýká, a nezapíše nic, je to platný výsledek —
uveď ho jako „bez zápisu" s jeho zdůvodněním, ne mezi vynechanými. Tichý nezápis
a vědomé rozhodnutí nezapisovat se v reportu nesmí splynout.

## Zásady

- **Zápis patří agentovi, ne tobě.** Do paměti nezapisuješ ani ji neopravuješ —
  právo k ní plyne z jeho `memory:` a mimo jeho běh neplatí. Tvoje role je
  vstup, cíl a ověření.
- **Netrénuj z domněnky.** Nepřečtený vstup, odvozený obsah ani „nejspíš tam
  bylo“ nestačí. Špatný záznam přežije v paměti déle než chyba v kódu, protože
  ho nikdo netestuje.
- **Definice agenta se tímhle skillem nemění.** Chybějící `memory:`, úzké `tools`
  i jakákoli jiná úprava frontmatteru jsou práce pro `write-agent`, který jde
  přes review.
- **Paměť je rozpočet, ne archiv.** Načítá se agentovi při každém spuštění, takže
  každý nadbytečný záznam se platí pořád. Konsolidace není úklid navíc, je součást
  zápisu.
