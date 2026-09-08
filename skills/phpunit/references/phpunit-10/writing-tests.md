# Writing Tests

## Basic structure

Test classes extend `PHPUnit\Framework\TestCase`. One class per unit under test, one file per class, ending in `Test.php`:

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

## Recognizing a method as a test

- Default: any `public` method named `test*`.
- Preferred in PHPUnit 10: mark any public method with `#[Test]` regardless of its name — this is the native-attribute style and doesn't force awkward names.

## Data providers

Provider methods must be `public static`, return an iterable/array, and not themselves start with `test`:

```php
public static function additionProvider(): array
{
    return [
        'adding zeros' => [0, 0, 0],
        'one plus one' => [1, 1, 2],
    ];
}

#[DataProvider('additionProvider')]
public function testAdd(int $a, int $b, int $expected): void
{
    $this->assertSame($expected, $a + $b);
}
```

- Use string keys ("named datasets") — failure output shows the dataset name instead of a numeric index, which is much easier to debug.
- `#[DataProviderExternal(ExternalDataProvider::class, 'additionProvider')]` reuses a provider defined on another class.
- `#[TestWith([0, 0, 0])]` / `#[TestWithJson('[0,0,0]')]` supply inline data without a separate provider method for small cases.

## Exceptions

```php
public function testException(): void
{
    $this->expectException(InvalidArgumentException::class);
    // code that throws goes AFTER expectException*() calls
    $this->thrower->doSomethingThatThrows();
}
```

`expectExceptionCode()`, `expectExceptionMessage()` (substring match, not exact), `expectExceptionMessageMatches()` (regex) refine the check. Call `expectException*()` before the code under test runs.

## Output assertions

```php
$this->expectOutputString('foo');
print 'foo';
```
Only one output expectation is allowed per test (`expectOutputString` or `expectOutputRegex`, not both).

## Incomplete / skipped tests

```php
public function testSomething(): void
{
    $this->markTestIncomplete('Not implemented yet.'); // shows as "I"
}

protected function setUp(): void
{
    if (!extension_loaded('pgsql')) {
        $this->markTestSkipped('pgsql extension not available'); // shows as "S"
    }
}
```

Prefer attribute-based skipping when the condition is static — no custom logic needed and it's visible from the method signature:

```php
#[RequiresPhpExtension('pgsql')]
final class DatabaseTest extends TestCase { /* ... */ }
```
Other requirement attributes: `#[RequiresPhp('^8.3')]`, `#[RequiresPhpunit('^10.0')]`, `#[RequiresOperatingSystem(regex)]`, `#[RequiresOperatingSystemFamily('Linux')]`, `#[RequiresFunction(name)]`, `#[RequiresMethod(class, method)]`, `#[RequiresSetting(setting, value)]`.

## Test dependencies

`#[Depends]` chains tests: the producer returns a fixture, the consumer receives it as its first (only) argument. If the depended-upon test fails, the dependent test is skipped, not run.

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

By default the value is passed by reference-like sharing; use `#[DependsUsingDeepClone]` / `#[DependsUsingShallowClone]` if the consumer must not see mutations the producer made after returning. `#[DependsOnClass]` depends on an entire other test class.

## Gotchas

- Data provider methods and `#[Before]`/`#[After]` hook methods must not be named `test*` or PHPUnit may try to run them as tests.
- `expectException()` must be called before invoking the code that throws, not after.
- A test with no assertions and no mock expectations is flagged **risky** by default unless it has `#[DoesNotPerformAssertions]`.

Source: https://docs.phpunit.de/en/10.5/writing-tests-for-phpunit.html, https://docs.phpunit.de/en/10.5/attributes.html
