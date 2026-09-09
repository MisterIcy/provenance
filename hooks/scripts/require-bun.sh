#!/usr/bin/env bash
# Shared by all hook wrappers: fail closed (exit 2) instead of silently
# skipping the gate when bun isn't installed. Exit 2 on PreToolUse blocks the
# tool call and surfaces this message to Claude; on PostToolUse it surfaces
# the message as context without blocking the already-completed call.
require_bun() {
  if ! command -v bun >/dev/null 2>&1; then
    echo "bun is required to run this hook but was not found on PATH. Install: https://bun.sh" >&2
    exit 2
  fi
}
