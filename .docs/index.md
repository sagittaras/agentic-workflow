# sagittaras — dokumentace

Znalostní báze vývoje pluginu pro vývojáře i agenty: proč skilly vypadají, jak
vypadají, a podle jakých principů se mění. Navigace začíná tady a vede stromem
indexů: každá sekce je složka s vlastním `index.md`, který popisuje, co sekce
pokrývá, a odkazuje na její stránky a podsekce.

Konvence, které skilly čtou za běhu v cizích projektech, tu nejsou — leží
u skillů, které je vynucují (`skills/write-skill/skill-conventions.md`
a obdobné), a ve sdíleném kontraktu `shared/`. Tahle báze vysvětluje, proč
vypadají tak, jak vypadají.

## Pravidla struktury

- Sekce = složka s `index.md`. Podsekce se zakládají stejně, do libovolné hloubky.
- Každý index odkazuje na všechny své přímé stránky a podsekce. Stránka, na kterou
  žádný index neodkazuje, není dohledatelná.
- Novou stránku nebo sekci vždy odkaž z nadřazeného indexu ve stejné změně, ve
  které vzniká.
- Stránky na sebe odkazují relativními markdown odkazy, na konkrétní místo
  s kotvou.

Proč je báze postavená takhle, říkají principy
[1.7](vision/principles.md#17-dokumentace-se-dohledává-stromem-indexů-od-claudemd-ne-registrem-cest)
a [1.8](vision/principles.md#18-znalostní-báze-docs-je-graf-stránek-a-plugin-ji-zakládá-a-udržuje-vlastními-skilly)
— plugin je předepisuje cílovým projektům a drží se jich i sám.

## Sekce

- [Vize spolupráce člověka s AI](vision/index.md) — principy, podle kterých se
  plugin přestavuje po ostrém provozu: kód jako kotva, issues ukotvené
  v precedentu, AI implementuje a člověk přezkoumává, issues v subagentech
  a nový precedent v párové session, navigace dokumentací, štíhlé skilly
  s příkazy místo popisu; a mapa dopadu na skilly.
- [Milestone workflow](milestone-workflow/index.md) — původní plán sady skillů
  pro milestone: životní cyklus, kontrakt v trackeru, forge vrstva, skripty
  a konfigurace jednotlivých skillů. Části kontraktu nahrazuje vize; co přesně,
  říká hlavička plánu.
