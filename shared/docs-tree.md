# Strom dokumentace

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Pravidla struktury znalostní
> báze cílového projektu — stromu indexů, který začíná odkazem z `CLAUDE.md` — a postup,
> jak v něm najít místo pro nový dokument a jak ho odkázat. Otevři ho vždy, když
> dokument v bázi **zakládáš nebo rozšiřuješ** (`write-docs`, `write-adr`,
> `write-art-bible`, `write-ux-spec`), když **posuzuješ** její strukturu nebo
> dohledatelnost dokumentu (`review-docs`, `review-adr`, `review-ux-spec`), a když
> doplňkový dokument citovaný v `Reference` **hledáš** (`plan-milestone`,
> `implement-issue`, `verify-issue`, `review-milestone`).

Strom je jediná cesta k dokumentaci: co na něj nenavazuje, nikdo nenajde. Registr cest
vedle dokumentů a hledání podle názvu souboru driftují, protože je změna, která
dokument přidává nebo přesouvá, needituje — index leží vedle stránek, které popisuje,
a stejná změna ho upraví přirozeně.

---

## Umístění báze

- **Výchozí umístění je `.docs/`** v kořeni projektu, vstupní index `.docs/index.md`.
- **Projekt s vlastní dokumentační složkou** (`docs/`, `wiki/`…) si ji ponechá — bázi
  nestěhuj ani nezakládej druhou vedle. Pravidla struktury platí pro ni stejně.

Kde báze leží, neurčuje tenhle kontrakt ani hádání podle tvaru složek, ale odkaz
z `CLAUDE.md`: vstupní index je ten soubor, na který `CLAUDE.md` odkazuje.

---

## Pravidla struktury

Minimum, které strom musí splnit, aby po něm šlo navigovat:

1. **`CLAUDE.md` odkazuje na vstupní index** a říká, kdy ho otevřít.
2. **Sekce = složka s `index.md`.** Podsekce se zakládají stejně, do libovolné hloubky.
3. **Index odkazuje na všechny své přímé stránky a podsekce** a u každého odkazu
   jednou větou řekne, co tam je. Podsekce se odkazuje jejím `index.md`.
4. **Nová stránka nebo sekce se odkazuje z nadřazeného indexu ve stejné změně**, ve
   které vzniká. Změna, která zneplatní zdokumentované chování, upraví ve stejné změně
   i dokumentaci.
5. **Stránky na sebe odkazují relativními markdown odkazy**, na konkrétní místo
   s kotvou (`../vision/principles.md#17-…`), ne absolutní cestou ani URL na forge.

Stránka, na kterou žádný index neodkazuje, je sirotek — existuje, ale navigací se
k ní nikdo nedostane.

---

## Jak najít místo pro nový dokument

Místo se hledá **sestupem stromem**, ne Globem kandidátních složek ani podle názvu
souboru:

1. Otevři `CLAUDE.md` a přejdi na vstupní index, na který odkazuje.
2. Podle vět u odkazů vyber sekci, do které téma dokumentu patří, a otevři její
   `index.md`.
3. Opakuj, dokud nenarazíš na index, jehož žádná podsekce téma nepokrývá přesněji.
   Dokument patří do složky tohohle indexu.
4. Nepokrývá-li téma žádná existující sekce, založ novou: složku s `index.md`, který
   jednou dvěma větami řekne, co sekce pokrývá, uvnitř té sekce, pod kterou téma
   věcně spadá.

Najdeš-li při sestupu stránku, která téma už pokrývá, **rozšiř ji** místo zakládání
druhé — dvě stránky o témže se rozejdou.

Stejným sestupem se **hledá existující dokument** (ADR citovaný v `Reference`, art
bible, UX spec): věta u odkazu řekne, který dokument platí a co v něm je, i když se
nejmenuje tak, jak by Glob čekal.

---

## Jak dokument odkázat

Ve stejné změně, ve které dokument vzniká:

- **Stránka** dostane řádek v indexu své složky:

  ```markdown
  - [Název stránky](nazev-stranky.md) — jedna věta o tom, co na stránce je.
  ```

- **Nová sekce** dostane řádek v indexu nadřazené složky, odkazující na svůj
  `index.md`:

  ```markdown
  - [Název sekce](nazev-sekce/index.md) — jedna věta o tom, co sekce pokrývá.
  ```

- **Související stránky** odkazuj relativně, a míříš-li na konkrétní místo, s kotvou.

Věta u odkazu není popisek souboru, ale rozhodnutí pro čtenáře, jestli tam má
sestoupit: říká, co tam najde, ne jak se soubor jmenuje.

---

## Projekt bez báze

Neodkazuje-li `CLAUDE.md` na vstupní index — nebo index, na který odkazuje,
neexistuje —, projekt bázi nemá. **Mezeru ohlas a strukturu nedomýšlej**: nezakládej
`.docs/` ani index mimochodem, nevybírej složku podle toho, co v repozitáři vypadá jako
dokumentace, a dokument nepřidávej mimo strom. Ohlášení řekne, co chybí (odkaz
v `CLAUDE.md`, vstupní index) a že založení báze je samostatný krok, ne součást
práce, kterou právě děláš — bázi zakládá `/sagittaras:write-docs`.

Báze založená jako vedlejší produkt jiného dokumentu nese strukturu, kterou nikdo
neposoudil, a další skill ji bude rozvíjet jako závaznou.
