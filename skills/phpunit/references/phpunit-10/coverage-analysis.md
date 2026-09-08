# Code Coverage

## Drivers

Coverage requires either:
- **Xdebug** — supports line, branch, and path coverage (must have its coverage mode enabled, e.g. `xdebug.mode=coverage` or `XDEBUG_MODE=coverage`).
- **PCOV** — line coverage only, considerably faster; good default for CI when branch/path data isn't needed.

If PHPUnit warns "no code coverage driver available," enable one of these extensions for the CLI SAPI specifically (a common gotcha: it's enabled for `php-fpm` but not the `php` CLI binary used to run tests).

## Metrics

Line, branch, path (Xdebug-only for branch/path), function/method, class/trait coverage, plus a computed CRAP index (complexity vs. coverage).

## Targeting with attributes

```php
#[CoversClass(Invoice::class)]
#[CoversFunction('calculateTotal')]
final class InvoiceTest extends TestCase { /* ... */ }
```
Restricts what this test contributes coverage data for. Pair with:
```php
#[UsesClass(Money::class)]
```
`#[UsesClass]`/`#[UsesFunction]` mark code the test is allowed to execute without attributing coverage to it — prevents false "unintentionally covered code" risky flags (see risky-incomplete-tests.md) when `--strict-coverage` is on.

`#[CoversNothing]` opts a test class out of coverage entirely — typical for integration/end-to-end tests where per-unit coverage attribution isn't meaningful.

## Excluding production code from analysis

```php
// @codeCoverageIgnoreStart
... generated or unreachable code ...
// @codeCoverageIgnoreEnd
```
Single line: `// @codeCoverageIgnore`. These doc-comment annotations are **not** deprecated (unlike most other annotations) and will keep working.

## Configuration

```xml
<source>
    <include>
        <directory suffix=".php">src</directory>
    </include>
    <exclude>
        <directory suffix=".php">src/generated</directory>
    </exclude>
</source>

<coverage includeUncoveredFiles="true" pathCoverage="false">
    <report>
        <html outputDirectory="coverage-html"/>
        <clover outputFile="coverage.xml"/>
        <text outputFile="php://stdout"/>
    </report>
</coverage>
```
`includeUncoveredFiles="true"` (default) reports files with zero executions too — recommended, otherwise coverage % looks inflated by simply never mentioning untested files. `pathCoverage` requires Xdebug.

Report formats: `html`, `clover`, `cobertura`, `crap4j`, `php` (serialized, for programmatic use), `text`, `xml`.

## Relevant CLI flags

`--coverage-html <dir>`, `--coverage-clover <file>`, `--coverage-text`, `--coverage-filter <dir>`, `--warm-coverage-cache` (precompute static analysis for faster subsequent runs), `--path-coverage`.

Source: https://docs.phpunit.de/en/10.5/code-coverage.html, https://docs.phpunit.de/en/10.5/configuration.html
