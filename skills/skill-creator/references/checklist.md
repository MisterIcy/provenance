# Pre-flight checklist

Run through before calling a skill done.

## Frontmatter
- [ ] `name` present, 1–64 chars, lowercase unicode alnum + hyphens only, no leading/trailing/double hyphen
- [ ] `name` matches the parent directory name exactly
- [ ] `description` present, 1–1024 chars, states both what and when, includes concrete trigger keywords
- [ ] No portability-breaking fields if this skill needs to work outside Claude Code (see `claude-code-extensions.md` table)
- [ ] `metadata` (if used) is a flat string→string map
- [ ] `compatibility` (if used) only present because there's a real environment requirement

## Body
- [ ] `SKILL.md` under ~500 lines / ~5000 tokens
- [ ] Detailed/rarely-needed material moved to `references/*` and linked, not inlined
- [ ] All relative links (`references/...`, `scripts/...`, `assets/...`) resolve to real files
- [ ] No reference-file-to-reference-file chains (keep one level deep)
- [ ] Body states what to do, not a narrated justification — every line is a recurring token cost once loaded

## Scripts (if any)
- [ ] Self-contained or dependencies clearly documented at the top
- [ ] Fails with a helpful error message, not a stack trace, on bad input
- [ ] Handles the obvious edge cases (missing file, empty input, etc.)

## Safety
- [ ] No secrets, tokens, or credentials embedded in any file
- [ ] No hardcoded paths specific to one machine/user (unless the skill is explicitly personal)

## Sanity test
- [ ] Would the `description` alone cause an agent to correctly activate this skill for a realistic user request, and *not* activate for unrelated requests?
- [ ] If Claude Code: confirm the invocation mode is intentional — auto+manual (default), manual-only (`disable-model-invocation: true`), or Claude-only (`user-invocable: false`)
