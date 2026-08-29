# provenance

A [Claude Code](https://claude.com/claude-code) plugin providing skills and agents for building well-formed Agent Skills, and for generating well-split, [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)-formatted git commits.

## What's included

### `git-committer`

Turns your working tree into one or more clean, well-scoped commits. It:

1. Inspects `git status`/`git diff` and groups the pending changes into logically separate commits (splitting a single file into hunks when it mixes unrelated edits).
2. Writes a Conventional Commits-formatted message for each group, in a plain, developer-readable voice.
3. Shows you the full plan — files and exact commit messages — before touching git, so you approve (or adjust) it first.
4. Commits each group only after approval.

Trigger it explicitly ("commit these changes", "split this into commits") or just by wrapping up a work session with uncommitted changes.

### `git-committer-setup`

One-time (or refresh) setup that samples your recent commit history and writes a personalized style profile (`.claude/git-committer-style.md`) so `git-committer` matches your actual voice instead of a generic default. Run it explicitly, e.g. "learn my commit style" or `/provenance:git-committer-setup`.

### `skill-creator`

A meta-skill for scaffolding and validating new Agent Skills — following the open [agentskills.io](https://agents.md/) standard, with extra guidance for Claude Code-specific frontmatter. Use it when you want to create a new `SKILL.md` or review/fix an existing one.

## Installing

Add this repository as a plugin marketplace source in Claude Code and install the `provenance` plugin, or clone it directly into a project's `.claude/skills/` (or `~/.claude/skills/`) if you only want individual skills.

## Repository layout

```
skills/                    # user-facing skills (git-committer, git-committer-setup)
agents/                    # subagents invoked by the git-committer skill
.claude/skills/skill-creator/  # vendored meta-skill for authoring skills
.claude-plugin/            # plugin/marketplace manifests
.github/workflows/         # release automation (milestone-triggered)
```

## Releases

Releases are cut automatically: closing a GitHub milestone titled `vX.Y.Z` triggers a workflow that builds the changelog entry from merged PR titles, bumps the plugin manifest versions, tags, and publishes a GitHub release.

## License

Apache-2.0 — see [LICENSE](LICENSE).
