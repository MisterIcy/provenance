---
name: subagent-creator
description: Scaffolds and reviews Claude Code subagents (Markdown files with YAML frontmatter under agents/ directories) — specialized helpers with their own system prompt, tool restrictions, and model. Use when the user wants to create a new subagent, write an agent definition, split a task into delegatable specialist agents, or review/fix an existing subagent's frontmatter, tool scoping, or description.
argument-hint: [agent specialization — e.g. "read-only SQL query reviewer" or "commit message writer"]
license: Apache-2.0
metadata:
  author: Alexandros Koutroulis
  version: "0.1"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/validate_agent_frontmatter.py *), Agent(subagent-job-clarifier)
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "${CLAUDE_SKILL_DIR}/scripts/validate_agent_frontmatter.py"
---

## What this skill does

Helps design, scaffold, and validate a **Claude Code subagent**: a Markdown file with YAML frontmatter, stored under an `agents/` directory, that Claude Code can delegate a task to (automatically, by @-mention, or as the whole session). A subagent is a *reusable specialist* — narrow job, own system prompt, its own tool/model/permission scoping — not a one-off task plan.

This skill only carries the authoring workflow inline. Full spec detail lives in `references/subagent-spec.md`, loaded on demand.

**`$ARGUMENTS` is the agent's specialization** (e.g. "read-only SQL query reviewer", "commit message writer"). If invoked with no arguments and the surrounding conversation doesn't already make the specialization obvious, **stop and delegate to `subagent-job-clarifier`** (step 1) before scaffolding anything — don't guess a job description. Reach for `AskUserQuestion` again at any later step below where the user's intent is genuinely ambiguous rather than assuming a default; this skill is about extracting precise, deliberate configuration, not filling in plausible-sounding YAML.

## Workflow

1. **Clarify the job.** Before writing anything, delegate to the `subagent-job-clarifier` agent (`Agent(subagent-job-clarifier)`) unless the specialization and every fact below is already unambiguous from `$ARGUMENTS`/context. Hand it whatever's already known (the specialization, any surrounding context); it interviews the user via `AskUserQuestion` for whatever's missing and returns a structured spec covering:
   - The single, narrow responsibility this agent owns (a grab-bag "does everything" agent won't get delegated to reliably — its description can't be specific)
   - What triggers delegation to it — concrete phrases the `description` needs to contain (e.g. "use proactively after code changes", "use when the user asks to audit X")
   - What it needs to touch — read-only analysis, read+draft/write, or destructive/mutating actions. This decides tool scope (step 4) and color (step 6)
   - Whether it's a one-shot job, a medium multi-step task, or a long/complex investigation. This decides `maxTurns` (step 5)
   - Whether it needs to call other agents, or be called by name from elsewhere. This decides the multi-agent tools in step 4
   Carry its returned spec forward into steps 2–11; if it reports open questions, resolve those with the user directly before proceeding.

2. **Decide placement — this is the step most likely to go wrong.** Ask if not already clear:
   - **`.claude/agents/` (project)** — shared with the team, checked into version control, scoped to this repo. Default choice for anything project-specific.
   - **`~/.claude/agents/` (personal)** — available in every project, not shared. Default choice for a personal workflow helper.
   - **A plugin's own `agents/` directory** — ships to *every* install of that plugin. **Only use this if the user explicitly wants the new agent to become part of a plugin's shipped surface.** If the current working directory is itself a plugin repo (check for `.claude-plugin/plugin.json` — provenance is one example, with its own `agents/` at repo root), do NOT default to dropping a new agent there just because it's convenient. An agent added to a plugin's `agents/` dir goes out to every user of that plugin on the next update; a project- or personal-scope agent does not. When genuinely unsure, ask.
   - Plugin agents are automatically namespaced (`plugin-name:agent-name`) so they don't collide with project/personal agents of the same bare name — but two *different* plugins reusing a generic name (e.g. `reviewer`) can still cause ambiguous @-mentions. Check existing agent names at the target scope before finalizing one.

