#!/usr/bin/env node
// Najde transkripty jednoho běhu run-milestone, spočítá jejich statistiky
// a zhustí je do čitelného výtahu. Čte jen soubory, nic nemění.
//
// Použití:
//   node run-transcripts.mjs find [--repo <cesta>] [--transcript <cesta|uuid>]
//                                 [--milestone <číslo|název>] [--projects-dir <cesta>]
//   node run-transcripts.mjs stats [<štítek>=]<transkript>...
//   node run-transcripts.mjs digest [<štítek>=]<transkript>... [--out-dir <složka>]
//                                   [--result-chars N]
//
// find — orchestrátor je transkript, ve kterém se spustil skill run-milestone
// (nástrojem Skill nebo příkazem /…:run-milestone). Hledá se v adresářích
// ~/.claude/projects, jejichž název začíná zakódovanou cestou hlavního
// repozitáře — i z worktree, protože kořen se bere z git-common-dir.
// Vybere se nejnovější kandidát; --transcript určí konkrétní, --milestone
// nejnovějšího s tímto argumentem běhu (přesná shoda tokenu nebo celého
// argumentu, bez ohledu na velikost písmen a úvodní #).
//
// Výstup: repo_root=, projects_dir=, candidates=N, sekce [candidates]
// (transcript= started= milestone_arg= title=), pak orchestrator=, started=,
// ended=, model= (nejčastější model orchestrátoru), milestone_arg=,
// repo= a repo_source= (prompt | remote | none), integration_branch=,
// plugin_root=, plugin_commit= a plugin_commit_source= (reflog — HEAD instalace
// v čase startu; commit_date — poslední commit před startem, když reflog
// nestačí; unknown — plugin není git), plugin_head=, sekce [sessions]
// s řádky label= issue= session= transcript= a sekce [agents] se zbylými
// transkripty subagentů orchestrátora (label=orch-a<k> transcript=). Cesty se
// vypisují s lomítky.
//
// [sessions]: každá podřazená session (start_session) a každý subagent
// (nástroj Agent), jehož zadání začíná „Naimplementuj issue #N". session= je
// id session (local_…), agent:<soubor> u subagenta, unknown u transkriptu bez
// záznamu o spuštění; transcript= je cesta, nebo „missing". label= je číslo
// issue, u opakování téhož issue s příponou -2, -3… — štítek pro stats a digest.
// Za řádkem session následují její vlastní subagenti (session předala
// implementaci agentovi z mapy Agenti) se štítkem <label>-a<k> a týmž issue=.
// Transkript session se páruje podle první zprávy se zadáním téhož issue
// (a téhož repozitáře a integrační větve, jsou-li známé), začaté mezi startem
// a koncem orchestrátora.
//
// stats — pro každý transkript řádek label= transcript= first= last= span_min=
// calls= input= cache_write= cache_read= output= last_context= tool_errors=
// subagent_files=, nakonec total_*. Do transkriptu se započítají i jeho
// subagents/*.jsonl, pokud nejsou mezi argumenty samostatně. Volání se počítají
// podle unikátního message.id — jedna odpověď modelu se v transkriptu zapisuje
// po blocích a nesčítá se vícekrát. Časy jsou v místním pásmu s posunem.
//
// digest — chronologický výtah: HUMAN (zpráva člověka bez system-reminderů,
// i napsaná během práce modelu), PEER (zpráva od orchestrátoru do session
// nebo subagenta — signály brány a připomínek), PROMPT (zadání, se kterým
// session nebo subagent začal), NOTE (oznámení aplikace, typicky konec turnu
// podřazené session), SKILL
// (načtený skill), AI (text modelu), TOOL (volání nástroje, u Bash příkaz),
// RESULT / RESULT[error] (zkrácený výsledek), COMPACT (shrnutí po kompakci).
// Přemýšlení modelu se vynechává. Každý transkript jde do <štítek>.txt
// ve --out-dir; bez něj do nové dočasné složky. Výstup: out_dir=, pak pro
// každý transkript řádek label= digest= lines= bytes=.
//
// Návratové kódy: 0 = v pořádku, 2 = chybný argument (i neexistující
// transkript u stats a digest), 3 = běh nenalezen (žádný kandidát, --transcript
// neukazuje na běh, --milestone nesedí na žádný běh), 4 = chybí adresář
// projektů nebo repozitář.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, "..", "..", "..");
const ASSIGNMENT = /Naimplementuj issue #(\d+)/;

