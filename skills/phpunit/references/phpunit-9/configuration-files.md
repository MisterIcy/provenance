# The XML Configuration File

`phpunit.xml` (or `phpunit.xml.dist`, checked in for a shareable default) is auto-detected in the current working directory. Generate a starter file interactively with `phpunit --generate-configuration`.

## Skeleton

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         stopOnFailure="false"
         executionOrder="depends,duration"
         cacheResult="true"
         processIsolation="false">

    <testsuites>
        <testsuite name="unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>

    <coverage includeUncoveredFiles="true">
        <include>
            <directory suffix=".php">src</directory>
        </include>
    </coverage>

    <logging>
        <junit outputFile="build/junit.xml"/>
    </logging>

    <php>
        <ini name="error_reporting" value="-1"/>
        <const name="MY_CONSTANT" value="1"/>
        <env name="APP_ENV" value="testing"/>
    </php>
</phpunit>
```

## Root element attributes worth knowing

- `bootstrap` — PHP file loaded before any test (autoloading, global helpers).
- `colors` — colored CLI output (default `false`; CI terminals often need `--colors=always` since they don't auto-detect a TTY).
- `stopOnFailure` — halt entire run at first failure (rarely wanted outside local debugging).
- `executionOrder` — `default`, `defects` (rerun previous failures first), `duration` (slowest last... or first depending on combo), `random`, `reverse`, `size`. Comma-combine, e.g. `"depends,duration"` (dependencies still respected, then ordered by duration).
- `cacheResult` — persists a `.phpunit.result.cache` file used by `defects`/`duration` ordering and `--order-by=defects`.
- `processIsolation` — every test in its own PHP process; safe but slow, use sparingly (also settable per-test via `@runInSeparateProcess`).
- `beStrictAboutTestsThatDoNotTestAnything`, `beStrictAboutOutputDuringTests`, `beStrictAboutChangesToGlobalState`, `beStrictAboutCoversAnnotation`, `enforceTimeLimit` — XML equivalents of the risky-test CLI flags (see risky-incomplete-tests.md).

## `<testsuites>`

Each `<testsuite name="...">` can contain `<directory>` (recursive auto-discovery of `*Test.php`), `<file>` (explicit, order-preserving), and `<exclude>` (skip a path within an otherwise-included directory).

## `<coverage>`

`<include>`/`<exclude>` scope which source directories are analyzed; nested `<report>` (in some 9.x point releases) or top-level `--coverage-*` CLI flags choose output formats. See coverage-analysis.md.

## `<php>`

Sets up the PHP runtime for the whole run: `<ini>` (php.ini directives), `<const>` (define constants), `<var>`/`<env>`/`<get>`/`<post>`/`<server>` (populate superglobals) — useful for injecting test-environment config (DB DSN, feature flags) without touching real `.env` files.

## `<listeners>` / `<extensions>`

`<listeners>` (implementing `PHPUnit\Framework\TestListener`) is the 9.x extension point for observing test run events — deprecated as of 8.0 and removed in PHPUnit 10's Events subsystem (see events.md), but still functional and commonly used in 9.x codebases. `<extensions>` registers `PHPUnit\Runner\BeforeFirstTestHook`/`AfterLastTestHook` style extension classes, the other 9.x extension mechanism.

## Source

https://docs.phpunit.de/en/9.6/configuration.html
