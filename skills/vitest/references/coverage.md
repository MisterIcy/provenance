# Coverage

```
vitest run --coverage
```

```ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',        // or 'istanbul'
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**'],
      exclude: ['src/**/*.d.ts', 'src/**/*.config.ts'],
      thresholds: {
        lines: 80, functions: 80, branches: 75, statements: 80,
        // or per-file: autoUpdate: true to ratchet thresholds up as coverage improves
      },
    },
  },
})
```

- `v8` provider is faster and needs no extra instrumentation (uses Node's/Chromium's native V8 coverage) but is line/function-based; `istanbul` gives more precise branch coverage at a real speed cost — default to `v8` unless the project specifically needs istanbul's branch precision.
- Coverage thresholds fail the run (non-zero exit) when unmet — useful to wire into CI, but don't set them so tight that legitimate untestable lines (e.g. defensive `throw`s for cases the type system already rules out) force meaningless tests just to hit a number.
- `exclude` needs to list generated/config/type-only files explicitly — the default excludes are conservative (`node_modules`, test files themselves) and won't guess a project's build output directories.
- Coverage percentage is a signal, not a goal — a file at 100% line coverage can still have zero assertions on outcomes (every line "executed" by a test that asserts nothing). Read the actual tests, don't just read the number, when judging whether a suite is adequate.

Source: https://vitest.dev/guide/coverage
