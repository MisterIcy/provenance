# Fixtures

## Per-test hooks

`setUp()`/`tearDown()` run before/after **every** test method, on a fresh instance of the test class each time:

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

## Per-class hooks

For expensive shared resources (DB connections, etc.), use static once-per-class hooks:

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

**Never assert inside `setUpBeforeClass()`/`tearDownAfterClass()`** — behavior is undefined.

## Full lifecycle order

```
setUpBeforeClass()                [once]
  setUp()                         [each test]
    assertPreConditions()
      <test method>
    assertPostConditions()
  tearDown()                      [each test]
tearDownAfterClass()               [once]
```

`assertPreConditions()`/`assertPostConditions()` let you share validation logic across every test in the class; failures there are reported as ordinary test failures (not errors).

## Attribute-based hooks (recommended over overriding setUp/tearDown)

`#[Before]`/`#[After]`/`#[BeforeClass]`/`#[AfterClass]` avoid the classic "forgot to call `parent::setUp()`" bug, because PHPUnit calls every method carrying the attribute up the inheritance chain — no manual chaining required:

```php
use PHPUnit\Framework\Attributes\Before;
use PHPUnit\Framework\Attributes\After;

abstract class MyTestCase extends TestCase
{
    #[Before]
    protected function setUpLogger(): void { /* ... */ }

    #[After]
    protected function tearDownLogger(): void { /* ... */ }
}

final class MyTest extends MyTestCase
{
    #[Before]
    protected function setUpFixture(): void { /* ... */ } // runs too, no parent:: needed
}
```

Multiple `#[Before]`/`#[After]` methods can be ordered with `priority` (higher runs first for `#[Before]`):

```php
#[Before(priority: 2)]
protected function connectToDatabase(): void { /* ... */ }

#[Before(priority: 1)]
protected function seedDatabase(): void { /* ... */ }
```

## Global/static state isolation

Backups prevent one test's global/static mutations leaking into the next:

- CLI: `--globals-backup`, `--static-backup`
- XML: `backupGlobals="true"`, `backupStaticProperties="true"`
- Attributes: `#[BackupGlobals(true)]`, `#[BackupStaticProperties(true)]`, `#[ExcludeGlobalVariableFromBackup('SOME_VAR')]`, `#[ExcludeStaticPropertyFromBackup(Class::class, 'prop')]`

Gotcha: non-serializable objects in `$GLOBALS` (e.g. a `PDO` handle) break the backup mechanism — exclude them explicitly.

## Design note

Sharing fixtures between tests to save setup work is a smell — "it reduces the value of the tests" by coupling them. Prefer stubs/mocks (see `test-doubles.md`) or fixing the underlying design over building a chain of dependent fixtures.

## Source

- https://docs.phpunit.de/en/12.5/fixtures.html
