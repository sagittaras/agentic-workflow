# Konvence ADR

> **Rozsah:** Referenční soubor skillů `write-adr` a `review-adr`. Závazná pravidla pro
> záznam architektonických rozhodnutí v cílovém projektu — kde ADR leží, jak se čísluje,
> jaké má stavy a co znamená „otevřená otázka". Tvar dokumentu nese
> [adr-template.md](adr-template.md); při rozporu platí tyto konvence.

ADR není zápis z porady, ale záznam pro čtenáře za rok — pro toho, kdo na rozhodnutí
narazí v kódu a bude chtít vědět, proč se to udělalo takhle a co se tehdy zvažovalo.
Všechna pravidla níže slouží tomuhle jedinému účelu.

---

## 1. Kde ADR leží

Plugin cestu nekonfiguruje a **odvozuje ji z repozitáře** — aby ADR šlo psát i v projektu,
který milestone workflow nepoužívá a `.claude/workflow.md` nemá. Postup:

1. Najdi soubory ve tvaru `NNNN-*.md` (glob `**/[0-9][0-9][0-9][0-9]-*.md`, mimo
   `node_modules/`, `vendor/` a `.git/`). Složka, kde jich leží nejvíc, je log projektu.
2. Nenajdeš-li žádný, hledej prázdnou kandidátní složku v tomhle pořadí: `.docs/adr/`,
   `.docs/architecture/`, `docs/adr/`, `docs/architecture/`, `doc/adr/`, `adr/`.
3. Vyjde-li kandidátů víc nebo žádný, **zeptej se**; u zakládaného logu navrhni
   `.docs/adr/`.

**Druhý log vedle existujícího nikdy nezakládej.** Rozdělený log znamená, že příští
rozhodnutí se opře o polovinu historie a druhou půlku nikdo nenajde.

---

## 2. Existující log má přednost před šablonou

Má-li log vlastní ustálený tvar — jiné pořadí sekcí, anglické nadpisy, jiný slovník stavů,
jinou hlavičku — **drž se ho** a šablonu použij jen na sekce, ke kterým se log nevyjadřuje.
Šablona platí v plné podobě pro log, který teprve zakládáš.

Důvod: v logu, kde každý dokument vypadá jinak, čtenář nepozná, co je konvence a co jen
tenhle jeden případ — a přestane se na tvar spoléhat. Jednotný tvar má větší cenu než
lepší tvar.

Totéž platí pro **jazyk**: ADR se píše jazykem existujícího logu. Nový log se ptá.

---

## 3. Číslo a název souboru

| Pravidlo | Detail |
| --- | --- |
| Název souboru | `NNNN-kratky-nazev.md` — čtyřmístné číslo, kebab-case slug |
| Číslování | vzestupné napříč celým repozitářem, ne per součást; první ADR je `0001` |
| Nadpis | `# ADR-NNNN: Název rozhodnutí` — nebo tvar, který drží existující log |
| Název | pojmenovává **předmět rozhodnutí**, ne „ADR o X" ani „Rozhodnutí ohledně X" |
| Slug | odvozený z názvu; stejný slug nese i větev `docs/adr-NNNN-kratky-nazev` |

Větev **není** `adr/…`: `create-branch` přijímá jen typy ze slovníku Conventional Commits
a jiný tvar odmítne kódem `3`. ADR je změna dokumentace, takže typ je `docs`.

**Výjimka u dořešení otevřených otázek** (kapitola 5): soubor se nepřejmenovává, takže
větev pojmenovaná jeho slugem by kolidovala s tou, na které vznikl původní dokument.
Dořešení proto větev odlišuje příponou — `docs/adr-NNNN-kratky-nazev-doreseni`. Rozchod
slugu větve a souboru je tady správně; jinde je to chyba.

Číslo urči takhle:

- **Zadal-li ho uživatel**, platí beze změny — typicky si čísla rozdělil předem, protože
  běží víc ADR souběžně. Jen ověř kolizi a případný střet nahlas.
- **Jinak** vezmi nejvyšší existující číslo v logu a přidej jedna.
- V obou případech prověř čísla **rezervovaná souběžnou prací**:

  ```bash
  git ls-remote --heads origin "docs/adr-*"
  ```

  Dvě větve se stejným `NNNN` se potkají až při merge, kdy se přečíslovává hotový
  dokument i s odkazy na něj. Zjistit to předem stojí jedno volání.

---

## 4. Stav a životní cyklus

| Stav | Kdy platí |
| --- | --- |
| **Navrženo** | Dokument je sepsaný a čeká na review. Jediný stav, ve kterém ADR do review patří. |
| **Přijato** | Review schválilo. Od merge do výchozí větve rozhodnutí platí. |
| **Nahrazeno ADR-NNNN** | Pozdější rozhodnutí tohle zvrátilo nebo změnilo. |
| **Zamítnuto** | Rozhodnutí se nakonec nepřijalo, ale záznam o zvažování má cenu. |

Slovník drž v jazyce logu — `Navrženo`/`Přijato` v českém, `Proposed`/`Accepted`
v anglickém. Nemíchej je: podle stavu se ADR filtrují a dvojí názvosloví filtr rozbije.

