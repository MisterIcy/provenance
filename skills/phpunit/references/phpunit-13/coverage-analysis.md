# Code Coverage Analysis

## Prerequisite: a coverage driver

Coverage requires **Xdebug** (coverage mode enabled) or **PCOV** loaded in the CLI's `php.ini`. Without one, PHPUnit warns and coverage flags are no-ops. PCOV supports line coverage only; Xdebug additionally supports branch/path coverage (`--branch-coverage`, `--path-coverage`), which is slower.

## Generating reports

```bash
phpunit --coverage-html coverage/            # browsable HTML
phpunit --coverage-clover clover.xml          # CI-consumable XML
phpunit --coverage-cobertura cobertura.xml
phpunit --coverage-text                       # stdout summary
phpunit --coverage-php coverage.php           # serialized, for merging across runs
```

## Declaring what a test covers

```php
#[CoversClass(Invoice::class)]
#[UsesClass(Money::class)]
final class InvoiceTest extends TestCase { }
```
`#[CoversClass]`/`#[CoversMethod]`/`#[CoversFunction]`/`#[CoversTrait]`/`#[CoversNamespace]` restrict which code this test's executed lines count toward. `#[UsesClass]` (and its `#[Uses*]` siblings) mark code the test legitimately exercises as a side effect, without claiming to cover it — this keeps `beStrictAboutCoverageMetadata` from flagging the test as risky for touching that code. `#[CoversNothing]` excludes a test entirely (typical for integration/E2E tests).

## Configuring the source set (XML)

```xml
<source includeUncoveredFiles="true">
    <include>
        <directory suffix=".php">src</directory>
    </include>
    <exclude>
        <directory suffix=".php">src/generated</directory>
    </exclude>
</source>
```
`includeUncoveredFiles="true"` (the default) reports files with *zero* executed lines too — without it, a file nobody's test ever loads silently vanishes from the report instead of showing 0%.

## Ignoring genuinely untestable code

```php
/** @codeCoverageIgnore */
public function unreachableCode(): void { }

// @codeCoverageIgnoreStart
if (false) { /* dead branch */ }
// @codeCoverageIgnoreEnd
```

## Gotcha

Coverage is measured at the **bytecode** level (via Xdebug/PCOV instrumentation), not by parsing source directly — PHP opcode optimizations mean the reported "lines" map to bytecode, so coverage can occasionally look slightly off relative to naive line-by-line reading of the source.

## Source
- https://docs.phpunit.de/en/13.3/code-coverage.html
- https://docs.phpunit.de/en/13.3/attributes.html
