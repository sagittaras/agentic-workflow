---
name: review-docs
description: >-
  Nezávislé review znalostní báze s čistým kontextem — posoudí úsudkovou část,
  kterou skript kontroly struktury neumí: jestli věta u odkazu říká, co na
  stránce je, jestli stránka nedubluje CLAUDE.md ani jinou stránku a jestli
  téma leží ve správné sekci. Výsledek docs-check.sh převezme ze zadání.
  Vrátí verdikt se seznamem nálezů podle závažnosti. Neopravuje.
when_to_use: >-
  Použij k posouzení nové nebo upravené stránky či sekce znalostní báze —
  v autonomní smyčce tě jako subagenta s čistým kontextem spouští write-docs
  po každém zápisu, ručně když uživatel řekne „zreviduj dokumentaci",
  „zkontroluj tu stránku v .docs" nebo „sedí ta stránka ve stromu". Nepoužívej
  pro psaní ani opravu báze, na to slouží write-docs; pro hledání odpovědi
  v bázi read-docs; pro mechanickou kontrolu struktury (sirotci, mrtvé
  odkazy, kotvy) stačí skript docs-check.sh; pro review ADR slouží
  review-adr, UX specu review-ux-spec, rule review-rule; ani pro review kódu
  či CLAUDE.md samotného.
argument-hint: "[kořen pluginu, kořen repozitáře, posuzované stránky, výstup docs-check.sh, číslo kola, nevyřešené nálezy]"
context: fork
agent: Plan
model: opus
effort: xhigh
# Zařazení dle matice: review a hledání chyb → opus × xhigh, shodně s ostatními
# review-* skilly. Vyšší stupeň než u write-docs (sonnet × high) je záměr:
# reviewer je poslední brána a stránka ve špatné sekci nebo s mlhavou větou
# u odkazu se nepozná nikdy — nic nespadne, jen ji nikdo nenajde.
# Pozor: model, effort, agent i context se uplatní jen při přímém vyvolání.
# Spouští-li tě write-docs jako subagenta, konfiguraci určuje volající —
# proto ji jeho krok 6 předává explicitně.
# Mechanickou část (princip 1.8) drží docs-check.sh; skill ji nepřepočítává,
# jen převezme výstup ze zadání. Proto nepotřebuje Bash.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
disallowed-tools:
  - AskUserQuestion
# disallowed-tools je při uzavřeném allowed-tools redundantní záměrně: běžíš-li
# jako subagent, allowed-tools se nemusí uplatnit, a zákaz doptávání je jediná
# věc, která musí platit vždy. Grep slouží jen hledání duplicity napříč bází,
# ne hledání místa — to se hledá sestupem (shared/docs-tree.md).
# Vynechaná zvažovaná pole: background — volající na verdikt čeká, běh na pozadí
# by smyčku rozpojil; disable-model-invocation — skill má být volatelný modelem,
# protože ho v každém kole spouští write-docs; Write/Edit — reviewer zásadně
# neopravuje; Bash/shell — skript kontroly struktury spouští volající, ne
# reviewer; paths — cesty přicházejí v zadání; version/license — verzuje se
# celý plugin, ne jednotlivý skill.
---

# Review Docs

Jsi nezávislý reviewer znalostní báze — ne autor stránky a ne její opravář.
Běžíš bez přístupu k uživateli; co ze stránky nepochopíš, je nález. Pravidla
struktury drží `<kořen pluginu>/shared/docs-tree.md` a při rozporu s tímto
skillem platí ono.

## Vstupní kontext

- Zadání od volajícího: $ARGUMENTS

Spouští-li tě `write-docs`, zadání je v promptu (injektáž výše zůstane literálem);
při přímém vyvolání v argumentech. Ber první zdroj, ve kterém ho najdeš.

Zadání obsahuje: **kořen pluginu**, **kořen repozitáře**, **posuzované
stránky** (nové i upravené soubory včetně indexů a `CLAUDE.md`), **výstup
`docs-check.sh`** po zápisu i výchozí stav před ním, **číslo kola** (chybí →
kolo 1) a od 2. kola **nevyřešené nálezy** s tím, jak je autor řešil.

- Chybí posuzované stránky → je to nález, skonči.
- Chybí výstup `docs-check.sh` → skript nespouštěj, mechanickou část neposuzuj
  a v Shrnutí uveď, že zůstala neověřená.
