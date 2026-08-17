# Konvence psaní agentů

> **Rozsah:** Referenční soubor skillu `write-agent`. Závazné konvence pro zakládání
> a úpravu agentů — jak těch v `.claude/agents/` projektů, nad kterými plugin běží,
> tak těch, které dodává plugin sám ve složce `agents/`. Obě umístění se řídí týmiž
> pravidly; liší se jen ukotvení cest a tři pole, která se plugin agentům neuplatní
> (viz kapitola 3). Volbu `model:`, `effort:` a `maxTurns:` řeší
> [agent-model-matrix.md](agent-model-matrix.md), kostru těla
> [agent-template.md](agent-template.md).
>
> Konvence skillů drží [skill-conventions.md](../write-skill/skill-conventions.md) —
> agent a skill jsou různé artefakty s různými pravidly, nepřenášej mezi nimi nic
> automaticky.

---

## 1. Kdy agent, a ne skill

Rozhodovací otázka zní: **kdyby tuhle práci dělal člověk, byla by to jeho role, nebo
jeho úkol?**

- **Agent je *někdo*.** Drží obor, nese za něj odpovědnost a rozhoduje se v něm
  i v situacích, které nikdo předem nesepsal. Jeho hodnota je úsudek uvnitř domény.
- **Skill je *jak*.** Postup, který provede kdokoli — model i agent — a dojde ke stejnému
  výsledku. Jeho hodnota je opakovatelnost.

| Znak | Agent | Skill |
| --- | --- | --- |
| Zadání | Otevřené, cíl místo kroků | Ohraničené, kroky známé předem |
| Výsledek závisí na | Úsudku v doméně | Dodržení postupu |
| Kontext | Vlastní, izolovaný | Sdílený s volajícím |
| Model a effort | Vlastní, podle role | Vlastní, podle postupu |
| Výstup | Report do hlavního kontextu | Změna stavu nebo odpověď |
| Vzniká, protože | Někdo má obor vlastnit | Postup se opakuje |

**Nejčastější chyba je agent tam, kde stačil skill.** Agent stojí kontext, vlastní běh
a údržbu navíc; pokud se dá práce popsat jako číslovaný postup a výsledek nezávisí
na úsudku, napiš skill.

