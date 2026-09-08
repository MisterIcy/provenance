# Writing Tests

A PHPUnit test is a method on a class extending `PHPUnit\Framework\TestCase`. Conventionally the class is named `{ClassName}Test` and lives in a file `{ClassName}Test.php` mirroring the source tree (e.g. `src/Email.php` → `tests/EmailTest.php`).

```php
<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;

final class EmailTest extends TestCase
{
    public function testCanBeCreatedFromValidEmail(): void
    {
        $email = Email::fromString('user@example.org');
        $this->assertSame('user@example.org', $email->asString());
    }
}
```

## Naming a test method

Either prefix the method name with `test`, or use the `#[Test]` attribute on any visibility-public method name:

```php
#[Test]
public function canBeCreatedFromAValidEmailAddress(): void { ... }
```

## Structure: Arrange-Act-Assert

Write tests as Arrange (set up inputs/collaborators), Act (invoke the SUT), Assert (check the outcome). For exception tests, flip Act and Assert into "Arrange-Expect-Act": call `expectException()` *before* the code that throws.

```php
public function testInvalidEmailThrows(): void
{
    $this->expectException(InvalidArgumentException::class);
    Email::fromString('not-an-email');
}
```
Other expectation methods: `expectExceptionCode()`, `expectExceptionMessage()`, `expectExceptionMessageMatches()`.

## Data providers

A data provider is a `public static` method returning an iterable of argument arrays (or `Generator`). PHPUnit runs the test once per data set; a failure in one data set doesn't stop the others.

```php
#[DataProvider('additionProvider')]
public function testAdd(int $a, int $b, int $expected): void
{
    $this->assertSame($expected, $a + $b);
}

public static function additionProvider(): array
{
    return [
        'zero plus one' => [0, 1, 1],
        'one plus one'  => [1, 1, 2],
    ];
}
```
Use string keys ("named data sets") — they show up in output and in `--filter testAdd@'one plus one'`. Related attributes: `#[DataProviderExternal]` (method on another class), `#[TestWith([...])]` / `#[TestWithJson('[...]')]` for small inline data sets without a separate method.

## Test dependencies

`#[Depends('testProducer')]` lets a test consume the return value of another test in the same class:

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
    $this->assertNotEmpty($stack);
    return $stack;
}
```
If the producer fails or errors, all dependents are skipped rather than run. Use sparingly — independent tests are easier to reason about and to run in isolation/parallel; reach for `#[Depends]` mainly when the fixture is expensive to rebuild. Variants: `#[DependsUsingDeepClone]`, `#[DependsUsingShallowClone]`, `#[DependsExternal]` (depend on a test in another class).

## Gotchas

- A test that makes no assertions and sets no mock expectations is reported as risky ("useless"); use `#[DoesNotPerformAssertions]` if that's intentional.
- Don't use `markTestSkipped()`/`markTestIncomplete()` to paper over a genuinely failing test — reserve skipping for environment/requirement mismatches (see `risky-incomplete-tests.md`).
- `declare(strict_types=1)` at the top of every test file is standard practice and catches type-coercion bugs in the SUT.

## Source
- https://docs.phpunit.de/en/13.3/writing-tests-for-phpunit.html
- https://docs.phpunit.de/en/13.3/attributes.html
