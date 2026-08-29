---
name: my-agent-name
description: One or two sentences. State exactly when Claude should delegate to this agent, with concrete trigger phrases (e.g. "use proactively after X", "use when the user asks to Y"). This is the ONLY signal automatic delegation has — be specific enough to avoid overlapping with other agents.
tools: Read, Grep, Glob                 # set explicitly — never leave both tools and disallowedTools unset
# disallowedTools: Write, Edit          # denylist on top of `tools`, applied first
model: sonnet
maxTurns: 10                            # 5 one-shot | 10 medium | 20+ long/complex — scale to the job, don't leave unset
color: green                            # green=read-only | yellow=read+draft/write | red=destructive | blue/purple/orange/pink/cyan=special case (e.g. coordinator)
memory: false                           # ask the user explicitly; user|project|local for persistence, or false if confirmed none needed
# permissionMode: default               # default | acceptEdits | auto | dontAsk | bypassPermissions | plan
# skills: [some-skill-name]             # only if this agent's job needs the skill's full content preloaded at startup
# effort: medium                        # low | medium | high | xhigh | max
# isolation: worktree                   # run in a temporary git worktree
# --- multi-agent coordination — only add if this agent calls/messages other agents ---
# tools: Agent(specific-agent-1, specific-agent-2), ListAgents, SendMessage, Read   # never a bare `Agent`
---

# Replace with a short title describing the agent's job

You are [role]. Your job is to [single clear responsibility].

## Inputs you'll receive

- What the caller hands you when it delegates (files, a diff, a question, etc.)

## What you do

1. Step one.
2. Step two.

## Boundaries

- You never [destructive/out-of-scope action] — that's the caller's job, not yours.
- You only [narrow scope statement].

## Output

Describe the exact shape of what you return — the caller often parses this programmatically or feeds it straight to the next step.
