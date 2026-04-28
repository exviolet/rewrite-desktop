#!/usr/bin/env bash
# Stop hook: напоминает Claude обновить HANDOFF.md в конце сессии.
# Не блокирует, просто внедряет additionalContext.

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"End-of-session reminder: обнови HANDOFF.md актуальным состоянием (статус, незакоммиченное в desktop и web/ submodule, next steps, открытые риски). Это правило ALWAYS из CLAUDE.md."}}
EOF
