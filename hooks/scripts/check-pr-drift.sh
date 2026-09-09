#!/usr/bin/env bash
# PostToolUse gate for the pr-description-sync skill. See pr-drift-check.ts
# for the actual logic.
set -uo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$script_dir/require-bun.sh"
require_bun

exec bun "$script_dir/pr-drift-check.ts"
