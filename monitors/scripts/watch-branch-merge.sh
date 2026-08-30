#!/usr/bin/env bash
# Background monitor: polls whether the current branch has been merged into
# the repo's default branch (via a merged PR, a git merge/fast-forward, or
# otherwise) and, if the working tree is clean, switches to the default
# branch and pulls automatically. Gated by the branch_merge_monitor_enabled
# plugin option; off by default. Monitor processes don't receive
# CLAUDE_PLUGIN_OPTION_* env vars or ${user_config.*} substitution, so
# options are read directly from settings.json on each loop.
set -uo pipefail

SETTINGS_FILE="${HOME}/.claude/settings.json"
PLUGIN_ID="provenance"

read_option() {
  local key="$1" default="$2"
  if ! command -v jq >/dev/null 2>&1 || [ ! -f "$SETTINGS_FILE" ]; then
    printf '%s' "$default"
    return
  fi
  local value
  value="$(jq -r --arg k "$key" '.pluginConfigs["'"$PLUGIN_ID"'"].options[$k] // empty' "$SETTINGS_FILE" 2>/dev/null || true)"
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

resolve_default_branch() {
  local branch
  branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
  if [ -z "$branch" ] && command -v gh >/dev/null 2>&1; then
    branch="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
  fi
  if [ -z "$branch" ]; then
    git remote set-head origin -a >/dev/null 2>&1 || true
    branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
  fi
  printf '%s' "${branch:-main}"
}

while true; do
  enabled="$(read_option branch_merge_monitor_enabled false)"
  if [ "$enabled" != "true" ]; then
    sleep 60
    continue
  fi

  interval="$(read_option branch_merge_check_interval_seconds 300)"
  case "$interval" in
    ''|*[!0-9]*) interval=300 ;;
  esac

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sleep "$interval"
    continue
  fi

  git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  state_file="${git_dir}/provenance-merge-notified"

  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  default_branch="$(resolve_default_branch)"

  if [ -z "$current_branch" ] || [ "$current_branch" = "HEAD" ] || [ "$current_branch" = "$default_branch" ]; then
    sleep "$interval"
    continue
  fi

  if [ -f "$state_file" ] && [ "$(cat "$state_file" 2>/dev/null)" = "$current_branch" ]; then
    sleep "$interval"
    continue
  fi

  git fetch --quiet --prune origin "$default_branch" "$current_branch" >/dev/null 2>&1 || true

  merged=false
  reason=""

  if git merge-base --is-ancestor "$current_branch" "origin/$default_branch" 2>/dev/null; then
    merged=true
    reason="its commits are all reachable from origin/$default_branch (merge or fast-forward)"
  fi

  if [ "$merged" = false ] && command -v gh >/dev/null 2>&1; then
    pr_number="$(gh pr list --head "$current_branch" --state merged --json number -q '.[0].number' 2>/dev/null || true)"
    if [ -n "$pr_number" ]; then
      merged=true
      reason="PR #$pr_number was merged"
    fi
  fi

  if [ "$merged" = "true" ]; then
    if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
      if git checkout "$default_branch" >/dev/null 2>&1 && git pull --quiet >/dev/null 2>&1; then
        echo "Branch '$current_branch' was merged into '$default_branch' ($reason). Automatically switched to '$default_branch' and pulled the latest changes."
      else
        echo "Branch '$current_branch' was merged into '$default_branch' ($reason), but automatically switching to '$default_branch' and pulling failed — check manually."
      fi
    else
      echo "Branch '$current_branch' was merged into '$default_branch' ($reason), but the working tree has uncommitted changes, so it was not switched automatically. Commit or stash your changes, then switch to '$default_branch' and pull."
    fi
    echo "$current_branch" > "$state_file" 2>/dev/null || true
  fi

  sleep "$interval"
done
