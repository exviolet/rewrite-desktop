#!/usr/bin/env bash
# PreToolUse hook for Bash: блокирует `git commit` в web/ submodule если tsc или lint падают.
# Срабатывает только когда:
#   1) команда содержит `git commit`
#   2) commit происходит в web/ submodule (cwd внутри web/ ИЛИ команда содержит `cd web`)
#   3) среди staged файлов есть .ts/.tsx в web/src/
# Иначе — silent pass.

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')

# Skip non-commit commands
if ! echo "$cmd" | grep -qE '(^|[[:space:];&|])git[[:space:]]+commit'; then
  exit 0
fi

project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Detect web/ submodule context
target=""
if echo "$cmd" | grep -qE 'cd[[:space:]]+web([[:space:]]|$|/)'; then
  target="$project_root/web"
elif [[ "$PWD" == "$project_root/web"* ]]; then
  target="$project_root/web"
else
  # commit в desktop — verification web ts/lint не нужен
  exit 0
fi

cd "$target" || exit 0
staged=$(git diff --cached --name-only 2>/dev/null | grep -E '^src/.*\.tsx?$' || true)
if [ -z "$staged" ]; then
  exit 0
fi

# Run tsc
if ! tsc_out=$(bun tsc --noEmit 2>&1); then
  reason=$(printf "Verification failed — tsc errors in web/. Fix before commit.\n\n%s" "$(echo "$tsc_out" | tail -30)")
  jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

# Run lint
if ! lint_out=$(bun lint 2>&1); then
  reason=$(printf "Verification failed — lint errors in web/. Fix before commit.\n\n%s" "$(echo "$lint_out" | tail -30)")
  jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

exit 0
