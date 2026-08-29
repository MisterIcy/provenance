#!/usr/bin/env bash
# PostToolUse gate for the pr-description-sync skill. Runs after a `git push`
# Bash call; exits silently unless the feature is enabled and the branch has
# an open PR. Never edits anything itself — it only asks Claude, via
# additionalContext, to run the pr-description-sync skill.
set -euo pipefail

if [ "${CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED:-false}" != "true" ]; then
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  exit 0
fi

pr_number="$(gh pr view --json number -q .number 2>/dev/null || true)"
if [ -z "$pr_number" ]; then
  exit 0
fi

# pr_number is numeric (from `gh -q .number`), so no JSON escaping is needed here.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A git push just completed and the current branch has an open PR (#%s). Invoke the provenance:pr-description-sync skill now to check whether the PR'\''s title/description has drifted from the actual changes, and update it if the user approves."}}' \
  "$pr_number"