function fail(code, key, detail) {
  console.log(`error=${key}`);
  if (detail) console.error(detail);
  process.exit(code);
}

function parseArgs(argv) {
  const opts = {}; const pos = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const v = argv[i + 1];
      if (v === undefined || v.startsWith("--")) fail(2, "missing_value", `${a} potřebuje hodnotu`);
      opts[a.slice(2)] = v; i++;
    } else pos.push(a);
  }
  return { opts, pos };
}

function readLines(file) {
  const out = [];
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    if (!line.trim()) continue;
    try { out.push(JSON.parse(line)); } catch { /* rozepsaný poslední řádek */ }
  }
  return out;
}

function readHead(file, bytes = 262144) {
  const fd = fs.openSync(file, "r");
  try {
    const buf = Buffer.alloc(bytes);
    const n = fs.readSync(fd, buf, 0, bytes, 0);
    const out = [];
    for (const line of buf.subarray(0, n).toString("utf8").split("\n")) {
      try { out.push(JSON.parse(line)); } catch { /* useknutý řádek */ }
    }
    return out;
  } finally { fs.closeSync(fd); }
}

function textOf(content) {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content.map((c) => (c.type === "text" ? c.text : "")).filter(Boolean).join("\n");
}

const stripReminders = (s) => s.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, "").trim();
const oneLine = (s, n) => { const t = s.replace(/\s+/g, " ").trim(); return t.length > n ? t.slice(0, n) + "…" : t; };

