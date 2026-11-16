## Workflow (sagittaras)

> Tuhle sekci spravuje `/sagittaras:init-workflow` a čtou ji ostatní skilly milestone
> workflow. Nadpisy nech beze změny; obsah pod nimi uprav, kdy chceš.

### Forge

- typ: github
- host: github.com
- repozitář: sagittaras/agentic-workflow

### Větvení

- výchozí větev: main
- issue větev: <type>/<popis>
- integrační větev: milestone/<slug>
- merge strategie: squash
- merge do výchozí větve: jen člověk, ledaže prompt, kterým byl aktuální běh
  spuštěn, obsahoval výslovný souhlas k mergi — pak smí mergnout `open-pr`

### Labely

- typové: feat, fix, chore, docs, refactor, test
- oblasti: area:skills

### Ověřovací příkazy

| oblast | příkaz |
| --- | --- |
| area:skills | `bash scripts/lint-skills.sh` |

### Jazyk issues

- čeština
