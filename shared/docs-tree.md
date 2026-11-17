# Strom dokumentace

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Pravidla struktury znalostní
> báze cílového projektu — stromu indexů, který začíná odkazem z `CLAUDE.md` — a postupy,
> jak v něm najít místo pro nový dokument, jak ho odkázat a jak v něm najít odpověď.
> Otevři ho vždy, když dokument v bázi **zakládáš nebo rozšiřuješ** (`write-docs`,
> `write-adr`, `write-art-bible`, `write-ux-spec`), když **posuzuješ** její strukturu
> nebo dohledatelnost dokumentu (`review-docs`, `review-adr`, `review-ux-spec`), a když
> v ní dokument nebo odpověď **hledáš** (`read-docs`, `verify-issue`,
> `review-milestone` a `implement-issue` v náhradním postupu) — doplňkový dokument
> citovaný v `Reference` i zázemí, o které se opírá zápis nebo review.

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

Existující dokument (ADR citovaný v `Reference`, art bible, UX spec) se hledá
postupem z § Jak najít odpověď v bázi.

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

## Jak najít odpověď v bázi

Odpověď na otázku i konkrétní dokument hledej **sestupem po větách u odkazů**. Bázi
neprohledávej Grepem, Globem ani `grep` v shellu — ani když sestup nic nenajde: řetězec
ani název souboru neřekne, co na stránce je a který dokument platí, věta v indexu ano.

1. Z adresáře projektu spusť `bash <kořen pluginu>/scripts/docs-map.sh` (ve skillu
   spuštěném loaderem je kořen pluginu `${CLAUDE_PLUGIN_ROOT}`). Vypíše řádek
   `root=<kořen repozitáře>` a pod ním strom indexů od vstupního indexu jako
   vnořený seznam: u každé stránky a sekce cestu vůči kořeni a větu z indexu.
   Indexy po jednom neotevírej, mapa je nese všechny. Kód 1 znamená, že projekt
   bázi nemá — platí § Projekt bez báze. Nemáš-li Bash, otevři vstupní index,
   na který odkazuje `CLAUDE.md`, a sestupuj po indexech podle vět.
2. V mapě vyber stránky, jejichž věta pokrývá téma tvé otázky — kryjí-li ho dvě,
   otevři obě. Stránku, jejíž věta téma nepokrývá, neotevírej, ani pro jistotu.
3. Čtení končí u stránky, která odpověď nese. Sousední stránky pro úplnost nečti.
   Míří-li odkaz na kotvu, odpověď je v té sekci.
4. Ze stránky jdi po odkazu dál, jen když stránka odpověď odkazem odkládá jinam
   („podrobnosti viz…"), nebo když odkaz míří na omezení či chráněné rozhodnutí
   v oblasti, kterou se chystáš měnit. Odkaz na související téma nesleduj.
5. Nenajdeš-li stránku, která odpověď nese, báze ji nemá. Vyčti ji z kódu,
   jde-li to, a mezeru uveď ve výstupu. Stránku mimochodem nezakládej — bázi rozšiřuje
   `/sagittaras:write-docs`.

**Rozpor stránky s kódem nerozhoduj přepisem jedné strany podle druhé.** Popisuje-li
stránka, *jak* kód funguje, platí kód a stránku uveď ve výstupu jako zastaralou.
Nese-li chráněné rozhodnutí — *proč* je konstrukce taková, jaká je —, rozpor uveď
a kód proti rozhodnutí neměň.

**Z čeho vycházíš, cituj relativní cestou s kotvou**, aby si to čtenář výstupu ověřil
bez nového sestupu.

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
