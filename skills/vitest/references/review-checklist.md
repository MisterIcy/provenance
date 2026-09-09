# Reviewing an existing Vitest suite

Use this when asked to review, audit, or improve an existing test suite rather than write new tests. Read the actual test files — a passing suite is not the same as a good one.

## Correctness/reliability anti-patterns

- **Un-awaited async assertions.** `expect(promise).resolves.toBe(x)` or a bare `asyncFn()` call with no `await`/`return` inside an `it` callback that isn't itself declared `async` — the test can report green before the assertion (or even the call) has actually run. Every promise-returning call in a test body must be awaited or returned.
- **Leaked mocks/spies/fake timers across tests.** A `vi.spyOn`/`vi.useFakeTimers()` with no matching `mockRestore()`/`vi.useRealTimers()` in `afterEach` (or no global `restoreMocks`/`clearMocks` in config) can make a later, unrelated test fail or pass for the wrong reason depending on file/run order.
- **Shared mutable state across `it.concurrent` tests.** Concurrent tests that read/write the same outer-scope object race; symptoms are flaky failures that don't reproduce when run with `-t` in isolation. Either give each concurrent test its own fixture (`test.extend`) or drop `.concurrent`.
- **Snapshot-only tests with no semantic assertion.** A `toMatchSnapshot()` with nothing else asserted turns "did this change" into the only signal — it'll happily accept a regression via `-u` if the reviewer isn't reading the diff. Prefer explicit assertions for anything with a checkable invariant; reserve snapshots for genuinely large/opaque output.
- **`.only` committed to the repo.** Silently disables every other test in the file/run — grep for `it.only`/`describe.only`/`test.only` before approving a diff.
- **Testing implementation details instead of behavior.** Asserting on internal call counts/mock call order for something with no externally observable contract makes the test break on any refactor even when behavior is unchanged — check whether the assertion would still make sense if the implementation were swapped for a different one with the same public behavior.
- **Time-dependent tests without fake timers.** `new Date()`/`Date.now()`/real `setTimeout` in a test with no `vi.useFakeTimers()` is a source of environment-dependent flakiness (slow CI runners, DST boundaries) — flag it even if it happens to be currently green.

## Structure/maintainability

- Test names that don't describe the *behavior* being verified (`it('works')`, `it('test 1')`) — a failing test's name is the first thing a reader sees; it should state the expected behavior, not just label an example.
- Duplicated setup across many `it` blocks in a file that could be `beforeEach` or a `test.extend` fixture.
- Missing negative/edge-case coverage next to a well-covered happy path — check for absent tests around empty inputs, error branches, and boundary values, not just line coverage percentage (see `coverage.md`'s point on coverage-as-signal-not-goal).
- Type tests (`*.test-d.ts`) present but no `--typecheck` step wired into CI — see `type-testing.md`.

## What NOT to flag

- Style choices already consistent within the file/repo (e.g. `test` vs `it`, `globals: true` vs explicit imports) — match existing convention, don't relitigate it in a review.
- A snapshot test for output that's genuinely large/opaque (rendered HTML trees, generated config) where the point is deliberately "alert a human to any change here."
