# Kostra CLAUDE.md

> **Rozsah:** Referenční soubor skillu `write-claude-md`. Nese tvar cílového souboru,
> výčet toho, co do něj nepatří, a kontrolní seznam před zápisem. Při rozporu s tělem
> skillu platí tento dokument.

Cílem souboru je, aby model, který projekt nezná, po jeho přečtení věděl **na čem se
pracuje, proč, a kde si dohledá zbytek**. Není to dokumentace projektu ani jeho
inventura — je to rozcestník se záměrem.

**Rozsah: cíl ~80 řádků, strop 200.** Čím delší soubor, tím menší váhu má každý jeho
řádek — a v kontextu je v každé session, takže se platí pořád.

---

## 1. Kostra

Sekce ber jako výchozí sadu, ne jako povinný formulář. Sekci, pro kterou projekt nemá
obsah, vynech celou — prázdný nadpis s jednou obecnou větou je horší než žádný.

Placeholdery v `[hranatých závorkách]` nahraď obsahem a závorky odstraň; text uvnitř
je pokyn, co do místa patří, ne text k opsání. Nadpisy jsou tu česky a titulek nese
anglický sufix — obojí přelož do jazyka, který jsi určil pro soubor.

````markdown
# [Název projektu] — Claude instructions

[2–5 vět: co se staví, pro koho a proč zrovna takhle. Tohle je nejcennější část
celého souboru, protože jako jediná nejde vyčíst z kódu. Patří sem záměr, žánr
či doména, a hlavní princip, na kterém projekt stojí. Ne historie, ne marketing.]

## Základní údaje

[Volitelná tabulka pro projekty s vázaným prostředím — verze enginu, cílová
platforma, runtime. Vynech, když se totéž dá přečíst z manifestu projektu.]

## Orientace ve struktuře repa

[Odrážky `cesta` — k čemu je. Jen úrovně, na kterých se láme odpovědnost, ne strom
souborů. U dokumentace odkazuj markdown odkazem a řekni, kdy ji otevřít — tím se
z opisu stane rozcestník.]

- `[cesta]` — [k čemu slouží, jednou větou].
- `[cesta/docs]` — [co obsahuje]; [kdy si to má model přečíst].
- [ODKAZ.md] — [co v něm je].

[Věta o tom, že se struktura bude rozšiřovat a seznam se má držet aktuální.]

## Tech stack

[Odrážky nebo krátká tabulka. Jen technologie, které mění způsob práce —
ne seznam závislostí. Bez vysvětlování, co daná technologie je.]

## Architektonické principy

[Invarianty, které platí napříč projektem a nejdou vyčíst z jednoho souboru:
kdo je zdroj pravdy, co se kde nesmí počítat, jaké jsou stabilní kontrakty.
Tohle je druhá nejcennější sekce — chrání před změnami, které projdou testy
a přitom rozbijí návrh.]

## Konvence práce

[Jen to, co model neuhodne a co nehlídá nástroj: jazyk kódu vs. jazyk komunikace,
odkaz na commit konvence, odkaz na branching. Formátování a styl přenech linteru.]
````

---

## 2. Co do souboru nepatří

Výchozí `/init` sype většinu následujícího a právě tím soubor nafoukne. Každý bod
je důvod ke škrtu:

| Nepatří | Proč |
| --- | --- |
| Výpis build / test / lint příkazů | Model si je přečte z `package.json`, `Makefile`, `*.csproj`. Opsané zastarají a začnou lhát. |
| Inventura všech složek a souborů | Orientace znamená vybrat úrovně, kde se láme odpovědnost. Strom souborů si model vypíše sám. |
| Vysvětlení, co je daná technologie | „Next.js je React framework" model ví. Zajímá ho, jak ji používá tenhle projekt. |
| Opsaný obsah dokumentace | Duplicita se rozejde s originálem. Odkaz drží krok, opis ne. |
| Obecné rady o kvalitě | „Piš čitelný kód", „přidávej testy" neřídí nic a zabírají místo. |
| Coding style a formátování | Hlídá linter a formatter. Když ne, patří to do jejich konfigurace, ne sem. |
| Seznam závislostí a verzí | Je v lock souboru, aktuálnější než tady. |
| Historie, changelog, roadmapa s daty | Zastará nejrychleji ze všeho a k rozdělané práci nepřispěje. |
| Pokyny platné pro jednu úlohu | Patří do zadání, ne do souboru, který se čte v každé session. |
| Duplicita se skilly a `.claude/settings.json` | Postupy patří do skillů, konfigurace do settings. Sem jen odkaz. |

Zvlášť si hlídej **ředění**: sekce, která má obsah na dvě věty, se snadno rozepíše
na patnáct řádků obecných formulací. Rozsah se tím naplní, informace nepřibude.

---

## 3. Kontrolní seznam před zápisem

- [ ] Úvodní odstavec odpovídá na „co se staví a proč" — a to „proč" v repu nikde jinde není
- [ ] Každá cesta v orientaci má uvedený důvod, proč ji model má znát
- [ ] Hlubší dokumentace je odkázaná, ne opsaná, a u odkazu je řečeno, kdy ho otevřít
- [ ] Žádný příkaz, který jde přečíst z manifestu projektu
- [ ] Žádné vysvětlování technologií, žádné obecné rady o kvalitě kódu
- [ ] Architektonické principy jsou invarianty, ne popis aktuální implementace
- [ ] Nic, co platí jen pro jednu úlohu nebo jedno období
- [ ] Cíl ~80 řádků; u souboru delšího je vyjmenované, co se neodsunulo do dokumentace a proč
- [ ] Hotový soubor nepřesahuje 200 řádků; nejde-li to bez ztráty informace, eskaluj místo ředění
- [ ] Jazyk konzistentní s projektem, identifikátory a cesty anglicky
- [ ] Sekce bez obsahu jsou vynechané celé, ne vyplněné obecnými větami
