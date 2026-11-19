#!/usr/bin/env bash
# Test skills/review-run/scripts/run-transcripts.mjs — nalezení běhu,
# statistiky a výtah transkriptu.
#
# Bez sítě: dočasný git repozitář a dočasný adresář projektů se dvěma ručně
# sestavenými běhy nad týmž issue — novějším s podřazenými session a starším
# v režimu subagentů.
#
# Kritérium 1: find bez výběru vezme novější běh, vypíše repo, integrační
#              větev a model, spáruje session s transkriptem podle zadání za
#              blokem Background, vypíše jejího vlastního subagenta jako 5-a1,
#              druhý transkript téhož issue označí 5-2, transkript, který
#              zadání jen cituje později, nespáruje, běh v adresáři sousedního
#              repozitáře s delší cestou nevezme a cesty píše s lomítky.
# Kritérium 2: find --transcript na starší běh se stejnou větví: repo a větev ze zadání Agent,
#              implementační subagent v [sessions], ostatní v [agents]
#              se štítkem orch-a1;
#              session novějšího běhu nepřiřadí.
# Kritérium 3: find --milestone vybírá přesnou shodou (1 nesedí na 13 ani 3)
#              a bez shody končí kódem 3.
# Kritérium 4: find bez běhu → kód 3 no_run_found; --transcript mimo běh → kód 3.
# Kritérium 5: stats počítá volání podle unikátního message.id a subagenta,
#              který je mezi argumenty samostatně, nezapočítá podruhé.
# Kritérium 6: digest zapíše výtah každého transkriptu do --out-dir: HUMAN bez
#              system-reminderu i z přílohy queued_command, TOOL Bash
#              s příkazem, TOOL start_session se zadáním, RESULT[error], NOTE
#              o konci turnu session, SKILL z meta zprávy, PROMPT se zadáním
#              session i subagenta a PEER ze zprávy orchestrátoru (peer
#              i coordinator); přemýšlení vynechá.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
script="$root/skills/review-run/scripts/run-transcripts.mjs"

fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT
fail=0

git init -q "$fx/repo" || { echo "fail=fixture reason=git_init"; exit 1; }
repo_root="$(git -C "$fx/repo" rev-parse --path-format=absolute --git-common-dir | sed 's#/\.git/*$##')"
prefix="$(printf '%s' "$repo_root" | sed 's/[^A-Za-z0-9]/-/g')"
proj="$fx/projects"
main="$proj/$prefix"
wt="$proj/$prefix--claude-worktrees-a"
mkdir -p "$main" "$wt" "$proj/other" "$main/orchB/subagents" "$wt/child/subagents" "$proj/$prefix-tools"

orch="$main/orch.jsonl"
cat >"$orch" <<'EOF'
{"type":"user","timestamp":"2026-11-17T14:56:00.000Z","origin":{"kind":"human"},"message":{"role":"user","content":[{"type":"text","text":"<system-reminder>worktree info</system-reminder>"},{"type":"text","text":"Spusť milestone #3"}]}}
{"type":"assistant","timestamp":"2026-11-17T14:56:10.000Z","message":{"id":"m1","model":"claude-opus-5-5","content":[{"type":"thinking","thinking":"TAJNE"},{"type":"tool_use","id":"t1","name":"Skill","input":{"skill":"sagittaras:run-milestone","args":"3"}}],"usage":{"input_tokens":1,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000,"output_tokens":10}}}
{"type":"assistant","timestamp":"2026-11-17T14:56:11.000Z","message":{"id":"m1","model":"claude-opus-5-5","content":[{"type":"text","text":"Spouštím."}],"usage":{"input_tokens":1,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000,"output_tokens":10}}}
{"type":"assistant","timestamp":"2026-11-17T14:57:00.000Z","message":{"id":"m2","model":"claude-opus-5-5","content":[{"type":"tool_use","id":"t2","name":"mcp__ccd_session__start_session","input":{"name":"issue-5","title":"#5 feat: x","initiation":"user_asked","source_branch":"milestone/x","prompt":"Naimplementuj issue #5 (feat: x) v repozitáři o/r skillem sagittaras:implement-issue, se základní větví milestone/x."}}],"usage":{"input_tokens":2,"cache_creation_input_tokens":200,"cache_read_input_tokens":2000,"output_tokens":20}}}
{"type":"user","timestamp":"2026-11-17T14:57:01.000Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t2","content":[{"type":"text","text":"Started session \"#5 feat: x\" (session_id: local_abc-1, name: issue-5). It runs on its own."}]}]}}
{"type":"assistant","timestamp":"2026-11-17T14:58:00.000Z","message":{"id":"m3","model":"claude-opus-5-5","content":[{"type":"tool_use","id":"t3","name":"Bash","input":{"command":"bash scripts/integration-gate.sh feat/x milestone/x"}}],"usage":{"input_tokens":3,"cache_creation_input_tokens":300,"cache_read_input_tokens":3000,"output_tokens":30}}}
{"type":"user","timestamp":"2026-11-17T14:58:30.000Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t3","is_error":true,"content":"Exit code 5 merge=conflict"}]}}
{"type":"user","timestamp":"2026-11-17T15:10:00.000Z","message":{"role":"user","content":"<system-reminder>\nThe session \"#5 feat: x\" you started (local_abc-1) finished a turn (PR #9).\n</system-reminder>"}}
{"type":"attachment","timestamp":"2026-11-17T15:11:00.000Z","attachment":{"type":"queued_command","prompt":"PR 9 může být zmergované.","origin":{"kind":"human"}}}
EOF

