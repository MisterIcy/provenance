# Configuration Files

## Layering

Settings apply in three layers, later overriding earlier: **built-in defaults** → **`phpunit.xml`** → **CLI options**. A CLI flag always wins for that specific setting; everything else keeps whatever the XML (or default) specified.

By default PHPUnit looks for `phpunit.xml` (falling back to `phpunit.xml.dist`) in the current directory. Point elsewhere with `-c`/`--configuration <file>`, or skip config entirely with `--no-configuration`.

## Minimal example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns="https://schema.phpunit.de/13.3"
         bootstrap="vendor/autoload.php"
         defaultTestSuite="unit"
         cacheDirectory=".phpunit.cache"
         colors="true"
         beStrictAboutCoverageMetadata="true">

    <testsuites>
        <testsuite name="unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/Integration</directory>
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

    <coverage>
        <report>
            <html outputDirectory="coverage"/>
            <clover outputFile="clover.xml"/>
        </report>
    </coverage>

    <php>
        <ini name="display_errors" value="On"/>
        <env name="APP_ENV" value="testing"/>
        <const name="MY_CONST" value="1"/>
    </php>

    <logging>
        <junit outputFile="junit.xml"/>
    </logging>

    <extensions>
        <bootstrap class="Vendor\MyExtension\MyExtension"/>
    </extensions>
</phpunit>
```

## Key sections

- **`<testsuites>`** — one or more named suites, each a set of `<directory>`/`<file>` entries; run one via `--testsuite <name>`; `defaultTestSuite` on the root picks which runs with no `--testsuite` flag.
- **`<source>`** — declares your project's *own* code (as opposed to vendored/third-party) for coverage measurement *and* for error-handling classification (self vs. direct vs. indirect deprecations, see `error-handling.md`). `<include>`/`<exclude>` take `<directory suffix=".php">` / `<file>`.
- **`<coverage>`** — `includeUncoveredFiles`, `branchCoverage`, `pathCoverage`, and a `<report>` block listing output formats (`html`, `clover`, `cobertura`, `crap4j`, `php`, `text`).
- **`<php>`** — `<ini>` (php.ini directives), `<env>` (environment variables), `<const>` (define constants), `<var>`, plus superglobal simulation (`<get>`, `<post>`, `<server>`, `<cookie>`).
- **`<logging>`** — `<junit>`, `<teamcity>`, `<testdoxHtml>`, `<testdoxText>` output files.
- **`<groups>`** — `<include>`/`<exclude>` by `#[Group]` name, an XML-level equivalent of `--group`/`--exclude-group`.
- **`<extensions>`** — `<bootstrap class="...">` registers a PHPUnit extension (see `events.md`); can pass `<parameter name="..." value="..."/>` children.

## Root `<phpunit>` attributes worth knowing

- Execution: `bootstrap`, `cacheDirectory`, `processIsolation`, `colors`, `columns`, `executionOrder` (`default`, `defects`, `depends`, `random`, `duration-ascending`, `size-ascending`, ...)
- Failure gates: `stopOnDefect`, `stopOnError`, `stopOnFailure`, `failOnWarning`, `failOnRisky`, `failOnAllIssues`
- Strictness: `beStrictAboutOutputDuringTests`, `beStrictAboutTestsThatDoNotTestAnything`, `requireCoverageMetadata`, `requireSealedMockObjects`
- Timeouts: `enforceTimeLimit`, `defaultTimeLimit`, `timeoutForSmallTests`, `timeoutForMediumTests`, `timeoutForLargeTests`

## Source
- https://docs.phpunit.de/en/13.3/configuration.html
- https://docs.phpunit.de/en/13.3/xml-configuration-file.html
