#!/usr/bin/env bash
# PreToolUse gate for `git push`. Forces a real permission prompt unless the
# git_committer_auto_push plugin option is on, regardless of the current
# permission mode (bypassPermissions/acceptEdits included) or any broad
# `Bash(git push:*)` allow rule in settings. Independent of
# git_committer_auto_commit / guard-git-commit.sh.
set -euo pipefail

if [ "${CLAUDE_PLUGIN_OPTION_GIT_COMMITTER_AUTO_PUSH:-false}" = "true" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"git_committer_auto_push is enabled"}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git_committer_auto_push is off — pushes require explicit approval"}}'
fi
