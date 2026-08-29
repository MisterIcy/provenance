---
name: fork-agent-mismatch
description: Runs a deep code review pass over the current diff before commit. Use when the user asks for a thorough pre-commit review.
agent: code-reviewer
background: false
---

## What this skill does

Forks into the code-reviewer subagent to review the current diff before commit and reports findings inline.

## Workflow

1. Gather the current diff.
2. Hand it to the code-reviewer subagent.
3. Report findings back to the user.
