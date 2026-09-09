---
name: vitest
description: Vitest knowledge for writing, running, debugging, and reviewing TypeScript/JavaScript unit and integration tests — test structure (describe/it/test), hooks, data-driven tests (it.each), async assertions, fixtures (test.extend), mocking (vi.fn/vi.spyOn/vi.mock/vi.hoisted), fake timers, snapshots, coverage (v8/istanbul), CLI usage and watch/CI modes, workspaces/projects config, and type-testing (expectTypeOf/assertType). Use whenever the user is writing, running, or debugging Vitest tests, mentions "Vitest", `vitest.config.ts`, `vi.mock`/`vi.fn`, `.test.ts`/`.spec.ts` in a TS/JS project, or asks to improve/review an existing Vitest suite.
---

# Vitest

Reference knowledge for anyone writing, running, debugging, or reviewing
Vitest tests in a TypeScript/JavaScript codebase — not a general JS testing
tutorial, and not for other test runners (Jest, Mocha, Jasmine) even though
much of the API is intentionally Jest-compatible.

## Workflow

1. **Confirm this is a Vitest project.** Look for `vitest` in
   `package.json` (dependencies or devDependencies), a `vitest.config.*` /
   `vitest.workspace.*` file, or a `test` block inside `vite.config.*`. Run
   `scripts/detect-runner.sh <project-root>` to get the package manager,
   suggested invocation, and any config files found — use its output to
   pick the right command instead of guessing `npx vitest`.

2. **Load the reference file(s) the task actually needs** — don't load all
   of them for a narrow question:
   - `references/writing-tests.md` — describe/it/test structure, hooks,
     `it.each` data-driven tests, async assertions, `test.extend` fixtures,
     concurrent tests, in-source testing.
   - `references/cli-and-config.md` — CLI flags, watch vs. `run` mode,
     `vitest.config.ts` shape, environments (node/jsdom/happy-dom),
     workspaces/projects, reporters, CI integration.
   - `references/mocking.md` — `vi.fn`/`vi.spyOn`, module mocking with
     `vi.mock` and hoisting (`vi.hoisted`), partial mocks, fake timers,
     `vi.stubGlobal`/`vi.stubEnv`.
   - `references/snapshots.md` — file vs. inline snapshots, updating with
     `-u`, custom serializers, when a snapshot is the wrong tool.
   - `references/coverage.md` — `--coverage`, v8 vs. istanbul providers,
     thresholds, reading coverage as a signal rather than a goal.
   - `references/type-testing.md` — `expectTypeOf`/`assertType`,
     `*.test-d.ts` files, running with `--typecheck`.
   - `references/review-checklist.md` — anti-patterns to check for when
     asked to review/audit an *existing* suite rather than write new tests.

3. **Writing tests**: match the existing repo's conventions (`test` vs.
   `it`, explicit imports vs. `globals: true`, fixture style) before
   introducing a different one — check a neighboring test file first, not
   just the config. Use `it.each`/fixtures/hooks per `writing-tests.md`
   rather than hand-rolled loops or repeated setup.

4. **Running tests**: always use `vitest run` (not bare `vitest`, which
   enters watch mode and will hang a non-interactive shell) for a one-shot
   verification pass. Add `--coverage`/`--typecheck`/`-t <pattern>` as the
   task requires.

5. **Reviewing/debugging an existing suite**: read the actual test files,
   not just whether the suite currently passes. Walk
   `references/review-checklist.md` explicitly — un-awaited async
   assertions, leaked mocks/timers, concurrent tests sharing mutable state,
   and snapshot-only tests with no semantic assertion are the highest-value
   things to catch, because they can pass green while masking a real bug.

6. **Prefer this skill's condensed knowledge first**, but every topic file
   ends with a `Source` line to the exact vitest.dev page it was drawn
   from — fetch that page directly if the user's installed version behaves
   differently than described (Vitest's API has been broadly stable across
   major versions for everything covered here; this skill deliberately does
   not version-gate the way `phpunit` does, since Vitest hasn't had
   comparable breaking churn in the surface this skill covers — if a
   genuine version-specific discrepancy shows up, note it explicitly rather
   than silently guessing).

## Common mistakes to avoid

- Running bare `vitest` in a script/CI context expecting a single pass —
  it enters watch mode and hangs. Use `vitest run`.
- Referencing outer-scope `const`/`let` variables inside a `vi.mock(...)`
  factory without `vi.hoisted()` — `vi.mock` calls are hoisted above
  imports and regular variable declarations, so this throws or silently
  uses `undefined`.
- Treating a green suite as a good suite during review — walk
  `review-checklist.md` explicitly rather than trusting pass/fail alone.
- Updating snapshots (`-u`) reflexively to clear a failure instead of
  confirming the underlying output change was intended.
- Loading every reference file for a single narrow question — load only
  the topic file(s) the task needs.
- Confusing this skill with a general JS/TS testing tutorial — it assumes
  the reader already knows TypeScript and just needs Vitest-specific
  mechanics.

## References

- `references/writing-tests.md`
- `references/cli-and-config.md`
- `references/mocking.md`
- `references/snapshots.md`
- `references/coverage.md`
- `references/type-testing.md`
- `references/review-checklist.md`
- `scripts/detect-runner.sh` — reports package manager, suggested Vitest
  invocation, and discovered config files for a project root
