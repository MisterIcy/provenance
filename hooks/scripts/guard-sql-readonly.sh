#!/usr/bin/env bash
# PreToolUse gate for DB CLI calls (mysql/psql/sqlite3) made by the
# sql-query-reviewer agent. The agent's Bash(mysql *)/Bash(psql *)/
# Bash(sqlite3 *) tool-permission patterns only restrict by binary name —
# they cannot see inside a `-e "..."` / `-c "..."` argument, so a command
# like `mysql -e "DELETE FROM ..."` would otherwise still match the
# allowlist. This hook inspects the actual command string and blocks it if
# it contains a mutating or DDL/DCL keyword; legitimate read-only calls fall
# through untouched so normal permission-mode behavior still applies.
#
# Heuristic, not a substitute for a read-only DB credential: keyword
# matching cannot catch every way to construct a mutating statement.
set -euo pipefail

command_str="$(jq -r '.tool_input.command // empty')"

if [ -z "$command_str" ]; then
  exit 0
fi

if echo "$command_str" | grep -Eqi '\b(insert|update|delete|drop|alter|truncate|create|grant|revoke|replace|merge|call|exec|execute|lock|unlock|vacuum|reindex|attach|detach|pragma|begin|commit|rollback|savepoint|set|copy|into)\b'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: command appears to contain a mutating SQL statement or DDL/DCL keyword. sql-query-reviewer is read-only — only SELECT/EXPLAIN/SHOW/DESCRIBE-style queries are permitted."}}'
fi
