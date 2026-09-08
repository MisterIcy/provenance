# Code Coverage Analysis (PHPUnit 11)

## Prerequisites

Coverage collection requires a driver: **Xdebug** (set its coverage mode) or **PCOV**. Without one, `--coverage-*` flags produce a warning and no data. PCOV supports line coverage only; branch/path coverage require Xdebug.

## Coverage metrics tracked

- Line coverage — did each executable line run
- Branch coverage (Xdebug only) — did a boolean expression evaluate both true and false
- Path coverage (Xdebug only) — were all execution paths exercised
- Method/function and class/trait coverage
- CRAP index — cyclomatic complexity combined with coverage, flags risky-to-maintain code

## Declaring what a test covers

```php
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\UsesClass;

#[CoversClass(Invoice::class)]
#[UsesClass(Money::class)]
final class InvoiceTest extends TestCase
{
    public function testAmountInitiallyIsEmpty(): void
    {
        $this->assertEquals(new Money, (new Invoice)->amount());
    }
}
```

- `#[CoversClass]`, `#[CoversMethod]`, `#[CoversFunction]`, `#[CoversTrait]` — declare the exact unit(s) this test's coverage counts toward. A method only counts as covered when *all* its executable lines run.
- `#[UsesClass]` / `#[UsesMethod]` / `#[UsesFunction]` / `#[UsesTrait]` — declare collaborator code the test legitimately exercises without wanting it counted as "covered by this test" — prevents false risky-test flags under `--strict-coverage`.
- `#[CoversNothing]` — for integration tests you don't want counted in unit coverage metrics at all.

## Ignoring code from coverage (still supported, not deprecated)

```php
/** @codeCoverageIgnore */
final class Foo { public function bar(): void {} }

if (false) {
    // @codeCoverageIgnoreStart
    print '*';
    // @codeCoverageIgnoreEnd
}
```

Note: unlike the general doc-comment metadata annotations (deprecated, see `annotations.md`), the three `@codeCoverageIgnore*` annotations are explicitly *not* deprecated and have no attribute equivalent yet.

## Running & reporting

```bash
vendor/bin/phpunit --coverage-html coverage/
vendor/bin/phpunit --coverage-text
vendor/bin/phpunit --coverage-clover clover.xml
vendor/bin/phpunit --coverage-filter src           # limit which dirs are analyzed
vendor/bin/phpunit --path-coverage                 # in addition to line coverage
```

XML config equivalent:

```xml
<source>
    <include>
        <directory suffix=".php">src</directory>
    </include>
</source>
<coverage includeUncoveredFiles="true">
    <report>
        <html outputDirectory="coverage"/>
    </report>
</coverage>
```

`includeUncoveredFiles="true"` (the default) lists files never touched by any test at all — turning it off hides them and inflates the reported percentage.

Source: https://docs.phpunit.de/en/11.5/code-coverage.html
