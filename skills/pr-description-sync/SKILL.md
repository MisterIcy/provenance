---
name: pr-description-sync
description: Checks whether the current branch's open GitHub PR title/description still accurately reflects its actual changes, and updates it via `gh pr edit` if it has drifted (e.g. review feedback changed the approach but the description still describes the old one). Use when the user asks to sync, refresh, or fix up a PR's description, or after pushing review-response commits to an open PR.
when_to_use: Also triggered automatically by this plugin's `PostToolUse` hook after a `git push`, when the `pr_sync_enabled` plugin option is on and the branch has an open PR — in that case you'll be told directly to invoke this skill.
disable-model-invocation: false
allowed-tools: Bash(gh pr view:*) Bash(gh pr edit:*) Read Write Agent
model: inherit
effort: medium
context: fork
agent: general-purpose
background: false
argument-hint: '[pr-number]'
---

# pr-description-sync

Keeps a PR's title/description honest about what the code actually does now, without rewriting it wholesale. One read-only subagent does the comparison; you present its findings and only call `gh pr edit` after the user approves.

## Workflow

1. **Confirm there's a PR to check.** Run `gh pr view $ARGUMENTS --json number,title,body,url` (with no `$ARGUMENTS`, this resolves the current branch's PR automatically). If this fails (no `gh` auth, no PR for the current branch, or the given number doesn't exist), say so and stop — don't guess or search for a PR by other means.

2. **Delegate the comparison.** Invoke the `provenance:pr-drift-analyzer` subagent (via the Agent tool) with the PR number and its current title/body. It diffs the actual changes and commit history against the description and returns either "no drift" or a proposed replacement — see `../../agents/pr-drift-analyzer.md` for its exact contract. Don't re-derive the comparison yourself; it already read the diff and commits.

3. **No drift found:** tell the user the description still matches the code, and stop. Don't edit anything.

4. **Drift found — show a before/after.** Present the specific stale claims, what the code shows instead, and the full proposed title/body. This is your confirmation gate — `gh pr edit` changes a shared, visible artifact, so don't run it until the user approves (approving the whole thing or asking for a tweak first are both fine).

5. **Apply on approval.** Write the approved body to a temp file with `Write`, then run `gh pr edit <number> --body-file <path>` (and `--title "..."` if the title also changed). Don't retype the body by hand or try to pipe/heredoc it — same reasoning as `git-committer`'s use of `git commit -F`: the exact text only exists as what the subagent (and any user edits) produced.

6. **Report the result.** Show the PR URL so the user can confirm the update landed.

## Edge cases

- **Multiple PRs / ambiguous branch**: `gh pr view` resolves the current branch's PR automatically; if it reports more than one or none, surface that rather than guessing which one the user means — ask the user to re-run with an explicit `[pr-number]` argument.
- **User pushback on the proposed rewrite**: treat it like any other plan review — adjust and re-show, don't apply a version the user didn't see.
- **Description has a repo template** (checklists, sections like "## Testing"): preserve the template structure; only correct the parts the diff shows are now wrong.
- **PR is a draft**: still fine to sync — drift correction isn't gated on ready-for-review status.

## References

- `../../agents/pr-drift-analyzer.md` — the read-only subagent this skill drives (a plugin-level agent, not skill-local)
