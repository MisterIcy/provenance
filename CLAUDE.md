# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

`provenance` is a **Claude Code plugin** (see `.claude-plugin/plugin.json` / `marketplace.json`), not an application. It has no build step, no compiled artifacts, and no test suite — its content *is* the product: Agent Skills (`SKILL.md` files) and subagent definitions consumed directly by Claude Code at runtime. Changes here are validated by reading/reasoning about the Markdown+frontmatter files, not by running a compiler.

## Commands

There is no build/lint/test tooling. The only executable script in the repo is:

```bash
skills/git-committer-setup/scripts/ingest-commits.sh [count]   # dumps last N commits by git user.email for style-profile ingestion
```

Releases are cut via GitHub Actions (`.github/workflows/release.yml`), triggered by closing a milestone named `vX.Y.Z`; `.github/scripts/build_release.py` regenerates `CHANGELOG.md` from merged PR titles (parsed as Conventional Commits) and bumps the version in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Don't hand-bump those version fields — the workflow does it.

## Architecture

The plugin ships three skills: two for git workflow automation, plus a meta-skill for authoring other skills:

- **`skills/git-committer/`** — the main entry point. `SKILL.md` orchestrates a two-subagent pipeline to turn the working tree into Conventional-Commits-formatted commits:
  1. `agents/commit-change-grouper.md` (read-only, sonnet) — inspects `git status`/`git diff` and proposes how to split pending changes into logical commit groups. It never touches git state.
  2. `agents/commit-message-writer.md` (haiku, `Read`-only) — given one group's diff + rationale, writes a single commit message following `skills/git-committer/references/conventional-commits.md` and either a learned voice profile or `references/style-voice-guidelines.md`.
  The orchestrating skill (the only actor allowed to run `git add`/`git apply`/`git commit`/`git push`) presents the full multi-commit plan, then executes group-by-group, writing each message to a temp file and committing with `git commit -F`, followed by `git push`. Whether each of those two calls actually needs the user's approval is enforced at the tool-permission layer, not by the skill's own judgment: `hooks/scripts/guard-git-commit.sh` and `hooks/scripts/guard-git-push.sh` are `PreToolUse` hooks (registered in `hooks/hooks.json`) that inspect the `git_committer_auto_commit` / `git_committer_auto_push` plugin options and return an explicit `"ask"` or `"allow"` permission decision for that call, overriding whatever the session's permission mode would otherwise do.

- **`skills/git-committer-setup/`** — one-time/refresh companion skill. Runs `ingest-commits.sh` to sample the current author's recent commits and writes a personalized voice profile to `.claude/git-committer-style.md` (gitignored/local, not committed here), which `git-committer` picks up automatically. Only triggers on an explicit user request — never inferred.

- **`skills/skill-creator/`** — a meta-skill for scaffolding and validating other Agent Skills (per the open agentskills.io spec, with a `references/claude-code-extensions.md` doc for CC-specific frontmatter). Now shipped as a first-class plugin skill, available wherever the `provenance` plugin is installed. Use it when authoring new skills in any repository.

- **`monitors/branch-merge-watch`** (`monitors/monitors.json` → `monitors/scripts/watch-branch-merge.sh`) — a background monitor, not a skill: Claude Code starts it automatically whenever the plugin is enabled, and it never runs through the agent's tool-permission loop. It polls whether the current branch has been merged into the repo's default branch (ancestor check for a plain merge/fast-forward, `gh pr list --state merged` for a squash-merged GitHub PR) and, if the working tree is clean, checks out the default branch and pulls without asking. Entirely gated by the `branch_merge_monitor_enabled` plugin option (off by default); the check cadence is `branch_merge_check_interval_seconds`. Because monitor processes don't receive `CLAUDE_PLUGIN_OPTION_*` env vars or `${user_config.*}` substitution (unlike hooks), the script reads both options straight out of `~/.claude/settings.json` on every loop iteration instead.

### Key conventions across the skill/agent files

- Frontmatter fields like `context: fork`, `agent:`, `tools:`/`allowed-tools:`, `disallowedTools:`, and `model:` (sonnet for the grouper, haiku for the writer) are deliberate — the grouper needs repo-reading tools and no write access, the writer needs only `Read`.
- Subagents in `agents/` are invoked *by* the orchestrating skill via the Agent tool; they are explicitly documented as "not meant to be invoked directly by a user."
- Reference material (`references/*.md`) is kept out of `SKILL.md` bodies to preserve progressive disclosure — only load it when the workflow step says to.
- All commit messages produced by this pipeline must conform to `skills/git-committer/references/conventional-commits.md`, which is also the format `build_release.py` parses when generating changelog entries — keep the two in sync if either changes.
