# Šablona UX specu

> **Rozsah:** Referenční soubor skillu `write-ux-spec`. Nese kostru dokumentu, výběr
> modulů podle povahy obrazovky a kontrolní seznam před zápisem. Při rozporu s tělem
> skillu platí tento dokument.

UX spec je **předávací artefakt mezi návrhem a implementací jedné obrazovky nebo flow**.
Odpovídá na to, co na obrazovce je, v jakých stavech, co dělá každý vstup, odkud se berou
data a kam se posílají akce. Píše se tak, aby podle něj šlo obrazovku postavit bez
doptávání — vágní věta v layoutu nebo ve stavech je díra, kterou implementace vyplní
odhadem.

Čím UX spec **není**:

| Není to | Kde to žije |
| --- | --- |
| Popis vzhledu, palety a typografie | Art bible. UX spec ji cituje a nikdy nepřerozhoduje. |
| Rozhodnutí o technologii nebo architektuře | ADR projektu. |
| Popis mechaniky, doménového pravidla nebo obsahu | Produktová či herní dokumentace. UX spec z ní bere data, stavy a fail stavy. |
| Zadání práce | Issue. Akceptační kritéria specu se do issues citují, ale spec sám není task list. |

---

## 1. Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď skutečným obsahem a závorky odstraň.
  Text uvnitř je pokyn, co do místa patří — ne text k opsání.
- Sekce označené `(modul)` jsou volitelné. Vynech ty, pro které obrazovka nemá obsah,
  a značku `(modul)` v hotovém dokumentu nikdy nenechávej.
- **Sekce si po výběru očísluj** a čísla drž — v review i v issues se na kapitoly
  odkazuje číslem.
- Jazyk obsahu převezmi z ostatních dokumentů projektu; identifikátory, cesty, názvy
  komponent, endpointy a ukázky kódu anglicky.
- **Vysvětlení, proč sekce existuje, zůstává tady** — do vzniklého dokumentu se nepřepisuje.
  Hotový spec obsahuje obsah, ne návod k sobě samému.
- Vyplněné příklady v této šabloně jsou ilustrace v `[závorkách]`. Do dokumentu se
  nepřenášejí ani upravené — spec o přihlašovacím dialogu, ve kterém zůstal řádek
  o mřížce inventáře, je horší než prázdná tabulka.
- **Pole hlavičky, pro které projekt nemá oporu** — princip u projektu bez pilířů,
  sousední spec u první obrazovky — vyplň pomlčkou. Vymyšlená hodnota je horší než
  přiznaná mezera; je-li ta hodnota potřeba, patří řádek do Otevřených otázek.

### 1.1 Výběr modulů

Jádro platí vždy. Moduly přibírej podle povahy obrazovky:

| Modul | Přiber, když |
| --- | --- |
| *Kontext při příchodu* | Uživatel na obrazovku přichází v rozpoznatelném stavu, který mění, co má vidět první — po dokončení dlouhé operace, po návratu z nečinnosti, před nevratným nebo rizikovým rozhodnutím. Typické pro hry a onboarding, zbytečné u nastavení. |
| *Přechody a animace* | Pohyb nese význam — odhalení výsledku, potvrzení akce, změna kontextu. Není potřeba tam, kde stačí přechody z art bible beze změny. |

Nejsi-li si u modulu jistý, polož si otázku: **rozhodl by se implementátor bez téhle
sekce špatně?** Když ne, sekce tam nepatří.

---

## 2. Kostra

````markdown
# UX spec — [Název obrazovky nebo flow]

| Pole | Hodnota |
| --- | --- |
| **Stav** | [Draft / K připomínkám / Schváleno / Implementováno] |
| **Autor** | [kdo dokument vede] |
| **Poslední úprava** | [RRRR-MM-DD] |
| **Poslední ověření** | [RRRR-MM-DD — kdy naposledy někdo potvrdil, že spec sedí se skutečným UI] |
| **Identifikátor** | [krátký název používaný v kódu a v issues — např. `InventoryScreen`] |
| **Platforma** | [co tenhle spec pokrývá — desktop, mobil, obojí] |
| **Vychází z** | [art bible; ADR; produktová dokumentace — konkrétní soubory a sekce] |
| **Sousední specy** | [rodičovská a sourozenecké obrazovky] |
| **Naplňuje princip** | [princip nebo pilíř projektu, který obrazovka obsluhuje] |

> [Jedna věta, co obrazovka je, když z názvu není zřejmé. Ne úvod, který převypráví nadpis.]

## Účel a potřeba uživatele

**Jakou potřebu obrazovka řeší?**

