# Claude Code-specific skill behavior

Source: https://code.claude.com/docs/en/skills — condensed. Claude Code follows the open agentskills.io spec and layers extra fields/behavior on top. Re-fetch the source if this drifts, especially version-gated behaviors noted below.

**Portability warning:** everything in this file is a Claude Code extension. A skill using any field here will fail hard validation if uploaded to claude.ai, the Skills API, or packaged with `package_skill.py` — those paths only accept the six spec fields (see `agent-skills-spec.md`). Only use these fields when the skill is explicitly Claude-Code-only.

## Where skills live and precedence

| Location   | Path | Scope |
| --- | --- | --- |
| Enterprise | managed settings dir | all org users |
| Personal   | `~/.claude/skills/<name>/SKILL.md` | all your projects |
| Project    | `.claude/skills/<name>/SKILL.md` | this project only |
| Plugin     | `<plugin>/skills/<name>/SKILL.md` | wherever plugin enabled |

- Name collisions across levels: enterprise > personal > project.
- A skill at any level overrides a bundled skill of the same name (but not its aliases).
- Plugin skills are namespaced `plugin-name:skill-name` — never collide with other levels.
- `.claude/commands/<name>.md` files work the same as skills; if both exist with the same name, the skill wins.
- Nested `.claude/skills/` (e.g. in a monorepo package) load once Claude touches a file in that subtree; if the name clashes with a root skill, the nested one becomes `dir/path:name` and both stay invocable.
- Live-reload: edits under `~/.claude/skills/`, project `.claude/skills/`, or `--add-dir` skill dirs are picked up mid-session. A **new top-level** skills directory needs a restart.
- `synced/` is a reserved folder name (any case) under personal/project/enterprise skill roots — don't create a skill with that name.

## Frontmatter fields beyond the open spec

All optional. Only `description` is recommended (fallback: first paragraph of body).

| Field | Purpose |
| --- | --- |
| `name` | In personal/project skills, only the *display label* — invocation name still comes from the directory. In plugin skills, sets the command's final segment. |
| `when_to_use` | Extra trigger phrases/examples, appended to `description`. Combined `description`+`when_to_use` truncates at 1536 chars in the listing — front-load the key use case. |
| `argument-hint` | Autocomplete hint, e.g. `[issue-number]`. |
| `arguments` | Named positional args for `$name` substitution (space-separated string or YAML list). |
| `disable-model-invocation` | `true` = only a human can invoke via `/name`; Claude never auto-loads it. Use for side-effecting actions (`/deploy`, `/commit`). Also blocks subagent preload and scheduled-task auto-run. |
| `user-invocable` | `false` = only Claude can invoke; hidden from `/` menu. Use for background knowledge, not actions. |
| `allowed-tools` | Tools pre-approved for the turn that invokes the skill (clears next message). Accepts space/comma string or YAML list. |
| `disallowed-tools` | Tools removed while the skill is active (clears next message). |
| `model` | Override model for the turn (or the forked subagent's model, with `context: fork`). |
| `effort` | Override effort level (`low`/`medium`/`high`/`xhigh`/`max`) while active. |
| `context: fork` | Run the skill in a forked subagent instead of inline. |
| `agent` | Which subagent type to fork into, when `context: fork`. |
| `background` | With `context: fork`, `false` = wait for the fork's result inline instead of backgrounding it. Default `true`. |
| `hooks` | Hooks registered for the rest of the session when this skill is invoked. |
| `paths` | Glob(s) — auto-activate only when working with matching files. |
| `shell` | `bash` (default) or `powershell` for inline `!command` execution. |
| `metadata` | Free-form map for your own tooling; Claude Code itself ignores it. |

Boolean fields accept `yes/no/on/off/1/0` in addition to `true/false` (v2.1.218+).

## Invocation control — the two knobs that matter most

- **`disable-model-invocation: true`** → human-only trigger. Use for anything with side effects or timing sensitivity (deploy, commit, send-message).
- **`user-invocable: false`** → Claude-only, not a slash command. Use for background/reference knowledge that isn't an "action" (e.g. "how our legacy billing system works").
- Neither set → both a human (`/name`) and Claude (auto-match on description) can trigger it. This is the default and right for most reusable-knowledge skills.

## String substitutions available in the body

`$ARGUMENTS`, `$ARGUMENTS[N]` / `$N`, `$name` (from `arguments:`), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}` (this skill's own dir — use for referencing bundled scripts regardless of cwd), `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` (plugin skills only).

Pattern for a script that runs without a permission prompt — use the same `${CLAUDE_SKILL_DIR}` value in both the body and `allowed-tools`:
```yaml
---
name: render-chart
description: Render a chart from a CSV file
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
---
Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render the chart.
```

## Dynamic context injection

A line starting with `` !`command` `` runs that shell command and splices its output into the skill body before Claude sees it — e.g. `` !`git diff HEAD` `` inlines the live diff. Doesn't work for synced/claude.ai-delivered skills outside cloud/Cowork sessions.

## Keeping a skill portable vs Claude-Code-only

| Distribution path | Allowed frontmatter |
| --- | --- |
| Claude Code, any level (incl. plugins) | every field above + the six spec fields |
| claude.ai upload / Skills API / `package_skill.py` | only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` |

If a skill might ever be uploaded or shared outside Claude Code, stick to the six spec fields — an extra key causes a hard error there (`Unexpected key(s) in SKILL.md frontmatter: ...`).