child="$wt/child.jsonl"
cat >"$child" <<'EOF'
{"type":"queue-operation","timestamp":"2026-11-17T14:57:02.000Z"}
{"type":"user","timestamp":"2026-11-17T14:57:03.000Z","message":{"role":"user","content":"<system-reminder>Linked sessions</system-reminder>\n\nBackground (from the session that started this one):\nIssue #5 patří do milestonu.\n\nNaimplementuj issue #5 (feat: x) v repozitáři o/r skillem sagittaras:implement-issue, se základní větví milestone/x."}}
{"type":"user","timestamp":"2026-11-17T14:57:05.000Z","isMeta":true,"message":{"role":"user","content":[{"type":"text","text":"Base directory for this skill: C:\\plugin\\skills\\implement-issue\n\n# Implement Issue"}]}}
{"type":"assistant","timestamp":"2026-11-17T15:05:00.000Z","message":{"id":"c1","content":[{"type":"text","text":"PR: #9"}],"usage":{"input_tokens":5,"cache_creation_input_tokens":50,"cache_read_input_tokens":500,"output_tokens":5}}}
{"type":"user","timestamp":"2026-11-17T15:06:00.000Z","isMeta":true,"origin":{"kind":"peer","from":"local_orch","name":"Milestone #3","body":"Brána neprošla: PR #9 má konflikt."},"message":{"role":"user","content":"Another Claude session sent a message:\n<cross-session-message>Brána neprošla: PR #9 má konflikt.</cross-session-message>"}}
EOF

# Session předala implementaci agentovi z mapy Agenti.
cat >"$wt/child/subagents/agent-n1.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-11-17T14:57:10.000Z","isSidechain":true,"message":{"role":"user","content":"Naimplementuj issue #5 (feat: x) v repozitáři o/r skillem sagittaras:implement-issue, se základní větví milestone/x."}}
EOF

# Novější běh v sousedním repozitáři, jehož cesta tu naši jen prodlužuje.
cat >"$proj/$prefix-tools/neighbor.jsonl" <<'EOF'
{"type":"assistant","timestamp":"2026-11-18T09:00:00.000Z","message":{"id":"n1","content":[{"type":"tool_use","id":"x1","name":"Skill","input":{"skill":"sagittaras:run-milestone","args":"9"}}]}}
EOF

# Druhý transkript téhož issue bez záznamu o spuštění.
cat >"$wt/child2.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-11-17T15:05:00.000Z","message":{"role":"user","content":"Naimplementuj issue #5 (feat: x) v repozitáři o/r skillem sagittaras:implement-issue, se základní větví milestone/x."}}
EOF

