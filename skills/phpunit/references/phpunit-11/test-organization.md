# Test Organization (PHPUnit 11)

## Mirror the source tree

Test case classes conventionally mirror the package/class structure of the system under test:

```
src/
├── Camera.php
├── canvas/Canvas.php
└── shapes/Sphere.php

tests/unit/
├── CameraTest.php
├── canvas/CanvasTest.php
└── shapes/SphereTest.php
```

Separate test *kinds* into distinct top-level directories, e.g. `tests/unit/` vs. `tests/integration/`, so they can be run/filtered independently.

## Test suites in XML config

```xml
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/11.5/phpunit.xsd"
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

Run a specific suite: `vendor/bin/phpunit --testsuite unit`. List what's defined: `vendor/bin/phpunit --list-suites`.

## Grouping tests (cuts across directories)

```php
#[Group('slow')]
final class ReportGeneratorTest extends TestCase { /* ... */ }
```

```bash
vendor/bin/phpunit --group slow
vendor/bin/phpunit --exclude-group slow
vendor/bin/phpunit --list-groups
```

`#[Ticket('PROJ-123')]` is a semantic alias for `#[Group(...)]`, useful for tagging tests tied to a bug/ticket.

## Size attributes double as organization + timeout policy

`#[Small]`, `#[Medium]`, `#[Large]` classify tests (default timeouts of 1s/10s/60s respectively when `--enforce-time-limit` is on) — see `risky-incomplete-tests.md`.

## Filtering without groups

```bash
vendor/bin/phpunit --filter testCreatesWorld       # by method/test name
vendor/bin/phpunit --covers Invoice                # tests covering a given class
vendor/bin/phpunit tests/unit/WorldTest.php         # a single file
```

Source: https://docs.phpunit.de/en/11.5/organizing-tests.html
