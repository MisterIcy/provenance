# CLI and configuration

## Running

```
vitest              # watch mode (default in dev) — reruns on file change
vitest run          # single run, no watch — use this in CI and for one-shot verification
vitest run path/to/file.test.ts
vitest run -t "pattern"   # filter by test name
vitest --coverage
vitest --ui               # opens the browser UI (@vitest/ui must be installed)
vitest related <files>     # run only tests affected by the given source files
```

Detect the project's actual invocation (package manager + config location) with `scripts/detect-runner.sh <project-root>` before assuming a bare `vitest`/`npx vitest` works — check `package.json` `scripts` first (a `test` or `test:unit` script may pass required flags like `--run` or `--environment`).

Always use `vitest run` (not bare `vitest`) for a single verification pass — bare `vitest` enters watch mode and will hang a non-interactive shell/CI step.

## Config file

`vitest.config.ts` (standalone) or a `test` block inside `vite.config.ts` (if the project already uses Vite):

```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: false,          // if true, describe/it/expect are ambient — no import needed (opt-in, prefer explicit imports unless the repo already sets this)
    environment: 'node',     // 'node' | 'jsdom' | 'happy-dom' | 'edge-runtime'
    setupFiles: ['./test/setup.ts'],
    include: ['src/**/*.{test,spec}.ts'],
    exclude: ['node_modules', 'dist'],
    coverage: { provider: 'v8', reporter: ['text', 'html'] },
  },
})
```

- `environment` matters for anything touching `document`/`window` — a component test needs `jsdom` or `happy-dom` (the latter is faster and covers most DOM needs; fall back to `jsdom` if a test hits an API happy-dom doesn't implement).
- `globals: true` mimics Jest's ambient-global style; this repo's test files import explicitly if `globals` is false or unset — check the existing config/imports before assuming which style is used, and match it rather than mixing styles across files.
- `alias` under `resolve` (top-level Vite config) must match `tsconfig.json` `paths` — a mismatch here is a common cause of "works in the editor, fails under Vitest" import errors.
- `includeSource: ['src/**/*.ts']` is required for in-source testing (`import.meta.vitest`) to be picked up.

## Workspaces / projects

A single Vitest run can span multiple sub-projects (e.g. a monorepo with different environments per package). The mechanism for this is **version-gated** — check the installed Vitest major (`package.json`/lockfile) before assuming which one applies:

- **Vitest 2.x and earlier**: a separate `vitest.workspace.ts` (or `.js`) file listing sub-project globs/configs — this is the only option.
  ```ts
  // vitest.workspace.ts
  export default ['packages/*', { test: { name: 'e2e', environment: 'node' } }]
  ```
- **Vitest 3.x+**: `vitest.workspace.ts` still works, but the same shape can also live inline as the `test.projects` field in the root `vitest.config.ts` — this field does not exist on 2.x, so writing it into a 2.x project is silently ineffective, not a smaller/older API surface.
  ```ts
  export default defineConfig({
    test: {
      projects: ['packages/*', { test: { name: 'e2e', environment: 'node' } }],
    },
  })
  ```

Each project can have its own `environment`, `setupFiles`, and `include` pattern. Don't assume a monorepo has a single flat `vitest.config.ts` — check for `vitest.workspace.*` (any version) or a `projects` field (3.x+ only) before writing a test file's assumed config, and confirm the installed major before recommending `test.projects` to a project pinned to 2.x.

## Reporters and CI

`--reporter=dot|verbose|json|junit|github-actions` (or an array in config). `github-actions` annotates failures inline on a PR diff when run inside GitHub Actions — worth enabling if the project's CI is GitHub Actions and it isn't already set.

## Type-checking as a test

`vitest --typecheck` runs `.test-d.ts`/`.test.ts` files through `tsc`/`vue-tsc` in addition to executing them — see `type-testing.md`.

Source: https://vitest.dev/config/, https://vitest.dev/guide/cli
