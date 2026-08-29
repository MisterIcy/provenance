# Subagent file format reference

Source: https://code.claude.com/docs/en/sub-agents — condensed. Re-fetch if this drifts.

## File locations & scope (priority order, highest first)

| Location | Scope | Use case |
| --- | --- | --- |
| Managed settings | Organization-wide | deployed centrally |
| `--agents` CLI flag | Current session | ad-hoc JSON at launch |
| `.claude/agents/` | Current project | team-shared, check into version control |
| `~/.claude/agents/` | All your projects | personal, cross-project |
| Plugin `agents/` directory | Wherever plugin enabled | ships with a plugin |

- Project agents are discovered walking up from cwd; nested dir wins on name clash.
- Plugin agents are namespaced (`plugin-name:agent-name`) — they don't collide with project/personal agents of the same bare name.
- Both project and personal scopes support recursive subfolders; subfolder path doesn't affect identity (name is still the identifier).

## File structure

Markdown with YAML frontmatter. The body becomes the subagent's **entire** system prompt — not the full Claude Code system prompt, just what's written here.

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices. Use proactively after code changes.
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

A file is silently skipped (no error) if: no `name` field, opening `---` isn't the first line, `name` starts with `-` or contains `:`, `name` present but no `description`, or YAML parsing fails. The last three cases do log to the debug log — check it if an agent isn't showing up.

## Required fields

- **`name`** — lowercase letters and hyphens only. Cannot start with `-` or contain `:` (`:` is reserved for plugin-scoped identifiers). Unique identifier used in @-mentions, CLI, logs.
- **`description`** — tells Claude *when* to delegate to this subagent. Include explicit triggers ("use proactively after X", "use when the user asks Y") — this is the only signal automatic delegation has. Keep it short; put procedural detail in the body instead. Combined subagent descriptions across the whole session should stay under ~15,000 tokens, so don't pad this field.

## Optional fields

All optional per the documented spec — but this skill's own workflow (see `SKILL.md`) treats `tools`/`disallowedTools`, `maxTurns`, `color`, and `memory` as fields that must be *deliberately* set (explicitly stated or confirmed with the user), not left to their permissive defaults. `references/tools-reference.md` has the full built-in tool list and multi-agent coordination tool guidance (`Agent(name1, name2)`, `ListAgents`, `SendMessage`).

| Field | Type | Notes |
| --- | --- | --- |
| `tools` | comma-list or array | Default: inherits every tool available to subagents. Exact names or MCP patterns (`mcp__server`, `mcp__server__*`, `mcp__*`). `Agent(name1, name2)` restricts which subagent types this agent can itself spawn. |
| `disallowedTools` | comma-list or array | Denylist, applied *before* the `tools` allowlist resolves. |
| `model` | string | Alias (`sonnet`/`opus`/`haiku`/`fable`, recommended), full model ID, or `inherit` (default). Resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var → per-invocation param → this field → main conversation's model. |
| `permissionMode` | string | `default`/`acceptEdits`/`auto`/`dontAsk`/`bypassPermissions`/`plan`. Inherits main conversation's mode by default; parent's `bypassPermissions`/`acceptEdits` takes precedence over a weaker value set here. |
| `maxTurns` | integer | Cap on agentic turns; on hitting it the subagent returns a partial-output marker and can be resumed via SendMessage. |
| `skills` | array of skill names | Preloads full skill content into the subagent's context at startup (not just the description). |
| `mcpServers` | array of names or inline defs | MCP servers scoped to this subagent only. Project-level (`.claude/agents/`) requires workspace trust. |
| `hooks` | object | `PreToolUse`/`PostToolUse`/`Stop` only. Project-level requires workspace trust. |
| `memory` | `user`/`project`/`local` | Persistent memory across sessions, stored under `~/.claude/agent-memory/<name>/`, `.claude/agent-memory/<name>/`, or `.claude/agent-memory-local/<name>/` respectively. |
| `background` | boolean | Default `false`. `true` keeps the subagent running in the background even if the caller requests foreground. |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` | Overrides session effort for this subagent. |
| `isolation` | `worktree` | Runs in a temporary git worktree branched from the default branch; auto-cleaned if unchanged. |
| `color` | one of 8 named colors | Cosmetic, task-list/transcript display only. |
| `initialPrompt` | string | Auto-submitted as first user turn — only relevant when this agent is launched as the *main* session via `--agent`/`agent` setting, not for subagent delegation. |
| `experimental` | object | e.g. `experimental: { cacheTtl: 5m }`. Subject to change. |

## Tool configuration patterns

Read-only allowlist:
```yaml
tools: Read, Grep, Glob
```

Denylist on top of full inheritance:
```yaml
disallowedTools: Write, Edit
```

Restrict which subagents this one can spawn:
```yaml
tools: Agent(worker, researcher), Read, Bash
```

MCP scoping:
```yaml
disallowedTools: mcp__github, mcp__slack__*
```

## Invocation

- **Automatic delegation** — Claude matches the task against every available subagent's `description` and picks one. This is the primary path; a vague description means it never fires.
- **@-mention** — `@"code-reviewer (agent)"` or `@agent-code-reviewer` guarantees invocation regardless of description quality.
- **Session-wide as main thread** — `claude --agent code-reviewer`, or `"agent": "code-reviewer"` in settings.json. Different use case from delegation: this makes the subagent *the* session, not a helper spawned within one.
- **CLI-defined (ephemeral)** — `claude --agents '{"name": {...}}'` accepts a JSON object with `description`, `prompt`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `isolation`.

## Best practices (from the docs)

1. Keep `description` short and trigger-focused; put detail in the body.
2. Store team subagents in `.claude/agents/` and commit them; personal ones in `~/.claude/agents/`.
3. Prefer model aliases over full model IDs for flexibility across model releases.
4. Restrict tools intentionally — allowlist for read-only analyzers, denylist to remove one or two dangerous tools from an otherwise-full set.
5. Write `description` so Claude can tell not just when to use this agent but when *not* to (avoid overlap with another agent's trigger phrases — overlapping descriptions cause flaky delegation).