# Transkript, který zadání cituje až později — nesmí se spárovat.
cat >"$main/analysis.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-11-17T15:06:00.000Z","origin":{"kind":"human"},"message":{"role":"user","content":"Rozeber běh."}}
{"type":"user","timestamp":"2026-11-17T15:07:00.000Z","origin":{"kind":"human"},"message":{"role":"user","content":"Naimplementuj issue #5 (feat: x) v repozitáři o/r"}}
EOF

# Starší běh v režimu subagentů, spuštěný příkazem.
orchB="$main/orchB.jsonl"
cat >"$orchB" <<'EOF'
{"type":"user","timestamp":"2026-11-10T10:00:00.000Z","origin":{"kind":"human"},"message":{"role":"user","content":"<command-name>/sagittaras:run-milestone</command-name>\n<command-args>13</command-args>"}}
{"type":"assistant","timestamp":"2026-11-10T10:01:00.000Z","message":{"id":"b1","model":"claude-opus-5-5","content":[{"type":"tool_use","id":"u1","name":"Agent","input":{"description":"Implement issue #5","subagent_type":"general-purpose","prompt":"Naimplementuj issue #5 (feat: x) v repozitáři o/r.\nZákladní větev: milestone/x — z ní větvi."}}],"usage":{"input_tokens":1,"cache_creation_input_tokens":10,"cache_read_input_tokens":100,"output_tokens":1}}}
{"type":"user","timestamp":"2026-11-10T10:30:00.000Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"u1","content":"PR: #7"}]}}
EOF
cat >"$main/orchB/subagents/agent-a1.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-11-10T10:01:01.000Z","isSidechain":true,"message":{"role":"user","content":"Naimplementuj issue #5 (feat: x) v repozitáři o/r.\nZákladní větev: milestone/x — z ní větvi."}}
{"type":"assistant","timestamp":"2026-11-10T10:20:00.000Z","isSidechain":true,"message":{"id":"a1m","content":[{"type":"text","text":"PR: #7"}],"usage":{"input_tokens":4,"cache_creation_input_tokens":40,"cache_read_input_tokens":400,"output_tokens":4}}}
{"type":"user","timestamp":"2026-11-10T10:25:00.000Z","isSidechain":true,"isMeta":true,"origin":{"kind":"coordinator"},"message":{"role":"user","content":"Připomínky: přečti je z PR #7."}}
EOF
cat >"$main/orchB/subagents/agent-a2.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-11-10T10:21:00.000Z","isSidechain":true,"message":{"role":"user","content":"Posuď pull request #7."}}
EOF

run() { out="$(cd "$fx/repo" && node "$script" "$@" 2>&1)"; rc=$?; }
kv() { sed -n "s/^$1=//p" <<<"$out" | head -1; }

run find --projects-dir "$proj"
if [ "$rc" -ne 0 ] || [ "$(kv candidates)" != 2 ] || [ "$(kv repo)" != o/r ] \
   || [ "$(kv repo_source)" != prompt ] || [ "$(kv model)" != claude-opus-5-5 ] \
   || [ "$(kv integration_branch)" != milestone/x ] || [ "$(kv milestone_arg)" != 3 ] \
   || ! grep -q "^label=5 issue=5 session=local_abc-1 transcript=.*child.jsonl$" <<<"$out" \
   || ! grep -q "^label=5-2 issue=5 session=unknown transcript=.*child2.jsonl$" <<<"$out" \
   || ! grep -q "^label=5-a1 issue=5 session=agent:agent-n1 transcript=.*agent-n1.jsonl$" <<<"$out" \
   || grep -q 'neighbor' <<<"$out" || grep -qF '\' <<<"$out" \
   || grep -q 'analysis.jsonl' <<<"$out" || grep -q 'agent-a1' <<<"$out"; then
  echo "$out"; echo "fail=criterion_1 reason=find_wrong rc=$rc"; fail=1
fi

run find --projects-dir "$proj" --transcript orchB
if [ "$rc" -ne 0 ] || [ "$(kv repo)" != o/r ] || [ "$(kv integration_branch)" != milestone/x ] \
   || ! grep -q "^label=5 issue=5 session=agent:agent-a1 transcript=.*agent-a1.jsonl$" <<<"$out" \
   || ! grep -q "^label=orch-a1 transcript=.*agent-a2.jsonl$" <<<"$out" || grep -q 'child' <<<"$out"; then
  echo "$out"; echo "fail=criterion_2 reason=agent_mode_or_window_wrong rc=$rc"; fail=1
