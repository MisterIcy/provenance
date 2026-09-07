#!/usr/bin/env bash
# PreToolUse gate for `git commit`. Forces a real permission prompt unless the
# git_committer_auto_commit plugin option is on, regardless of the current
# permission mode (bypassPermissions/acceptEdits included) or any broad
# `Bash(git commit:*)` allow rule in settings.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

command_str="$(jq -r '.tool_input.command // empty')"

if [ -z "$command_str" ] || ! printf '%s\n' "$command_str" | grep -Eq '(^|[;&|]|[[:space:]])git[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

if [ "${CLAUDE_PLUGIN_OPTION_GIT_COMMITTER_AUTO_COMMIT:-false}" = "true" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"git_committer_auto_commit is enabled"}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git_committer_auto_commit is off — commits require explicit approval"}}'
fi