**Přijaté ADR se nepřepisuje.** Má právě dvě výjimky:

1. **Dořešení otevřené otázky**, kterou si dokument sám vyhradil — viz kapitola 5.
   Stav přitom zůstává `Přijato`; do `Navrženo` se ADR nevrací, protože rozhodnutí
   platilo i mezitím a měnit stav zpětně by mátlo každého, kdo se na něj odkázal.
2. **Překlopení Stavu na „Nahrazeno ADR-NNNN"**, když ho zvrátí novější ADR. Text
   Rozhodnutí i Důsledků zůstává beze změny — je to historický záznam toho, čemu se
   tehdy věřilo, a přepsat ho znamená zahodit důvod, proč se to muselo měnit.

---

## 5. Otevřené otázky

Sekce „Otevřené otázky" je **vědomý výčet toho, co rozhodnutí nechává nedořešené** — ne
známka nehotového dokumentu. Přijaté ADR ji mít smí; ADR, který si nedořešené věci
nepřizná, je horší než ten, který je vyjmenuje.

- Do výčtu patří jen **skutečné nerozhodnuté kompromisy**, ne spekulativní budoucí
  starosti bez vazby na tohle rozhodnutí.
- Co je zodpovězené jinde v témže dokumentu nebo v jiném ADR, do výčtu nepatří.
- Nezůstává-li nic, **vynech celou sekci** — prázdná sekce s nadpisem vypadá jako
  opomenutí.

**Dořešení versus nové ADR** — hranice je v tom, co se s odpovědí děje:

| Situace | Co s tím |
| --- | --- |
| Doplňuje se odpověď, kterou dokument **výslovně nechal otevřenou** | Editace téhož ADR: odpověď se vloží do Rozhodnutí (a Důsledků), položka z výčtu zmizí. Je to dokončení téhož rozhodnutí. |
| Mění se nebo zvrací odpověď, kterou dokument **už dal** | Vždy nové ADR, a původnímu se překlopí Stav na „Nahrazeno ADR-NNNN". |

---

## 6. Kód jako rozhodnutí

Někdy je nejpřesnějším vyjádřením rozhodnutí kus kódu — rozhraní, typ, kostra třídy,
strom adresářů — a ne odstavec, který ho opisuje. Nabídne-li ho uživatel v interview, ber
ho jako **závazné znění rozhodnutí**, ne jako materiál k parafrázi:

- **Zachovej ho jako fenced blok** uvnitř té podsekce Rozhodnutí, které se týká, v podobě,
  v jaké přišel. Kosmetické pročištění je v pořádku; přetvarovat ho ne.
- **Drž ho minimální** — rozhraní nebo kostra, ne implementace. Seznam vlastností,
  signatura metody nebo union typů fixuje **kontrakt**; těla metod, ošetření chyb
  a byznys logika patří do zdrojáků, ne do ADR. Přišlo-li toho víc, zúž to na části,
  které určují tvar.
- **Prověř ho proti konvencím, které fixovala dřívější ADR** (pojmenování, směr
  závislostí, typový styl). Rozpor nemusí být chyba — uživatel může vědomě nahrazovat —
  ale je to nejednoznačnost, kterou musíš vynést na světlo, ne ji tiše přijmout ani tiše
  „opravit" na starou konvenci.
- **Kód neodpovídá na „proč".** Zdůvodnění, zamítnuté varianty tvaru a Důsledky musí
  zůstat v próze kolem něj; blok kódu nikdy nenahrazuje text Rozhodnutí.

---

## 7. Kontrolní seznam před dokončením

- [ ] Soubor leží v logu podle kapitoly 1, číslo navazuje a nekoliduje s rezervovaným
- [ ] Název souboru, nadpis i větev `docs/adr-NNNN-slug` nesou tentýž slug
- [ ] Tvar dokumentu odpovídá existujícímu logu, u nového logu šabloně
- [ ] Stav sedí na režim: `Navrženo` u nového ADR, `Přijato` u dořešení otevřených
      otázek už přijatého; datum vyplněné
- [ ] Nezůstal žádný `[placeholder]`, instrukční komentář ze šablony ani značka
      `(volitelné)` v nadpisu sekce, která se použila
- [ ] Povinné sekce vyplněné konkrétním obsahem, nepoužité volitelné vynechané **celé**
- [ ] Kontext pojmenovává skutečný problém, ne obhajobu předem hotového řešení
- [ ] Rozhodnutí je implementovatelné bez doptávání
- [ ] Alternativy jsou reálné a důvody zamítnutí věcné; samotné „nedělat nic" nestačí
- [ ] Důsledky obsahují aspoň jeden, který jde proti zvolené variantě
- [ ] Otevřené otázky jsou pravdivé — nic zodpovězeného, nic spekulativního
- [ ] Rozhodnutí neodporuje jinému přijatému ADR, aniž by to přiznalo
- [ ] Tvrzení o projektu sedí na dokumentaci, ze které vycházejí
- [ ] Jazyk dokumentu je jazyk logu
