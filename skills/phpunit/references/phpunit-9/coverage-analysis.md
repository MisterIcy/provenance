# Code Coverage Analysis

Code coverage measures how much of the production source was executed by the test suite. PHPUnit delegates to the `php-code-coverage` library, which needs a driver:

- **Xdebug** (with coverage mode enabled) or **PCOV** — either works for CLI PHP.
- **PHPDBG** — alternative, older option.

Without one of these, PHPUnit warns "no code coverage driver is available" and skips coverage silently.

## Generating reports

```bash
phpunit --coverage-html build/coverage      # browsable HTML report
phpunit --coverage-clover build/clover.xml  # Clover XML (CI tooling, badges)
phpunit --coverage-text                     # human-readable summary to stdout
phpunit --coverage-php build/coverage.php   # serialized PHP_CodeCoverage object
phpunit --coverage-xml build/coverage-xml   # PHPUnit's own XML format
```

Restrict analysis to relevant source with `--coverage-filter <dir>` or the XML `<coverage><include>` block; `--no-coverage` disables it entirely (fast local runs).

## Metrics

- **Line coverage** — did each executable line run at least once.
- **Branch coverage** — did each boolean condition evaluate both ways.
- **Path coverage** — were all paths through a function exercised.
- **Method/class coverage** — was the method/class touched at all.
- **CRAP index** — cyclomatic complexity weighted against coverage; a complex, poorly-covered method scores high (bad).

## `@covers` / `@uses`

Declare which production code a test targets — used both for reporting and for the "unintentionally covered code" risky-test check:

```php
/**
 * @covers \Invoice
 * @uses \Money
 */
final class InvoiceTest extends TestCase { /* ... */ }
```

Prefer class-level `@covers` (`@covers \Invoice`) over method-level — it survives internal refactors better. `@uses` documents code the test exercises as a side effect but doesn't consider itself responsible for covering.

`@coversNothing` opts a test out of coverage accounting entirely — appropriate for integration/end-to-end tests where coverage attribution to a single class doesn't make sense.

## Excluding code from coverage

```php
if (!function_exists('some_extension_only_fn')) {
    // @codeCoverageIgnoreStart
    function some_extension_only_fn() { /* ... */ }
    // @codeCoverageIgnoreEnd
}

exit; // @codeCoverageIgnore
```

## Configuration (`<coverage>` in phpunit.xml)

```xml
<coverage includeUncoveredFiles="true">
    <include>
        <directory suffix=".php">src</directory>
    </include>
    <exclude>
        <directory suffix=".php">src/Generated</directory>
    </exclude>
    <report>
        <html outputDirectory="build/coverage"/>
        <clover outputFile="build/clover.xml"/>
    </report>
</coverage>
```

- `includeUncoveredFiles="true"` (default) — files never touched by any test still show up in the report at 0%, which is usually what you want (otherwise dead/untested files disappear from the numbers).
- `processUncoveredFiles="true"` — actually loads those uncovered files to compute accurate executable-line counts (costs time).

## Gotchas

- Coverage tools slow test runs significantly (Xdebug especially) — keep a coverage-enabled run as a separate CI job, not the default local dev loop.
- A high percentage doesn't mean good tests — it means lines executed, not assertions made. Pair coverage numbers with the risky-test "unintentionally covered code" check to catch tests that touch code without meaningfully asserting on it.

## Source

https://docs.phpunit.de/en/9.6/code-coverage-analysis.html
