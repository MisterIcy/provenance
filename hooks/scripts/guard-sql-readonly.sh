#!/usr/bin/env bash
# PreToolUse gate for DB CLI calls (mysql/psql/sqlite3) made by the
# sql-query-reviewer agent. See sql-readonly-guard.ts for the actual
# keyword-matching logic.
set -uo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$script_dir/require-bun.sh"
require_bun

exec bun "$script_dir/sql-readonly-guard.ts"
