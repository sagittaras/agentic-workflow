---
name: write-skill
description: >-
  Vytvoří nový skill v pluginu nebo upraví existující — provede interview,
  navrhne název a konfiguraci frontmatteru podle matice model × effort,
  sepíše SKILL.md podle závazné šablony a nechá výsledek nezávisle zrevidovat
  subagentem s čistým kontextem. Kola oprav a review řídí autonomně;
  na uživatele se obrací jen při eskalaci.
when_to_use: >-
  Použij, když chce uživatel založit nový skill nebo upravit existující —
  „vytvoř skill", „přidej skill na…", „napiš mi skill", „uprav frontmatter
  skillu" — ale i tehdy, když popisuje opakovaný postup, který by stálo za to
  zachytit jako skill, aniž by slovo skill zmínil. Nepoužívej pro zakládání
  agentů ani commandů, ty mají vlastní pravidla; pro samotné posouzení
  hotového skillu slouží review-skill; ani pro běžné použití existujícího skillu.
model: opus
effort: high
# Zařazení dle matice: otevřené zadání s interview a psaním dokumentu →
# opus × high. Nikoli xhigh: skill nemá dlouhoběžnou autonomní exekuci,
# těžiště je v návrhu a textu, a matice velí při váhání mezi dvěma stupni
# volit nižší.
argument-hint: "[název nebo téma skillu]"
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - AskUserQuestion
  - Agent
# Vynechaná zvažovaná pole: disable-model-invocation — skill je užitečný
# i když si ho model vyvolá sám z popisu opakovaného postupu; context/agent/
# background — interview potřebuje uživatele v hlavním kontextu, fork nebo
# běh na pozadí by neměly komu klást otázky; paths — skill se spouští
# z konverzace nad tématem, ne prací nad konkrétními soubory;
# disallowed-tools — allowed-tools je uzavřený výčet, není co zakazovat navíc.
---

# Write Skill

Cílem je skill, který obstojí v automatickém provozu: spouští se ve správných
situacích, běží na správném modelu a jeho instrukce dávají smysl i tomu, kdo
nezná kontext jeho vzniku. Závazným kontraktem jsou tři referenční soubory
vedle tohoto — při rozporu s čímkoli, včetně tohoto skillu, mají přednost ony.

## Vstupní kontext

- Zadání od uživatele (může být prázdné): $ARGUMENTS

## Postup

### 1. Příprava

1. Přečti [skill-conventions.md](skill-conventions.md) — pravidla pojmenování
   a frontmatteru, na která se budeš celou dobu odvolávat.
2. Přečti [skill-template.md](skill-template.md) — kostru, do které budeš psát.
3. [model-effort-matrix.md](model-effort-matrix.md) otevři až ve chvíli, kdy
   budeš zařazovat úlohu; dřív ji nepotřebuješ.
4. Projdi existující skilly v `skills/` — stačí `description` a `when_to_use`
   z jejich frontmatterů. Nový skill nesmí triggeringem kolidovat se sousedy;
   hranici je potřeba vytyčit negativním vymezením **na obou stranách**, takže
   pokud úprava souseda k zadání patří, udělej ji zároveň.

### 2. Interview

Piš jen to, co víš od uživatele. Nejdřív vytěž konverzaci, pak se doptej po
kolech — nástrojem AskUserQuestion a s konkrétními možnostmi tam, kde dávají
smysl. Zjisti:

- **Účel** — jaký opakovaný problém skill řeší a jak často poběží.
- **Triggering** — kdy se má spouštět (situace i fráze, které uživatel reálně
  řekne) a kdy naopak ne. Negativní vymezení vůči sousedním skillům je povinná
  část `when_to_use`, ne ozdoba.
- **Vstupy a výstup** — jestli přijímá argumenty, co je výsledkem a kam se ukládá.
- **Nástroje** — co postup skutečně potřebuje. Užší `allowed-tools` je lepší
  než široký, ale skill, kterému chybí nástroj, se zasekne uprostřed práce.
- **Název** — navrhni `<činnost>-<předmět>` a nech si ho potvrdit.
- **Zařazení do matice** — navrhni dvojici model × effort i s odůvodněním
  a nech si ji potvrdit.

Interview končí, až umíš vyplnit všechna povinná pole frontmatteru a rozhodnout
o každém zvažovaném poli. Než začneš psát, shrň uživateli, co skill bude dělat
a jak bude nakonfigurovaný, a nech si shrnutí potvrdit — oprava návrhu stojí
jednu větu, oprava hotového skillu celé kolo.

**Nemáš-li uživatele, skill nepiš.** Skill napsaný z domněnek se spouští ve
špatných situacích a na špatném modelu, což je horší než žádný skill. Selže-li
volání AskUserQuestion nebo odpověď nedorazí, shrň, na co potřebuješ odpovědět,
a skonči — nezakládej soubory.

### 3. Sepsání

