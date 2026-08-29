# AGENTS.md

Instructions for coding agents working in this repository.

## Repository shape

This is a **Claude Code plugin**: a collection of Agent Skills (`SKILL.md` + supporting `references/`, `scripts/`, `assets/`) and subagent definitions (`agents/*.md`), distributed via `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. There is no application code, no build step, and no automated test suite. The deliverable is the Markdown/frontmatter content itself — validate changes by reading them carefully against the specs referenced below, not by compiling or running tests.

## Directory map

| Path | Purpose |
| --- | --- |
| `skills/git-committer/` | Skill that groups a working tree's changes and writes Conventional Commits messages, with user approval before any git mutation |
| `skills/git-committer-setup/` | Companion skill: samples recent commit history into a personalized voice profile |
| `skills/skill-creator/` | Meta-skill for scaffolding and validating other Agent Skills |
| `agents/commit-change-grouper.md` | Read-only subagent invoked by `git-committer` to propose a commit split |
| `agents/commit-message-writer.md` | `Read`-only subagent invoked by `git-committer` to write one commit message per group |
| `.claude-plugin/` | Plugin and marketplace manifests (`plugin.json`, `marketplace.json`) |
| `.github/workflows/release.yml` + `.github/scripts/build_release.py` | Milestone-triggered release automation: builds `CHANGELOG.md`, bumps manifest versions, tags, publishes a GitHub release |

## Editing skills and agents

- Every `SKILL.md` and `agents/*.md` starts with YAML frontmatter. `name` must exactly match its containing directory (for skills) or be a stable identifier (for agents). Keep required fields (`name`, `description`) accurate — `description` is the *only* thing loaded at activation time and is how an agent decides whether to use the skill, so it must state both what the skill does and when to use it.
- Keep `SKILL.md` bodies lean (~500 lines / ~5000 tokens is the working ceiling used elsewhere in this repo). Move detailed or rarely-needed material into `references/*.md` and link to it — don't inline everything, and don't chain references-of-references.
- Subagents in `agents/` are invoked by an orchestrating skill via the Agent tool, never directly by a user. When editing one, preserve its declared `tools`/`disallowedTools` — e.g. `commit-change-grouper` is intentionally read-only (no `Write`/`Edit`) and `commit-message-writer` intentionally has only `Read`. Don't widen these without a reason tied to the workflow.
- `git-committer`'s orchestration logic (grouping → write messages → present full plan → approve → commit group-by-group) is the one place in this repo that performs real, hard-to-reverse actions (`git commit`). Any change to that flow must preserve the pre-commit approval gate.
- Commit message format is governed by `skills/git-committer/references/conventional-commits.md`. `.github/scripts/build_release.py` parses PR titles against the same Conventional Commits shape to build the changelog — if you change the accepted format in one place, check the other.
- If you use `skill-creator` to add a brand-new skill, run its own checklist (`skills/skill-creator/references/checklist.md`) before considering the new skill done.

## Versioning

Don't hand-edit the `version` fields in `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json`, or write `CHANGELOG.md` entries under a new version header by hand — `release.yml` / `build_release.py` do this automatically when a `vX.Y.Z` milestone is closed, sourcing entries from merged PR titles.

## Commits

If you're using this repo's own `git-committer` skill to commit your own changes to it: it will read `skills/git-committer/references/conventional-commits.md` for structure and, if present, `.claude/git-committer-style.md` for voice — don't bypass its plan-then-approve flow.
