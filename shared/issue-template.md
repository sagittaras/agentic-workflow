# Šablona issue

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Závazný tvar názvu a těla issue pro
> celý milestone workflow. Otevři ho vždy, když issue **zakládáš** (`plan-milestone`,
> `file-issue`), **posuzuješ** (`review-milestone`), **implementuješ** (`implement-issue`)
> nebo **ověřuješ** (`verify-issue`).

Tvar není kosmetika — tři místa v těle se čtou strojově a při odchylce se řetěz rozpadne:
sekce `Závisí na` je zdroj grafu závislostí pro `run-milestone`, zaškrtávátka
v `Akceptační kritéria` přepisuje `verify-issue`, a sekce `Reference` je jediné, podle
čeho `implement-issue` pozná, které dokumenty si má otevřít.

---

## Název

```
<type>(<scope>): <popis v rozkazovacím způsobu, malé písmeno na začátku>
```

- `<type>` je typ podle Conventional Commits a **musí se shodovat s typovým labelem**,
  který je na issue nasazený. Rozpor mezi názvem a labelem je nález pro `review-milestone`.
- `<scope>` je oblast v kódu, ne téma milestonu.
- Jazyk popisu určuje sekce `Jazyk issues` v projektové konfiguraci.

---

## Tělo

````markdown
## Souhrn

[Jedna až dvě věty: co tenhle issue dodá. Ne jak, to patří do kritérií.]

## Akceptační kritéria

- [ ] [Pozorovatelné chování — co vrátí požadavek, co dokáže test, co vypíše příkaz.]
- [ ] [Další kritérium, každé ukotvené v konkrétní sekci dokumentu ze sekce Reference.]

## Reference

- [Cesta k dokumentu § konkrétní sekce — kde je kritérium ukotvené.]

## Závisí na

- #N — [krátce čím blokuje]
````

**Sekci `Závisí na` vynech celou**, když issue na ničem nezávisí. Prázdná sekce
s pomlčkou nebo „nic" je horší než žádná: parser `run-milestone` řeší jen dva stavy —
sekce je, nebo není.

---

## Jak psát akceptační kritéria

Tohle je nejdůležitější část celé šablony a nejčastější místo selhání.

**Kritérium popisuje pozorovatelné chování, ne mechanismus.** Špatně: „porovnávání
nezávislé na velikosti písmen je vlastnost typu sloupce, ne kódu v tomhle repozitáři."
Takové kritérium implicitně odrazuje od testu právě toho kódu, který tu vlastnost může
zrušit. Správně: „registrace `zechy` při existujícím `Zechy` ohlásí konflikt."
Mechanismus patří do `Reference`; kritérium říká, co musí platit.

**Každé kritérium je ukotvené.** Když neumíš ukázat, ze které sekce kterého dokumentu
kritérium plyne, nepatří do issue — patří do readiness checku jako mezera v dokumentaci.
Věrohodně znějící parafráze bez opory je nález pro `review-milestone`.

**Kritérium má být ověřitelné bez doptávání.** Kritérium, které jde přečíst dvěma způsoby,
zdrží celý řetěz až u `verify-issue`, kde už stojí čas inženýra i recenzenta.

**Zaškrtávátka zakládej prázdná.** Odškrtává je až `verify-issue` podle toho, co skutečně
ověřil — ne autor a ne implementující agent.