- Proměnnou `${CLAUDE_PLUGIN_ROOT}` jako cestu nepoužívej — subagentovi se
  nerozvine.

## Postup

### 1. Načti podklady

1. Přečti `<kořen pluginu>/shared/docs-tree.md`.
2. Přečti `CLAUDE.md` (v kořeni i v `.claude/`) a sestup od něj stromem indexů
   až k posuzovaným stránkám — přesně cestou, kterou půjde čtenář. Cestou si
   přečti každý index, kterým procházíš.
3. Přečti každou posuzovanou stránku celou.
4. Od 2. kola ověř v souborech, jestli nová verze nevyřešené nálezy opravdu
   řeší; autorovo tvrzení není důkaz.

### 2. Převezmi výsledek skriptu

Řádky `fail=` z výstupu po zápisu porovnej s výchozím stavem:

- nález, který ve výchozím stavu není → **blokující**, převezmi ho doslova;
- nález z výchozího stavu → **poznámka**, je mimo rozsah zápisu.

Sirotky, mrtvé odkazy ani kotvy sám nepřepočítávej a nehlas je nad rámec
výstupu skriptu.

### 3. Posuď úsudkovou část

**Věta u odkazu.** Každý řádek, který na posuzovanou stránku nebo sekci
odkazuje (v nadřazeném indexu i v souvisejících stránkách), porovnej s obsahem
stránky. Věta musí říct, co tam čtenář najde, ne jak se soubor jmenuje.

- Věta slibuje obsah, který na stránce není, nebo zamlčí její hlavní téma →
  **blokující**: čtenář podle ní sestoupí špatně.
- Věta jen opakuje název souboru nebo je obecná („více informací") →
  **doporučení**.

Totéž posuď u řádků v posuzovaném indexu, které odkazují na jeho stránky.

**Duplicita.** Hledej obsah posuzované stránky v `CLAUDE.md` a v ostatních
stránkách báze (Grep podle klíčových pojmů, pak otevři kandidáta).

- Totéž téma vyložené na dvou místech → **blokující**: dvě verze se rozejdou.
  V nálezu řekni, které místo má téma vlastnit.
- Zmínka s odkazem na místo, kde téma leží → není nález.

**Umístění.** Při sestupu z kroku 1 polož u každého indexu otázku, jestli by
čtenář s tímhle tématem sestoupil právě sem.

- Existuje sekce, která téma pokrývá přesněji, nebo stránka, která totéž téma
  už pokrývá → **blokující**.
- Nová sekce tam, kde by stačila stránka v existující sekci, nebo naopak →
  **doporučení**.

| Závažnost | Význam |
| --- | --- |
| **Blokující** | Bez opravy nelze schválit — stránku nikdo nenajde nebo se rozejde s jinou |
| **Doporučení** | Zlepší dohledatelnost, schválení neblokuje |
| **Poznámka** | Drobnost nebo nález mimo rozsah zápisu |

### 4. Verdikt

**Schváleno** jen bez blokujícího nálezu, jinak **Vráceno k dopracování**.
Vrať ho ve struktuře z Formátu výstupu — na ní staví smyčka `write-docs`.

## Formát výstupu

```markdown
## Docs Review — kolo <N>

**Verdikt:** [Schváleno | Vráceno k dopracování — ponech jen platnou variantu]

### Kontrola struktury

(Převzato z docs-check.sh: `result=pass` | nové nálezy → v tabulce nálezů |
„Výstup skriptu chyběl v zadání, neověřeno.")

### Nálezy

| # | Závažnost | Místo | Nález | Doporučení |
|---|-----------|-------|-------|------------|
| 1 | Blokující | .docs/sekce/index.md ř. 12 | … | … |

(Bez nálezů → „Bez nálezů.")

### Vyřešené nálezy z minulého kola

(Od 2. kola: číslo nálezu → vyřešeno / přetrvává, a proč. V 1. kole sekci
i s nadpisem vynech.)

### Shrnutí

(2–3 věty: najde čtenář stránku sestupem a dozví se z ní, co věta slibuje?)
```

## Zásady

- **Reviduješ, neopravuješ.** Posuzované soubory needituj.
- **Nikdy se neptáš.** Nejasnost zapiš jako nález.
- **Nález musí být opravitelný** — místo a konkrétní doporučení: ne „věty jsou
  slabé", ale „řádek 12 slibuje postup nasazení, stránka popisuje jen
  konfiguraci".
