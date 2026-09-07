#!/usr/bin/env bash
# PreToolUse gate for `git push`. Forces a real permission prompt unless the
# git_committer_auto_push plugin option is on, regardless of the current
# permission mode (bypassPermissions/acceptEdits included) or any broad
# `Bash(git push:*)` allow rule in settings. Independent of
# git_committer_auto_commit / guard-git-commit.sh.
#
# Command parsing (tokenizing, handling -C/-c, compound commands) lives in
# git_guard.py so it can't be dodged by shell quoting tricks a regex misses.
set -uo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  exit 0
fi

exec python3 "$(dirname "${BASH_SOURCE[0]}")/git_guard.py" push CLAUDE_PLUGIN_OPTION_GIT_COMMITTER_AUTO_PUSH
