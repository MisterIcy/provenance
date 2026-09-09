#!/usr/bin/env bash
# PreToolUse gate for `git commit`. Forces a real permission prompt unless the
# git_committer_auto_commit plugin option is on, regardless of the current
# permission mode (bypassPermissions/acceptEdits included) or any broad
# `Bash(git commit:*)` allow rule in settings.
#
# Command parsing (tokenizing, handling -C/-c, compound commands) lives in
# git-guard.ts so it can't be dodged by shell quoting tricks a regex misses.
set -uo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$script_dir/require-bun.sh"
require_bun

exec bun "$script_dir/git-guard.ts" commit CLAUDE_PLUGIN_OPTION_GIT_COMMITTER_AUTO_COMMIT
