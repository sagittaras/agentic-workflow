# Conventional Commits

> **Rozsah:** Referenční soubor skillu `make-commit`. Obecný formát commit zpráv
> podle [Conventional Commits](https://www.conventionalcommits.org/), nezávislý
> na konkrétním repozitáři. Konvence platí pro nově vznikající commity; existující
> historii nepřepisuj.

Cílem je strojově čitelná historie — jde z ní generovat changelog a na první
pohled rozeznat povahu změny.

## Struktura zprávy

```
<type>[(scope)][!]: <popis>

[tělo — proč, ne co; zalamuj kolem 72 znaků]

[footery — BREAKING CHANGE: <dopad>, Refs: #123, Co-Authored-By: …]
```

Hlavička je povinná, tělo i footery volitelné. Mezi hlavičkou, tělem a footery
je vždy prázdný řádek.

## Type

| Type | Kdy |
| --- | --- |
| `feat` | Nová schopnost pro uživatele |
| `fix` | Oprava chybného chování |
| `docs` | Dokumentace bez dopadu na chování |
| `refactor` | Přeskupení bez změny chování ani rozhraní |
| `test` | Testy a jejich podpůrné soubory |
| `chore` | Údržba, závislosti, konfigurace repozitáře |
| `ci` | Pipeline a automatizace |
| `build` | Build, balení, distribuce |
| `perf` | Změna cílená na výkon |
| `style` | Formátování bez dopadu na význam |

Rozhoduje **povaha změny, ne typ souboru**. Tentýž soubor může nést `feat`,
`fix` i `docs` podle toho, co se v něm změnilo — dokumentace, která mění, jak
se systém chová, není `docs`; a soubor s kódem, kde se přepsal jen komentář, není
`feat`.

## Scope

Oblast, které se změna týká — komponenta, modul, balíček nebo funkční celek.

**Nejdřív se podívej, jaké scopy repozitář už používá** (`git log --oneline -30`),
a drž se zavedeného slovníku. Nový scope zaváděj jen pro oblast, která zatím
žádný nemá; nekonzistentní scopy jsou horší než žádné, protože se podle nich
nedá filtrovat.

U průřezové změny scope vynech — zástupný scope typu `misc` nebo `general`
nenese informaci.

## Popis

- Anglicky, malým počátečním písmenem, **rozkazovací způsob** („add", ne
  „added" ani „adds"), bez tečky na konci.
- Do ~72 znaků. Nevejde-li se smysl, patří zbytek do těla — ne do delší hlavičky.
- Popisuj výsledek, ne postup: `add retry to upload handler`, ne
  `edited handler and added a loop`.

## Tělo

Přidej, když **proč** není z popisu zřejmé. Vysvětluj důvod a dopad, ne výčet
změněných řádků — ten je v diffu. Zalamuj kolem 72 znaků.

## Breaking change

Obojí naráz, jinak to nástroje nezachytí:

1. `!` za type nebo scope,
2. footer `BREAKING CHANGE:` s popisem dopadu.

## Attribution

Vzniká-li commit prací agenta, přidej footer `Co-Authored-By:`. **Přesnou podobu
řádku určuje prostředí** — nevymýšlej ji, převezmi ji z instrukcí prostředí.
Jednotný footer drží historii čitelnou pro zpětnou analýzu.

## Předávání zprávy gitu

Víceřádkovou zprávu předávej vždy stdinem přes heredoc **s ukončovačem
v uvozovkách**:

```bash
git commit -F - <<'MSG'
fix(parser): handle empty input without crashing

Prázdný vstup dřív spadl na indexaci prvního tokenu. Vrací se
prázdný výsledek, protože volající s ním počítá.

Co-Authored-By: …
MSG
```

Uvozovky kolem `'MSG'` zabrání expanzi `$` a zpětných apostrofů v obsahu —
bez nich by shell část zprávy vyhodnotil a do historie by dorazilo něco jiného,
než jsi napsal. U jednořádkové zprávy stačí `git commit -m "…"`.

## Příklady

```
feat(auth): add password reset flow
fix(api): reject requests with empty payload
docs(readme): document required environment variables
chore(deps): bump lockfile after security advisory
refactor(storage)!: replace in-memory cache with redis

BREAKING CHANGE: REDIS_URL is now required; the process exits on
startup without it.
```
