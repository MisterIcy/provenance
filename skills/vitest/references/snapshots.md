# Snapshots

```ts
expect(renderOutput).toMatchSnapshot()
expect(value).toMatchInlineSnapshot()   // Vitest writes the expected value directly into the test file
```

- File snapshots live in `__snapshots__/<file>.snap` next to the test; inline snapshots are embedded in the test source itself — prefer inline for small, single-value assertions (a serialized object, a short string) since the expectation is visible without opening another file, and file snapshots for large output (full component render trees, large JSON fixtures).
- Update snapshots deliberately: `vitest run -u` (or `--update`) rewrites every mismatched snapshot to match current output. Never run this reflexively to make a failure go away — a snapshot failure means output changed, and `-u` should follow confirming that change was *intended*, not precede it.
- `toMatchSnapshot()` output is only as good as the reviewer reading the diff; a snapshot test with no other assertions can mask a meaningless change (e.g. a stray whitespace) as easily as a real regression — see the review checklist for when a snapshot is the wrong tool.
- `expect.addSnapshotSerializer(...)` registers a custom serializer (e.g. to strip volatile fields like timestamps/ids before comparison) instead of manually stripping fields in every test.
- Snapshots are per-test-name keyed; renaming a test orphans its old snapshot entry (`vitest run --reporter=verbose` and a stale-snapshot check flag it) — clean up `__snapshots__` files when tests are renamed or removed, don't leave orphaned entries.

Source: https://vitest.dev/guide/snapshot
