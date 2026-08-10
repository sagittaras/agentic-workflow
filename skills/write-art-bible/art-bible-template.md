# Šablona art bible

> **Rozsah:** Referenční soubor skillu `write-art-bible`. Nese kostru dokumentu, výběr
> modulů podle povahy projektu a kontrolní seznam před zápisem. Při rozporu s tělem
> skillu platí tento dokument.

Art bible je **jediný zdroj pravdy o tom, jak projekt vypadá**. Čte ho člověk i agent;
píše se proto normativně — ne „mohlo by to být tmavé", ale „podklad je `surface`".
Když v něm někdo něco nenajde, nemá si vymyslet vlastní styl, ale doplnit ho sem.

Čím art bible **není**:

| Není to | Kde to žije |
| --- | --- |
| Implementace design systému | V kódu — balíček komponent, token soubor. Art bible ho specifikuje, nenahrazuje. |
| Rozhodnutí o technologii stylingu | ADR. Art bible říká *co* vypadá jak, ADR *čím* se to staví. |
| Katalog obsahu (počty map, itemů, obrazovek) | Design dokument projektu. Art bible popisuje vzhled, ne rozsah. |
| Marketingový brand manuál | Samostatný dokument, pokud existuje. Art bible z něj smí vycházet a odkazovat na něj. |

---

## 1. Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď skutečným obsahem a závorky odstraň.
  Text uvnitř je pokyn, co do místa patří — ne text k opsání.
- Sekce označené `(modul)` jsou volitelné. Vynech ty, pro které projekt nemá obsah, a
  značku `(modul)` v hotovém dokumentu nikdy nenechávej.
- **Sekce si po výběru očísluj** a čísla drž — uvnitř art bible se na kapitoly odkazuje
  a v issues a review se cituje „kapitola 3.2", ne „ta sekce o barvách".
- Jazyk obsahu převezmi z cílového projektu; identifikátory, tokeny, cesty a ukázky kódu
  anglicky.
- Prázdnou sekci nikdy nevyplňuj obecnými větami. Buď má obsah, nebo se vynechá, nebo
  se z ní stane řádek v **Otevřených otázkách** s vlastníkem.

### 1.1 Výběr modulů

Jádro platí vždy. Moduly přibírej podle toho, co projekt reálně vyrábí:

| Povaha projektu | Moduly navíc |
| --- | --- |
| Aplikace, nástroj, web — rozhraní složené z komponent | *Vizuální plochy a režimy*, jen pokud vzniká i druhá plocha (export, dokument, e-mail) |
| Hra | *Postavy a ilustrace*, *Prostředí a scény*, *Pohyb a zpětná vazba* |
| Projekt s tištěným nebo exportovaným výstupem (PDF, doklady, sestavy) | *Vizuální plochy a režimy* — a to povinně, je to hranice mezi světy |
| Prezentace značky, kampaně, obsah pro kanály | *Postavy a ilustrace*; *Produkční standardy assetů* rozšířit o formáty kanálů (kapitola jádra, ne modul) |

Když si u modulu nejsi jistý, projdi si otázku: **rozhodl by se někdo bez téhle sekce
špatně?** Když ne, sekce tam nepatří.

---

## 2. Kostra

````markdown
# Art bible — [Název projektu]

| Pole | Hodnota |
| --- | --- |
| **Verze** | [1.0] |
| **Stav** | [Draft / K připomínkám / Závazné] |
| **Poslední úprava** | [RRRR-MM-DD] |
| **Vlastník** | [kdo rozhoduje o změnách dokumentu] |
| **Platí pro** | [části repa nebo produktu, kterých se dokument týká] |
| **Navazuje na** | [dokumenty, ze kterých vychází — pilíře, ADR, brand manuál] |

> [Jedna až tři věty: pro koho je dokument závazný a co se čeká od toho, kdo v něm
> něco nenajde. Ne úvod, který převypráví nadpis.]

## Vizuální identita

[2–5 vět: čím projekt je, jak má působit a podle čeho se to pozná. Tohle je nejcennější
odstavec dokumentu — jako jediný nejde odvodit z kódu ani z palety. Pojmenuj vedoucí
barvu, dominantní náladu a to, čemu se vzhled podřizuje (hustotě dat, atmosféře, tisku).]

### Reference

