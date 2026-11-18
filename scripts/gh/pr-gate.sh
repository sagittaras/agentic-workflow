#!/usr/bin/env bash
# Brána před review jedním voláním: testy kritérií a integrační brána nad PR,
# při úspěchu zápis výsledku do trackeru. Výstup key=value na stdout.
#
# Použití:
#   bash scripts/gh/pr-gate.sh -R owner/repo <PR> --issue <N> --base <integrační větev> \
#     [--no-write] [-- <ověřovací příkaz…>]
#
# Postup: přečte tělo issue a PR, hlavu i cíl PR vezme z forge (ne z odhadu
# názvu větve), spustí criteria-tests.sh a při kódu 0 integration-gate.sh.
# Prošlo-li obojí, nahraje tělo issue s odškrtnutými kritérii a pošle k PR
# komentář „Brána prošla" — s --no-write jen vypíše, že by to udělal.
#
# Výstup: pr=, issue=, head=, base=; řádky criteria-tests.sh (criteria=,
# tested=, human=, changed_files=, fail=…), criteria_tests=pass|fail; řádky
# brány (pr_sha=, integration_sha=, merge=, check=, conflicts=, command=,
# exit_code=, worktree_removed=);
# issue_body=updated|skipped, comment_mode=review|comment|skipped; result=pass|fail.
# Sekce brány ([conflicts], [merge_output], [output]) se vypisují jen při
# neúspěchu — při úspěchu výstup ověřovacího příkazu nikoho nezajímá a jen plní
# kontext. U kódů 2, 3, 4 a 7 řádek result= chybí, důvod nese error= na stderr.
#
# Návratové kódy: 0 = prošlo a je zapsáno, 1 = nález v mapě kritérií,
# 2 = chybný argument, PR nemíří do --base nebo issue bez sekce kritérií,
# 3 = čtení z forge, remote nebo worktree selhalo, 4 = brána prošla, ale zápis
# do trackeru selhal, 5 = konflikt s integrační větví, 6 = ověřovací příkaz
# selhal, 7 = gh chybí nebo není přihlášené.

set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/_common.sh"

repo="" pr="" issue="" base="" write=true
cmd=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -R|--repo) require_value "$1" "${2:-}"; repo="$2"; shift 2 ;;
    --issue) require_value "$1" "${2:-}"; issue="$2"; shift 2 ;;
    --base) require_value "$1" "${2:-}"; base="$2"; shift 2 ;;
    --no-write) write=false; shift ;;
    --) shift; cmd=("$@"); break ;;
    -*) die_usage "unknown_option" "neznámý přepínač $1" ;;
    *)
      if [ -z "$pr" ]; then pr="$1"; shift
      else die_usage "unexpected_argument" "přebývá argument '$1'"; fi
      ;;
  esac
done

require_repo "$repo"
require_number "$pr"
require_number "$issue"
[ -n "$base" ] || die_usage "missing_base" "povinné je --base <integrační větev>"
gh_require

d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT

echo "pr=$pr"
echo "issue=$issue"

# Selhání čtení nesmí propadnout syrovým kódem gh (typicky 1 = „nález v mapě").
read_or_die() { # read_or_die <error> <cíl> <příkaz…>
  local err="$1" out="$2" rc=0; shift 2
  "$@" >"$out" 2>"$d/read.err" || rc=$?
  if [ "$rc" -ne 0 ]; then
    cat "$d/read.err" >&2
    [ "$rc" -eq 7 ] && exit 7
    echo "error=$err" >&2
    exit 3
  fi
}
read_or_die issue_read_failed "$d/issue.md" bash "$here/issue-read.sh" -R "$repo" "$issue" --body
read_or_die pr_read_failed "$d/pr.md" bash "$here/pr-read.sh" -R "$repo" "$pr" --body
read_or_die pr_read_failed "$d/refs" gh pr view "$pr" -R "$repo" --json headRefName,baseRefName \
  --jq '.headRefName + " " + .baseRefName'
