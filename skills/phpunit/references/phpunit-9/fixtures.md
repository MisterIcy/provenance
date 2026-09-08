# Fixtures

A "fixture" is the known state a test runs against: the objects under test, their collaborators, and any setup/teardown around them.

## Per-test: `setUp()` / `tearDown()`

Run before/after **every** test method in the class:

```php
protected function setUp(): void
{
    $this->stack = [];
}

protected function tearDown(): void
{
    // release resources opened in setUp(), if any
}
```

Store fixture state as instance properties (`$this->stack`), not method-local variables, so multiple test methods can reuse it without duplicating setup code. `tearDown()` is often unnecessary for plain PHP objects with no external resources (files, sockets, DB connections) — don't add empty teardown boilerplate.

## Once per class: `setUpBeforeClass()` / `tearDownAfterClass()`

Static methods, run once before the first test and once after the last test in the class — good for expensive shared setup (e.g. a DB handle):

```php
private static PDO $dbh;

public static function setUpBeforeClass(): void
{
    self::$dbh = new PDO('sqlite::memory:');
}

public static function tearDownAfterClass(): void
{
    self::$dbh = null;
}
```

## Global state (backup/restore)

PHPUnit can snapshot and restore `$GLOBALS` and static class properties around each test:

```bash
phpunit --globals-backup --static-backup
```

or in XML: `backupGlobals="true"`, `backupStaticAttributes="true"`. Exclude specific globals from the (de)serialization dance if they contain non-serializable resources:

```php
protected array $backupGlobalsExcludeList = ['someResourceHandle'];
```

These backups are relatively expensive; leave them off unless tests actually mutate global/static state.

## Gotchas

- Sharing fixtures across tests (e.g. one shared object all tests mutate) reduces the value of the tests — it masks design problems and creates order-dependence. Prefer fresh fixtures per test via `setUp()`, and reach for dependency injection over global/static coupling in the code under test.
- `setUp()`/`tearDown()` run around *every* test method — including ones that don't need the fixture — so keep them cheap; push genuinely expensive one-time setup to `setUpBeforeClass()`.

## Source

https://docs.phpunit.de/en/9.6/fixtures.html
