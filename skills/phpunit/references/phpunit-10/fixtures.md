# Fixtures

## Per-test lifecycle

```php
protected function setUp(): void
{
    $this->example = new Example($this->createStub(Collaborator::class));
}

protected function tearDown(): void
{
    $this->example = null;
}
```

`setUp()` runs before every test method on a fresh instance of the test class; `tearDown()` runs after every test method regardless of pass/fail. Only implement `tearDown()` if you allocated an external resource (file handle, socket, temp table) that needs explicit cleanup — PHP's GC handles plain object graphs.

## Per-class (shared) lifecycle

```php
public static function setUpBeforeClass(): void { /* once, before the first test */ }
public static function tearDownAfterClass(): void { /* once, after the last test */ }
```

Use for expensive, safely-shareable setup (e.g., spinning up a test database connection) — not for anything a test might mutate, since sharing state across tests is exactly what makes tests order-dependent and flaky.

## Multiple hooks: `#[Before]` / `#[After]`

If a subclass forgets to call `parent::setUp()`, inherited setup silently breaks. Prefer attribute-based hook methods, which PHPUnit calls automatically without any `parent::` chain:

```php
#[Before]
protected function connectToDatabase(): void { /* ... */ }

#[After]
protected function closeDatabase(): void { /* ... */ }
```
Also available: `#[BeforeClass]` / `#[AfterClass]` (static, once per class), `#[PreCondition]` / `#[PostCondition]` (run just inside setUp/tearDown, useful for hooks that assert rather than arrange).

## Global state isolation

- `#[BackupGlobals]` / XML `backupGlobals="true"` — snapshot and restore `$GLOBALS`, `$_ENV`, `$_POST`, etc. around each test.
- `#[BackupStaticProperties]` / `backupStaticProperties="true"` — snapshot/restore class static properties.
- Per-test opt-outs: `#[ExcludeGlobalVariableFromBackup]`, `#[ExcludeStaticPropertyFromBackup]`.
- These are expensive; prefer explicitly resetting the specific static/global you touch in `setUp()`/`tearDown()` over blanket backup/restore.

## Gotchas

- Fixture *sharing* between tests (a fixture created once and reused, mutated by one test and seen by another) is a smell — it couples test order and hides bugs. Prefer fresh fixtures via `setUp()` plus stubs/mocks for collaborators.
- `tearDown()` still runs even when a test fails or throws, so it's safe to rely on for guaranteed cleanup.

Source: https://docs.phpunit.de/en/10.5/fixtures.html
