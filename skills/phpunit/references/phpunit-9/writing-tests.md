# Writing Tests

## Basic structure

Test classes extend `PHPUnit\Framework\TestCase` and are named `{ClassName}Test`. Test methods must be `public`, and either:

- start with `test` (`testPushAndPop`), or
- carry the `@test` annotation in their doc-comment.

```php
<?php declare(strict_types=1);

use PHPUnit\Framework\TestCase;

final class StackTest extends TestCase
{
    public function testPushAndPop(): void
    {
        $stack = [];
        $this->assertSame(0, count($stack));

        array_push($stack, 'foo');
        $this->assertSame('foo', $stack[count($stack) - 1]);
        $this->assertSame(1, count($stack));

        $this->assertSame('foo', array_pop($stack));
        $this->assertSame(0, count($stack));
    }

    /** @test */
    public function itIsInitiallyEmpty(): void
    {
        $this->assertEmpty([]);
    }
}
```

Prefer `final` classes and `declare(strict_types=1)`; there's no reason to subclass a test case or allow implicit type coercion in assertions.

## Test dependencies (`@depends`)

A test can consume the return value of another test it depends on. If the producer fails, all its consumers are automatically skipped (not failed) — this improves defect localization since a failure isn't reported redundantly down a chain.

```php
public function testEmpty(): array
{
    $stack = [];
    $this->assertEmpty($stack);
    return $stack;
}

/** @depends testEmpty */
public function testPush(array $stack): array
{
    array_push($stack, 'foo');
    $this->assertSame('foo', $stack[count($stack) - 1]);
    return $stack;
}
```

Multiple `@depends` annotations feed arguments in the order listed. By default, objects returned by a producer are passed by reference into the consumer; use `@depends clone` or `@depends shallowClone` to force a (shallow) copy instead.

## Data providers (`@dataProvider`)

Runs the same test body against multiple input sets. The provider returns an array of arrays (or an `Iterator`/generator):

```php
/** @dataProvider additionProvider */
public function testAdd(int $a, int $b, int $expected): void
{
    $this->assertSame($expected, $a + $b);
}

public function additionProvider(): array
{
    return [
        'adding zeros' => [0, 0, 0],
        'one plus one' => [1, 1, 2],
    ];
}
```

Use string keys to get readable dataset names in output (especially with `--filter 'testAdd@one plus one'`). You can stack multiple `@dataProvider` annotations on one test method. Combined with `@depends`, provider arguments come first, dependency arguments after.

## Exception, error, warning, and notice expectations

```php
public function testException(): void
{
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('must be positive');
    $this->expectExceptionCode(1);

    throw new InvalidArgumentException('must be positive', 1);
}
```

- `expectExceptionMessageMatches($regex)` — regex match instead of substring.
- Call `expect*()` methods **before** the code that triggers the exception (PHPUnit stops executing the test as soon as the exception is thrown).

PHPUnit converts PHP errors, warnings, deprecations, and notices raised by code under test into exceptions, so they can be asserted the same way:

```php
public function testDeprecationCanBeExpected(): void
{
    $this->expectDeprecation();
    $this->expectDeprecationMessage('foo');
    trigger_error('foo', E_USER_DEPRECATED);
}
```

Analogous pairs exist for warnings (`expectWarning`/`expectWarningMessage`) and notices (`expectNotice`/`expectNoticeMessage`). To suppress an expected warning/notice instead of asserting it, use `@` on the call: `$this->assertFalse(@$writer->write('/bad/path', 'x'));`.

## Output testing

```php
public function testOutputsFoo(): void
{
    $this->expectOutputString('foo');
    print 'foo';
}
```

Also available: `expectOutputRegex()`, `getActualOutput()`, `setOutputCallback()`. Combining `expectOutput*` with `@runInSeparateProcess` doesn't work reliably — output expectations use buffering in-process.

## Gotchas

- A test with zero assertions is flagged **risky** by default (see risky-tests.md) unless it has `@doesNotPerformAssertions`.
- Assertion order matters for readability but not correctness; PHPUnit stops the method at the first failed assertion.
- `assertEquals` does loose/type-juggling comparison; prefer `assertSame` unless you specifically want loose equality (e.g., float tolerance, object `==`).

## Source

https://docs.phpunit.de/en/9.6/writing-tests-for-phpunit.html
