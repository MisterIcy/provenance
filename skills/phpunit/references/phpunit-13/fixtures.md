# Fixtures

PHPUnit runs a fixed set of template methods around every test, in this order:

1. `setUpBeforeClass()` — once, before any test in the class (static)
2. `setUp()` — before every test
3. `assertPreConditions()`
4. *the test method*
5. `assertPostConditions()`
6. `tearDown()` — after every test
7. `tearDownAfterClass()` — once, after all tests in the class (static)

```php
final class ExampleTest extends TestCase
{
    private ?Example $example = null;

    protected function setUp(): void
    {
        $this->example = new Example($this->createStub(Collaborator::class));
    }

    protected function tearDown(): void
    {
        $this->example = null;
    }
}
```

## Prefer attributes over overriding template methods

`#[Before]` / `#[After]` / `#[BeforeClass]` / `#[AfterClass]` / `#[PreCondition]` / `#[PostCondition]` mark *any* method name as playing that role, and **multiple methods can share the same role** — this sidesteps the classic problem of a subclass forgetting to call `parent::setUp()`.

```php
final class PriorityTest extends TestCase
{
    #[Before(priority: 2)]
    protected function connectToDatabase(): void { /* runs first */ }

    #[Before(priority: 1)]
    protected function seedDatabase(): void { /* runs second */ }
}
```
Higher `priority` runs earlier; default is 0.

## Shared/expensive fixtures

Use `setUpBeforeClass()`/`#[BeforeClass]` for state expensive to rebuild per-test (e.g. a database connection):

```php
final class DatabaseTest extends TestCase
{
    private static PDO $dbh;

    public static function setUpBeforeClass(): void
    {
        self::$dbh = new PDO('sqlite::memory:');
    }
}
```
Don't put assertions inside `setUpBeforeClass()`/`tearDownAfterClass()` — behavior on failure there is undefined/inconsistent. Sharing fixtures across tests couples them together and can mask ordering bugs; prefer it only when justified by cost.

## Isolation knobs

- `#[BackupGlobals(true)]` / `backupGlobals="true"` in XML — snapshot/restore superglobals per test.
- `#[BackupStaticProperties(true)]` — snapshot/restore static class properties per test (catches state leaking between tests via statics).
- `#[WithEnvironmentVariable('APP_ENV', 'test')]` — scope an env var change to one test.
- `#[RunInSeparateProcess]` / `#[RunTestsInSeparateProcesses]` — hard isolation when global state can't be reset any other way (slow).

## Cleanup tips

- Only implement `tearDown()` if you allocated something external (file handle, socket, temp file) — PHPUnit doesn't need it for plain object cleanup.
- `unset()` large object-graph properties in `tearDown()` if memory pressure across a big suite matters; otherwise fixture objects live until the test-runner process ends.

## Source
- https://docs.phpunit.de/en/13.3/fixtures.html
- https://docs.phpunit.de/en/13.3/attributes.html