[Jeden odstavec. Pojmenuj lidskou potřebu, ne systémovou funkci. Co by uživatel řekl, že
chce, když obrazovku otevře, a co by ho frustrovalo, kdyby to nešlo — ta frustrace je
ta potřeba. „Zobrazuje data o X" je popis funkce, ne potřeby.]

**Cíl uživatele:** [Jedna věta, konkrétní tak, aby z ní šlo napsat akceptační kritérium.]

**Cíl systému:** [Jedna věta — co potřebuje zaznamenat nebo odeslat druhá strana.
Brání obrazovkám, které vypadají dobře a neslouží systému, jehož jsou součástí.]

## Kontext při příchodu (modul)

| Otázka | Odpověď |
| --- | --- |
| Co uživatel právě dělal? | [odkud přichází] |
| V jakém je stavu? | [soustředěný, spěchá, čeká na výsledek, rozhoduje se o něčem nevratném] |
| Co už ví? | [informace, které nese s sebou a nemají se opakovat] |
| Co se nejspíš snaží udělat? | [primární případ užití — ten určuje, co je vidět první] |
| Čeho se obává? | [riziko, které má obrazovka rozptýlit] |

**Jak má obrazovka působit:** [Jedna věta o pocitu, ne o vzhledu.]

## Pozice v navigaci

**Hierarchie:**

```
[Kořen]
  └── [Rodičovská obrazovka]
        └── [Tato obrazovka]
              └── [Dětská obrazovka nebo dialog]
```

**Chování překryvu:** [Samostatná obrazovka / překryv, pod kterým aplikace běží dál /
blokující dialog. U blokujícího řekni, čím se zavírá a jestli jde zavřít vůbec —
nezavíratelný dialog je vysoké tření a musí být zdůvodněný.]

**Vstupní body:**

| Vstupní bod | Vyvoláno čím | Adresa | Poznámka |
| --- | --- | --- | --- |
| [odkud] | [akce uživatele nebo systému] | [route, pokud je obrazovka adresovatelná] | [primární / sekundární / systémový] |

## Vstupní a výstupní body

**Vstupy:**

| Trigger | Zdrojový stav | Typ přechodu | Data předaná dovnitř | Poznámka |
| --- | --- | --- | --- | --- |
| [co obrazovku otevře] | [odkud] | [nová route / překryv / náhrada] | [co s sebou nese] | |

**Výstupy:**

| Akce | Cíl | Typ přechodu | Co se uloží nebo vrátí | Poznámka |
| --- | --- | --- | --- | --- |
| [co obrazovku opustí] | [kam] | | [stav potvrzený druhou stranou] | |

[Každý vstup má mít odpovídající výstup. Nedefinovaný přechod se stane bugem, ve kterém
uživatel uvízne — prázdná buňka v téhle tabulce je nedodělaný návrh, ne kosmetika.]

## Specifikace layoutu

### Wireframe

[ASCII kresba pro jednu referenční šířku. Nemusí být přesná na pixel — musí sdělit
hierarchii, blízkost a proporci. Značky: `[ ]` interaktivní prvek, `{ }` obsahová oblast,
`...` scrollovatelný obsah, `●` prvek s fokusem při otevření.]

```
[wireframe]
```

### Zóny

| Zóna | Obsah | Přibližná velikost | Scrollovatelná | Chování při přetečení |
| --- | --- | --- | --- | --- |
| [název] | [co v ní je] | [podíl šířky a výšky] | [ano/ne] | [zkrácení, stránkování, scroll indikátor] |

### Inventář komponent

| Komponenta | Typ | Zóna | Účel | Zdroj |
| --- | --- | --- | --- | --- |
| [název] | [button, text, dlaždice…] | [zóna] | [k čemu] | [primitivum z knihovny / existující komponenta / nová, složená z primitiv] |

[Sloupec Zdroj je nejdůležitější — určuje, co se staví a co se jen použije. Nová
komponenta se skládá z primitiv knihovny, ne z vlastního markupu a stylů. Než prohlásíš
komponentu za novou, ověř v sousedních specech, že ji některý už nedefinoval.]

**Fokus při otevření:** [Který prvek ho dostane a co se stane, když neexistuje.]

### Chování na úzkém viewportu

[Co se s layoutem stane pod breakpointem z art bible — které zóny se skládají, co se
skrývá, co zůstává. Vynech jen tehdy, když obrazovka na úzký viewport nemíří.]

## Stavy a varianty

| Stav | Trigger | Co se mění vizuálně | Co se mění v chování | Poznámka |
| --- | --- | --- | --- | --- |
| [Načítání] | | | | |
| [Prázdný] | | | | |
| [Naplněný] | | | | |
| [Chyba] | | | | |
| [stav specifický pro tuhle obrazovku] | | | | |

[Obrazovka není jeden obrázek, ale sada stavů. Návrh jen pro šťastnou cestu se pozná
podle rozbitého prázdného stavu a neviditelného načítání. Tahle tabulka je zároveň
testovací matice.]

## Mapa interakcí

| Vstup | Kontext | Akce | Odezva | Poznámka |
| --- | --- | --- | --- | --- |
| [Enter / klik] | [co musí být fokusované] | [co se stane] | [co uživatel uvidí] | |
| [Tab / šipky] | | [pohyb fokusu] | | [chování na okrajích zóny] |
| [Esc] | | | | |
| [dotyk, je-li v rozsahu] | | | | |

**Omezení podle stavu:**

| Stav | Co je nedostupné | Proč |
| --- | --- | --- |
| [stav] | [vstupy] | [důvod — typicky prevence souběhu] |

[Každá akce dosažitelná myší musí být dosažitelná i klávesnicí. Mezera v téhle tabulce
je bug, který se najde až v provozu.]

## Datové požadavky

| Údaj | Zdroj | Kdy se načítá | Vlastník | Formát | Chybí-li |
| --- | --- | --- | --- | --- | --- |
| [co obrazovka zobrazuje] | [endpoint nebo kontrakt] | [při otevření, po události] | [modul, který data vlastní] | [tvar] | [co se zobrazí místo toho] |

## Odeslané požadavky

| Akce uživatele | Požadavek | Payload | Příjemce | Poznámka |
| --- | --- | --- | --- | --- |
| [co uživatel udělá] | [endpoint] | [co se posílá] | [modul] | [kdy se aktualizuje UI] |

[Tahle a předchozí sekce jsou dvě poloviny hranice mezi rozhraním a zbytkem systému.
Platí-li v projektu, že výsledek počítá server, musí se to z obou tabulek dát přečíst:
rozhraní čte z pojmenovaných zdrojů a odesílá požadavky, nepočítá výsledek u sebe
a nezapisuje stav mimo ně.]

## Přechody a animace (modul)

| Přechod | Trigger | Typ | Trvání | Easing | Přerušitelný | Při reduced motion |
| --- | --- | --- | --- | --- | --- | --- |
| [co se hýbe] | | | [ms] | | | [co se stane místo animace] |

[Hodnoty ber z art bible. Vlastní tempo nebo vlastní křivka na jedné obrazovce je nález,
ne detail — a vzor vyhrazený pro určitý typ obsahu si nepůjčuj proto, že dobře působí.]

## Přístupnost obrazovky

**Kontrast:**

| Prvek | Podklad | Požadavek | Naměřeno | Vyhovuje |
| --- | --- | --- | --- | --- |
| [text nebo prvek] | [na čem leží] | [práh z art bible] | [hodnota, nebo „ověří se při implementaci"] | |

**Prvky rizikové pro barvoslepost:**

| Prvek | Riziko | Mitigace |
| --- | --- | --- |
| [co je odlišené barvou] | [jaký typ barvosleposti] | [tvar, ikona, text navíc — barva nikdy sama] |

**Pořadí fokusu:** [Číslovaná sekvence a kam se fokus vrací. Řekni i to, kam fokus
záměrně nevstupuje a proč.]

**Oznámení pro čtečku:**

| Změna stavu | Text oznámení | Kdy |
| --- | --- | --- |
| [co se změní] | [co čtečka řekne] | [okamžik] |

## Akceptační kritéria

[Binární, ověřitelné bez doptávání autora. Mají vyplynout ze sekcí výše — nový požadavek,
který se objeví až tady, je znamení, že chybí výš.]

**Layout a stavy**
- [ ] [kritérium]

**Vstupy**
- [ ] [kritérium]

**Data**
- [ ] [kritérium]

**Přístupnost**
- [ ] [kritérium]

## Otevřené otázky

| Otázka | Vlastník | Deadline | Stav |
| --- | --- | --- | --- |
| [co není rozhodnuté — konkrétně] | [kdo rozhodne] | [kdy nebo před čím] | [Otevřeno / Vyřešeno] |

[Dokument ve stavu Schváleno má nula otevřených otázek. Nezbývá-li žádná, sekci vynech celou.]
````

---

## 3. Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| Hlavička s metadaty | ✅ | Stav, vlastník, čerstvost, z čeho spec vychází | Chybí „Poslední ověření" — nikdo nepozná, jestli spec ještě popisuje realitu |
| Účel a potřeba uživatele | ✅ | Lidská potřeba, cíl uživatele, cíl systému | Popis funkce místo potřeby („zobrazuje seznam objednávek") |
| Kontext při příchodu | ⬜ (modul) | Stav, ve kterém uživatel přichází, a co z toho plyne pro pořadí informací | Vyplněno u obrazovky, kde žádný rozpoznatelný kontext není |
| Pozice v navigaci | ✅ | Hierarchie, chování překryvu, všechny vstupní body | Obrazovka dosažitelná z osmi míst bez povšimnutí, že je to signál složitosti |
| Vstupní a výstupní body | ✅ | Kontrakt s okolím, oboustranně úplný | Vstup bez odpovídajícího výstupu |
| Specifikace layoutu | ✅ | Wireframe, zóny, inventář komponent se zdrojem | Nová komponenta prohlášená bez kontroly, že ji soused už nemá |
| Stavy a varianty | ✅ | Všechny stavy včetně prázdného a chybového | Jen šťastná cesta |
| Mapa interakcí | ✅ | Co dělá každý vstup a co je kdy nedostupné | Akce dosažitelná jen myší |
| Datové požadavky | ✅ | Odkud se co čte a co se stane, když to chybí | Údaj bez uvedeného zdroje |
| Odeslané požadavky | ✅ | Každá akce měnící stav | Akce, která stav mění a v tabulce není |
| Přechody a animace | ⬜ (modul) | Pohyb, který nese význam | Vlastní tempo místo hodnot z art bible |
| Přístupnost obrazovky | ✅ | Kontrast, barvoslepost, fokus, oznámení — pro prvky téhle obrazovky | Opsaný obecný požadavek bez vztahu ke konkrétním prvkům |
| Akceptační kritéria | ✅ | Binární kritéria plynoucí ze sekcí výše | Nový požadavek, který se výš neobjevil |
| Otevřené otázky | ⬜ | Nerozhodnuté s vlastníkem a termínem | Otázka, na kterou dokument jinde odpovídá |

### 3.1 Dva zdroje obsahu

Tohle je hlavní rozlišení, na kterém spec stojí — spletení obou směrů je nejčastější
způsob, jak vznikne špatný dokument:

- **Standardy rozhodnuté napříč projektem** — barvy, typografie, styl komponent, tempo
  přechodů, práh kontrastu, architektonické invarianty. Žijí v art bible a v ADR. Spec je
  **cituje a nepřerozhoduje**. Zdá-li se, že obrazovka potřebuje výjimku, je to otevřená
  otázka, ne řádek k tichému zapsání.
- **Původní návrh téhle obrazovky** — jaké panely na ní jsou, co je vidět první, přesné
  rozvržení zón, stavy nad rámec obecné trojice, zkratky, pořadí fokusu. Tohle nikde
  napsané není a **vydoluje se z uživatele**, nevymýšlí.

Sekce, u které nevíš, do které skupiny patří, se nedá dobře napsat — urči to dřív, než
do ní začneš psát.

---

## 4. Rozsah

- **Spec je tak dlouhý, jak je obrazovka složitá.** Dvě až čtyři stovky řádků jsou
  u plnohodnotné obrazovky normální; potvrzovací dialog vystačí s třetinou a vynechanými
  moduly.
- **Prázdnou sekci nevyplňuj obecnou větou.** Buď má obsah, nebo se vynechá, nebo je
  z ní řádek v Otevřených otázkách.
- **Vágnost je díra.** Věta, u které by se implementátor musel doptat, není spec —
  je to poznámka k dalšímu jednání a patří mezi otevřené otázky.
- **Spec se aktualizuje na místě.** Nová obrazovka dostane nový dokument; změna
  existující obrazovky je úprava jejího dokumentu, ne druhý dokument o téže věci.

## 5. Kontrolní seznam před zápisem

- [ ] Účel popisuje potřebu uživatele, ne funkci rozhraní
- [ ] Každá hodnota převzatá z art bible nebo ADR je citovaná, ne přepsaná vlastními slovy
- [ ] Žádná sekce tiše nemění projektový standard; výjimky jsou otevřené otázky
- [ ] Layout má wireframe, zóny i inventář komponent a u každé komponenty je zdroj
- [ ] Před prohlášením nové komponenty jsem ověřil sousední specy
- [ ] Stavy pokrývají načítání, prázdno a chybu, ne jen šťastnou cestu
- [ ] Každá akce dosažitelná myší je dosažitelná i klávesnicí
- [ ] Každá akce měnící stav je v tabulce odeslaných požadavků
- [ ] Přístupnost mluví o prvcích téhle obrazovky, ne obecně
- [ ] Akceptační kritéria jsou binární a plynou ze sekcí výše
- [ ] Otevřené otázky mají vlastníka a termín; u stavu Schváleno žádné nezbývají
- [ ] V dokumentu nezůstal placeholder, značka `(modul)` ani příklad z této šablony —
      značky `[ ]` a `{ }` ve wireframu a zaškrtávací pole `- [ ]` u kritérií jsou výjimka
- [ ] Sekce jsou očíslované a čísla sedí s odkazy uvnitř dokumentu
- [ ] Jazyk konzistentní s ostatními dokumenty projektu, identifikátory anglicky
