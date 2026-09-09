# Mocking

## Function mocks and spies

```ts
const fn = vi.fn((x: number) => x + 1)
fn(1)
expect(fn).toHaveBeenCalledWith(1)
expect(fn).toHaveReturnedWith(2)

const spy = vi.spyOn(obj, 'method')
obj.method()
expect(spy).toHaveBeenCalledOnce()
spy.mockRestore()   // restores the original implementation
```

- `vi.fn()` creates a standalone mock; `vi.spyOn` wraps an existing object method while still (by default) calling through to the real implementation — call `.mockImplementation(...)` on the spy if the real call must be suppressed.
- Restore spies (`vi.restoreAllMocks()` in an `afterEach`) rather than leaving them patched — a spy left in place leaks into later tests in the same file/process if `restoreMocks`/`clearMocks` isn't set globally.
- Config shortcuts: `clearMocks: true` (calls/results reset before each test), `restoreMocks: true` (also restores original implementation), `mockReset: true` (also clears mock implementation back to a no-op) — set once in `vitest.config.ts` `test` block instead of repeating manual reset calls in every file.

## Module mocking

```ts
vi.mock('./db', () => ({
  query: vi.fn().mockResolvedValue([{ id: 1 }]),
}))
```

`vi.mock` calls are **hoisted** to the top of the file by Vitest's transform, before imports — this means the mock factory itself *runs* before any outer-scope `const`/`let` declared below the `vi.mock` call has been initialized. The rule this actually implies is narrower than "never reference an outer variable": what breaks is *dereferencing* the outer binding's value while the factory body executes (at hoist time), not merely closing over the identifier for later use.

```ts
// BREAKS — the factory reads mockUrl's value immediately, at hoist time,
// before the `const mockUrl = ...` below it has run.
const mockUrl = 'http://test.local'
vi.mock('./config', () => ({ apiUrl: mockUrl }))
```

Use `vi.hoisted()` to declare a value that the factory needs *at factory-execution time*:

```ts
const { queryMock } = vi.hoisted(() => ({ queryMock: vi.fn() }))
vi.mock('./db', () => ({ query: queryMock }))
```

But a factory that returns a *function* which only reads the outer variable when that function is later **called** (not when the factory itself runs) does not need `vi.hoisted()` — the outer `const` has long since been initialized by the time any test actually invokes it:

```ts
// WORKS without vi.hoisted() — the factory runs at hoist time and returns an
// object whose execFileSync is an arrow function; that arrow function's body
// isn't executed until some test later calls execFileSync(...), by which
// point execFileSyncMock has already been assigned.
const execFileSyncMock = vi.fn()
vi.mock('node:child_process', () => ({
  execFileSync: (...args: unknown[]) => execFileSyncMock(...args),
}))
```

Don't over-apply "any outer reference in `vi.mock` needs `vi.hoisted()`" as a blanket rule — check whether the factory *body* dereferences the variable immediately (needs `vi.hoisted()`) or only inside a nested function invoked later (doesn't).

Partial mocking (keep most of a module real, override one export):

```ts
vi.mock('./utils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./utils')>()
  return { ...actual, randomId: () => 'fixed-id' }
})
```

`vi.mocked(fn)` casts an imported function to its mocked type for TypeScript, without changing runtime behavior — use it instead of an `as unknown as Mock` cast.

Auto-mocking (`vi.mock('./mod')` with no factory) replaces every export with an auto-generated mock — prefer an explicit factory in most cases so the test file documents what behavior it depends on.

## Timers

```ts
vi.useFakeTimers()
const fn = vi.fn()
setTimeout(fn, 1000)
vi.advanceTimersByTime(1000)
expect(fn).toHaveBeenCalled()
vi.useRealTimers()   // always restore in afterEach — see review checklist
```

`vi.runAllTimers()` (runs every pending timer, including ones scheduled by earlier timers — can loop forever against a self-rescheduling `setInterval`) vs `vi.advanceTimersByTime(ms)` (bounded, prefer this unless the test genuinely needs to flush everything).

## Mocking modules/globals for environment concerns

`vi.stubGlobal('fetch', vi.fn())` / `vi.stubEnv('NODE_ENV', 'production')` — paired with `vi.unstubAllGlobals()`/`vi.unstubAllEnvs()` in cleanup, or set `unstubGlobals`/`unstubEnvs` in config to do it automatically between tests.

Source: https://vitest.dev/api/vi.html, https://vitest.dev/guide/mocking
