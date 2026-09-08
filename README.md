# provenance

A [Claude Code](https://claude.com/claude-code) plugin providing skills and agents for building well-formed Agent Skills, and for generating well-split, [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)-formatted git commits.

## What's included

| Skill | Summary |
| --- | --- |
| `git-committer` | Groups the working tree's pending changes into logically separate commits and writes Conventional Commits-formatted messages for each, with your approval before anything is committed. |
| `git-committer-setup` | One-time (or refresh) setup that learns your commit style from recent history, so `git-committer` matches your voice. |
| `pr-description-sync` | Checks an open PR's title/description against its actual diff and fixes it up if it has drifted. |
| `skill-creator` | Scaffolds and validates new Agent Skills against the [agentskills.io](https://agents.md/) standard. |
| `subagent-creator` | Scaffolds and reviews Claude Code subagents. |
| `mariadb-sql` | MariaDB dialect reference for reviewing/tuning SQL. |
| `phpunit` | PHPUnit reference for writing, running, and debugging tests. |

See the [wiki](https://github.com/MisterIcy/provenance/wiki/Skills) for a full description of each skill.

## Installing

Add this repository as a plugin marketplace source in Claude Code and install the `provenance` plugin, or clone it directly into a project's `.claude/skills/` (or `~/.claude/skills/`) if you only want individual skills.

## Repository layout

```
skills/                    # user-facing skills (see the wiki for the full list)
agents/                    # subagents invoked by the skills above
monitors/                  # background monitors started automatically when the plugin is enabled
.claude-plugin/            # plugin/marketplace manifests
.github/workflows/         # release automation (milestone-triggered)
```

## Releases

Releases are cut automatically: closing a GitHub milestone titled `vX.Y.Z` triggers a workflow that builds the changelog entry from merged PR titles, bumps the plugin manifest versions, tags, and publishes a GitHub release.

## License

Apache-2.0 — see [LICENSE](LICENSE).
