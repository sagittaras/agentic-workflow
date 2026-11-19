# Šablona reportu běhu run-milestone

> **Rozsah:** Referenční soubor skillu `review-run`. Kostra reportu, který skill
> zapisuje. Čtenářem je agent nebo vývojář, který podle reportu opravuje plugin
> `sagittaras` — report musí obstát bez transkriptů po ruce.

## Jak šablonu použít

- Placeholdery v `[hranatých závorkách]` nahraď a závorky odstraň. Sekci, pro
  kterou běh nedal žádná data, nech s jednou větou proč — nevynechávej ji, čtenář
  by nepoznal, jestli se na ni zapomnělo.
- Fakta a interpretace drž oddělené: fakt má důkaz (čas a session, číslo issue
  nebo PR, výstup skriptu), interpretace a návrh jsou kurzívou s návěstím
  *Návrh:* nebo *Interpretace:*.
- Časy v místním pásmu, jak je vypisuje `run-transcripts.mjs`.
- Tokeny v milionech (M) nebo tisících (k) na jedno desetinné místo.

---

## Kostra

````markdown
# Report běhu `run-milestone` — [repo], milestone #[číslo] „[název]"

> **Pro koho:** agent analyzující plugin `sagittaras`. Report popisuje jeden
> skutečný běh od spuštění po [poslední stav: zavření milestonu | přerušení],
> s důrazem na místa, kde se postup skillu střetl s realitou. Fakta jsou ověřená
> proti trackeru a transkriptům; interpretace a návrhy jsou označené.
>
> **Datum běhu:** [datum], časy v [pásmo].
> **Repozitář:** `[owner/repo]` ([forge]).
> **Plugin:** běh jel na `[plugin_commit]` (určeno z [reflogu instalace | data
> commitu]), report porovnává s `[plugin_head]`. [Při `unknown`: verzi běhu
> nešlo určit, nálezy jsou ověřené proti aktuálnímu textu.]
> **Orchestrátor:** [model z transkriptu], podřazené session přes [start_session | Agent].

---

## 1. Shrnutí

| | |
| --- | --- |
| Výsledek | [dokončeno / přerušeno; issues, PR do integrační větve, integrační PR] |
| Celková doba | [od–do, z toho implementace] |
| Dávka | [velikost dávky] |
| Podřazené session | [počet; chybějící transkripty] |
| Běhy brány | [počet, z toho červených] |
| Eskalace na člověka | [počet] |
| Tokeny celkem | [zpracované, výstupní] |
| Odchylky orchestrátoru od skillu | [počet] |

**Hlavní zjištění:**

1. [Nejzávažnější nález jednou větou, odkaz na F-číslo.]

---

## 2. Výchozí stav a rozhodnutí před startem

[Stav milestonu při startu (issues, PR, počty z trackeru), konfigurace projektu
relevantní pro běh (forge, jazyk issues, ověřovací příkazy, Agenti), rozpory
zjištěné v kroku 1 a jak je rozhodl člověk.]

---

## 3. Časová osa PR

| PR | Issue | Otevřeno | Zmergováno | Běhy brány (výsledek) |
| --- | --- | --- | --- | --- |
| #[n] | #[n] | [čas] | [čas] | [pass, conflict, fail…] |

[Konfliktní soubory s počtem výskytů, pokud se konflikty opakovaly. Výsledek
testů kritérií napříč issues.]

---

## 4. Statistika tokenů a času

| Session | Rozpětí | Volání | Zápis cache | Čtení cache | Výstup | Kontext na konci |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Orchestrátor | [min] | [n] | [M] | [M] | [k] | [k] |
| Pomocní agenti orchestrátora | | [n] | [M] | [M] | [k] | |
| #[issue] (vč. vlastních subagentů) | … | … | … | … | … | … |
| **Celkem** | | **[n]** | **[M]** | **[M]** | **[M]** | |

[Pozorování: co určilo cenu, které session byly nejdražší a proč. „Rozpětí" je
první až poslední záznam včetně čekání, ne čistý čas práce.]

---

## 5. Nálezy k pluginu

Formát: **ID · závažnost · kde** — pozorování → důkaz → dopad → *návrh*.

### F1 · [vysoká | střední | nízká] · `[soubor pluginu, krok]`

[Pozorování.]
→ [Důkaz: čas, session, výstup.]
→ [Dopad na běh.]
[Od běhu změněno: commity, které soubor upravily, a zda text problém pořád má.]
*Návrh:* [interpretace a návrh opravy]

---

## 6. Už opraveno

[Problémy, které běh zasáhly, ale aktuální verze pluginu je řeší — jedním
řádkem: co se stalo, commit opravy. Prázdné, když plugin_commit = plugin_head.]

---

## 7. Eskalace na člověka

| # | Kdy | Proč (pravidlo skillu) | Rozhodnutí |
| --- | --- | --- | --- |
| E1 | [čas] | [důvod] | [co rozhodl člověk] |

---

## 8. Odchylky orchestrátoru od skillu

| ID | Pravidlo skillu | Co se stalo | Proč |
| --- | --- | --- | --- |
| D1 | [citace nebo parafráze pravidla] | [skutečný postup] | [důvod z transkriptu] |

---

## 9. Co fungovalo dobře

- [Mechanismus, který obstál, s důkazem.]

---

## 10. Otázky pro analýzu pluginu

1. [Rozhodnutí, které report nemůže udělat sám — koncepční volba pro vlastníka
   pluginu.]

---

## 11. Zdroje dat

- Tracker: `[owner/repo]`, milestone #[n], issues [výčet], PR [výčet].
- Transkript orchestrátoru: `[cesta]`.
- Transkripty session: [cesty nebo složky; chybějící transkripty jmenovitě].
- Plugin: `[plugin_root]` na `[plugin_commit]`.
````
