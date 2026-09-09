# Writing tests

## Structure

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest'

describe('Cart', () => {
  let cart: Cart

  beforeEach(() => {
    cart = new Cart()
  })

  it('starts empty', () => {
    expect(cart.items).toHaveLength(0)
  })
})
```

- `test`/`it` are interchangeable aliases; pick one convention per repo and stay consistent.
- `describe.skip`/`it.skip`, `describe.todo`/`it.todo`, `it.only`/`describe.only` (only for local debugging — never commit `.only`).
- `it.fails` marks a test expected to fail (inverse of a normal assertion failure being a bug).

## Hooks

`beforeAll`/`afterAll` run once per `describe` block (or file, at top level); `beforeEach`/`afterEach` run per test. Hooks registered at the top level of a file apply to every test in that file, not just tests below them in file order — order relative to other top-level hooks is the order they were registered in.

Always pair setup with teardown in the same hook pair (e.g. spin up a resource in `beforeEach`, tear it down in the matching `afterEach`) rather than a single `afterAll` — this keeps tests independent when one test in the middle fails and skips its own cleanup path.

## Data-driven tests

```ts
it.each([
  [1, 1, 2],
  [1, 2, 3],
])('add(%i, %i) -> %i', (a, b, expected) => {
  expect(add(a, b)).toBe(expected)
})

it.each`
  a    | b    | expected
  ${1} | ${1} | ${2}
  ${1} | ${2} | ${3}
`('add($a, $b) -> $expected', ({ a, b, expected }) => {
  expect(add(a, b)).toBe(expected)
})
```

Prefer `it.each` over a hand-rolled `for` loop over test cases — failures report which row failed individually instead of collapsing into one assertion failure.

## Async tests

Any `it`/`test` callback can be `async`; Vitest awaits it. Always `await` (or `return`) promise-based assertions — a dangling un-awaited `expect(promise).resolves.toBe(x)` silently passes even if it never settles before the test ends. Use `await expect(fn()).rejects.toThrow(...)` for expected rejections instead of wrapping in try/catch and asserting in the catch block.

## Test context and fixtures

`test.extend` builds a custom `test`/`it` with injected, composable fixtures (replaces ad-hoc `beforeEach` setup that assigns to outer-scope `let` variables):

```ts
const it = test.extend<{ db: Database }>({
  db: async ({}, use) => {
    const db = await createTestDb()
    await use(db)
    await db.close()
  },
})

it('finds a user', async ({ db }) => {
  await db.seed({ users: [{ id: 1 }] })
  expect(await db.findUser(1)).toBeDefined()
})
```

Fixtures are lazy (only instantiated if a test requests them) and can depend on each other. Prefer this over closures over outer `let` variables when a fixture needs its own teardown or is shared across many test files — it also makes each test's dependencies explicit in its parameter list.

## Concurrent tests

`describe.concurrent`/`it.concurrent` run tests in parallel within a file. Only use this for tests that don't share mutable state (a shared `beforeEach`-created object being mutated by concurrent tests is a race condition, not a speedup) — see the review checklist for the failure mode this causes.

## In-source testing

Vitest supports colocating tests with implementation using `import.meta.vitest`, guarded so production builds strip them:

```ts
export function add(a: number, b: number) { return a + b }

if (import.meta.vitest) {
  const { it, expect } = import.meta.vitest
  it('adds', () => { expect(add(1, 1)).toBe(2) })
}
```

Requires `includeSource` in config (see `cli-and-config.md`) and a build-time `define: { 'import.meta.vitest': 'undefined' }` for production bundles. Rare in practice — most codebases keep tests in separate `*.test.ts` files; only reach for this when the user's project already uses the pattern.

Source: https://vitest.dev/guide/ (Test API, Test Context, Test Filtering)
