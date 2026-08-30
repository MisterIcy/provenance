---
name: skill-creator
description: Scaffolds and reviews Agent Skills (SKILL.md packages) following the open agentskills.io standard, with extra guidance for Claude Code. Use when the user wants to create a new skill, write a SKILL.md, package instructions/scripts/references into a skill, or review/fix an existing skill's frontmatter or structure.
license: Apache-2.0
metadata:
  author: Alexandros Koutroulis
  version: "0.1"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/validate_frontmatter.py *)
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/skill-creator/scripts/validate_frontmatter.py"
---

## What this skill does

Helps a human (or Claude) design, scaffold, and validate an **Agent Skill**: a directory with a `SKILL.md` file (plus optional `scripts/`, `references/`, `assets/`) that a skills-compatible agent loads on demand.

This skill only carries the *authoring* workflow inline. Deep spec detail lives in `references/` and is loaded only when needed — don't paste those files into the conversation unless the task requires the detail.

## Workflow

1. **Clarify the target.** Ask (or infer from context) three things before writing anything:
   - What task/expertise should the skill capture? (one clear job, not a grab-bag)
   - Which agent(s) will run it? Generic (agentskills.io only) vs Claude Code-specific (can use CC's extended frontmatter — see `references/claude-code-extensions.md`)
   - Where does it live? Personal (`~/.claude/skills/`), project (`.claude/skills/`), or plugin (`<plugin>/skills/`) — see that same reference for precedence rules.

2. **Name it.** Directory name = skill name. Must satisfy (from `references/agent-skills-spec.md`):
   - 1–64 chars, lowercase unicode alphanumerics and hyphens only
   - no leading/trailing hyphen, no `--`
   - `name` in frontmatter must match the directory name exactly

3. **Write the description first.** This is the single highest-leverage field — it's the only thing loaded at startup (progressive disclosure stage 1) and it's how the agent decides to activate the skill at all. It must say **what** the skill does and **when** to use it, with concrete trigger keywords. Max 1024 chars. Weak: "Helps with PDFs." Good: "Extracts text/tables from PDFs, fills forms, merges files. Use when the user mentions PDFs, forms, or document extraction."

4. **Scaffold the directory:**
   ```
   <skill-name>/
   ├── SKILL.md          # required
   ├── scripts/           # optional: executable code the agent runs, doesn't load into context
   ├── references/        # optional: docs loaded on demand (keep each file focused/small)
   └── assets/             # optional: templates, static resources
   ```
   Use `assets/SKILL.template.md` in this skill as a starting point for the new file.

5. **Write the body.** No format is mandated — write what an agent needs to execute the task correctly. Recommended shape: short overview → numbered workflow/steps → edge cases → pointers to `references/*` for anything detailed. Keep `SKILL.md` **under 500 lines / ~5000 tokens**; move anything longer into `references/` and link to it with a relative path one level deep (don't chain references-of-references).

6. **Decide on frontmatter fields.**
   - Only `name` and `description` are required by the open spec.
   - If the skill is Claude-Code-only, extra fields (`disable-model-invocation`, `user-invocable`, `allowed-tools`, `context: fork`, `arguments`, `paths`, `hooks`, etc.) are fair game — see `references/claude-code-extensions.md`.
   - If the skill must also work unmodified outside Claude Code (claude.ai upload, Skills API, other agentskills.io clients), restrict frontmatter to the six spec fields: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Anything else causes a hard validation error on those paths.

7. **Validate before calling it done.**
   - Run `${CLAUDE_SKILL_DIR}/scripts/validate_frontmatter.py <path-to-new-SKILL.md>` — checks frontmatter against the spec/CC rules above (name format + directory match, description presence/length, field types, unknown keys, etc.) and exits non-zero if anything's wrong. This also runs automatically as a `PostToolUse` hook while this skill is active, so an `Edit`/`Write` to any `SKILL.md` gets checked as you go — but the script only catches what's mechanically checkable; it doesn't replace judgment calls.
   - Then walk `references/checklist.md` for everything else: body under the size guideline, all relative links resolve, no secrets/credentials embedded, scripts are self-contained with error handling, and the sanity-test questions at the bottom.

8. **Report what you built**: skill path, how it's invoked (auto-match on description, or `/skill-name` in Claude Code), and any manual step needed (e.g. restart to pick up a new top-level skills dir).

9. **Offer to set up evals** (optional, skip for trivial/throwaway skills) — a small `evals/evals.json` of 2-3 realistic test prompts with expected outputs, so skill quality can be checked with-vs-without the skill instead of by one manual try. See `references/evaluating-skills.md`.

## References

- `references/agent-skills-spec.md` — full open agentskills.io specification (frontmatter fields, constraints, progressive disclosure model, validation)
- `references/claude-code-extensions.md` — Claude Code-specific frontmatter fields, skill locations/precedence, invocation control, string substitutions, dynamic context injection
- `references/checklist.md` — pre-flight checklist to run before declaring a skill done
- `references/evaluating-skills.md` — designing eval test cases, running with/without-skill comparisons, grading, iterating
- `scripts/validate_frontmatter.py` — validates a `SKILL.md`'s frontmatter against the spec/CC rules; also wired as this skill's own `PostToolUse` hook (see frontmatter)
- `assets/SKILL.template.md` — copy-paste starting point for a new `SKILL.md`
- `evals/evals.json` — this skill's own eval test cases (see `references/evaluating-skills.md`)

## A note on this skill's own portability

This skill's frontmatter uses `allowed-tools` and `hooks` — the latter is Claude Code-only, so *this skill itself* is no longer portable to claude.ai/Skills API uploads unmodified (it would need `hooks` stripped first). That's a deliberate trade-off for the self-checking hook; it doesn't change the portability guidance this skill gives about the skills *it* helps you author.

## Common mistakes to avoid

- Description too vague ("helps with X") — the agent will never activate it.
- `name` not matching the directory, or using uppercase/underscores.
- Dumping everything into `SKILL.md` instead of splitting large reference material out — this defeats progressive disclosure and wastes context on every activation.
- Adding Claude-Code-only frontmatter fields to a skill meant to be portable/uploaded elsewhere.
- Treating a skill as a place for one-off task state — a skill is reusable procedural knowledge, not a scratch note.
