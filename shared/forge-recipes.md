# Recepty pro forge

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Pro každou operaci nad trackerem
> jeden řádek s konkrétním voláním — zvlášť pro Gitea a zvlášť pro GitHub. Otevři ho
> pokaždé, než sáhneš na issue, milestone, label nebo PR, a **volání neodvozuj z hlavy**.
> Kterou větev použít, říká sekce `Forge` v projektové konfiguraci
> ([workflow-config.md](workflow-config.md)).

Asymetrie mezi sloupci je vědomá: MCP nástroj nejde zavolat ze shellu, takže Gitea stranu
nelze schovat do skriptu tak jako GitHub. Náhradou je tahle tabulka — plní tutéž roli jako
skript, jen ji vykonává model místo bashe.

---

## Načtení nástrojů (jen Gitea)

Nástroje `mcp__gitea__*` jsou odložené. Načti je **jedním** voláním `ToolSearch` podle
toho, co skill dělá — ne po jednom, každé volání je kolo navíc:

| Role skillu | `ToolSearch` query |
| --- | --- |
| Zakládá issues a milestony | `select:mcp__gitea__issue_write,mcp__gitea__issue_read,mcp__gitea__list_issues,mcp__gitea__milestone_write,mcp__gitea__milestone_read,mcp__gitea__label_read,mcp__gitea__label_write` |
| Jen čte a komentuje | `select:mcp__gitea__issue_read,mcp__gitea__issue_write,mcp__gitea__list_issues,mcp__gitea__milestone_read` |
| Sahá jen na labely | `select:mcp__gitea__label_read,mcp__gitea__label_write` |
| Pracuje s PR | `select:mcp__gitea__pull_request_read,mcp__gitea__pull_request_write,mcp__gitea__list_pull_requests,mcp__gitea__pull_request_review_write` |
| Orchestruje celý milestone | `select:mcp__gitea__milestone_read,mcp__gitea__issue_read,mcp__gitea__issue_write,mcp__gitea__list_issues,mcp__gitea__pull_request_read,mcp__gitea__pull_request_write,mcp__gitea__list_pull_requests` |

Každé volání Gitea MCP potřebuje `owner` a `repo` ze sekce `Forge` konfigurace.

---

## Tabulka operací

`gh` skripty leží v `${CLAUDE_PLUGIN_ROOT}/scripts/gh/`, jejich kontrakt popisuje
[git-scripts.md](git-scripts.md).

