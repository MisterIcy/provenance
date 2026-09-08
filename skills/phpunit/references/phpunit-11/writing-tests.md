# Writing Tests (PHPUnit 11)

## Basic test class

```php
<?php declare(strict_types=1);

use PHPUnit\Framework\TestCase;

final class GreeterTest extends TestCase
{
    public function testGreetsWithName(): void
    {
        $greeter = new Greeter;
        $this->assertSame('Hello, Alice!', $greeter->greet('Alice'));
    }
}
```

- Test class extends `PHPUnit\Framework\TestCase`.
- Test methods are `public`, return `void`, and either start with `test` or carry the `#[Test]` attribute.
- Always start files with `declare(strict_types=1);`.
- Naming convention: `Greeter` → `GreeterTest`, mirroring the source tree (see `test-organization.md`).

## Expecting exceptions

```php
public function testThrowsOnNegativeAmount(): void
{
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('must be positive');  // substring match, NOT exact
    $this->expectExceptionCode(1234);

    new Money(-1);
}
```

- `expectExceptionMessage()` asserts the actual message *contains* the expected string — not an exact match. Use `expectExceptionMessageMatches($regex)` for regex matching.
- Call `expect*` methods *before* the code that throws.

## Data providers

```php
public static function additionProvider(): array
{
    return [
        'zero + zero' => [0, 0, 0],
        'one + one'   => [1, 1, 2],
    ];
}

#[DataProvider('additionProvider')]
public function testAdd(int $a, int $b, int $expected): void
{
    $this->assertSame($expected, $a + $b);
}
```

- The provider method must be `public static` and return an `iterable` (array or generator) of argument arrays.
- Named datasets (string keys) make failure output readable — always prefer them.
- `#[DataProviderExternal(ExternalProvider::class, 'methodName')]` pulls the provider from a different class.
- Inline alternatives: `#[TestWith([0, 0, 0])]` for a single row, `#[TestWithJson('[0,0,0]')]` for JSON-encoded data — no separate provider method needed.

## Testing output

```php
public function testPrintsFoo(): void
{
    $this->expectOutputString('foo');
    print 'foo';
}
```

- Only **one** output expectation can be set per test (`expectOutputString()` or `expectOutputRegex()`).

## Test dependencies

```php
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

- `#[Depends('producerMethod')]` chains tests, passing the producer's return value as an argument.
- If the producer fails/errors, dependent tests are automatically skipped (not run).
- Return values are passed by reference by default (mutation in one dependent test is visible to the next); use `#[DependsUsingDeepClone]` / `#[DependsUsingShallowClone]` to control cloning behavior instead.
- Use dependencies sparingly — heavy chains between tests are usually a design smell (see `fixtures.md`); prefer independent tests + test doubles.

## Gotchas

- `#[Test]` and `test*` naming are interchangeable — pick one convention per project and stick to it.
- Assertions can be called statically (`self::assertSame(...)`), as instance methods (`$this->assertSame(...)`), or as global functions (`assertSame(...)`) — all equivalent.

Source: https://docs.phpunit.de/en/11.5/writing-tests-for-phpunit.html