3. **Name it.** `name` (from `references/subagent-spec.md`):
   - Lowercase letters, digits, hyphens only; cannot start with `-`; cannot contain `:` (reserved for plugin namespacing)
   - Unique within its scope — a same-name project agent silently shadows a personal one

4. **Scope the tools explicitly — never leave `tools`/`disallowedTools` both unset.** Omitting both silently inherits every tool available to subagents; that's almost never the right call for a narrow specialist and hides what the agent can actually do. Work out the list from the agent's job (step 1), and confirm it with the user via `AskUserQuestion` whenever the right scope isn't obvious from the job description:
   - Read-only analyzer/reviewer → `tools: Read, Grep, Glob` (+ `Bash` only if it genuinely needs to run read-only commands)
   - Reads and drafts/writes (e.g. writes a message, a report, a doc, but doesn't touch the target repo's real files) → add `Write`/`Edit` scoped to its own draft output
   - Needs to mutate the working tree or run arbitrary commands → add `Write`/`Edit`/`Bash` explicitly — this is the destructive tier, grant it deliberately
   - Prefer an explicit `tools` allowlist over `disallowedTools` for anything narrow; use `disallowedTools` only to strip one or two specific tools from an otherwise-intentional full-inheritance case
   - **Multi-agent tools** (see `references/tools-reference.md`): if this agent needs to spawn or hand off to other specific agents, add `Agent(agent-name-1, agent-name-2)` — never a bare `Agent`, which allows spawning anything. If it needs to discover what agents/sessions are addressable (e.g. to resume one or message a teammate), add `ListAgents`. If it needs to message another agent, teammate, or session directly, add `SendMessage`. Only add these when the job actually requires cross-agent coordination — most single-purpose specialists need none of them.

5. **Set `maxTurns` — don't leave it unset.** An unset `maxTurns` lets the agent run indefinitely, burning tokens on jobs that should have stopped. Scale it to the job identified in step 1:
   - **5** — one-shot jobs (single lookup, single file write, single message draft)
   - **10** — medium-effort jobs (a few steps of investigation + one action)
   - **20+** — long/complex jobs (multi-file investigation, iterative review, multi-step orchestration)
   Ask the user if the job's effort level isn't clear from the description.

6. **Colorize the agent.** `color` is not cosmetic-only here — treat it as a required signal of blast radius, chosen from the tool scope decided in step 4:
   - **green** — read-only (no `Write`/`Edit`/`Bash` mutation capability)
   - **yellow** — reads and drafts/writes (produces or edits content, but not destructive to existing state — e.g. writes a new report, drafts a message)
   - **red** — can make destructive/irreversible changes (commits, deletes, force-pushes, runs arbitrary `Bash`, edits the working tree)
   - **blue / purple / orange / pink / cyan** — reserve for agents that don't fit the green/yellow/red ladder cleanly: a coordinator that only spawns other agents and never touches files itself, a pure research/read-external-web agent, a scheduling/notification agent, etc. Pick consistently within a project (e.g. always `purple` for coordinators) rather than arbitrarily.

7. **Decide `memory` explicitly — always ask, never assume.** Do not default to no memory (`memory` unset or `false`) without confirming with the user via `AskUserQuestion`: does this agent need to persist anything across separate invocations/sessions (e.g. a learned style profile, accumulated findings)? If yes, pick `user`/`project`/`local` per `references/subagent-spec.md`; if the user explicitly wants no persistence, set `memory: false` so the choice is visible in the file rather than silently defaulted.

8. **Decide `skills` — only when the agent genuinely needs one preloaded.** Most agents should leave `skills` unset; only add specific skill names here when the agent's job requires that skill's full content available at startup (not just as something it could look up) — this trades a fixed token/time cost at every invocation for saving a discovery step. Don't add a skill "just in case."

9. **Pick a model.** Prefer an alias (`sonnet`/`opus`/`haiku`/`fable`) over a full model ID, or omit the field entirely (defaults to `inherit` — same model as the calling session). Pin a full ID only when there's a concrete reason (cost-sensitive high-volume agent → `haiku`; needs the strongest reasoning → `opus`).

