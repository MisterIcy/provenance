# XML Configuration Files (`phpunit.xml`)

## Precedence model

Effective config = **built-in defaults** → overridden by **`phpunit.xml`** → overridden by **CLI options**. CLI always wins.

Generate a starter file instead of hand-writing one:

```bash
./vendor/bin/phpunit --generate-configuration
./vendor/bin/phpunit --migrate-configuration   # upgrade an old-schema file in place
```

## Root element

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/12.5/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         cacheDirectory=".phpunit.cache"
         cacheResult="true"
         colors="true"
         processIsolation="false"
         executionOrder="default"
         enforceTimeLimit="false"
         stopOnFailure="false">
```

Common top-level attributes: `bootstrap`, `colors`, `cacheDirectory`, `cacheResult` (required for `defects`/`duration` ordering), `processIsolation`, `defaultTestSuite`, `executionOrder`, every `stopOn*` and `failOn*` flag (mirrors the CLI `--stop-on-*`/`--fail-on-*` families).

## `<testsuites>`

```xml
<testsuites>
    <testsuite name="unit">
        <directory>tests/unit</directory>
    </testsuite>
    <testsuite name="integration" bootstrap="tests/integration/bootstrap.php">
        <directory>tests/integration</directory>
        <exclude>tests/integration/slow</exclude>
    </testsuite>
    <testsuite name="smoke">
        <file>tests/smoke/FirstTest.php</file>
    </testsuite>
</testsuites>
```

## `<source>` — scopes coverage AND issue reporting to first-party code

```xml
<source restrictNotices="true" restrictWarnings="true" ignoreIndirectDeprecations="true">
    <include>
        <directory suffix=".php">src</directory>
    </include>
    <exclude>
        <directory suffix=".php">src/generated</directory>
        <file>src/autoload.php</file>
    </exclude>
</source>
```

Attributes: `identifyIssueTrigger` (default true — classifies issues as self/direct/indirect, at a performance cost), `ignoreSelfDeprecations`/`ignoreDirectDeprecations`/`ignoreIndirectDeprecations`, `restrictNotices`/`restrictWarnings`, `baseline` (path to a baseline file), and the `ignoreSuppressionOf*` family that forces `@`-suppressed issues to be reported anyway.

## `<coverage>`

```xml
<coverage includeUncoveredFiles="true" pathCoverage="false">
    <report>
        <html outputDirectory="build/coverage-html" lowUpperBound="50" highLowerBound="90"/>
        <clover outputFile="build/clover.xml"/>
        <text outputFile="php://stdout" showOnlySummary="true"/>
    </report>
</coverage>
```

## `<logging>`

```xml
<logging>
    <junit outputFile="build/junit.xml"/>
    <otr outputFile="build/otr.xml" includeGitInformation="false"/>
    <teamcity outputFile="build/teamcity.txt"/>
</logging>
```

## `<php>` — runtime env for the test process

```xml
<php>
    <ini name="display_errors" value="1"/>
    <const name="APP_ENV" value="test"/>
    <var name="foo" value="bar"/>
    <env name="DATABASE_URL" value="sqlite://test.db" force="true"/>
</php>
```

`verbatim="true"` on a `<php>` child prevents PHPUnit's usual string-to-bool coercion (so `"true"` stays a string, not `bool(true)`).

## `<groups>`

```xml
<groups>
    <include><group>unit</group></include>
    <exclude><group>slow</group></exclude>
</groups>
```

Equivalent to `--group unit --exclude-group slow`.

## `<extensions>`

```xml
<extensions>
    <bootstrap class="Vendor\ExampleExtension\Extension">
        <parameter name="message" value="the-message"/>
    </bootstrap>
</extensions>
```

## PHPUnit 12 notes

- Schema is versioned per release — point `xsi:noNamespaceSchemaLocation` at `https://schema.phpunit.de/12.5/phpunit.xsd` (or your exact patch version) so IDE validation matches your installed PHPUnit.
- `<logging><otr .../></logging>` (Open Test Reporting) is the current recommended machine-readable log format, alongside legacy JUnit.
- `<source>`'s deprecation/notice/warning-restriction attributes are the main lever for adopting stricter `error-handling.md` behavior incrementally on a legacy codebase — combine with `baseline` for existing debt.
- Always run `--migrate-configuration` after upgrading from PHPUnit 11, rather than hand-editing an old file — element/attribute names do shift between majors.

## Source

- https://docs.phpunit.de/en/12.5/configuration.html
- https://docs.phpunit.de/en/12.5/xml-configuration-file.html
