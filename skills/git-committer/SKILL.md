---
name: git-committer
description: Discovers the current git diff, groups related changes into logically separate commits, and writes Conventional Commits-formatted messages in plain developer-readable language (personalized to the project author's style if git-committer-setup has been run). Use when the user asks to commit changes, split their working tree into commits, or write commit messages.
when_to_use: Also trigger when wrapping up a work session, finishing a task, or switching to something else and the working tree has uncommitted changes worth capturing — e.g. "I'm done for now", "let's wrap up", "before I switch tasks", not just an explicit "commit this" request. Whether committing and pushing require your approval first depends on the `git_committer_auto_commit` / `git_committer_auto_push` plugin options — see the workflow below.
argument-hint: "[optional: focus hint, e.g. a path or theme to prioritize]"
disable-model-invocation: false
allowed-tools: Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git apply:*) Bash(git commit:*) Bash(git push:*) Bash(git rev-parse:*) Read Write
model: inherit
effort: medium
context: fork
agent: general-purpose
background: false
---

# git-committer

Turns the current working tree into one or more well-formed commits. Two subagents do the analysis and writing; you (the invoking agent) orchestrate them and are the only one who actually touches git state. Committing and pushing are each independently configurable via the `git_committer_auto_commit` and `git_committer_auto_push` plugin options — but that's not just a rule you're expected to follow: `hooks/scripts/guard-git-commit.sh` and `hooks/scripts/guard-git-push.sh` are registered as `PreToolUse` hooks on `git commit`/`git push` and force a real approval prompt whenever the relevant option is off (or hand back `allow` to skip it when the option is on), regardless of the session's permission mode. So the plan-presentation steps below are about giving the user useful context before that prompt fires, not about you deciding whether to ask.

## Workflow

1. **Check for changes.** Run `git status --porcelain=v1`. If there's nothing staged, unstaged, or untracked, say so and stop.

2. **Check for a style profile.** Look for `${CLAUDE_PROJECT_DIR}/.claude/git-committer-style.md`.
   - If present, note it exists and pass its path along to the message writer later.
   - If absent, mention once that running `/provenance:git-committer-setup` will personalize commit voice for this project, then continue using `references/style-voice-guidelines.md` as the default voice.

3. **Group the changes.** Invoke the `provenance:commit-change-grouper` subagent (via the Agent tool) with the current git status output and, if the user gave `$ARGUMENTS`, that as a focus hint (e.g. "prioritize keeping changes under src/auth together"). It returns a numbered grouping plan (files/hunks, rationale, diff excerpt per group) — see `agents/commit-change-grouper.md` for its exact contract. Don't re-derive the grouping yourself; if its plan looks wrong, send it back with what's wrong rather than overriding it silently.

4. **Write one message per group.** For each group in the plan, invoke the `provenance:commit-message-writer` subagent (haiku) with: that group's diff excerpt and rationale, the path `${CLAUDE_SKILL_DIR}/references/conventional-commits.md`, and the path to the style profile if one exists (otherwise `${CLAUDE_SKILL_DIR}/references/style-voice-guidelines.md`). Use the absolute `${CLAUDE_SKILL_DIR}`-rooted paths, not bare relative ones — the subagent resolves paths against the session, not this skill's directory, and once the plugin is installed elsewhere a relative `references/...` path won't exist. Collect the returned message for each group.

5. **Present the full plan.** Show the user, for every group: which files/hunks, and the exact commit message that will be used, then proceed to step 6 — `guard-git-commit.sh` is what actually decides whether `git commit` needs a real approval prompt from here, not this step.

6. **Execute, one group at a time:**
   - Stage exactly that group's files. If a file needs a hunk-level split (the grouper will have flagged this), build a patch covering only the group's hunks and apply it with `git apply --cached` — `git add -p` is interactive and can't be driven through the Bash tool, so treat the patch approach as primary, not a fallback.
   - Write the writer's exact message (verbatim, including wrapping/footers) to a temp file with `Write`, then commit with `git commit -F <path-to-that-file>`. Don't retype the message by hand, and don't try to pipe or heredoc it into `git commit` — the message only exists as the subagent's returned text, so it has to go through a file. If `git_committer_auto_commit` is off, this call surfaces the guard hook's approval prompt; if the user declines it, stop and report that rather than retrying.
   - Move to the next group only after the commit succeeds.

7. **Push.** Run `git push` (or, if the branch has no upstream yet — check with `git rev-parse --abbrev-ref --symbolic-full-name @{u}` failing — `git push -u origin HEAD`). Just like the commit step, `guard-git-push.sh` decides whether this needs a real approval prompt (gated on `git_committer_auto_push`, independent of `git_committer_auto_commit`); if the user declines it, stop and report that rather than retrying.

8. **Report the result.** Show `git log --oneline -n <number of commits made>` and `git status` (and, if you pushed, confirm the push succeeded) so the user can see the final state.

## Edge cases

- **Mixed staged + unstaged changes**: treat both as candidates for grouping; the grouper should account for what's already staged rather than ignoring it.
- **Untracked files**: include them in the grouping only if they're clearly part of the pending work (new source files, not build artifacts/junk) — flag anything that looks like it shouldn't be committed (secrets, local config, build output) instead of silently including it.
- **Binary files / renames**: pass them through to the grouper as-is; `git diff` handles renames and binary markers, the grouper just needs to place them in a sensible group.
- **No git user configured**: `git commit` will fail — tell the user to run `git config user.name`/`user.email` rather than guessing values.
- **Merge/rebase in progress**: don't attempt to commit; tell the user to resolve or abort the in-progress operation first.
- **User's `$ARGUMENTS` conflicts with a sensible split**: prefer correctness over the hint — tell the user why you deviated.

## References

- `references/conventional-commits.md` — the commit format both subagents must follow
- `references/style-voice-guidelines.md` — default tone/voice when no learned profile exists
- `agents/commit-change-grouper.md`, `agents/commit-message-writer.md` — the two subagents this skill drives
