# Organizing Tests

## Filesystem convention

PHPUnit recursively scans a test directory for files matching `*Test.php` (configurable via `--test-suffix`). Mirror your source tree:

```
src/Currency.php   ->  tests/CurrencyTest.php
src/Money.php      ->  tests/MoneyTest.php
```

## `phpunit.xml` test suites

Define one or more named suites, each pointing at a directory (auto-discovered) or explicit files (explicit order):

```xml
<phpunit bootstrap="vendor/autoload.php">
  <testsuites>
    <testsuite name="unit">
      <directory>tests/Unit</directory>
    </testsuite>
    <testsuite name="integration">
      <directory>tests/Integration</directory>
      <exclude>tests/Integration/SlowTest.php</exclude>
    </testsuite>
  </testsuites>
</phpunit>
```

Run one suite with `phpunit --testsuite unit`. Listing individual `<file>` elements instead of a `<directory>` lets you pin execution order explicitly — relevant when tests have order-sensitive `@depends` relationships across files.

## Grouping with `@group`

Tag tests (method- or class-level) to run/exclude subsets independent of file layout:

```php
/** @group slow */
public function testExpensiveImport(): void { /* ... */ }
```

```bash
phpunit --group slow
phpunit --exclude-group slow
phpunit --list-groups
```

`@author`, `@ticket`, `@large`/`@medium`/`@small` are all effectively aliases for `@group` under the hood (author name, ticket ID, or size respectively become the group name), so they compose with `--group`/`--exclude-group` the same way.

## Bootstrap / autoloading

`bootstrap="tests/bootstrap.php"` (or Composer's `vendor/autoload.php`) runs before any test executes — the natural place to wire up autoloading, constants, or global test helpers.

## Practical layout tips

- Keep one test class per production class, named `{Class}Test`, in the mirrored path — this is what most tooling (IDEs, `--filter`) assumes.
- Use `@group` for cross-cutting concerns (slow, db, external-api) rather than trying to encode them in directory structure.
- Use multiple `<testsuite>` blocks (unit vs integration vs functional) so CI can run fast unit tests on every push and slower suites less often.

## Source

https://docs.phpunit.de/en/9.6/organizing-tests.html
