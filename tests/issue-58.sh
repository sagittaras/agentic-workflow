#!/usr/bin/env bash
# Test kritérií issue #58 ověřitelných příkazem.
#
# Kritérium 1: skills/review-docs/SKILL.md existuje, frontmatter nese name
# (shodné se složkou), description, when_to_use, model a effort, běží
# s čistým kontextem jako ostatní review-* skilly (context: fork, zákaz
# AskUserQuestion), description a when_to_use se vejdou do 1 536 znaků
# a `bash scripts/lint-skills.sh` projde.
#
# Návratové kódy: 0 = prošlo, 1 = selhalo.

set -uo pipefail

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root"

f=skills/review-docs/SKILL.md
fail=0

if [ ! -f "$f" ]; then
  echo "fail=criterion_1 reason=missing_skill_file"
  exit 1
fi

end_line="$(awk 'NR>1 && $0=="---"{print NR; exit}' "$f")"
block="$(sed -n "2,$((${end_line:-1} - 1))p" "$f")"

for field in name description when_to_use model effort; do
  if ! grep -q "^$field:" <<<"$block"; then
    echo "fail=criterion_1 reason=missing_field field=$field"
    fail=1
  fi
done

if ! grep -qx 'name: review-docs' <<<"$block"; then
  echo "fail=criterion_1 reason=name_mismatch"
  fail=1
fi

if ! grep -qx 'context: fork' <<<"$block"; then
  echo "fail=criterion_1 reason=missing_clean_context"
  fail=1
fi

if ! awk '/^disallowed-tools:/{f=1; next} f && /^  - /{print; next} {f=0}' <<<"$block" \
    | grep -q 'AskUserQuestion'; then
  echo "fail=criterion_1 reason=ask_user_not_disallowed"
  fail=1
fi

chars="$(awk '
  /^[a-z_-]+:/ { key = $1; sub(/:.*/, "", key); next }
  key == "description" || key == "when_to_use" {
    if ($0 ~ /^  /) { line = $0; sub(/^ +/, "", line); text = text line " " }
  }
  END { printf "%d", length(text) }
' <<<"$block")"
if [ "$chars" -gt 1536 ]; then
  echo "fail=criterion_1 reason=description_budget_exceeded chars=$chars"
  fail=1
fi

if ! bash scripts/lint-skills.sh >/dev/null; then
  echo "fail=criterion_1 reason=lint_skills_failed"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "result=pass"
fi
exit "$fail"
