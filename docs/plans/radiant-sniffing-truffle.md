# Port hook scripts from Python/Bash to TypeScript/Bun

## Context

The plugin's `PreToolUse`/`PostToolUse` hooks (`hooks/scripts/`) are currently a mix of Python (`git_guard.py`, the shared tokenizer used by the commit/push guards) and Bash (`guard-sql-readonly.sh`, `check-pr-drift.sh`). Python is only used for one file, tested via `unittest`, with no type checking. This work replaces the whole hook-script family with TypeScript executed by Bun, with a Vitest suite, and changes the "missing runtime" failure mode from fail-open (silent exit 0) to a hard blocking error (exit 2), so a broken dev environment is surfaced immediately instead of silently skipping a security gate. Scope, toolchain location (repo root), and branch (`refactor/hooks-bun-typescript`, already checked out) were confirmed with the user up front.

## Dev environment (repo root)

- `package.json` (`private: true`) — devDependencies: `typescript`, `vitest`, `@types/node`. Scripts: `test` (`vitest run`), `test:watch` (`vitest`), `typecheck` (`tsc --noEmit`).
- `tsconfig.json` — `target`/`module`: `ES2022`/`NodeNext`, `strict: true`, `noEmit: true` (Bun executes `.ts` directly at runtime — no build step, consistent with the repo's existing "no build step" model in `CLAUDE.md`; `tsc` is only used for type-checking).
- `vitest.config.ts` — test match under `hooks/scripts/tests/**/*.test.ts`.
- `.gitignore` — add `node_modules/`. Commit the generated `bun.lock`.
- Write hook logic using only Node-standard APIs (`node:fs`, `node:child_process`), not Bun-only globals — this lets Vitest (Node) import and unit-test the pure logic directly, while only the CLI/integration tests need to shell out to a real `bun` binary.

## Shared "require bun" pattern

New `hooks/scripts/require-bun.sh`, sourced by every wrapper:
```bash
require_bun() {
  if ! command -v bun >/dev/null 2>&1; then
    echo "bun is required to run this hook but was not found on PATH. Install: https://bun.sh" >&2
    exit 2
  fi
}
```
Exit 2 on `PreToolUse` blocks the tool call and surfaces the stderr message to Claude; on `PostToolUse` (the PR-drift check) it surfaces the same message as context without blocking the already-completed call. This replaces today's `command -v python3 || exit 0` fail-open check in `guard-git-commit.sh`/`guard-git-push.sh` — a deliberate behavior change requested by the user.

## File-by-file port

1. **`hooks/scripts/git-guard.ts`** — port of `git_guard.py`: `splitSegments`, `findSubcommand`, `joinLineContinuations`, `commandInvokes`, and a `main()` CLI reading `process.argv` for `<subcommand> <PLUGIN_OPTION_ENV_VAR>` and stdin (via `fs.readFileSync(0, "utf8")`) for the JSON payload, preserving exact current semantics (fail-open on malformed/missing payload, fail-closed/treat-as-match on tokenizer errors, same `permissionDecision` JSON output shape).
2. **`hooks/scripts/guard-git-commit.sh`** / **`guard-git-push.sh`** — shrink to: source `require-bun.sh`, call `require_bun`, then `exec bun "$(dirname "${BASH_SOURCE[0]}")/git-guard.ts" commit|push <ENV_VAR>`. Same two argv contract, same env var names, no `hooks.json` changes needed.
3. **`hooks/scripts/sql-readonly-guard.ts`** — port of `guard-sql-readonly.sh`'s keyword-matching logic (same regex, same deny-JSON message) reading stdin the same way; **`guard-sql-readonly.sh`** shrinks to the `require_bun` + `exec bun .../sql-readonly-guard.ts` pattern.
4. **`hooks/scripts/pr-drift-check.ts`** — port of `check-pr-drift.sh`: reads `CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED` from env, shells out to `gh pr view --json number -q .number` via `node:child_process` (`execFileSync`, no shell interpolation), and prints the same `additionalContext` JSON; **`check-pr-drift.sh`** shrinks to the same `require_bun` + `exec bun` pattern.
5. Delete `hooks/scripts/git_guard.py` and `hooks/scripts/tests/test_git_guard.py` once their replacements are green.

## Tests (Vitest, `hooks/scripts/tests/*.test.ts`)

- `git-guard.test.ts` — direct port of every case in `test_git_guard.py` (`CommandInvokesTests` as unit tests importing `commandInvokes` straight from the module; `MainCliTests` as integration tests spawning `bun hooks/scripts/git-guard.ts ...` via `child_process.spawnSync`, mirroring the existing `run_guard` helper).
- `sql-readonly-guard.test.ts` — table-driven cases covering each keyword in the current regex plus a few read-only queries that must pass through untouched.
- `pr-drift-check.test.ts` — cases for: feature flag off, `gh` missing, no open PR, open PR present (mock `execFileSync`/`gh` via a stub on `PATH` or module mock).
- One small `require-bun.test.ts` (or fold into each wrapper's coverage) that overrides `PATH` to hide `bun` and asserts the wrapper exits 2 with a non-empty stderr message.

## CI and docs

- `.github/workflows/hooks-tests.yml` — replace the Python step with `oven-sh/setup-bun@v2`, `bun install --frozen-lockfile`, `bun run typecheck`, `bun run test`; broaden the `paths:` trigger to include `package.json`, `tsconfig.json`, `vitest.config.ts`.
- `CLAUDE.md` — update the "Commands" section's test command from `python3 -m unittest discover ...` to `bun install && bun run test`, and adjust the opening paragraph's "no build step, except hook scripts have a unit test suite" note to mention Bun/TypeScript/Vitest instead of the Python detail.

## Verification

- `bun install && bun run typecheck && bun run test` all green locally.
- Manually pipe sample JSON payloads into each rewritten wrapper (same payloads used in the old Python tests) and diff behavior against the current scripts on `main` for parity.
- Temporarily shadow `bun` off `PATH` (e.g. `PATH=/usr/bin bash hooks/scripts/guard-git-push.sh`) and confirm exit code 2 with the expected stderr message, for each of the four wrappers.
