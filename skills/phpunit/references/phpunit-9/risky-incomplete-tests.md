# Risky, Incomplete, and Skipped Tests

## Risky tests

A test can pass yet still be flagged **risky** (`R`) — a signal that it may not be validating what it appears to, or violates test hygiene rules. Five categories, each independently toggleable:

### 1. Useless tests (no assertions)
A test that performs zero assertions is risky by default. A mock object's `expects()` counts as an assertion, so pure interaction-verification tests aren't flagged.

- Disable check: `--dont-report-useless-tests` / `beStrictAboutTestsThatDoNotTestAnything="false"`
- Silence intentionally: `@doesNotPerformAssertions` on the test method.

### 2. Unintentionally covered code
A test annotated with `@covers` that executes production code *not* listed in any `@covers`/`@uses` annotation on the class is risky.

- Enable: `--strict-coverage` / `beStrictAboutCoversAnnotation="true"`
- `forceCoversAnnotation="true"` additionally requires every test to declare `@covers` at all.

### 3. Output during test execution
Any `print`/`echo`/etc. output during a test, when this check is enabled, makes it risky.

- Enable: `--disallow-test-output` / `beStrictAboutOutputDuringTests="true"`

### 4. Time limit exceeded
Requires `@small`/`@medium`/`@large` annotation (or `--enforce-time-limit` config) and the `phpunit/php-invoker` + `pcntl` extension. Default thresholds: small = 1s, medium = 10s, large = 60s (`timeoutForSmallTests` etc. in XML config).

- Enable: `--enforce-time-limit` / `enforceTimeLimit="true"`

### 5. Global state manipulation
Detects a test that changes global state (superglobals, static properties) when it shouldn't.

- Enable: `--strict-global-state` / `beStrictAboutChangesToGlobalState="true"`

Use `--fail-on-risky` in CI to turn any risky test into a hard failure (non-zero exit), rather than just a warning character in output.

## Incomplete tests

Use when a test is stubbed out but not yet implemented — distinguishes "not done" from "broken":

```php
public function testSomething(): void
{
    $this->markTestIncomplete('Not implemented yet.');
}
```

Reported with `I`; overall run summary says "OK, but incomplete or skipped tests!" rather than a clean OK.

## Skipped tests

Use for environment-dependent tests (missing extension, wrong OS, etc.):

```php
protected function setUp(): void
{
    if (!extension_loaded('mysqli')) {
        $this->markTestSkipped('mysqli extension not available.');
    }
}
```

### Declarative skipping with `@requires`

```php
/**
 * @requires PHP >= 8.0
 * @requires extension redis >= 2.2.0
 * @requires OS Linux
 * @requires function imap_open
 * @requires setting date.timezone Europe/Berlin
 */
public function testConnection(): void { /* ... */ }
```

Version comparisons support `<`, `<=`, `>`, `>=`, `=`/`==`, `!=`/`<>`. `@requires` can be class-level (applies to all methods) or method-level.

## Source

- https://docs.phpunit.de/en/9.6/risky-tests.html
- https://docs.phpunit.de/en/9.6/incomplete-and-skipped-tests.html
