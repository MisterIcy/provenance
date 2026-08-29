# Pre-flight checklist

Run through before calling a new subagent done.

## Frontmatter
- [ ] Run `scripts/validate_agent_frontmatter.py <path-to-agent.md>` — catches the mechanical checks below
- [ ] `name` present: lowercase letters and hyphens only, doesn't start with `-`, contains no `:`
- [ ] `name` matches the intended @-mention / delegation identifier
- [ ] `description` present and states both *when* to delegate and, implicitly, when not to (no overlap with another agent's trigger phrases)
- [ ] `model` uses an alias (`sonnet`/`opus`/`haiku`/`fable`) or `inherit`, not a hardcoded full model ID, unless there's a specific reason to pin
- [ ] `tools` and/or `disallowedTools` are **explicitly set** — never both left unset — and reflect real least-privilege for the job, either derived from the agent's purpose or confirmed with the user
- [ ] `maxTurns` is set, scaled to effort: 5 (one-shot), 10 (medium), 20+ (long/complex) — not left unset
- [ ] `skills` is only set if the agent's job genuinely requires that skill's full content preloaded at startup — not added speculatively
- [ ] `memory` was explicitly decided with the user (asked, not assumed) — set to `user`/`project`/`local` if persistence is wanted, or `false` if the user confirmed none is needed
- [ ] `color` is set and matches the tool scope: `green` (read-only), `yellow` (read + draft/write, non-destructive), `red` (destructive/mutating), or one of `blue`/`purple`/`orange`/`pink`/`cyan` for a genuinely special case (e.g. pure coordinator) — chosen consistently, not arbitrarily
- [ ] If this agent calls other agents: `tools` includes `Agent(specific-name-1, specific-name-2)` (never a bare `Agent`), plus `ListAgents` and/or `SendMessage` only if it actually needs to discover or message other agents/sessions
- [ ] If `hooks` or `mcpServers` is used at project scope: confirm this repo is trusted, since both require workspace trust

## Body (system prompt)
- [ ] The body is the agent's *entire* system prompt — it does not inherit the main Claude Code system prompt. Anything the agent needs to know (constraints, output format, what NOT to do) must be written here explicitly.
- [ ] States what the agent should do, its inputs/outputs, and its boundaries (what it must NOT touch — e.g. "read-only, never runs git commands")
- [ ] No task-specific one-off state — a subagent definition is reusable, not a scratch note for the current task

## Scope & placement
- [ ] Confirmed target location with the user: `.claude/agents/` (project, shared/committed), `~/.claude/agents/` (personal), or a plugin's `agents/` dir (ships with that plugin to every install)
- [ ] If this repo IS a plugin (like provenance): a new agent only goes into the plugin's own `agents/` directory when the user explicitly wants it to ship with the plugin to every installer — otherwise it belongs in `.claude/agents/` (this project only) or `~/.claude/agents/` (personal), so it doesn't silently become part of the plugin's shipped surface
- [ ] `name` doesn't collide with an existing agent name the user already relies on at the same or a higher-priority scope (managed > CLI > project > personal > plugin) — a same-name project agent silently shadows a personal one; plugin agents are pre-namespaced so they don't collide, but a bare mention could still resolve ambiguously if two plugins both use the same generic name

## Safety
- [ ] No secrets, tokens, or credentials embedded
- [ ] No hardcoded machine-specific paths (unless explicitly a personal, single-machine agent)
- [ ] Destructive tools (`Bash`, `Write`, `Edit`) are only granted when the agent's job genuinely requires mutation — read-only agents (reviewers, analyzers, auditors) should not carry them

## Sanity test
- [ ] Would the `description` alone cause Claude to correctly auto-delegate to this agent for a realistic prompt, and *not* delegate for an unrelated one?
- [ ] Does the body give the agent everything it needs to act correctly with zero conversation history (it starts with none)?
- [ ] Try invoking it once (automatic delegation or explicit @-mention) and confirm the tool restrictions actually hold (e.g. a read-only agent can't be coaxed into writing)
