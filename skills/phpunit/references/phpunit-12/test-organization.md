# Organizing Tests

Two complementary approaches; use XML config once a project outgrows plain filesystem discovery.

## Filesystem-based

PHPUnit recursively scans directories for files matching `*Test.php`. Mirror your source tree so test location is predictable:

```
src/canvas/Canvas.php        ->  tests/unit/canvas/CanvasTest.php
```

```bash
./vendor/bin/phpunit --bootstrap tests/bootstrap.php tests
./vendor/bin/phpunit --bootstrap src/autoload.php tests/unit/WorldTest.php
./vendor/bin/phpunit --bootstrap src/autoload.php tests/unit --filter test_creating_a_world
```

## XML-configuration-based

Define named suites once in `phpunit.xml` instead of repeating CLI paths every run:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/12.5/phpunit.xsd"
         bootstrap="tests/bootstrap.php">
    <testsuites>
        <testsuite name="unit">
            <directory>tests/unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/integration</directory>
            <exclude>tests/integration/slow</exclude>
        </testsuite>
        <testsuite name="smoke">
            <file>tests/smoke/FirstTest.php</file>
        </testsuite>
    </testsuites>
</phpunit>
```

Point `xsi:noNamespaceSchemaLocation` at the schema matching your installed version (`.../12.5/phpunit.xsd`) so your editor validates the file correctly.

```bash
./vendor/bin/phpunit --list-suites
./vendor/bin/phpunit --testsuite unit
./vendor/bin/phpunit               # runs everything configured
```

A `<testsuite>` can also carry its own `bootstrap`, a `phpVersion`/`phpVersionOperator` filter, and a `groups` attribute (comma-separated group names) — see `configuration-files.md` for the full `<testsuites>` schema.

## Choosing

Filesystem discovery is enough for small/single-purpose projects. Reach for `phpunit.xml` `<testsuites>` as soon as you need multiple logical groupings (unit vs. integration vs. smoke), per-suite bootstraps, or CI jobs that run a subset by name.

## Source

- https://docs.phpunit.de/en/12.5/organizing-tests.html
