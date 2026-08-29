---
name: git-committer-setup
description: One-time (or refresh) setup for the git-committer skill — ingests the N most recent commits by the current git author and writes a personalized commit-message style profile for this project. Use only when the user explicitly asks to set up, configure, calibrate, or personalize git-committer, or to (re)learn their commit style.
argument-hint: "[commit-count, default 30]"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/ingest-commits.sh *) Read Write
---

# git-committer setup

Builds `${CLAUDE_PROJECT_DIR}/.claude/git-committer-style.md` — a short profile the `git-committer` skill's `commit-message-writer` subagent reads to match the project author's actual voice instead of a generic default. Re-run any time to refresh it (e.g. after conventions change).

## Steps

1. Determine the commit count: `$0` if given (an integer), otherwise `30`.
2. Run `${CLAUDE_SKILL_DIR}/scripts/ingest-commits.sh <count>`. It prints the N most recent commits by the configured `git config user.email`, falling back to all authors if that author has fewer than 5 commits in this repo (it says so on stderr — pass that caveat along to the user).
3. Read through the returned subjects and bodies yourself (you, the main agent — no subagent needed for this) and derive a short profile covering only what's actually observable in the sample:
   - **Type/scope usage** — do they already use Conventional Commits? Which types and scopes show up, if any?
   - **Subject style** — imperative vs. not, typical length, capitalization, trailing punctuation.
   - **Body habits** — do they usually write a body at all? Typical length, wrapping, bullet vs. prose.
   - **Vocabulary/tone** — formal vs. terse vs. casual; any recurring phrases; anything they conspicuously avoid.
   - **Anything else concrete and repeated** — don't invent patterns from a handful of outliers; if the sample is too small or inconsistent to say something with confidence, say so instead of guessing.
4. Write the profile to `${CLAUDE_PROJECT_DIR}/.claude/git-committer-style.md`, plain prose/bullets, no more than ~40 lines. Note at the top the sample size and date, e.g. "Derived from the 30 most recent commits by <email> on <date>."
5. Confirm to the user: where the profile was written, the sample size actually used (including the fallback note if it applies), and that `git-committer` will pick it up automatically on its next run.

## Notes

- This only reads git history — it never modifies commits or files other than the profile itself.
- If the repo has no commits yet, say so and stop; there's nothing to learn from.
- The structural rules in `../git-committer/references/conventional-commits.md` are never overridden by this profile — the profile only tunes tone/length/vocabulary, not the type/scope/footer format.