refs="$(cat "$d/refs")"
head="${refs%% *}"
pr_base="${refs##* }"
echo "head=$head"
echo "base=$pr_base"
if [ "$pr_base" != "$base" ]; then
  echo "error=base_mismatch" >&2
  echo "hint=PR #$pr míří do '$pr_base', čekala se '$base'" >&2
  exit 2
fi

# --- testy kritérií --------------------------------------------------------
rc=0
ct_out="$(bash "$here/../criteria-tests.sh" --issue-body "$d/issue.md" --pr-body "$d/pr.md" \
  --base "$base" --head "$head" --ticked-body "$d/ticked.md" 2>"$d/ct.err")" || rc=$?
[ -n "$ct_out" ] && { printf '%s\n' "$ct_out" | grep -v -e '^result=' -e '^ticked_body=' || true; }
if [ "$rc" -ne 0 ]; then
  cat "$d/ct.err" >&2
  echo "criteria_tests=fail"
  case "$rc" in
    1) echo "result=fail"; exit 1 ;;
    2) exit 2 ;;
    *) exit 3 ;;
  esac
fi
echo "criteria_tests=pass"
kv() { printf '%s\n' "$ct_out" | sed -n "s/^$1=//p" | head -1; }
criteria="$(kv criteria)" tested="$(kv tested)" human="$(kv human)"

# --- integrační brána ----------------------------------------------------
rc=0
if [ "${#cmd[@]}" -gt 0 ]; then
  gate_out="$(bash "$here/../integration-gate.sh" "$head" "$base" -- "${cmd[@]}" 2>"$d/gate.err")" || rc=$?
else
  gate_out="$(bash "$here/../integration-gate.sh" "$head" "$base" 2>"$d/gate.err")" || rc=$?
fi
case "$rc" in
  0|5|6) : ;;
  2) cat "$d/gate.err" >&2; exit 2 ;;
  *) cat "$d/gate.err" >&2; exit 3 ;;
esac
# Hlavička brány (do první prázdné řádky) bez interních cest.
printf '%s\n' "$gate_out" | sed '/^$/q' | grep -E '^(pr_sha|integration_sha|merge|check|conflicts|command|exit_code|worktree_removed)=' || true
if [ "$rc" -ne 0 ]; then
  printf '%s\n' "$gate_out" | sed -n '/^\[/,$p'
  echo "result=fail"
  exit "$rc"
fi
check="$(printf '%s\n' "$gate_out" | sed -n 's/^check=//p' | head -1)"

# --- zápis do trackeru ---------------------------------------------------
if [ "$write" = false ]; then
  echo "issue_body=skipped"
  echo "comment_mode=skipped"
  echo "result=pass"
  exit 0
fi

if [ "$check" = "pass" ]; then
  command_line="- Ověřovací příkaz: \`${cmd[*]}\` — prošel"
else
  command_line="- Ověřovací příkaz: přeskočen, pro oblast není příkaz"
fi
cat >"$d/comment.md" <<EOF
## Brána prošla

- Testy kritérií: $tested z $criteria, $human ověří člověk
$command_line
EOF

if ! bash "$here/issue-update.sh" -R "$repo" "$issue" --body-file "$d/ticked.md" >/dev/null 2>"$d/w.err"; then
  cat "$d/w.err" >&2
  echo "error=issue_update_failed" >&2
  exit 4
fi
echo "issue_body=updated"
if ! c_out="$(bash "$here/pr-comment.sh" -R "$repo" "$pr" --body-file "$d/comment.md" 2>"$d/w.err")"; then
  cat "$d/w.err" >&2
  echo "error=comment_failed" >&2
  exit 4
fi
echo "comment_mode=$(printf '%s\n' "$c_out" | sed -n 's/^mode=//p')"
echo "result=pass"
