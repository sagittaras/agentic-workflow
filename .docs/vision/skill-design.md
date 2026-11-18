# Tvar skillů

Principy 3.x: jak má vypadat skill sám — co do něj patří, co ne, a jak velký
smí být. Na rozdíl od [principů spolupráce](principles.md) a [issues](issues.md)
se netýkají cyklu člověk↔AI, ale textu, který agent čte při každém spuštění
skillu. Promítají se do konvencí `write-skill` a do kritérií `review-skill`
(viz [mapa dopadu](skill-impact.md#princip-31)).

## 3.1 Skill je základní linie postupu, ne podnět k úvaze; co jde příkazem, je příkaz

Skill existuje proto, aby se agentovi nemusela tatáž činnost vysvětlovat znovu.
Nese základní linii: jaký je postup, jak se chovat v místech, kde se rozhoduje,
a co určitě nedělat. Nic víc. Krok, který jde nahradit příkazem, je ve skillu
zapsaný jako příkaz, který má agent spustit — ne jako popis, ze kterého by si
příkaz musel poskládat. A žádná věta skillu nemá agenta vést k přemýšlení nad
souvislostmi, které jeho úloha nepotřebuje.

**Why:**
- **Každá věta se platí při každém běhu.** Tělo skillu se při spuštění načte do
  kontextu a zůstane v něm po zbytek session. Platí se tokeny — a pozorností:
  agent každou větu převáží, jestli se ho v tomhle běhu týká. Skilly pluginu
  mají dohromady přes osm tisíc řádků, nejdelší (`run-milestone`) skoro sedm
  set.
- **Instrukce spouští úvahu.** Tohle se dosud nezvažovalo. Skill, který vyjmenuje
  možnosti, popíše vzácný hraniční případ nebo vyzve „zvaž, jestli…", agenta
  k té úvaze dovede i tam, kde ji úloha nepotřebuje — hledá hraniční případ,
  který nenastal, a domýšlí souvislosti, o které nikdo nežádal. Je to stejná
  diagnóza jako u agentního review v [2.6](issues.md#26-review-výsledného-kódu-dělá-člověk-ne-agent):
  důslednost nejde nadávkovat promptem — a část té nadměrné důslednosti
  zakládá text skillu sám.
- **Příkaz je nejlevnější a deterministický.** I obyčejné `git commit` stojí
  tokeny, než agent vymyslí přepínače, uvozování zprávy, co stagnout a jak
  ošetřit odpojenou HEAD. Skript to má vyřešené jednou: vezme argumenty, ošetří
  hraniční stavy a vrátí krátký strojově čitelný výstup (`key=value`), podle
  kterého agent jen vybere větev. Osvědčilo se to na skriptech `make-commit`,
  `create-branch`, forge vrstvy i integrační brány.
- **Co skill rozhodne, agent nemusí.** Skill složený z příkazů a jednoznačných
  rozhodnutí může běžet na levnější dvojici model × effort — úspora se tak
  sčítá: méně textu, méně úvahy a levnější model.

**Co do skillu patří — test každé věty.** Věta ve skillu musí splnit aspoň
jedno:
- jmenuje příkaz, který má agent spustit, nebo mapuje jeho výstup (návratový
  kód, `key=value`) na další krok;
- rozhoduje něco, co by agent jinak musel rozhodnout sám, nebo dává
  jednoznačné kritérium, podle kterého to rozhodne;
- brání chybě, která se v provozu opravdu stala — ne hypotetické;
- určuje tvar výstupu, který čte někdo další (jiný skill, člověk, tracker).

Co neprojde, se škrtá, nebo stěhuje tam, kde to agent za běhu nečte. Stejně
jako u PR ([2.7](issues.md#27-issue-je-velké-nanejvýš-tak-aby-jeho-pr-šlo-přezkoumat-ručně))
tu není číselný limit řádků — rozhoduje test, ne počet.

**Typické spouštěče úvahy a čím je nahradit:**

| Spouštěč | Náhrada |
| --- | --- |
| Krok popsaný prózou, který jde provést příkazem | Skript; skill jen jmenuje příkaz a mapuje výstup |
| Výčet možností bez rozhodnutí („může jít o A, B, nebo C") | Rozhodnutí, nebo jednoznačné kritérium výběru |
| Vzácný hraniční případ rozepsaný v těle | Ošetření ve skriptu (návratový kód), nebo reference otevíraná jen v té větvi |
| Výzva k úvaze bez kritéria, kdy přestat („zvaž", „promysli", „pro jistotu ověř") | Konkrétní signál, kdy kontrolovat — nebo kontrola ve skriptu |
| Dlouhé zdůvodnění u deterministického kroku | Jen příkaz; zdůvodnění do komentáře nebo do `.docs/` |
| Zákaz chování, které se nikdy nestalo | Škrt — zákaz se zakládá až na pozorovanou chybu |
| Zásady, které opakují postup jinými slovy | Škrt — postup říká postup |

**Zdůvodnění pro vývojáře žije mimo tělo.** Proč je skill postavený zrovna
takhle (zařazení v matici, odchylky od konvencí, historie rozhodnutí), patří do
komentářů ve frontmatteru, které se při spuštění skillu do kontextu nenačítají,
a obecnější úvahy do `.docs/` ([1.8](principles.md#18-znalostní-báze-docs-je-graf-stránek-a-plugin-ji-zakládá-a-udržuje-vlastními-skilly)).
Tělo nese jen to, co potřebuje běh.

**Co se mění proti dnešním konvencím:** pravidlo „u instrukcí, které nejsou
samozřejmé, připoj důvod" zůstává, ale zužuje se. Důvod patří k místu, kde agent
dělá úsudek, který skill udělat nemůže — tam pomáhá rozhodnout správně, a stačí
na něj jedna věta. U kroku, který nahrazuje příkaz, důvod nepatří nikam do
těla: příkaz se nespouští spolehlivěji proto, že agent ví proč.

**Platí i pro agenty a rules.** Definice agenta se čte při každém vyvolání
a rule při každém dotyku cesty, kterou pokrývá — tedy ještě častěji než skill.
Test každé věty a tabulka spouštěčů platí pro ně stejně.

**Důsledek pro workflow:** princip se nepromítá jednorázovým přepisem všech
skillů. Napřed se změní `write-skill` a `review-skill`, aby podle něj vznikalo
všechno nové, a stávající skilly se podle něj zeštíhlí, když se na ně sahá
z jiného důvodu — přepisy podle 1.7, 1.8 a 2.6–2.9 zasáhnou většinu
milestonového řetězu, včetně nejdelších `run-milestone` a `verify-issue`.

### Změřeno v provozu

Rozbor transkriptů prvního ostrého běhu `run-milestone` (milestone o 17 issues,
17. 11. 2026, Opus 5.5) dal principu čísla. Běh stál v cenách API asi $133: čtení
cache 55 %, zápis cache 25 %, výstup 20 %. Cena každého volání roste s kontextem,
a každá session začínala na ~86k tokenech ještě před první akcí — rozhoduje tedy
počet volání × velikost kontextu. Text skillů pluginu v implementační session
(~30k tokenů, čeština vychází na ~2,1 znaku na token) stál asi 7 % běhu; výstup
modelu i s opakovaným čtením asi 31 %; výstupy buildů a testů jen ~1,5 %. Odsud
plyne pořadí pák: méně volání (paralelní čtení, skript místo řetězu příkazů),
kratší text načítaný na začátku session, rozhodnutí v plánu místo v kontextu
implementace. Měření opravňuje výjimku z pravidla „zeštíhlit až při dotyku":
skilly, které se načítají do každé implementační session (`implement-issue`,
`open-pr`, `make-commit`, `create-branch`), se zeštíhlily cíleně.