| Reference | Médium | Co si z toho bereme |
| --- | --- | --- |
| [Konkrétní produkt, hra, film, tiskovina] | [Hra / aplikace / tiskovina] | [Jedna konkrétní vlastnost, ne „celkový dojem"] |

[Jednou větou i to, co si z reference záměrně nebereme, když hrozí záměna —
například „pouze UX vzor, ne vizuální styl".]

### Čeho se držíme a čeho ne

| Ano | Ne |
| --- | --- |
| [Vlastnost, kterou vzhled má mít] | [Její konkrétní opak, který se v projektu objevuje] |

[Nemá-li projekt opak, který mu reálně hrozí, sekci vynech celou — vymyšlený
protiklad jen ředí.]

## Vizuální plochy a režimy (modul)

[Když projekt renderuje do víc prostředí — rozhraní a exportovaný dokument, HUD a
marketingový materiál — každá plocha má napevno určený režim a vlastní sadu tokenů.
Míchat se nesmí a přepínat taky ne.]

| | [Plocha A] | [Plocha B] |
| --- | --- | --- |
| Kde vzniká | [cesty, trasy, kanály] | [cesty, trasy, kanály] |
| Režim | [tmavý / světlý / natvrdo?] | [tmavý / světlý / natvrdo?] |
| Podklad | [token] | [token] |
| Sada tokenů | [prefix nebo výčet] | [prefix nebo výčet] |

[Očíslovaná pravidla, která z rozdělení plynou: co se do které plochy nesmí dostat,
kde je hranice mezi sadami tokenů a co se rozbije, když se poruší.]

## Barevný systém

> [Kde tyhle hodnoty reálně žijí — token soubor, balíček, blok v CSS. Art bible a kód
> se nesmí rozejít; napiš, které místo se mění současně s tímhle dokumentem.]

### Základ

- **Primární barva: [barva].** [Co nese — identitu, primární akci, hlavičky.]
- **Neutrál: [rodina].** [Jediná povolená; vyjmenuj rodiny, které se nepoužívají,
  a řekni proč — blízké odstíny vedle sebe vypadají jako chyba, ne jako záměr.]
- **Sémantika: [barvy].** [Úspěch, varování, chyba, informace — a proč jsou zvolené
  právě takhle, když hrozí záměna s identitní barvou.]
- [Co je vyhrazené pro datové řady, rarity, kategorie — a tedy mimo UI.]

### Kanonické tokeny

[Blok v jazyce, ve kterém tokeny doopravdy žijí — ne pseudokód. Každý token s hodnotou
a komentářem, k čemu je. Tenhle blok je jediný zdroj barev; hodnota, která tu není,
v projektu neexistuje.]

```[jazyk]
[tokeny]
```

> [Pravidlo míchání: token, nebo syrová paleta — nikdy obojí na jedné ploše.]

### Sémantické mapování

[Stav, priorita nebo kategorie se nikdy nesignalizuje jen textem. Tabulka je závazná —
nepřebarvuj případ od případu.]

| Význam | Token | [Provedení na ploše A] | [Provedení na ploše B] |
| --- | --- | --- | --- |
| [Neutrální, výchozí] | [token] | [třídy nebo popis] | [třídy nebo popis] |
| [Informace] | [token] | | |
| [Úspěch] | [token] | | |
| [Varování] | [token] | | |
| [Chyba] | [token] | | |

### Poměr barvy na ploše

[Orientační rozložení jedné obrazovky nebo stránky — kolik neutrálu, kolik identitní
barvy, kolik sémantiky. Bez tohohle čísla vzniká buď šeď, nebo duha.]

## Typografie

[Písma a jejich role — ozdobné pro nadpisy, čitelné pro běžný text. U každého uveď
licenci a fallback stack, pokud se hostuje.]

| Použití | [Plocha A] | [Plocha B] |
| --- | --- | --- |
| [Titulek] | [velikost, řez, barva] | [velikost, řez, barva] |
| [Nadpis sekce] | | |
| [Běžný text] | | |
| [Sekundární text] | | |
| [Metadata, popisky] | | |

**Pravidla:**

- [Povolená škála velikostí — a že mimo ni se nesází.]
- [Povolené řezy.]
- [Zacházení s čísly, zarovnáním, kapitálkami — co je vyhrazené pro co.]

## Prostor a tvar

| Vlastnost | Povolené hodnoty | Poznámka |
| --- | --- | --- |
| Rozestupy | [škála] | [Co se nepoužívá.] |
| Rádius | [hodnoty a k čemu] | |
| Hranice | [tloušťky] | |
| Vrstvení (stíny, elevace) | [pravidlo] | [Čím se nahrazuje, když se stíny nepoužívají.] |
| Šířka obsahu / breakpointy | [hodnoty] | [Kdy se layout láme.] |

## Ikonografie

- [Zdroj ikon — knihovna, nebo vlastní autorství. Jiný se nezavádí.]
- [Povolené velikosti a jak se zapisují.]
- [Kdy ikona nese barvu stavu a kdy je neutrální.]
- [Pravidlo, že ikona nikdy nestojí sama jako jediný nositel významu.]
- [Rozlišení tříd ikon, když jich projekt má víc — systémové vs. obsahové.]

## Katalog prvků

[Kanonické provedení opakujících se prvků. Tahle kapitola je specifikací komponent:
takhle prvek vypadá uvnitř knihovny a takhle vypadá, dokud knihovna neexistuje.
Ne galerie — jen prvky, které se doopravdy opakují.]

### [Název prvku]

```[jazyk]
[Kanonická ukázka — krátká, ukazuje jednu věc.]
```

[Pravidla k prvku: kolik jich smí být na obrazovce, které stavy musí mít, co smí
volající zvenčí ovlivnit a co ne.]

## Postavy a ilustrace (modul)

- **Silueta a čitelnost** — [požadavek plus akceptační kritérium: v jaké nejmenší
  velikosti musí zůstat rozpoznatelné.]
- **Barevné kódování** — [podle čeho se rozlišují — třída, kategorie, vzácnost —
  a pravidlo priority, když se vlastnosti kombinují.]
- **Proporce a míra detailu** — [a čemu se podřizují.]
- **Stavy a varianty** — [co se vizuálně mění a co je vědomě odložené.]

## Prostředí a scény (modul)

[Čím se jednotlivá prostředí odlišují — a čím naopak ne, protože rámy a layout jsou
sdílené.]

| [Prostředí] | Charakter podkladu |
| --- | --- |
| [Název] | [Popis nálady a obsahu — ne výčet objektů] |

[Pravidlo pro text nad ilustrovaným podkladem: čím se zajišťuje kontrast.]

## Pohyb a zpětná vazba (modul)

- **Běžné přechody** — [délka, křivka, na co se vztahují.]
- **Zvýrazněné momenty** — [kde se pracuje s napětím nebo postupným odhalením, proč
  a jak to jde přeskočit.]
- **Notifikace a hlášení** — [vizuální váha podle důležitosti, odkud berou barvu.]
- **Čekání** — [co je technický stav a co záměrná pauza; hráč ani uživatel je nesmí
  zaměnit.]

## Produkční standardy assetů

### Konvence pojmenování

`[kategorie]_[nazev]_[varianta]_[velikost].[pripona]`

[Tři až čtyři skutečné příklady z tohoto projektu.]

| Kategorie | Rozlišení | Formát | Poznámka |
| --- | --- | --- | --- |
| [Kategorie] | [Max rozlišení] | [Formát] | [Kdy se použije fallback.] |

## Přístupnost

| Požadavek | Pravidlo |
| --- | --- |
| Kontrast textu | [Prahy a to, že kombinace mimo dokument se musí ověřit.] |
| Zakázané kombinace | [Konkrétní dvojice, které v projektu vznikají.] |
| Barvoslepost | [Že barva nikdy není jediný nositel informace — a co ji doprovází.] |
| Fokus | [Jak vypadá a že se neodstraňuje bez náhrady.] |
| Klikací plocha | [Minimum.] |
| Minimální velikost písma | [Hodnota.] |
| Sémantika a jazyk | [Značky, popisky, jazyk rozhraní.] |

[Výjimky pojmenuj výslovně — například že práh pro netextový kontrast neplatí na
neaktivní prvky — jinak se z nich stane tichá volnost.]

## Tvrdá pravidla

[Sem patří selhání, které v tomhle projektu vzniká opakovaně — u generovaných rozhraní
typicky „šedý text na šedém pozadí se šedým tlačítkem". Pravidla piš tak, aby se dala
odškrtnout pohledem na výsledek.]

**Na každé [obrazovce / stránce / záběru] musí být splněno:**

1. [Pravidlo — konkrétní, ověřitelné.]
2. [Pravidlo.]

| ❌ Nedělej | ✅ Dělej |
| --- | --- |
| [Konkrétní vzor, který se v projektu objevuje] | [Jeho náhrada] |

**Kontrolní otázka před odevzdáním:** _[Otázka, která odhalí porušení bez měření —
například: kdyby se z obrázku odstranil veškerý text, poznal by člověk, co je akce,
co je v pořádku a co je problém?]_

## Checklist

[Odškrtávací seznam pro toho, kdo odevzdává práci dotčenou tímhle dokumentem.
Každý bod je otázka na diff nebo na výsledek, ne obecná zásada.]

- [ ] [Otázka na použití tokenů místo syrových hodnot]
- [ ] [Otázka na zakázané vzory z předchozí kapitoly]
- [ ] [Otázka na stavy interaktivních prvků]
- [ ] [Otázka na přístupnost]
- [ ] [Otázka na to, jestli se změna promítla i do kódu tokenů]

## Křížové odkazy

| Tento dokument odkazuje na | Cílový dokument | Konkrétní element | Povaha |
| --- | --- | --- | --- |
| [Co odsud závisí na jiném dokumentu] | [cesta] | [sekce nebo pojem] | [Pravidlová / datová závislost, předání vlastnictví] |

[Nemá-li dokument explicitní závislost na jiném dokumentu, sekci vynech celou.]

## Otevřené otázky

| Otázka | Vlastník | Deadline | Stav |
| --- | --- | --- | --- |
| [Co ještě není rozhodnuté — konkrétně, ne „doladit barvy"] | [kdo rozhodne] | [kdy nejpozději, nebo před čím] | [Otevřeno / Řešení] |

[Když nic otevřeného nezbývá, sekci vynech celou.]

## Údržba dokumentu

- [Kdy se dokument mění a kdo změnu smí provést.]
- [Které místo v kódu se mění současně, aby se dokument a implementace nerozešly.]
- [Co už není úprava art bible, ale rozhodnutí do ADR — jiná primární barva, jiný
  režim, jiné písmo, jiná struktura balíčku.]
- [Že se při každé změně zvyšuje verze a datum v hlavičce.]
````

---

## 3. Vysvětlivky k sekcím

| Sekce | Povinná | Co do ní patří | Typická chyba |
| --- | --- | --- | --- |
| Hlavička s metadaty | ✅ | Verze, stav, vlastník, rozsah platnosti | Chybí „Platí pro" — nikdo neví, jestli se dokument týká i nové části repa |
| Vizuální identita | ✅ | Záměr vzhledu, vedoucí barva, čemu se vzhled podřizuje | Přídavná jména bez závazku („moderní, čisté, uživatelsky přívětivé") |
| Reference | ✅ | Konkrétní produkt a jedna konkrétní vlastnost, kterou si z něj bereme | „Inspirace: Apple." Bez uvedení čím se z reference stává výmluva |
| Čeho se držíme a čeho ne | ⬜ | Dvojice záměr / jeho konkrétní opak | Opak, který v projektu nikdy nehrozil |
| Vizuální plochy a režimy | ⬜ (modul) | Napevno určený režim každé plochy a hranice mezi sadami tokenů | Popis „podporujeme světlý i tmavý režim" bez určení, kdo který dostane |
| Barevný systém | ✅ | Tokeny s hodnotami, sémantické mapování, poměr barvy na ploše | Paleta bez mapování na význam — barvy jsou, ale nikdo neví, kdy kterou |
| Typografie | ✅ | Role textu → provedení, povolená škála | Výčet fontů bez pravidla, kde se který sází |
| Prostor a tvar | ✅ | Povolené hodnoty škál a co se nepoužívá | Odkaz na „výchozí škálu frameworku" bez zúžení — pak se použije cokoli |
| Ikonografie | ✅ | Zdroj, velikosti, kdy ikona nese barvu | Chybí pravidlo, že ikona sama není nositelem významu |
| Katalog prvků | ✅ | Kanonické provedení opakujících se prvků | Galerie všeho, co v projektu existuje, místo prvků, které se doopravdy opakují |
| Postavy a ilustrace | ⬜ (modul) | Silueta, barevné kódování, pravidlo priority u kombinací | Barevné kódování bez pravidla, co se stane při kombinaci vlastností |
| Prostředí a scény | ⬜ (modul) | Čím se prostředí odlišují a co naopak sdílejí | Odlišení, které si vynutí vlastní vizuální jazyk panelů |
| Pohyb a zpětná vazba | ⬜ (modul) | Tempo, kde se pracuje s napětím, jak se pozná technické čekání | Animace popsané pocitově, bez čísel a bez možnosti přeskočit |
| Produkční standardy assetů | ✅ | Pojmenování, rozlišení, formáty | Konvence pojmenování bez jediného skutečného příkladu |
| Přístupnost | ✅ | Prahy, zakázané kombinace, výslovné výjimky | Odkaz „splňujeme WCAG AA" bez uvedení, které kombinace se ověřily |
| Tvrdá pravidla | ✅ | Opakované selhání projektu a jeho odškrtnutelný opak | Pravidla, která nejde ověřit bez měřicího nástroje |
| Checklist | ✅ | Otázky na diff a na výsledek | Přepis obecných zásad, které nikdo neodškrtává |
| Křížové odkazy | ⬜ | Každá explicitní závislost na jiném dokumentu | Závislost zmíněná jen v textu, takže se při změně cíle neupraví |
| Otevřené otázky | ⬜ | Nerozhodnuté s vlastníkem a deadlinem | „Doladit později" bez vlastníka — nikdy se nedoladí |
| Údržba dokumentu | ✅ | Kdo mění, co se mění současně v kódu, co patří do ADR | Chybí vazba na kód — dokument a implementace se tiše rozejdou |

### 3.1 Provenience rozhodnutí

Art bible žije dlouho a její hodnoty se posouvají. Když se hodnota **změní proti
původnímu záměru** nebo když se **rozhodne o sporu**, zapiš k ní rozhodnutí přímo do
sekce, které se týká — ne do changelogu na konci:

```markdown
**Rozhodnutí k [čemu] ([odkaz na issue nebo diskusi], rozhodl člověk, ne agent):**
[Co bylo původně a proč to nestačilo — s naměřenou hodnotou, jde-li změřit.]
Rozhodnutí: **[co se mění]**. [Proč právě takhle a ne jinak.] [Kam se to promítá.]
```

Bez tohohle záznamu se za rok nikdo nedozví, jestli je hodnota výsledkem měření, nebo
překlepu — a někdo ji „opraví" zpátky.

---

## 4. Rozsah

- **Art bible je dlouhá a to je v pořádku** — na rozdíl od CLAUDE.md se nečte v každé
  session, ale otevírá se cíleně. Rozsah kolem čtyř set až sedmi set řádků je u zavedeného
  projektu normální.
- **Dlouhá ale neznamená rozředěná.** Každá věta musí být pokyn, hodnota nebo důvod.
  Odstavce, které jen popisují, co je daná technologie nebo jak je vzhled důležitý, škrtni.
- **První verze je krátká.** Vzniká na začátku projektu, kdy je rozhodnutá identita,
  paleta a typografie — katalog prvků se plní, jak prvky vznikají. Prázdná kapitola
  s poznámkou „doplní se při návrhu X" je lepší než vymyšlený obsah.
- **Nový opakující se prvek → doplnit do katalogu**, ne kreslit znovu jinde.

## 5. Kontrolní seznam před zápisem

- [ ] Vizuální identita říká něco, co nejde vyčíst z palety ani z kódu
- [ ] Každá reference má uvedenou konkrétní vlastnost, kterou si z ní bereme
- [ ] Každá barva má význam — paleta bez sémantického mapování je jen seznam hexů
- [ ] Tokeny v dokumentu odpovídají tokenům v kódu a je řečeno, kde v kódu žijí
- [ ] U škál je vyjmenované i to, co se nepoužívá, ne jen co je povolené
- [ ] Katalog obsahuje jen prvky, které se opakují, a u každého jeho stavy
- [ ] Moduly navíc odpovídají povaze projektu; nevyplněný modul je vynechaný, ne prázdný
- [ ] Přístupnost má prahy a výslovně pojmenované výjimky
- [ ] Tvrdá pravidla míří na selhání, které v tomhle projektu doopravdy vzniká
- [ ] Checklist se dá odškrtat pohledem na diff nebo na výsledek
- [ ] Otevřené otázky mají vlastníka a deadline, nebo tam nejsou
- [ ] Sekce jsou očíslované a čísla sedí s odkazy uvnitř dokumentu
- [ ] Údržba říká, které místo v kódu se mění současně a co už patří do ADR
- [ ] Jazyk konzistentní s projektem, tokeny a cesty anglicky