**Tabulka uvádí jen jméno skriptu a jeho vlastní argumenty.** Ke každému volání vždy
připoj celou cestu a `-R <owner>/<repo>` ze sekce `Forge` konfigurace — bez cesty skončí
volání kódem `127`, bez `-R` se skript řídí aktuálním adresářem, což v izolovaném worktree
neplatí. Tedy:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/gh/issue-read.sh -R owner/repo 42
```

| Operace | Gitea (MCP) | GitHub (skript) |
| --- | --- | --- |
| Přečti issue | `issue_read` → `get`, `issue_number` | `gh/issue-read.sh <n>` |
| Přečti komentáře issue | `issue_read` → **`get_comments`**, `issue_number` | `gh/issue-read.sh <n>` → pole `comments` |
| Vypiš issues milestonu | `list_issues`, `milestones: ["<id>"]`, `type: "issues"` | `gh/issue-list.sh --milestone <m> --state all` |
| Vypiš issues napříč repozitářem | `list_issues`, `type: "issues"`, `state`, případně `labels: ["<název>"]` | `gh/issue-list.sh --state all` |
| Založ issue | `issue_write` → `create`, `title`, `body`, `milestone`, `labels` | `gh/issue-create.sh --title T --body-file F --milestone M --label L` |
| Uprav tělo issue | `issue_write` → `update`, `issue_number`, `body` | `gh/issue-update.sh <n> --body-file F` |
| Zavři issue | `issue_write` → `update`, `issue_number`, `state: "closed"` | `gh/issue-update.sh <n> --state closed` |
| Okomentuj issue | `issue_write` → `add_comment`, `issue_number`, `body` | `gh/issue-comment.sh <n> --body-file F` |
| Vypiš milestony | `milestone_read` → `list`, `state` | `gh/milestone-list.sh --state open` |
| Založ milestone | `milestone_write` → `create`, `title`, `description` | `gh/milestone-create.sh --title T --description D` |
| Zavři milestone | `milestone_write` → `update`, `id`, `state: "closed"` | `gh/milestone-update.sh <n> --state closed` |
| Vypiš labely | `label_read` → `list_repo_labels` | `gh/label-list.sh` |
| Založ label | `label_write` → `create_repo_label`, `name`, `color` | `gh/label-create.sh --name N --color C` |
| Založ PR | `pull_request_write` → `create`, `base`, `head`, `title`, `body` | `gh/pr-create.sh --base B --head H --title T --body-file F` |
| Přečti PR | `pull_request_read` → `get`, `pull_number` | `gh/pr-read.sh <n>` |
| Najdi PR podle head větve | `list_pull_requests`, `state: "open"` → porovnej `head` v odpovědi | `gh/pr-list.sh --state all` → porovnej `headRefName` |
| Najdi PR patřící k issue | `list_pull_requests`, `state: "all"` → porovnej `head` a `Closes #N` v těle | `gh/issue-read.sh <n>` → `closedByPullRequestsReferences` |
| Vypiš PR milestonu | `list_pull_requests`, `milestone: <id>`, `state: "all"` | `gh/pr-list.sh --milestone <m> --state all` |
| Přiřaď PR milestone | `pull_request_write` → `update`, `pull_number`, `milestone` | `gh/pr-set-milestone.sh <n> --milestone M` |
| Komentář k PR (review) | `pull_request_review_write` → `create`, `pull_number`, `state: "COMMENT"`, `body` | `gh/pr-comment.sh <n> --body-file F` |
| Mergni PR | `pull_request_write` → `merge`, `pull_number`, `merge_style: "squash"`, `delete_branch` | `gh/pr-merge.sh <n> --squash --delete-branch` |

---

## Nástrahy, na které se naráží opakovaně

- **`labels` u `issue_write` jsou číselná ID, ne názvy.** Napřed `label_read` →
  `list_repo_labels`, z něj si vytáhni ID. Předané názvy volání tiše nepřipnou nic.
  Naproti tomu `list_issues` filtruje `labels` podle **názvů** — dvě různé konvence
  v jednom API.
- **`list_issues` bere `milestones` jako pole řetězců**, ale `list_pull_requests` bere
  `milestone` jako jedno číslo. Neplést.
- **Tvar hodnoty `milestone` se liší podle forge.** Gitea chce číselné ID, `gh` bere název
  i číslo. Nepředávej hodnotu, kterou ti dal uživatel, rovnou — napřed si milestone
  dohledej ve výpisu a použij, co daná strana čeká.
- **`list_issues` vrací i PR, dokud neomezíš `type: "issues"`.** Bez toho vyjde počet
  issues vyšší, než ve skutečnosti je, a kontrola „všechno zavřené" projde omylem.
- **Stránkuje se po 30.** Než uvěříš, že jsi viděl všechny issues milestonu, porovnej
  počet s `open_issues` + `closed_issues` z `milestone_read`. Při rozporu radši ohlas
  než rozhodni.
- **Komentář se přidává metodou `add_comment`, ne `comment`.**
- **Milestone při zakládání PR nastavit nelze** — ani na Gitea, ani na GitHubu. Je to
  povinné druhé volání hned po `create`, ne kosmetika: `close-milestone` podle téhle
  vazby integrační PR dohledává.
- **Gitea milestone neumí komentáře.** Trvalý záznam o review milestonu proto patří jako
  komentář na issue s nejnižším číslem v daném milestonu.
- **404 na zápisu, i když objekt zjevně existuje**, je skoro vždy chybějící oprávnění
  účtu, pod kterým MCP běží — ne špatný název. Ověř `get_me`, řekni to uživateli a nech
  ho přidat přístup; nehádej jiný repozitář.
- **Tělo se předává souborem (`--body-file`), ne argumentem.** Víceřádkový markdown
  s uvozovkami a zpětnými apostrofy se v shellu jinak rozpadne.