fi

run find --projects-dir "$proj" --milestone 13
ok13=$([ "$rc" -eq 0 ] && grep -q '^orchestrator=.*orchB.jsonl$' <<<"$out" && echo y)
run find --projects-dir "$proj" --milestone 1
if [ "$ok13" != y ] || [ "$rc" -ne 3 ] || ! grep -qx 'error=milestone_not_found' <<<"$out"; then
  echo "$out"; echo "fail=criterion_3 reason=milestone_selection_wrong rc=$rc"; fail=1
fi

mkdir -p "$fx/empty/$prefix"
run find --projects-dir "$fx/empty"
c4a=$([ "$rc" -eq 3 ] && grep -qx 'error=no_run_found' <<<"$out" && echo y)
run find --projects-dir "$proj" --transcript analysis
if [ "$c4a" != y ] || [ "$rc" -ne 3 ] || ! grep -qx 'error=transcript_not_a_run' <<<"$out"; then
  echo "$out"; echo "fail=criterion_4 reason=missing_run_not_reported rc=$rc"; fail=1
fi

run stats "orch=$orch" "ob=$orchB" "5=$main/orchB/subagents/agent-a1.jsonl"
line="$(grep '^label=orch ' <<<"$out")"
lineB="$(grep '^label=ob ' <<<"$out")"
if [ "$rc" -ne 0 ] || ! grep -q ' calls=3 ' <<<"$line" || ! grep -q ' input=6 ' <<<"$line" \
   || ! grep -q ' cache_read=6000 ' <<<"$line" || ! grep -q ' output=60 ' <<<"$line" \
   || ! grep -q ' tool_errors=1 ' <<<"$line" || ! grep -q ' last_context=3303 ' <<<"$line" \
   || ! grep -q ' calls=1 ' <<<"$lineB" || ! grep -q ' subagent_files=1$' <<<"$lineB" \
   || ! grep -qx 'total_calls=5' <<<"$out"; then
  echo "$out"; echo "fail=criterion_5 reason=stats_wrong rc=$rc"; fail=1
fi

run digest "orch=$orch" "5=$child" "b5=$main/orchB/subagents/agent-a1.jsonl" --out-dir "$fx/d"
db="$(cat "$fx/d/b5.txt" 2>/dev/null)"
d="$(cat "$fx/d/orch.txt" 2>/dev/null)"
dc="$(cat "$fx/d/5.txt" 2>/dev/null)"
if [ "$rc" -ne 0 ] || ! grep -q '^label=5 digest=' <<<"$out" \
   || ! grep -q 'HUMAN: Spusť milestone #3$' <<<"$d" \
   || grep -q 'worktree info' <<<"$d" || grep -q 'TAJNE' <<<"$d" \
   || ! grep -q 'TOOL Bash: bash scripts/integration-gate.sh feat/x milestone/x' <<<"$d" \
   || ! grep -q 'RESULT\[error\]: Exit code 5 merge=conflict' <<<"$d" \
   || ! grep -q 'NOTE: .*finished a turn (PR #9)' <<<"$d" \
   || ! grep -q 'SKILL: Base directory for this skill: .*implement-issue' <<<"$dc" \
   || ! grep -q 'HUMAN: PR 9 může být zmergované\.$' <<<"$d" \
   || ! grep -q 'TOOL mcp__ccd_session__start_session: .*Naimplementuj issue #5' <<<"$d" \
   || ! grep -q 'PROMPT: Background .*Naimplementuj issue #5' <<<"$dc" \
   || ! grep -q 'PEER: from=Milestone #3 Brána neprošla: PR #9 má konflikt\.$' <<<"$dc" \
   || ! grep -q 'PROMPT: Naimplementuj issue #5' <<<"$db" \
   || ! grep -q 'PEER: from=coordinator Připomínky: přečti je z PR #7\.$' <<<"$db"; then
  echo "$out"; echo "$d"; echo "$dc"; echo "fail=criterion_6 reason=digest_wrong rc=$rc"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
