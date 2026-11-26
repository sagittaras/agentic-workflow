#!/usr/bin/env bash
# Test scripts/agent-model.sh — běží offline nad dočasným repozitářem
# s vlastním HOME, aby ho neovlivnili agenti nainstalovaní na stroji.
#
# Kritérium 1: agenta najde podle `name:` ve frontmatteru i v podsložce
#              a se jménem souboru, které se s `name` neshoduje; model a effort
#              bere jen z frontmatteru, ne z těla (i s konci řádků CRLF).
# Kritérium 2: `model: inherit` vypíše jako prázdný model.
# Kritérium 3: neznámé jméno → found=false a kód 0; bez jména kód 2.
# Kritérium 4: agent v ~/.claude/agents se najde, projektový má přednost.
# Kritérium 5: tools= spojí výčet na jednom řádku i YAML seznam; bez výčtu je
#              prázdné. can_run_skills=false, jen když výčet existuje a chybí
#              v něm Skill nebo Bash (i ve tvaru Bash(…)).
# Kritérium 6: isolation= vypíše hodnotu z definice, bez ní prázdné.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/scripts/agent-model.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

mkdir -p "$tmp/repo/.claude/agents/sub" "$tmp/home/.claude/agents"
git -C "$tmp/repo" init -q
printf -- '---\r\nname: backend-engineer\r\nmodel: opus\r\neffort: xhigh\r\ntools: Read, Edit, Bash(dotnet:*), Skill\r\n---\r\nmodel: haiku\r\n' >"$tmp/repo/.claude/agents/sub/be.md"
printf -- '---\nname: inh\nmodel: inherit\n---\n' >"$tmp/repo/.claude/agents/i.md"
printf -- '---\nname: listed\nmodel: sonnet\ntools:\n  - Read\n  - Bash\n  - Skill\n---\n' >"$tmp/repo/.claude/agents/l.md"
printf -- '---\nname: noskill\nmodel: sonnet\ntools: Read, Grep, Bash\nisolation: worktree\n---\n' >"$tmp/repo/.claude/agents/n.md"
printf -- '---\nname: global-only\nmodel: sonnet\neffort: medium\n---\n' >"$tmp/home/.claude/agents/g.md"
printf -- '---\nname: backend-engineer\nmodel: haiku\n---\n' >"$tmp/home/.claude/agents/be-global.md"

run() { (cd "$tmp/repo" && HOME="$tmp/home" bash "$script" "$@"); }
flat() { tr '\n' ' ' <<<"$1"; }

out="$(run backend-engineer)"
grep -qx 'found=true' <<<"$out" && grep -qx 'model=opus' <<<"$out" && grep -qx 'effort=xhigh' <<<"$out" \
  && grep -q '^path=.*/repo/.claude/agents/sub/be.md$' <<<"$out" \
  || { echo "fail=criterion_1_4 out=$(flat "$out")"; fail=1; }
grep -qx 'tools=Read,Edit,Bash(dotnet:\*),Skill' <<<"$out" && grep -qx 'can_run_skills=true' <<<"$out" \
  || { echo "fail=criterion_5 case=inline out=$(flat "$out")"; fail=1; }

out="$(run inh)"
grep -qx 'model=' <<<"$out" && grep -qx 'tools=' <<<"$out" && grep -qx 'can_run_skills=true' <<<"$out" \
  || { echo "fail=criterion_2_5 out=$(flat "$out")"; fail=1; }

out="$(run listed)"
grep -qx 'tools=Read,Bash,Skill' <<<"$out" && grep -qx 'can_run_skills=true' <<<"$out" \
  || { echo "fail=criterion_5 case=list out=$(flat "$out")"; fail=1; }

out="$(run noskill)"
grep -qx 'can_run_skills=false' <<<"$out" || { echo "fail=criterion_5 case=noskill out=$(flat "$out")"; fail=1; }
grep -qx 'isolation=worktree' <<<"$out" || { echo "fail=criterion_6 case=set out=$(flat "$out")"; fail=1; }
out="$(run listed)"
grep -qx 'isolation=' <<<"$out" || { echo "fail=criterion_6 case=unset out=$(flat "$out")"; fail=1; }

out="$(run nikdo)"; rc=$?
run >/dev/null 2>&1; rc2=$?
if ! grep -qx 'found=false' <<<"$out" || [ "$rc" -ne 0 ] || [ "$rc2" -ne 2 ]; then
  echo "fail=criterion_3 rc=$rc rc2=$rc2"; fail=1
fi

out="$(run global-only)"
grep -qx 'model=sonnet' <<<"$out" && grep -qx 'effort=medium' <<<"$out" \
  || { echo "fail=criterion_4 out=$(flat "$out")"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
