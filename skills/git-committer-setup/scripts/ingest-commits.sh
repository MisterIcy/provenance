#!/usr/bin/env bash
# Dumps the N most recent commits by the current git author, for style ingestion.
# Usage: ingest-commits.sh [count]
set -euo pipefail

count="${1:-30}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository." >&2
  exit 1
fi

author_email="$(git config user.email || true)"

if [ -z "$author_email" ]; then
  echo "No git user.email configured; falling back to all authors." >&2
  git log -n "$count" --pretty=format:'commit %H%nsubject: %s%n%n%b%n===END===%n'
  exit 0
fi

by_author_count="$(git log --author="$author_email" --oneline | wc -l | tr -d ' ')"

if [ "$by_author_count" -lt 5 ]; then
  echo "Fewer than 5 commits found for $author_email; falling back to all authors." >&2
  git log -n "$count" --pretty=format:'commit %H%nsubject: %s%n%n%b%n===END===%n'
else
  git log --author="$author_email" -n "$count" --pretty=format:'commit %H%nsubject: %s%n%n%b%n===END===%n'
fi
