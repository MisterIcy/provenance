# Type-testing

Vitest can assert on TypeScript *types*, not just runtime values — useful for testing generic utility types, overloads, and public API type signatures where a runtime test can't catch a type regression.

## API

```ts
import { expectTypeOf, assertType } from 'vitest'

expectTypeOf(add).toBeFunction()
expectTypeOf(add).parameters.toEqualTypeOf<[number, number]>()
expectTypeOf(add).returns.toBeNumber()

function takesString(x: string) {}
assertType<string>('hello')   // compile-time only — no runtime assertion object
```

- `expectTypeOf` is the richer, chainable API (`.toEqualTypeOf`, `.toMatchTypeOf`, `.parameters`, `.returns`, `.toBeCallableWith(...)`); `assertType<T>(value)` is a lighter one-shot check.
- These calls produce **no runtime assertions** — they exist purely for the TypeScript compiler to check at build/typecheck time. A file full of `expectTypeOf` calls with no `vitest --typecheck` step run against it is dead weight; the type errors never surface.

## Running

Put type tests in files matched by the `typecheck.include` pattern (default: `**/*.{test,spec}-d.ts`) and run:

```
vitest --typecheck
```

This spawns `tsc --noEmit` (or `vue-tsc` if configured) against the matched files in addition to Vitest's normal runtime execution. It's usually a separate CI step/script (e.g. `test:types`) rather than bundled into every `vitest run`, since typechecking is slower — check the project's `package.json` scripts before assuming `--typecheck` runs by default.

## Common pitfalls

- `toEqualTypeOf` requires an *exact* structural match (extra or missing optional properties fail); `toMatchTypeOf` (deprecated in newer Vitest — check the installed version's docs) allows a supertype/subtype relationship. Reach for the exact form by default; only relax to a subtype check when the API genuinely allows a wider type in practice.
- A `.test-d.ts` file with no `--typecheck` step in CI gives false confidence — the file looks like a test and will even run its non-type assertions, but the type-level checks silently never execute.
- `tsconfig.json` strictness (`strict`, `exactOptionalPropertyTypes`, `noUncheckedIndexedAccess`) affects what `toEqualTypeOf` considers equal — a type test that passes under a loose `tsconfig` can fail once strictness is tightened elsewhere; keep type tests under the same `tsconfig` the rest of the project typechecks against.

Source: https://vitest.dev/guide/testing-types
