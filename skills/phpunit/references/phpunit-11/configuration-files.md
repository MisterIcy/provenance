# XML Configuration File (PHPUnit 11)

## Skeleton

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/11.5/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         cacheDirectory=".phpunit.cache"
         executionOrder="depends,defects"
         failOnWarning="true"
         beStrictAboutTestsThatDoNotTestAnything="true">

    <testsuites>
        <testsuite name="unit">
            <directory>tests/unit</directory>
        </testsuite>
    </testsuites>

    <source>
        <include>
            <directory suffix=".php">src</directory>
        </include>
        <exclude>
            <directory suffix=".php">src/generated</directory>
        </exclude>
    </source>

    <coverage includeUncoveredFiles="true">
        <report>
            <html outputDirectory="coverage"/>
        </report>
    </coverage>
</phpunit>
```

Note the schema URL is pinned to the minor version (`.../11.5/phpunit.xsd`) — bump it when you upgrade PHPUnit minor versions, or use `--migrate-configuration` to have PHPUnit rewrite the file for you.

## Key sections

| Element | Purpose |
|---|---|
| `<testsuites>` | Named suites of `<directory>`/`<file>`, with `<exclude>` |
| `<source>` | First-party code boundary — drives coverage *and* error-handling scoping (deprecation/notice/warning restriction) |
| `<coverage>` | Report formats: HTML, Clover, Cobertura, Crap4J, XML, PHP, text |
| `<logging>` | JUnit XML, TeamCity, TestDox HTML/text output |
| `<groups>` | Include/exclude by `#[Group]` name |
| `<php>` | Runtime env: `<ini>`, `<const>`, `<var>`, `<env>`, `<server>`, `<includePath>` |
| `<extensions>` | `<bootstrap class="...">` registers a custom `Extension` (see `events.md`) |

## Notable root-element attributes and defaults

| Attribute | Default | Notes |
|---|---|---|
| `cacheResult` | `true` | needed for `executionOrder="defects"` |
| `executionOrder` | `default` | also: `defects`, `duration`, `random`, `size`, `depends`, combinable as `"depends,defects"` |
| `failOnWarning` | `false` | XML equivalent of `--fail-on-warning` |
| `failOnRisky` | `false` | XML equivalent of `--fail-on-risky` |
| `beStrictAboutTestsThatDoNotTestAnything` | `true` | flags assertion-less tests as risky |
| `processIsolation` | `false` | one PHP process per test — slow, use sparingly |
| `stopOnDefect` | `false` | |
| `colors` | `false` | `true`≈auto |
| `timeoutForSmallTests` | `1` (sec) | only enforced with `enforceTimeLimit="true"` |

## Version note

`restrictDeprecations` (a `<source>` attribute) is deprecated as of PHPUnit 11.1 — replaced by three finer-grained flags: `ignoreSelfDeprecations`, `ignoreDirectDeprecations`, `ignoreIndirectDeprecations`. See `error-handling.md`.

## Generating / migrating

```bash
vendor/bin/phpunit --generate-configuration   # interactive scaffold
vendor/bin/phpunit --migrate-configuration    # upgrade an older config in place
```

Source: https://docs.phpunit.de/en/11.5/configuration.html