**Agent a skill nejsou alternativy.** Dobrý agent existující skilly volá — viz
[kapitola 4](#4-tělo-agenta).

---

## 2. Pojmenování

Základní tvar je **`<obor>-<role>`**, ale tvar je až druhá věc. První je tohle:

> **Jméno agenta má odpovídat roli, která by na daném projektu reálně existovala.**

Agenti se píší do konkrétního projektu, ne do vakua. Než agenta pojmenuješ, zjisti,
jakým slovníkem projekt o rolích mluví — `README.md`, `CONTRIBUTING.md`, `CODEOWNERS`,
dokumentace, ADR, názvy týmů a štítků v issue trackeru. Když tým říká „release
manager“, agent se jmenuje `release-manager`, ne `deployment-coordinator`.

```
code-reviewer     qa-lead     release-manager     level-designer     data-steward
```

| Pravidlo | Detail |
| --- | --- |
| Tvar | `<obor>-<role>` nebo ustálený název role z projektu |
| Slovní druh | Substantivum — agent je *kdo*, ne *co udělá* |
| Znaky | Jen malá písmena, číslice a pomlčka; **nikdy `:`** (rezervováno pro namespace pluginů, soubor se nenačte) |
| Délka | 3–50 znaků, ideálně dvě slova |
| Číslo | Jednotné — `qa-lead`, ne `qa-leads` |
| Shoda | Název souboru = hodnota `name:` ve frontmatteru |
| Unikátnost | V rámci projektu unikátní, a **odlišný od názvů skillů** |

**Proč substantivum, když skilly mají sloveso.** U skillu se rozhoduje podle akce,
takže sloveso nese informaci. U agenta se rozhoduje podle toho, čí je to obor —
a akci nese `description`. Substantivní tvar navíc odliší agenty od skillů v katalogu
a čte se správně při zmínce `@agent-code-reviewer`.

**Čemu se vyhnout:**

- **Obecné role** — `helper`, `assistant-agent`, `main-agent`. Neříkají, co agent vlastní.
- **Slovesné tvary** — `review-code` jako agent se plete se skillem, který dělá totéž.
- **Vymyšlené tituly** — role, kterou na projektu nikdo nepoužívá, nikdo nepozná ani
  nezavolá.
- **Opakování názvu projektu** — `titan-qa-lead` v repozitáři `titan`.
- **Tři a víc slov** — obvykle znamená, že agent drží dvě role a patří rozdělit.

---

## 3. Frontmatter

Frontmatter agenta je **konfigurace běhu i bezpečnostní hranice**. Agent běží
v odděleném kontextu bez dohledu, takže co mu tady povolíš, udělá bez ptaní.

### Povinné minimum

| Pole | Účel | Pravidla |
| --- | --- | --- |
| `name` | Identifikátor | Viz kapitola 2; shodné s názvem souboru |
| `description` | **Co dělá i kdy delegovat** | Trojdílná struktura, viz níže |
| `model` | Který model roli obsluhuje | Explicitně, dle [matice](agent-model-matrix.md) |
| `effort` | Hloubka uvažování | Explicitně, dle [matice](agent-model-matrix.md); u `model: haiku` naopak **vynech** — úrovně uvažování nepodporuje |
| `tools` | Nástroje, které role potřebuje | Explicitní výčet; viz níže |

`model` a `effort` mají výchozí hodnotu „zděď po volajícím“. Tu nikdy nenech platit:
agent má běžet podle toho, co dělá, ne podle toho, kdo ho náhodou zavolal. Bez
explicitního nastavení se tentýž agent chová pokaždé jinak.

`tools` je u agentů povinné navíc proti skillům, protože výchozí stav je „zdědí
všechno“. Práva musí sedět na mandát: agent, který má delegovat a ne implementovat,
nesmí mít `Write` a `Edit` — jinak si mandát dřív nebo později poruší sám.

> **Pozor:** když se ani jedna položka `tools` nerozřeší na existující nástroj, agent
> se vůbec nespustí a vrátí chybu. Názvy nástrojů opisuj, nevymýšlej.

### `description` — trojdílná struktura

Agent nemá `when_to_use`. `description` je **jediný text, podle kterého se orchestrátor
rozhoduje delegovat**, takže musí nést obojí. Piš ho ve třech dílech, každý jednou
větou:

1. **Co agent vlastní** — obor a výstup, věcně, třetí osoba.
2. **Kdy ho zavolat** — konkrétní situace, ne obecné „když je potřeba“.
3. **Kdy ne** — negativní vymezení vůči sousednímu agentovi nebo skillu. Povinná část.

```yaml
description: >-
  Drží testovací strategii projektu — navrhuje testovací plány, posuzuje závažnost
  nalezených chyb a rozhoduje, co blokuje vydání. Použij, když je potřeba posoudit
  kvalitu hotové změny, sestavit testovací plán nebo vyhodnotit připravenost
  k releasu. Nepoužívej pro psaní samotných testů, na to slouží test-engineer;
  ani pro review kódu, to vlastní code-reviewer.
```

**Časté chyby:**

- **Chybějící třetí díl.** Bez negativního vymezení se dva agenti přetahují o stejná
  zadání a deleguje se náhodně.
- **Jednostranné vymezení.** Když se `qa-lead` vymezí vůči `test-engineer`, musí
  se `test-engineer` vymezit i zpátky. Upravuj oba naráz.
- **Popis osobnosti místo schopnosti.** „Zkušený senior s citem pro detail“ nikomu
  neřekne, kdy agenta zavolat. Persona patří do těla, ne do `description`.
- **Vlepení celého postupu.** Popis není systémový prompt.

### Ostatní parametry — vždy zvaž

| Pole | Kdy nastavit |
| --- | --- |
| `disallowedTools` | Je jednodušší odebrat pár nástrojů než vyjmenovat všechny povolené. Při obou se nejdřív odečte denylist, pak se vyhodnotí allowlist. |
| `memory` | **U trvalých rolí výchozí volba** — viz níže. |
| `maxTurns` | Vždy — strop se volí u každého agenta podle [matice](agent-model-matrix.md). „Bez stropu“ je platná volba, ale patří do komentáře k vynechaným polím jako každá jiná. |
| `background` | `true` u dlouhých běhů, na jejichž výsledek se nečeká. Bez nastavení volí volající. |
| `isolation` | `worktree` u agenta, který zapisuje do repozitáře a jehož práce se má dát zahodit vcelku. |
| `color` | V sezení běží víc agentů a transkript se má dát číst. |
| `skills` | Skill, bez kterého agent neudělá ani první krok — přednačte se celý obsah, ne jen popis. Pro skilly volané za běhu stačí nástroj `Skill`. |
| `initialPrompt` | Agent je určený i pro běh jako hlavní sezení (`--agent`). |
| `permissionMode`, `mcpServers`, `hooks` | Jen pro agenty v `.claude/agents/`. **U agentů dodávaných pluginem se ignorují** — plugin je z bezpečnostních důvodů nenačte. |

**`memory` u trvalých rolí.** Role, která na projektu existuje dlouhodobě, má z učení
napříč sezeními největší užitek — `qa-lead`, který zná opakující se vzorce chyb
projektu, je použitelnější než ten, co začíná pokaždé od nuly. Výchozí volba je proto
`memory: project` (sdílené přes verzování). `local` použij, když se záznamy nemají
dostat do repozitáře, `user` jen u agentů, které nejsou vázané na jeden projekt.
U jednorázových a posuzovacích agentů paměť naopak vynech: paměť, kterou nikdo nečistí,
tiše zastarává a agent pak jedná podle nepravdy.

### Povinné komentáře

Ve frontmatteru jsou povinné dva komentáře — stejný režim jako u skillů:

- **Zařazení do matice** — dvojice model × effort a důvod, včetně odchylky, pokud jsi
  se od matice odchýlil.
- **Vynechaná zvažovaná pole** — každé netriviální pole, které jsi nepoužil, i s důvodem.

Volitelných polí je u agentů víc než u skillů, takže bez záznamu nejde po roce
rozpoznat rozhodnutí od opomenutí. Chybějící zdůvodnění je nález i tehdy, když je
vynechání správné.

### Co agentovi nikdy nepatří

Subagentovi jsou některé nástroje odebrány **vždy**, i když je vypíšeš v `tools`:
`AskUserQuestion`, `EnterPlanMode`, `EndConversation`, `ScheduleWakeup` a další.
Agent běžící na pozadí navíc přijde o většinu built-in nástrojů mimo základní práci
se soubory, shellem a webem — **tentýž `tools:` seznam tedy vyjde jinak na popředí
a jinak na pozadí**.

Prakticky to znamená jedinou věc, ale zásadní: **agent se nemá koho zeptat.** Cokoli
ve tvaru „zeptej se uživatele“, „počkej na schválení“ nebo „vyžádej si potvrzení“
je v agentovi nevymahatelné — agent buď souhlas předstírá, nebo se zasekne. Místo
otázky patří do těla pokyn, co si má agent zapsat do reportu a skončit.

---

## 4. Tělo agenta

Tělo je **systémový prompt role**, ne návod k použití. Kostru nese
**[agent-template.md](agent-template.md)** — otevři ji vždy, než začneš psát; tahle
kapitola shrnuje principy, na kterých stojí.

- **Persona v úvodu, rozkaz ve zbytku.** Úvod ve druhé osobě zakládá identitu
  („Jsi QA lead tohoto projektu…“), postup a hranice se píší rozkazovacím způsobem.
  Identita rozhoduje v situacích, které postup nepokrývá — a právě tam je agent k něčemu.
- **Postup neduplikuje skilly.** Když už postup existuje jako skill, agent ho zavolá
  a neopisuje jeho kroky do svého těla. Dvě kopie téhož postupu se rozejdou a nikdo
  si toho nevšimne.
- **Report je jediný výstup.** Agent běží ve vlastním kontextu; co nezapíše do reportu,
  pro volajícího neexistuje. Viz [kapitola 5](#5-report).
- **Hranice místo eskalace.** U každé hranice řekni nejen co agent nedělá, ale i **co
  místo toho** — obvykle „zapiš do reportu a skonči“.
- **Mapa návazností jen s nástrojem `Agent`.** Sekci `## Delegace` piš pouze u agenta,
  který smí spouštět subagenty. „Reportuje: producer“ u agenta bez toho nástroje
  je fikce, kterou nemá co vymáhat.
- **Instrukce, ne dokumentace.** Vynech všechno, co model umí sám od sebe. U instrukcí,
  které nejsou samozřejmé, připoj důvod — instrukci s důvodem model dodrží spolehlivěji
  než holý příkaz.
- **Jedna role.** Když se tělo rozpadá na dvě nesouvisející odpovědnosti, jsou to
  dva agenti.

Obsah piš česky, identifikátory anglicky.

### Na co se agent neodkazuje

Definice agenta je statický systémový prompt: načítá se celá při každém spuštění a nic
v ní nehlídá, jestli to, na co ukazuje, pořád existuje a pořád platí. Dva druhy odkazů
proto do těla nepatří vůbec.

**Konkrétní dokumenty cílového projektu.** Žádné „řiď se `docs/architecture.md`“,
„vycházej z ADR-0003“ ani „konvence testů najdeš v `docs/testing.md`“. Dokumenty se
přejmenovávají, dělí a ruší, kdežto definice agenta zůstává — agent pak čte neexistující
cestu, nebo se řídí verzí, která už neplatí. Co má role vědět trvale, jde do její
**paměti**; plní ji skill `train-agent` a záznam v ní se dá opravit i zahodit, aniž by
kdokoli sahal na definici. Tělo agenta proto pojmenuje **druh znalosti a odkud ji bere** —
„vzorce projektu máš v paměti“, „zdroje pravdy dostaneš v zadání“ — a ne soubory.
Vyjde-li z interview, že role potřebuje znát konkrétní dokument, není to důvod ho
do definice zapsat, ale položka pro následné spuštění `train-agent`.

**Rules v `.claude/rules/`.** Rule se do kontextu dostane sama: bez `paths` při startu
sezení, s `paths` ve chvíli, kdy agent sáhne na soubor odpovídající globu. Pokyn „přečti
si `.claude/rules/api.md`“ tedy načte totéž podruhé a rozbije se, jakmile někdo rule
přejmenuje nebo rozdělí. Agent o existenci rules nemá vědět nic.

**Odkazovat naopak smí** na doprovodné soubory, které se s ním dodávají (to je případ
agentů uvnitř pluginu), na skilly volané jmenovitě — název skillu je stabilní kontrakt —
a na dokument, jehož cestu dostane od volajícího v zadání.

---

## 5. Report

Report agenta má **jednotnou kostru napříč všemi agenty** a volnou část podle role.
Volající tak ví, co parsovat, aniž by četl definici každého agenta zvlášť.

```markdown
## <Role> — <předmět běhu>

**Výsledek:** <jedna věta: co je hotové, nebo jaký je verdikt>

### Co jsem udělal
<stručně, v pořadí; u posuzovatelů místo toho nálezy>

### Čeho jsem se nedotkl
<co bylo mimo mandát, co zůstalo nedokončené a proč, nejasnosti, na které
se agent nemohl zeptat — „nic" je platná odpověď>

### Doporučené další kroky
<konkrétně, včetně toho, kdo nebo co má navázat>
```

Volnou část si agent určí podle role — tabulka nálezů u posuzovatele, seznam změněných
souborů u vykonavatele, testovací plán u QA. Kostra se ale nemění a **žádná z jejích
sekcí se nevynechává**; prázdná sekce „Čeho jsem se nedotkl“ je informace, chybějící
sekce je ztráta.

Sekce „Čeho jsem se nedotkl“ nese to, co by u interaktivního běhu byla otázka.
Bez ní se nejasnosti ztratí a volající se dozví jen, že práce „proběhla“.

---

## 6. Kontrolní seznam před dokončením

- [ ] Práce skutečně vyžaduje roli, ne postup — jinak měl vzniknout skill
- [ ] Název je substantivní role, odpovídá slovníku cílového projektu, neobsahuje `:`,
      název souboru i `name:` se shodují a nekoliduje s názvem žádného skillu
- [ ] `description` má všechny tři díly — co vlastní, kdy zavolat, kdy ne
- [ ] Negativní vymezení sedí i z druhé strany, u souseda, vůči kterému se vymezuje
- [ ] `model` a `effort` nastavené explicitně podle matice, `effort` vynechaný u `haiku`
- [ ] `maxTurns` zvolený podle matice, nebo vynechaný se zdůvodněním
- [ ] `tools` je explicitní výčet, sedí na mandát role a všechny názvy existují
- [ ] `memory` zvážená — u trvalé role zapnutá, jinak vynechaná s důvodem
- [ ] Ostatní parametry vědomě zvážené; komentář se zařazením do matice i s výpisem
      vynechaných polí ve frontmatteru je
- [ ] Tělo odpovídá [šabloně](agent-template.md): úvod jako persona, zbytek rozkazovacím
      způsobem, placeholdery nahrazené, značky `(volitelné)` odstraněné
- [ ] Nikde není pokyn zeptat se uživatele nebo počkat na schválení
- [ ] Každá hranice říká, co má agent udělat místo zakázané akce
- [ ] `## Delegace` je v těle jen tehdy, má-li agent nástroj `Agent`
- [ ] Postup neopisuje kroky skillů, které existují — volá je
- [ ] Tělo neodkazuje na konkrétní dokumenty cílového projektu — trvalá znalost role
      patří do paměti, kterou plní `train-agent`
- [ ] Nikde není zmínka o `.claude/rules/` — rules se do kontextu načítají samy
- [ ] Report drží jednotnou kostru včetně sekce „Čeho jsem se nedotkl“
- [ ] Agent má jednu roli
