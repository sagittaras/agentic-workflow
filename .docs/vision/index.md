# Vize: jak má člověk pracovat s AI okolo tohoto pluginu

> **Stav:** rozepsáno, píše se průběžně po principech — od 24. 8. 2026;
> 16. 11. 2026 přibyly principy 1.7 a 1.8, vize se rozdělila na stránky a principy
> 2.6–2.9 posunuly cíl od úplné autonomie ke kompromisu (viz níž).
> **Kontext:** po týdnu ostrého provozu řetězu `write-adr → plan-milestone →
> review-milestone → run-milestone` (popsaného v [původním plánu
> sady](../milestone-workflow/index.md)) se ukázalo, že nad delším autonomním
> horizontem výsledek ujíždí od ADR a issues, zatímco ruční práce s kódovou
> kostrou jako kotvou byla rychlejší i přesnější. Vize se ptá od zelené louky,
> jak by měl optimální cyklus člověk↔AI okolo pluginu vypadat — původní plán
> zůstává jako záznam toho, co bylo postaveno a proč (sdílený kontrakt, skripty,
> forge vrstva zůstávají v platnosti bez ohledu na výsledek téhle úvahy).

**Posun cíle (16. 11. 2026).** Plugin vznikal jako cesta k úplné autonomizaci
práce v Claude Code. Provoz ukázal, že nejdražší část průchodu issue není
implementace, ale agentní review — a že se jeho důslednost nedá spolehlivě
nadirigovat promptem. Vize proto míří ke kompromisu: konkrétní práci vykoná AI,
výsledný kód přezkoumává člověk, a orchestrátor spouští issues v podřazených
session, ke kterým člověk píše připomínky podle jejich PR
([2.6](issues.md#26-review-výsledného-kódu-dělá-člověk-ne-agent)–[2.8](issues.md#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech)).
Než PR člověk uvidí, musí mít každé kritérium test a orchestrátor potvrdit,
že testy prochází
([2.9](issues.md#29-každé-akceptační-kritérium-kryje-test-session-ho-napíše-orchestrátor-potvrdí)).

Principy jsou číslované napříč stránkami. Číslo je stabilní identifikátor —
odkazují se na něj stránky mezi sebou i komentáře ve skillech (`run-milestone`:
„princip 2.4"), takže se při přesunu nebo rozdělení stránky nepřečíslovává. Nový
princip dostane další volné číslo ve své skupině a řádek v přehledu níž.
Nahrazený princip se nemaže ani nepřečíslovává — dostane hlavičku „Nahrazeno"
s odkazem na nástupce a zůstává jako záznam, proč se směr změnil.

## Principy

**[Principy spolupráce](principles.md)** — kde vzniká kotva, podle které agent
pracuje, a co zbývá dokumentům:

- [1.1](principles.md#11-kostru-projektu-staví-člověk-ne-agent) Kostru projektu
  staví člověk, ne agent.
- [1.2](principles.md#12-kostra-je-zdroj-pravdy--ne-dokument-vedle-ní) Kostra je
  zdroj pravdy — ne dokument vedle ní.
- [1.3](principles.md#13-první-klíčová-funkcionalita-vzniká-v-páru-ne-autonomně)
  První klíčová funkcionalita vzniká v páru, ne autonomně.
- [1.4](principles.md#14-write-rule-běží-po-každém-založení-precedentu--obecně-ne-principem-po-principu)
  `write-rule` běží po každém založení precedentu.
- [1.5](principles.md#15-adr-zaznamenává-proč-ne-jak--a-jen-tam-kde-hrozí-oprava-bez-kontextu)
  ADR zaznamenává proč, ne jak — a jen tam, kde hrozí „oprava" bez kontextu.
- [1.6](principles.md#16-agent-se-zakládá-pro-opakovaně-dispečovanou-roli-train-agent-kryje-mezeru-po-review-ne-rutinu)
  Agent se zakládá pro opakovaně dispečovanou roli; `train-agent` kryje mezeru
  po review.
- [1.7](principles.md#17-dokumentace-se-dohledává-stromem-indexů-od-claudemd-ne-registrem-cest)
  Dokumentace se dohledává stromem indexů od `CLAUDE.md`, ne registrem cest.
- [1.8](principles.md#18-znalostní-báze-docs-je-graf-stránek-a-plugin-ji-zakládá-a-udržuje-vlastními-skilly)
  Znalostní báze `.docs/` je graf stránek a plugin ji zakládá a udržuje
  vlastními skilly.

**[Issues a autonomní vývoj](issues.md)** — co issue nese a jak se po něm
autonomně staví:

- [2.1](issues.md#21-co-issue-stanovuje) Issue stanovuje ohraničený přírůstek
  ukotvený v kódu.
- [2.2](issues.md#22-dvě-roviny-poznámka-a-zadání) Dvě roviny: Poznámka
  a Zadání.
- [2.3](issues.md#23-povýšení-poznámky-na-zadání-je-samostatný-krok) Povýšení
  Poznámky na Zadání je samostatný krok.
- [2.4](issues.md#24-plánování-je-vlnové-gatované-dostupností-vzoru--ne-jednorázová-dávka)
  Plánování je vlnové, gatované dostupností vzoru.
- [2.5](issues.md#25-review-zadání-dvě-úzké-role-žádná-nesmí-přesáhnout-svůj-mandát)
  ~~Review Zadání: dvě úzké role, žádná nesmí přesáhnout svůj mandát.~~
  Nahrazeno 2.6 a 2.8; mandát role A platí pro ručně spuštěný `verify-issue`.
- [2.6](issues.md#26-review-výsledného-kódu-dělá-člověk-ne-agent) Review
  výsledného kódu dělá člověk, ne agent.
- [2.7](issues.md#27-issue-je-velké-nanejvýš-tak-aby-jeho-pr-šlo-přezkoumat-ručně)
  Issue je velké nanejvýš tak, aby jeho PR šlo přezkoumat ručně.
- [2.8](issues.md#28-orchestrátor-spouští-issues-v-podřazených-session-ne-v-subagentech)
  Orchestrátor spouští issues v podřazených session, ne v subagentech.
- [2.9](issues.md#29-každé-akceptační-kritérium-kryje-test-session-ho-napíše-orchestrátor-potvrdí)
  Každé akceptační kritérium kryje test; session ho napíše, orchestrátor
  potvrdí.

## Stránky

- [Principy spolupráce](principles.md) — 1.1–1.8: kostra, vzorová implementace,
  rules, ADR, agenti, navigace dokumentací a znalostní báze `.docs/` s vlastními
  skilly.
- [Issues a autonomní vývoj](issues.md) — 2.1–2.9: tvar issue, Poznámka
  a Zadání, vlnové plánování, lidské review místo agentního, velikost issue
  podle přezkoumatelnosti PR, orchestrace přes podřazené session, testy ke
  kritériím potvrzené orchestrátorem.
- [Dopad na existující skilly](skill-impact.md) — který skill se kterým
  principem mění a jak; samostatná tabulka pro 1.7 a výčet skillů, kterých se
  vize netýká.