10. **Write the body.** The body is the subagent's **entire** system prompt — it does not inherit Claude Code's main system prompt, tone guidance, or any of this conversation's context. State explicitly: its job, expected inputs, output shape, and boundaries (what it must never do — e.g. "read-only, never runs git commands", "never contacts external services"). Use `assets/AGENT.template.md` as a starting point.

11. **Write the description last, tune it hardest.** This is the single field automatic delegation reads. It must say *when* to use this agent with concrete trigger phrases, and implicitly *when not to* — check it doesn't overlap with an existing agent's triggers at the same scope (overlapping descriptions cause flaky, unpredictable delegation between the two).

12. **Validate before calling it done.**
    - Run `${CLAUDE_SKILL_DIR}/scripts/validate_agent_frontmatter.py <path-to-agent.md>` — checks frontmatter against the documented fields/types (name format, description presence + trigger phrasing, tools/disallowedTools presence, maxTurns, model/permissionMode/memory/effort/color/hooks validity, unknown keys) and exits non-zero on any error. Also runs automatically as a `PostToolUse` hook on `Edit`/`Write` while this skill is active.
    - Then walk `references/checklist.md` for placement, tool-scoping, and safety checks the script can't verify mechanically.

13. **Report what you built**: file path, scope (project/personal/plugin), how it's invoked (auto-delegation on description match, `@agent-name`, or `--agent name` for session-wide use), and any manual step needed (e.g. workspace trust for `hooks`/`mcpServers` at project scope).

## References

- `references/subagent-spec.md` — full frontmatter field reference, file discovery/priority order, invocation methods, tool-scoping syntax, best practices
- `references/tools-reference.md` — condensed built-in tools list, read-only vs mutating vs multi-agent-coordination tools, and the `Agent(name1, name2)` restriction syntax
- `references/checklist.md` — pre-flight checklist covering frontmatter, body completeness, placement/collision, and safety
- `scripts/validate_agent_frontmatter.py` — validates an agent file's frontmatter against the documented spec; also wired as this skill's own `PostToolUse` hook
- `assets/AGENT.template.md` — copy-paste starting point for a new subagent definition

## Common mistakes to avoid

- Scaffolding a job description the user never actually gave — if `$ARGUMENTS`/context doesn't specify the specialization, delegate to `subagent-job-clarifier` first.
- Description too vague ("helps with code") or missing an explicit trigger phrase — automatic delegation will rarely or never fire.
- Writing an agent that does several unrelated things — split it into separate narrow agents with distinct, non-overlapping descriptions instead.
- Leaving both `tools` and `disallowedTools` unset "to keep it simple" — this silently grants full tool inheritance; state the scope explicitly every time.
- Leaving `maxTurns` unset — pick 5/10/20+ per the job's effort level (step 5), don't let an agent run unbounded.
- Adding `skills` "just in case" — only preload a skill the agent's job actually requires at startup.
- Assuming no persistent `memory` is wanted without asking — always confirm with the user, don't silently default.
- Skipping `color`, or picking one arbitrarily — it's the at-a-glance blast-radius signal (green=read-only, yellow=read+draft, red=destructive; blue/purple/orange/pink/cyan for special cases like coordinators).
- Giving a coordinator/delegating agent a bare `Agent` tool instead of `Agent(specific-name-1, specific-name-2)` — a bare grant lets it spawn anything.
- **Dropping a new agent into a plugin's own `agents/` directory just because the current repo happens to be a plugin** — that ships it to every install. Confirm the user actually wants it in the plugin's shipped surface; otherwise use `.claude/agents/` (project) or `~/.claude/agents/` (personal).
- Assuming the body inherits Claude Code's system prompt or the current conversation's context — it doesn't; the agent starts with only what's written in its own file.
- Forgetting that `hooks` and `mcpServers` at project scope (`.claude/agents/`) require workspace trust to activate.
