# Default commit-message voice (no learned style yet)

Used when `${CLAUDE_PROJECT_DIR}/.claude/git-committer-style.md` doesn't exist — i.e. `/provenance:git-committer-setup` hasn't been run for this project yet.

- Plain, direct, technical English. No jargon for jargon's sake, no marketing tone, no hedging ("might", "could potentially").
- Imperative mood in the subject: "add", "fix", "remove" — not "added", "adds", "adding".
- Say what changed and why in terms a developer on *this* project would use — reference the actual mechanism (function, module, behavior), not abstract praise ("improves robustness", "enhances quality").
- No slop phrases: "this commit", "in order to", "leverage", "seamless", "robust", "comprehensive", emoji, exclamation marks.
- Short is fine. A one-line body is fine. An empty body is fine when the subject already says everything (e.g. a trivial typo fix) — don't pad it.

Once a style profile exists, it overrides this file's defaults for tone/length/vocabulary; the structural rules in `conventional-commits.md` (type, scope, wrapping, footers) always apply regardless.
