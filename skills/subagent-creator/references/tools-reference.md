# Built-in tools reference (condensed)

Source: https://code.claude.com/docs/en/tools-reference — condensed for tool-scoping decisions when authoring a subagent. Re-fetch if this drifts.

## Read-only tools (safe for a `green` agent)

`Glob`, `Grep`, `Read`, `CronList`, `TaskList`, `TaskGet`, `LSP`, `ListAgents`, `ListMcpResourcesTool`, `WebSearch`, `WebFetch`, `ReadMcpResourceTool`, `ReportFindings`, `ScheduleWakeup`, `SendFeedback`, `AskUserQuestion`

## Mutating tools (push an agent toward `yellow` or `red`)

`Write`, `Edit`, `Bash`, `PowerShell`, `NotebookEdit`, `Agent`, `Artifact`, `CronCreate`, `CronDelete`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `RemoteTrigger`, `SendMessage`, `ShareOnboardingGuide`, `Skill`, `TaskCreate`, `TaskUpdate`, `TaskStop`, `Workflow`, `EndConversation`

Not every mutating tool is *destructive* in the same sense — draw the yellow/red line by what the mutation touches:
- **yellow** (reads + drafts/writes, not destructive to existing state): `Write`/`Edit` scoped to the agent's own new output (a report, a draft message, a new file), `Artifact`
- **red** (can destroy or irreversibly change existing state): `Bash` (arbitrary commands), `Write`/`Edit` against the working tree or existing files, `EnterWorktree`/`ExitWorktree`, `CronCreate`/`CronDelete`, `TaskStop`, `EndConversation`

## Multi-agent coordination tools

`Agent`, `SendMessage`, `ListAgents`, `Workflow` — grant only when the agent's job genuinely requires calling or coordinating with other agents/sessions:

- **`Agent(name1, name2)`** — spawns a subagent. Always scope to specific agent names the coordinator is allowed to invoke; a bare `Agent` (no parens) permits spawning *any* subagent type, which defeats least-privilege scoping for a coordinator role.
- **`ListAgents`** — read-only; lists addressable agents/sessions (subagents spawned, teammates, other local/cloud sessions). Grant when the agent needs to discover what's running before messaging or resuming one — not needed if it only ever spawns fresh agents itself.
- **`SendMessage`** — sends a message to a teammate, a previously spawned subagent, or another session. Grant when the agent needs to hand off work, resume a running agent, or communicate results outside its own return value.
- **`Workflow`** — runs a deterministic multi-agent orchestration script. Only relevant for an agent whose entire job is running/managing workflows; most specialists never need this.

## Permission rule syntax

```
Read(~/secrets/**)           # path pattern (Read, Edit, Write, Glob, Grep, LSP, NotebookEdit)
Bash(npm run *)              # command pattern (Bash, PowerShell, Monitor)
WebFetch(domain:example.com) # domain pattern (WebFetch)
Agent(name1, name2)          # specific subagent/teammate names (Agent, and Skill for skill names)
Artifact                     # bare name — most tools take no specifier
```

## Resolution logic for `tools`/`disallowedTools`

- **Neither set** → inherits every tool available to subagents (rarely correct for a narrow specialist — state the scope explicitly instead, per the main workflow)
- **`tools` only** → gets only the listed tools
- **`disallowedTools` only** → gets everything except the listed tools
- **Both set** → `disallowedTools` wins on any conflict

## Notes relevant to subagent authoring

- `Edit(...)` on a path also grants read access to that path; a `Read(deny)` rule also blocks `Edit`/`Write` there.
- `Monitor` follows the same permission patterns as `Bash`; `NotebookEdit` follows the same path patterns as `Edit`.
- `TaskCreate`/`TaskList`/`TaskGet`/`TaskUpdate`/`TodoWrite` are excluded on Opus 4.8+ unless the session opts in via `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` — don't rely on them for an agent meant to run under that model tier.
- `EndConversation` cannot be blocked via `disallowedTools` — don't rely on denying it as a safety measure.
