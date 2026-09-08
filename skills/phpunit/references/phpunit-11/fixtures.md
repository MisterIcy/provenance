# Fixtures (PHPUnit 11)

## Per-test setup/teardown

```php
protected function setUp(): void
{
    $this->sut = new Example($this->createStub(Collaborator::class));
}

protected function tearDown(): void
{
    $this->sut = null;
}
```

- Run before/after **every** test method.
- **Gotcha:** if you override `setUp()`/`tearDown()` in a subclass, you must call `parent::setUp()` / `parent::tearDown()` yourself or the parent's fixture logic silently doesn't run. PHPUnit 11's preferred fix: use `#[Before]` / `#[After]` attributed methods instead — multiple methods can coexist across a class hierarchy without the inheritance footgun.

```php
#[Before]
protected function connectToDatabase(): void { /* ... */ }

#[After]
protected function disconnect(): void { /* ... */ }
```

## Per-class setup/teardown

```php
public static function setUpBeforeClass(): void
{
    self::$dbh = new PDO('sqlite::memory:');
}

public static function tearDownAfterClass(): void
{
    self::$dbh = null;
}
```

Run once before the first test / once after the last test in the class. **Never call assertions inside these** — behavior is undefined. `#[BeforeClass]` / `#[AfterClass]` attributes are the alternative form (support a `priority` param and stack across a hierarchy).

## Global state backups

- `--globals-backup` (CLI) / `backupGlobals="true"` (XML) / `#[BackupGlobals]` (attribute) — snapshots and restores `$GLOBALS`, `$_ENV`, `$_POST`, `$_GET`, `$_COOKIE`, `$_SERVER`, `$_FILES`, `$_REQUEST` around each test.
- `--static-backup` / `backupStaticProperties="true"` / `#[BackupStaticProperties]` — same, for static class properties.
- **Gotcha:** static-property backup only takes effect for tests that have it enabled; if an earlier test without it mutates a static property, that mutation leaks into later tests regardless. Prefer explicitly resetting statics in `setUp()`/`tearDown()` over relying on the backup flag.
- Objects that can't be serialized (e.g. `PDO`) will break backup if stored in `$GLOBALS`.
- `#[ExcludeGlobalVariableFromBackup]` / `#[ExcludeStaticPropertyFromBackup]` carve out specific exceptions.

## Design note

If tests need to share fixtures with each other, that's usually a sign of loose coupling problems in the code under test — prefer fixing the design and using test doubles (see `test-doubles.md`) over building dependencies between tests.

Source: https://docs.phpunit.de/en/11.5/fixtures.html
