---
name: read-docs
description: >-
  Najde ve znalostní bázi projektu odpověď na otázku — mapu stromu indexů
  vypíše skriptem, podle vět u odkazů vybere a přečte jen stránky, které téma
  pokrývají, a z jednorázového kontextu vrátí krátkou odpověď s citacemi
  cesta#kotva, doslovné pasáže chráněných rozhodnutí a mezery báze. Kód
  nečte a nic nemění.
when_to_use: >-
  Použij, když potřebuješ z dokumentace projektu zjistit, co z kódu vyčíst
  nejde — záměr, cílový návrh, pravidla vrstvy, chráněné rozhodnutí —, typicky
  dřív, než sáhneš na oblast, kterou báze popisuje; ručně, když uživatel řekne
  „co říká dokumentace o…", „najdi v docs…", „proč je tohle udělané takhle".
  Do argumentu dej otázku a oblast, kterou měníš. Nepoužívej pro zápis do
  báze, na to slouží write-docs; pro zápis nového rozhodnutí nebo dořešení
  ADR write-adr; pro posouzení stránky review-docs; pro kontrolu struktury
  báze stačí skript docs-check.sh; ani pro hledání v kódu.
argument-hint: "[otázka; oblast, kterou měníš]"
context: fork
agent: general-purpose
model: sonnet
effort: medium
# Zařazení dle matice: průzkum a mapování → sonnet × medium, bez odchylky.
# Úsudek je úzký („pokrývá věta téma", „je to chráněné rozhodnutí"), tvar
# výstupu je pevný a mechaniku stromu drží docs-map.sh. Nikoli haiku: výběr
# stránek podle vět a rozpoznání chráněného rozhodnutí je úsudek, ne
# klasifikace. Levný fork je celý smysl skillu — sestup a zamítnuté stránky
# platí jednorázový kontext, ne volající.
# agent: general-purpose — neutrální prompt. Explore i Plan zamítnuty: oba
# tlačí k průzkumu kódu a Plan navíc připojuje k odpovědi sekci „Critical
# Files", která rozbije pevný formát. Čtení bez zápisu drží allowed-tools.
user-invocable: true
allowed-tools:
  - Read
  - "Bash(bash:*)"
# Bash(bash:*) pustí jakýkoli příkaz `bash …`; na docs-map.sh ho omezuje
# instrukce v těle, ne pravidlo.
# Vynechaná zvažovaná pole: Grep/Glob — bázi kontrakt zakazuje prohledávat
# hledáním řetězce i názvu (shared/docs-tree.md, § Jak najít odpověď v bázi)
# a kód skill nečte; disallowed-tools — skill se spouští vždy loaderem, takže
# uzavřený allowed-tools platí celý, AskUserQuestion v něm není;
# disable-model-invocation — hlavní přínos je, že si skill vyvolá model sám
# místo čtení báze ve vlastním kontextu; background — volající na odpověď
# čeká; paths — spouští se otázkou, ne prací nad soubory; shell — skript se
# spouští explicitním `bash`; version/license — verzuje se celý plugin.
---

# Read Docs

Cílem je odpověď z báze, kterou volající použije bez vlastního sestupu. Výběr
a čtení stránek drží `${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md`, § Jak najít
odpověď v bázi, body 1–4 — při rozporu s tímto skillem platí ony. Bod 5
a rozpor stránky s kódem tu neplatí: kód čte volající.

## Skripty

| Skript | Co dělá |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}/scripts/docs-map.sh` | Vypíše řádek `root=<absolutní cesta ke kořeni repozitáře>` a pod ním strom indexů báze jako vnořený seznam s cestou vůči kořeni a větou u každé stránky. Kódy: 0 mapa, 1 projekt bázi nemá (řádky `fail=`), 2 nejde o git repozitář |

Volej ho tvarem `bash ${CLAUDE_PLUGIN_ROOT}/scripts/docs-map.sh`, z kteréhokoli
adresáře repozitáře. Cestu pro Read slož z `root=` a cesty z mapy.

## Vstupní kontext

- Zadání od volajícího: $ARGUMENTS

Zadání nese otázku a oblast, kterou volající mění. Chybí-li oblast, je jí téma
otázky. Chybí-li otázka, vrať jen řádek `Chybí otázka.` a skonči.

## Postup

### 1. Vypiš mapu

Přečti § Jak najít odpověď v bázi v `${CLAUDE_PLUGIN_ROOT}/shared/docs-tree.md`
a spusť skript.

| Výstup | Další krok |
| --- | --- |
| kód 0 | Krok 2 |
| kód 1, `reason=missing_claude_md` | Vrať Odpověď z báze s odpovědí „Projekt nemá CLAUDE.md ani bázi — začni `/sagittaras:write-claude-md`." a prázdnými variantami ostatních sekcí, skonči |
| kód 1, `reason=missing_entry_index_link` | Vrať Odpověď z báze s odpovědí „Projekt bázi nemá — založ ji `/sagittaras:write-docs`." a prázdnými variantami ostatních sekcí, skonči |
| kód 2 | Vrať jen řádek `Nejde o git repozitář.` a skonči |

### 2. Vyber a přečti stránky

Postupuj body 2–4 kontraktu: z mapy vyber stránky, jejichž věta pokrývá téma
otázky, přečti je a po odkazu jdi dál jen podle bodu 4, s oblastí ze zadání.

### 3. Sestav odpověď

Odpověz podle Formátu výstupu, jen z přečtených stránek. Za chráněné rozhodnutí
ber pasáž, která zdůvodňuje, proč je konstrukce v oblasti ze zadání taková,
jaká je; jiná zdůvodnění necituj. Chráněné rozhodnutí cituj doslova, ne
parafrází — volající podle něj rozhoduje, jestli smí konstrukci změnit. Do
Mezer a rozporů patří, co přečtené stránky nepokrývají, dvě stránky, které si
odporují, a stránka, která sama uvádí, že je nahrazená.

## Formát výstupu

Cesty uváděj vůči kořeni repozitáře, tak jak je vypíše mapa. Kotvu vynech,
leží-li citované místo před prvním nadpisem stránky.

```markdown
## Odpověď z báze

**Otázka:** <otázka ze zadání>

<odpověď v 1–5 větách, jen z přečtených stránek>

### Opora

- `<cesta>#<kotva>` — <co z místa plyne pro otázku>

(Žádná → „Žádná.")

### Chráněná rozhodnutí

> <doslovná pasáž>

— `<cesta>#<kotva>`

(Žádné → „Žádná.")

### Mezery a rozpory

- <co báze nepokrývá | `<cesta>` × `<cesta>`: v čem si odporují | `<cesta>` je nahrazená, platí `<cesta>`>

(Žádné → „Žádné.")

**Přečtené stránky:** <`<cesta>`, `<cesta>` | žádné>
```

## Zásady

- **Kód nečti** — ani když báze odpověď nemá. Mezeru ohlas v Mezerách; čtení
  kódu i rozpor stránky s kódem řeší volající.
