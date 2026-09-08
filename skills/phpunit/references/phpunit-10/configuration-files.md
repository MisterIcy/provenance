# XML Configuration File

PHPUnit auto-discovers `phpunit.xml` then `phpunit.xml.dist` in the working directory if `-c/--configuration` isn't passed. Schema: `https://schema.phpunit.de/10.5/phpunit.xsd` (version-pinned — bump when upgrading PHPUnit).

## Minimal example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
         bootstrap="tests/bootstrap.php"
         colors="true"
         executionOrder="depends,duration"
         cacheResult="true"
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
    </source>

    <coverage includeUncoveredFiles="true">
        <report>
            <html outputDirectory="coverage"/>
            <clover outputFile="clover.xml"/>
        </report>
    </coverage>

    <php>
        <ini name="display_errors" value="1"/>
        <env name="APP_ENV" value="testing"/>
    </php>
</phpunit>
```

## Section reference

- **`<phpunit>` root** — 40+ execution-behavior attributes: stop-on-* (`stopOnFailure`, `stopOnError`, `stopOnDefect`, ...), fail-on-* (`failOnWarning`, `failOnRisky`, `failOnDeprecation`, ...), strictness (`beStrictAboutOutputDuringTests`, `beStrictAboutChangesToGlobalState`, `beStrictAboutCoverageMetadata`, `requireCoverageMetadata`), `executionOrder`, timeouts (`enforceTimeLimit`, `timeoutForSmallTests` default 1s / `...Medium` 10s / `...Large` 60s), `cacheResult` (default true) + `cacheDirectory`, `columns` (default 80), `bootstrap`, `extensionsDirectory`.
- **`<testsuites>`** — one or more `<testsuite name="...">`, each with `<directory>`/`<file>`/`<exclude>` children; optional `phpVersion`/`phpVersionOperator` for conditional inclusion.
- **`<source>`** — **new in PHPUnit 10** (replaces the old `<whitelist>`/`<filter>` from 9.x): defines what counts as "your code" for both coverage *and* error/deprecation/notice/warning attribution. `<include>`/`<exclude>` with `<directory suffix=".php">`; `restrictDeprecations`/`restrictNotices`/`restrictWarnings` scope error reporting to this source set; `<baseline>` attribute references a baseline file.
- **`<coverage>`** — `includeUncoveredFiles` (default true), `pathCoverage` (default false, needs Xdebug), `ignoreDeprecatedCodeUnits`. `<report>` child holds `<html>`, `<clover>`, `<cobertura>`, `<crap4j>`, `<php>`, `<text>`, `<xml>`.
- **`<logging>`** — `<junit>`, `<teamcity>`, `<testdoxHtml>`, `<testdoxText>`.
- **`<groups>`** — `<include>`/`<exclude>` of `<group>` names, equivalent to `--group`/`--exclude-group`.
- **`<extensions>`** — `<bootstrap class="Fully\Qualified\ClassName">` with `<parameter name="..." value="..."/>` children (see events.md).
- **`<php>`** — `<includePath>`, `<ini name="" value=""/>`, `<const>`, `<var>`, `<env force="true">`, `<get>`/`<post>`/`<cookie>`/`<server>`/`<files>`/`<request>` to populate superglobals for the test run.

## What changed vs PHPUnit 9 (know this when migrating a 9.x config)

- `<filter>`/`<whitelist>` is gone — replaced by `<source>`, which now drives error/deprecation/notice attribution too, not just coverage.
- Many boolean attributes were renamed/consolidated around the `beStrictAbout*` and `stopOn*`/`failOn*` naming families.
- Coverage report elements moved under `<coverage><report>` instead of being top-level `<logging>` entries.

Source: https://docs.phpunit.de/en/10.5/configuration.html
