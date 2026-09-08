# Organizing Tests

## Naming and layout

- Test files end in `*Test.php`; PHPUnit's directory-based discovery only picks those up.
- Mirror the source tree: `src/Canvas/Canvas.php` → `tests/unit/Canvas/CanvasTest.php`.
- Separate test *kinds* into their own directories/suites (`tests/unit`, `tests/integration`) so they can be run selectively — integration tests are usually slower and less parallelizable.

## Running by path (no config needed)

```bash
phpunit tests                       # recurse and run every *Test.php under tests/
phpunit tests/unit/WorldTest.php    # a single class
```

## Test suites via XML

```xml
<phpunit xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
         bootstrap="tests/bootstrap.php">
    <testsuites>
        <testsuite name="unit">
            <directory>tests/unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/integration</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

Then `phpunit` (no args) runs everything, or `phpunit --testsuite unit` runs just one.

## Grouping across suites

`#[Group('slow')]` on a class or method tags it for cross-cutting selection independent of directory structure:

```php
#[Group('slow')]
final class ReportGenerationTest extends TestCase { /* ... */ }
```
```bash
phpunit --group slow
phpunit --exclude-group slow
```
`#[Ticket('PROJ-123')]` is an alias for `#[Group]`, useful for tying tests to issue trackers.

## Discovery/listing helpers

```bash
phpunit --list-suites
phpunit --list-tests
phpunit --list-groups
```

## Gotchas

- PHPUnit describes tests as meant to be **composable**: "we want to be able to run any number or combination of tests together" — design suites/groups so any subset is runnable in isolation, not just the full suite in a fixed order.
- `executionOrder` (XML attribute, e.g. `executionOrder="depends,duration"`) affects the order tests run in — relevant if using `#[Depends]`, since PHPUnit needs to know it can/should reorder to satisfy dependencies.

Source: https://docs.phpunit.de/en/10.5/organizing-tests.html