Okopíruj kostru ze [skill-template.md](skill-template.md) a vyplň ji. Šablona
je kostra k vyplnění, ne text k opsání: placeholdery nahraď, závorky i značky
`(volitelné)` odstraň, nepoužité volitelné sekce smaž celé.

Ve frontmatteru:

- povinná pětice `name`, `description` (co), `when_to_use` (kdy + negativní
  vymezení), `model`, `effort` — a součet `description` + `when_to_use`
  do 1 536 znaků;
- komentář se zařazením do matice a s odůvodněním, pokud ses odchýlil;
- komentář vypisující každé vynechané netriviální zvažované pole i s důvodem.
  Bez něj review nerozliší uvážené vynechání od opomenutí.

V těle piš rozkazovacím způsobem a u instrukcí, které nejsou samozřejmé,
**vysvětli proč** — instrukci s důvodem model dodrží spolehlivěji než holý
příkaz. Nepopisuj, co model umí sám od sebe. Objemný materiál (referenční
tabulky, šablony) odsuň do vedlejších souborů a u každého odkazu řekni, **kdy**
se má otevřít.

### 4. Vlastní kontrola

Projdi hotový skill proti kontrolnímu seznamu v závěru
[skill-conventions.md](skill-conventions.md), bod po bodu. Zvlášť ověř, že:

- v souboru nezůstal žádný placeholder ani značka `(volitelné)`;
- `when_to_use` obsahuje negativní vymezení a sedí i z druhé strany — u souseda,
  vůči kterému se vymezuješ;
- `model` a `effort` odpovídají zařazení, které uživatel potvrdil.

Reviewer bude kontrolovat proti témuž seznamu — co si opravíš tady, nemusíš
řešit v dalším kole.

### 5. Nezávislé review

1. Nástrojem Agent spusť subagenta typu **Plan** na modelu `opus`, **synchronně**
   (`run_in_background: false`) — bez verdiktu nemáš jak pokračovat. V zadání
   předej: pokyn přečíst `skills/review-skill/SKILL.md` a provést jeho postup,
   **cestu k posuzovanému skillu**, **číslo kola** a od druhého kola
   **nevyřešené nálezy z minulého kola i s tím, jak jsi je řešil**.

   Subagent startuje s čistým kontextem — právě proto je jeho pohled nezávislý,
   a právě proto si historii kol nepamatuje. Co mu nepředáš, pro něj neexistuje.

2. **Vráceno k dopracování** → zapracuj všechny blokující nálezy, doporučení
   uvážlivě zvaž. Pak spusť další kolo s **novým** subagentem; tomu vypotřebovanému
   nedávej opravu k posouzení, ztratil by odstup.

3. **Schváleno** → skill je hotový. Reportuj uživateli: název skillu, cestu
   k souboru, zvolenou dvojici model × effort i s důvodem, počet kol review
   a nálezy, které jsi odmítl, i s odůvodněním.

Nálezy neodmítej mlčky. Reviewer nezná interview, takže může napadnout něco,
co uživatel vědomě chtěl — takový nález patří do reportu, ne do koše.

### 6. Eskalace

Přeruš smyčku a obrať se na uživatele, když:

- nález zpochybňuje účel nebo podobu skillu, kterou uživatel v interview
  výslovně potvrdil — záměr vlastní uživatel, ne ty ani reviewer;
- stejný blokující nález přetrvává i po tvém pokusu o opravu (dvě kola);
- proběhla tři kola bez schválení;
- narazíš na technickou chybu, kterou opakování nevyřeší.

Při eskalaci shrň stav smyčky, ocituj sporný nález a polož konkrétní otázku.
Mlhavá eskalace uživatele jen zdrží.

## Formát výstupu

```
skills/<název-skillu>/
  SKILL.md              ← postup a rozhodování
  <reference>.md        ← volitelně: objemný materiál odsunutý z těla
```

Název složky se musí shodovat s hodnotou `name` ve frontmatteru.

## Zásady

- Referenční soubory mají přednost před tímto skillem. Když si odporují,
  platí konvence a šablona, ne tento postup.
- Interview a eskalace jsou jediné fáze, které vyžadují uživatele. Mezi nimi
  běží smyčka psaní a review autonomně — nepřerušuj ji kvůli průběžnému hlášení.
- Bez interview skill nevzniká.
- Review si neděláš sám. Vlastní kontrola v kroku 4 ho nenahrazuje: autor
  nevidí, co do skillu podvědomě doplnil z hlavy.
- Úprava existujícího skillu jde stejným postupem jako vznik nového, včetně
  review — drobnost není výmluva.
- Skill má jednu odpovědnost. Když se postup při psaní rozpadá na dva
  nesouvisející sledy kroků, vrať se k uživateli s návrhem rozdělit ho.
- Nevejde-li se `description` s `when_to_use` do limitu, není to problém
  formulace, ale záběru — skill dělá víc věcí najednou.
