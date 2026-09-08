# Writing Tests

Requires PHP 8.3+. A test is a method on a class extending `PHPUnit\Framework\TestCase`, named `test*()` or marked `#[Test]`.

```php
<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;

final class EmailTest extends TestCase
{
    public function testCanBeCreatedFromValidEmail(): void
    {
        $string = 'user@example.org';
        $email = Email::fromString($string);
        $this->assertSame($string, $email->asString());
    }

    #[Test]
    public function rejectsInvalidEmail(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Email::fromString('invalid');
    }
}
```

## Structure and gotchas

- **Arrange, Act, Assert.** Prepare inputs, run the unit, then assert.
- **Arrange, Expect, Act for exceptions.** Call `expectException()`/`expectExceptionMessage()`/`expectExceptionCode()`/`expectExceptionMessageMatches()`/`expectExceptionObject()` **before** invoking the code that throws.
- The **first failed assertion halts the method** — later assertions in the same test never run. When verifying several related values, assert the whole structure as one comparison (e.g. compare an array/object) rather than one assertion per field, so you get one clear diff.
- Data providers run **before** `setUp()`/`setUpBeforeClass()`.

## Data providers

Provider methods must be `public static`, return an iterable, and each element must be an array of arguments.

```php
use PHPUnit\Framework\Attributes\DataProvider;

final class NumericDataSetsTest extends TestCase
{
    public static function additionProvider(): array
    {
        return [
            'adding zeros'  => [0, 0, 0],
            'zero plus one' => [0, 1, 1],
        ];
    }

    #[DataProvider('additionProvider')]
    public function testAdd(int $a, int $b, int $expected): void
    {
        $this->assertSame($expected, $a + $b);
    }
}
```

Named keys become the readable dataset labels in output and in `--filter 'testAdd@"adding zeros"'`. Also available: `#[TestWith([0, 0, 0])]` for inline data, `#[TestWithJson('[0, 0, 0]')]`, and `#[DataProviderExternal(ClassName::class, 'method')]` to reuse a provider from another class.

## Test dependencies

`#[Depends('testMethodName')]` passes a producer test's return value into a dependent test, and skips the dependent test if the producer fails/errors — this improves defect localization by not reporting a cascade of unrelated failures.

```php
use PHPUnit\Framework\Attributes\Depends;

public function testEmpty(): array
{
    $stack = [];
    $this->assertEmpty($stack);
    return $stack;
}

#[Depends('testEmpty')]
public function testPush(array $stack): array
{
    $stack[] = 'foo';
    $this->assertSame(['foo'], $stack);
    return $stack;
}
```

Variants: `#[DependsUsingDeepClone('testEmpty')]` (deep-clones the returned value instead of passing the same reference), `#[DependsOnClass(ClassName::class)]`, `#[DependsExternal(ClassName::class, 'method')]`.

## Testing output

```php
public function testExpectFooActualFoo(): void
{
    $this->expectOutputString('foo');
    print 'foo';
}
```

`expectOutputRegex('/pattern/')` is the regex variant — the two cannot be combined in one test. `expectErrorLog()` verifies that `error_log()` was invoked.

## Incomplete / skipped tests

```php
$this->markTestIncomplete('Not yet implemented.');
$this->markTestSkipped('PostgreSQL extension unavailable.');
```

Prefer the declarative attributes when the condition is static/environmental: `#[RequiresPhp('>= 8.3')]`, `#[RequiresPhpExtension('pgsql')]`, `#[RequiresSetting(...)]`, `#[RequiresOperatingSystem(...)]`, `#[RequiresMethod(...)]`, `#[RequiresFunction(...)]`, `#[RequiresPhpunit('>= 12.0')]` — see `annotations.md` for the full attribute catalog.

## Source

- https://docs.phpunit.de/en/12.5/writing-tests-for-phpunit.html