function pad(n) { return String(n).padStart(2, "0"); }
function localStamp(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  const off = -d.getTimezoneOffset();
  const sign = off >= 0 ? "+" : "-";
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}${sign}${pad(Math.floor(Math.abs(off) / 60))}:${pad(Math.abs(off) % 60)}`;
}
const hhmm = (iso) => { const d = new Date(iso); return `${pad(d.getHours())}:${pad(d.getMinutes())}`; };

function git(args, cwd) {
  try { return execFileSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim(); }
  catch { return ""; }
}

function projectsDir(opts) {
  const base = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), ".claude");
  return opts["projects-dir"] || path.join(base, "projects");
}

// Cesty se vypisují s lomítky — dosazené bez uvozovek do Git Bashe by zpětná
// lomítka ztratily.
const fwd = (p) => p.replace(/\\/g, "/");

function listTranscripts(dir, prefix) {
  const out = [];
  for (const d of fs.readdirSync(dir)) {
    // Jen repozitář sám a jeho worktree, ne sousední repo s delší cestou.
    if (d !== prefix && !d.startsWith(`${prefix}--claude-worktrees-`)) continue;
    const full = path.join(dir, d);
    if (!fs.statSync(full).isDirectory()) continue;
    for (const f of fs.readdirSync(full)) if (f.endsWith(".jsonl")) out.push(path.join(full, f));
  }
  return out;
}

const subagentDir = (file) => path.join(file.replace(/\.jsonl$/, ""), "subagents");
function subagentFiles(file) {
  const dir = subagentDir(file);
  return fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith(".jsonl")).map((f) => path.join(dir, f)) : [];
}

function runMilestoneStart(entries) {
  for (const e of entries) {
    if (e.type === "assistant") {
      for (const c of e.message?.content || []) {
        if (c.type === "tool_use" && c.name === "Skill" && /(^|:)run-milestone$/.test(c.input?.skill || "")) {
          return { started: e.timestamp, arg: c.input.args || "" };
        }
      }
    }
    if (e.type === "user") {
      const t = textOf(e.message?.content);
      if (/<command-name>\/?(?:[\w-]+:)?run-milestone<\/command-name>/.test(t)) {
        const a = t.match(/<command-args>([\s\S]*?)<\/command-args>/);
        return { started: e.timestamp, arg: a ? a[1].trim() : "" };
      }
    }
  }
  return null;
}

function titleOf(entries) {
  let t = "";
  for (const e of entries) if (e.type === "custom-title" && e.customTitle) t = e.customTitle;
  return t;
}

function firstUserText(entries) {
  for (const e of entries) {
    if (e.type !== "user" || e.isMeta) continue;
    const t = stripReminders(textOf(e.message?.content));
    if (t) return { text: t, ts: e.timestamp };
  }
  return null;
}

const repoIn = (s) => ((s.match(/v repozitáři ([\w.-]+\/[\w.-]+)/) || [])[1] || "").replace(/\.+$/, "");
const branchIn = (s) => ((s.match(/(?:se základní větví|Základní větev:)\s*([^\s,]+)/) || [])[1] || "").replace(/[.,;]+$/, "");

function milestoneMatches(arg, wanted) {
  const norm = (s) => s.toLowerCase().replace(/^#/, "").trim();
  const w = norm(wanted);
  if (norm(arg) === w) return true;
  return arg.split(/[^\p{L}\p{N}_-]+/u).map(norm).includes(w);
}

function repoFromRemote(root) {
  const url = git(["remote", "get-url", "origin"], root);
  const m = url.match(/[:/]([\w.-]+\/[\w.-]+?)(?:\.git)?\/?$/);
  return m ? m[1] : "";
}

function pluginCommitAt(started) {
  if (!git(["rev-parse", "--git-dir"], pluginRoot)) return { sha: "unknown", source: "unknown" };
  // Starší start, než sahá reflog, by vrátil jeho nejstarší záznam — pak raději datum commitu.
  const oldest = Number((git(["reflog", "--date=unix", "--format=%gd", "HEAD"], pluginRoot).split("\n").pop().match(/\{(\d+)\}/) || [])[1]);
  const reflog = oldest && new Date(started).getTime() / 1000 >= oldest
    ? git(["rev-parse", "--short", `HEAD@{${started}}`], pluginRoot) : "";
  if (reflog) return { sha: reflog, source: "reflog" };
  const byDate = git(["log", "-1", "--format=%h", `--before=${started}`], pluginRoot);
  return byDate ? { sha: byDate, source: "commit_date" } : { sha: "unknown", source: "unknown" };
}

function cmdFind(opts) {
  const repoArg = opts.repo || process.cwd();
  const common = git(["rev-parse", "--path-format=absolute", "--git-common-dir"], repoArg);
  if (!common) fail(4, "not_a_git_repository", repoArg);
  const repoRoot = common.replace(/[\\/]\.git[\\/]?$/, "");
  const dir = projectsDir(opts);
  if (!fs.existsSync(dir)) fail(4, "projects_dir_missing", dir);
  const prefix = repoRoot.replace(/[^A-Za-z0-9]/g, "-");
  console.log(`repo_root=${fwd(repoRoot)}`);
  console.log(`projects_dir=${fwd(dir)}`);

  const files = listTranscripts(dir, prefix);
  const candidates = [];
  for (const f of files) {
    if (!fs.readFileSync(f, "utf8").includes("run-milestone")) continue;
    const entries = readLines(f);
    const start = runMilestoneStart(entries);
    if (start) candidates.push({ file: f, entries, ...start, title: titleOf(entries) });
  }
  candidates.sort((a, b) => (a.started < b.started ? 1 : -1));
  console.log(`candidates=${candidates.length}`);
  console.log("[candidates]");
  for (const c of candidates) {
    console.log(`transcript=${fwd(c.file)} started=${localStamp(c.started)} milestone_arg=${oneLine(c.arg, 80)} title=${oneLine(c.title, 80)}`);
  }

  let orch;
  if (opts.transcript) {
    const t = opts.transcript;
    orch = candidates.find((c) => c.file === path.resolve(t) || path.basename(c.file, ".jsonl") === t);
    if (!orch) fail(3, "transcript_not_a_run", t);
  } else if (opts.milestone) {
    orch = candidates.find((c) => milestoneMatches(c.arg, opts.milestone));
    if (!orch) fail(3, "milestone_not_found", opts.milestone);
  } else {
    if (!candidates.length) fail(3, "no_run_found", prefix);
    orch = candidates[0];
  }

  const entries = orch.entries;
  const ended = entries.reduce((m, e) => (e.timestamp && e.timestamp > m ? e.timestamp : m), "");
  const models = {};
  for (const e of entries) if (e.type === "assistant" && e.message?.model) models[e.message.model] = (models[e.message.model] || 0) + 1;
  const model = Object.entries(models).sort((a, b) => b[1] - a[1])[0]?.[0] || "";

  // Spuštění: start_session (vstup nese prompt, výsledek id) a Agent se zadáním issue.
  const uses = new Map();
  let repo = ""; let branch = "";
  for (const e of entries) {
    if (e.type !== "assistant") continue;
    for (const c of e.message?.content || []) {
      if (c.type !== "tool_use") continue;
      const prompt = c.input?.prompt || "";
      if (/start_session$/.test(c.name) || (/^(Agent|Task)$/.test(c.name) && ASSIGNMENT.test(prompt))) {
        uses.set(c.id, c.input || {});
        repo ||= repoIn(prompt);
        branch ||= c.input?.source_branch || branchIn(prompt);
      }
    }
  }
  const sessions = [];
  for (const e of entries) {
    if (e.type !== "user" || !Array.isArray(e.message?.content)) continue;
    for (const c of e.message.content) {
      if (c.type !== "tool_result" || !uses.has(c.tool_use_id)) continue;
      const res = textOf(c.content) || (typeof c.content === "string" ? c.content : "");
      const m = res.match(/Started session "([^"]*)" \(session_id: (local_[\w-]+)/);
      if (!m) continue;
      const issue = ((uses.get(c.tool_use_id).prompt || "").match(ASSIGNMENT) || m[1].match(/^#(\d+)/) || [])[1] || "";
      sessions.push({ issue, id: m[2] });
    }
  }

  let repoSource = repo ? "prompt" : "none";
  if (!repo) { repo = repoFromRemote(repoRoot); if (repo) repoSource = "remote"; }

  // Páruj podřazené transkripty podle první zprávy v okně běhu.
  const byIssue = new Map();
  for (const f of files) {
    if (f === orch.file) continue;
    const first = firstUserText(readHead(f));
    if (!first || first.ts < orch.started || first.ts > ended) continue;
    const m = first.text.match(ASSIGNMENT);
    if (!m) continue;
    if (repoSource === "prompt" && !first.text.includes(repo)) continue;
    if (branch && !first.text.includes(branch)) continue;
    if (!byIssue.has(m[1])) byIssue.set(m[1], []);
    byIssue.get(m[1]).push({ file: f, ts: first.ts });
  }
  for (const list of byIssue.values()) list.sort((a, b) => (a.ts < b.ts ? -1 : 1));

  const rows = [];
  const used = new Map();
  for (const s of sessions) {
    const list = byIssue.get(s.issue) || [];
    const k = used.get(s.issue) || 0;
    used.set(s.issue, k + 1);
    rows.push({ issue: s.issue, session: s.id, transcript: list[k] ? list[k].file : "missing" });
  }
  for (const [issue, list] of byIssue) {
    for (const t of list.slice(used.get(issue) || 0)) rows.push({ issue, session: "unknown", transcript: t.file });
  }
  const agents = [];
  for (const f of subagentFiles(orch.file)) {
    const first = firstUserText(readHead(f));
    const m = first && first.text.match(ASSIGNMENT);
    if (m) rows.push({ issue: m[1], session: `agent:${path.basename(f, ".jsonl")}`, transcript: f });
    else agents.push(f);
  }

  const { sha, source } = pluginCommitAt(orch.started);
  console.log(`orchestrator=${fwd(orch.file)}`);
  console.log(`started=${localStamp(orch.started)}`);
  console.log(`ended=${localStamp(ended)}`);
  console.log(`model=${model}`);
  console.log(`milestone_arg=${oneLine(orch.arg, 80)}`);
  console.log(`repo=${repo}`);
  console.log(`repo_source=${repoSource}`);
  console.log(`integration_branch=${branch}`);
  console.log(`plugin_root=${fwd(pluginRoot)}`);
  console.log(`plugin_commit=${sha}`);
  console.log(`plugin_commit_source=${source}`);
  console.log(`plugin_head=${git(["rev-parse", "--short", "HEAD"], pluginRoot) || "unknown"}`);
  console.log("[sessions]");
  const seen = new Map();
  for (const r of rows) {
    const n = (seen.get(r.issue) || 0) + 1;
    seen.set(r.issue, n);
    const label = n === 1 ? r.issue : `${r.issue}-${n}`;
    const t = r.transcript === "missing" ? "missing" : fwd(r.transcript);
    console.log(`label=${label} issue=${r.issue} session=${r.session} transcript=${t}`);
    // Session, která implementaci předala agentovi (mapa Agenti), má práci v subagentech.
    if (r.transcript === "missing" || r.session.startsWith("agent:")) continue;
    subagentFiles(r.transcript).forEach((f, i) => {
      console.log(`label=${label}-a${i + 1} issue=${r.issue} session=agent:${path.basename(f, ".jsonl")} transcript=${fwd(f)}`);
    });
  }
  console.log("[agents]");
  agents.forEach((f, i) => console.log(`label=orch-a${i + 1} transcript=${fwd(f)}`));
}

function labeled(arg) {
  const m = arg.match(/^([^=\\/:]+)=(.+)$/);
  return m ? { label: m[1], file: m[2] } : { label: path.basename(arg, ".jsonl"), file: arg };
}

function statsOf(files) {
  const seen = new Set();
  let first = ""; let last = ""; let lastCtxTs = ""; let lastCtx = 0; let errors = 0;
  const sum = { input: 0, cache_write: 0, cache_read: 0, output: 0 };
  for (const f of files) {
    for (const e of readLines(f)) {
      if (e.timestamp && ["user", "assistant"].includes(e.type)) {
        if (!first || e.timestamp < first) first = e.timestamp;
        if (!last || e.timestamp > last) last = e.timestamp;
      }
      if (e.type === "user" && Array.isArray(e.message?.content)) {
        for (const c of e.message.content) if (c.type === "tool_result" && c.is_error) errors++;
      }
      const u = e.type === "assistant" && e.message?.usage;
      if (!u) continue;
      const id = e.message.id || e.uuid;
      if (seen.has(id)) continue;
      seen.add(id);
      sum.input += u.input_tokens || 0;
      sum.cache_write += u.cache_creation_input_tokens || 0;
      sum.cache_read += u.cache_read_input_tokens || 0;
      sum.output += u.output_tokens || 0;
      if (f === files[0] && e.timestamp >= lastCtxTs) {
        lastCtxTs = e.timestamp;
        lastCtx = (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
      }
    }
  }
  const span = first && last ? Math.round((new Date(last) - new Date(first)) / 60000) : 0;
  return { first, last, span, calls: seen.size, ...sum, lastCtx, errors };
}

function cmdStats(pos) {
  if (!pos.length) fail(2, "missing_transcript", "stats potřebuje aspoň jeden transkript");
  const items = pos.map(labeled);
  for (const { file } of items) if (!fs.existsSync(file)) fail(2, "transcript_missing", file);
  const explicit = new Set(items.map(({ file }) => path.resolve(file)));
  const total = { calls: 0, input: 0, cache_write: 0, cache_read: 0, output: 0, errors: 0 };
  for (const { label, file } of items) {
    const subs = subagentFiles(file).filter((f) => !explicit.has(path.resolve(f)));
    const s = statsOf([file, ...subs]);
    console.log(`label=${label} transcript=${fwd(file)} first=${localStamp(s.first)} last=${localStamp(s.last)} span_min=${s.span} calls=${s.calls} input=${s.input} cache_write=${s.cache_write} cache_read=${s.cache_read} output=${s.output} last_context=${s.lastCtx} tool_errors=${s.errors} subagent_files=${subs.length}`);
    for (const k of Object.keys(total)) total[k] += s[k];
  }
  console.log(`total_calls=${total.calls}`);
  console.log(`total_input=${total.input}`);
  console.log(`total_cache_write=${total.cache_write}`);
  console.log(`total_cache_read=${total.cache_read}`);
  console.log(`total_output=${total.output}`);
  console.log(`total_tool_errors=${total.errors}`);
}

function toolInput(c) {
  const i = c.input || {};
  if (c.name === "Bash" || c.name === "PowerShell") return oneLine(i.command || "", 400);
  if (c.name === "Skill") return oneLine(`${i.skill} ${i.args || ""}`, 300);
  if (/SendMessage|send_message/.test(c.name)) return oneLine(`to=${i.to || i.session_id || ""} ${i.message || i.text || ""}`, 600);
  if (/start_session/.test(c.name)) return oneLine(`name=${i.name || ""} title=${i.title || ""} initiation=${i.initiation || ""} ${i.prompt || ""}`, 600);
  if (/^(Agent|Task)$/.test(c.name)) return oneLine(`${i.description || ""} type=${i.subagent_type || ""} ${i.prompt || ""}`, 400);
  return oneLine(JSON.stringify(i), 300);
}

function cmdDigest(pos, opts) {
  if (!pos.length) fail(2, "missing_transcript", "digest potřebuje aspoň jeden transkript");
  const items = pos.map(labeled);
  for (const { file } of items) if (!fs.existsSync(file)) fail(2, "transcript_missing", file);
  const dir = opts["out-dir"] || fs.mkdtempSync(path.join(os.tmpdir(), "review-run-"));
  fs.mkdirSync(dir, { recursive: true });
  console.log(`out_dir=${fwd(dir)}`);
  for (const { label, file } of items) digestOne(label, file, path.join(dir, `${label}.txt`), Number(opts["result-chars"] || 600));
}

function digestOne(label, file, outFile, limit) {
  const entries = readLines(file);
  const out = [`# digest ${file} title=${titleOf(entries)}`];
  for (const e of entries) {
    // Zpráva člověka napsaná během práce modelu se ukládá jako příloha queued_command.
    if (e.type === "attachment" && e.attachment?.type === "queued_command") {
      const ts = e.timestamp || e.attachment.timestamp;
      const who = e.attachment.origin?.kind === "human" || !e.attachment.origin ? "HUMAN" : "PEER";
      if (ts) out.push(`${hhmm(ts)} ${who}: ${oneLine(stripReminders(String(e.attachment.prompt || "")), 2000)}`);
      continue;
    }
    if (!e.timestamp || !["user", "assistant"].includes(e.type)) continue;
    const t = hhmm(e.timestamp);
    if (e.type === "user") {
      if (e.isCompactSummary) { out.push(`${t} COMPACT: ${oneLine(textOf(e.message?.content), 300)}`); continue; }
      const content = e.message?.content;
      if (Array.isArray(content) && content.some((c) => c.type === "tool_result")) {
        for (const c of content) {
          if (c.type !== "tool_result") continue;
          const r = textOf(c.content) || (typeof c.content === "string" ? c.content : "");
          out.push(`${t} RESULT${c.is_error ? "[error]" : ""}: ${oneLine(r, c.is_error ? limit * 2 : limit)}`);
        }
        continue;
      }
      const raw = textOf(content);
      // Načtený skill přichází jako meta zpráva — musí se poznat před vyřazením meta.
      if (raw.startsWith("Base directory for this skill:")) { out.push(`${t} SKILL: ${oneLine(raw.split("\n")[0], 200)}`); continue; }
      // Zpráva od orchestrátoru (session: peer, subagent: coordinator) je meta zpráva —
      // nese signály brány a připomínek, proto se pozná před vyřazením meta.
      if (["peer", "coordinator"].includes(e.origin?.kind)) {
        const body = e.origin.body || stripReminders(raw);
        out.push(`${t} PEER: from=${e.origin.name || e.origin.kind} ${oneLine(body, 2000)}`);
        continue;
      }
      if (e.isMeta) continue;
      const clean = stripReminders(raw);
      if (e.origin?.kind === "human" && clean) { out.push(`${t} HUMAN: ${oneLine(clean, 2000)}`); }
      let noted = 0;
      for (const n of raw.match(/<system-reminder>[\s\S]*?<\/system-reminder>/g) || []) {
        if (/finished a turn|session .* (you started|messaged)|<side-sessions-event>|ci-monitor-event/i.test(n)) {
          out.push(`${t} NOTE: ${oneLine(n.replace(/<\/?system-reminder>/g, ""), limit)}`);
          noted++;
        }
      }
      // Bez origin a bez oznámení je to zadání — první zpráva session nebo subagenta.
      if (!e.origin && clean && !noted) out.push(`${t} PROMPT: ${oneLine(clean, 2000)}`);
      continue;
    }
    for (const c of e.message?.content || []) {
      if (c.type === "text" && c.text.trim()) out.push(`${t} AI: ${oneLine(c.text, 1500)}`);
      if (c.type === "tool_use") out.push(`${t} TOOL ${c.name}: ${toolInput(c)}`);
    }
  }
  const body = out.join("\n") + "\n";
  fs.writeFileSync(outFile, body);
  console.log(`label=${label} digest=${fwd(outFile)} lines=${out.length} bytes=${Buffer.byteLength(body)}`);
}

const [cmd, ...rest] = process.argv.slice(2);
const { opts, pos } = parseArgs(rest);
switch (cmd) {
  case "find": cmdFind(opts); break;
  case "stats": cmdStats(pos); break;
  case "digest": cmdDigest(pos, opts); break;
  default: fail(2, "unknown_command", "použití: find | stats | digest");
}
