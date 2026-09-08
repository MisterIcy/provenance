# Test Doubles

Two kinds: **stubs** control indirect inputs (what a dependency returns); **mocks** verify indirect outputs (that a dependency was called correctly). A double only needs to satisfy the interface the SUT expects — it need not behave like the real thing.

## Stubs — control what comes back

```php
$stub = $this->createStub(DatabaseInterface::class);

$stub->method('query')->willReturn([['id' => 1, 'name' => 'Test']]);

// consecutive calls return different values in sequence
$stub->method('fetch')->willReturn('first', 'second');

// dynamic value via callback
$stub->method('process')->willReturnCallback(
    static fn(string $input) => strtoupper($input)
);

// argument-based mapping
$stub->method('lookup')->willReturnMap([
    ['foo', 'bar', 'result1'],
    ['baz', 'qux', 'result2'],
]);

$stub->method('configure')->willReturnSelf(); // fluent interfaces
$stub->method('connect')->willThrowException(new ConnectionException('Failed'));
```

For finer control (partial doubles, constructor args):

```php
$stub = $this->getStubBuilder(Service::class)
    ->onlyMethods(['methodOne', 'methodTwo'])
    ->disableOriginalConstructor()
    ->getStub();
```

## Mocks — verify calls happened

```php
$mock = $this->createMock(DatabaseInterface::class);

$mock->expects($this->once())
    ->method('save')
    ->with('data', 123);
```

Call-count matchers: `$this->once()`, `$this->exactly(3)`, `$this->never()`. `atLeastOnce()` and `any()` are discouraged when the count genuinely doesn't matter — use `createStub()` instead in that case.

Argument constraints: `$this->equalTo(...)`, `identicalTo(...)`, `isType('array')`, `isInstanceOf(Class::class)`, `stringContains(...)`, `matchesRegularExpression(...)`, `countOf(...)`.

Call-order verification (`->id('x')` / `->after('x')`) exists but is discouraged — it couples tests to implementation order and makes them brittle.

## Interface unions and PHP 8.4 hooked properties

```php
$stub = $this->createStubForIntersectionOfInterfaces([InterfaceA::class, InterfaceB::class]);

use PHPUnit\Framework\MockObject\Runtime\PropertyHook;
$stub->method(PropertyHook::get('property'))->willReturn('value');
```

## PHPUnit 12 changes vs. 11 — don't do these anymore

- `->expects($this->any())` is **deprecated** — use `createStub()` when you don't care about call count.
- Calling `->with()` on a plain **stub** (not a mock) is **deprecated** — if you need argument verification, use `createMock()`.
- Call-order (`id()`/`after()`) remains available but is flagged as a maintainability risk in the docs, not just a style preference.

## Limitations

Cannot double: `final` classes, `final`/`private`/`static` methods, or enums. Doubled static methods become exception-throwing stubs, not real doubles.

## Practical guidance

- Prefer doubling interfaces over concrete classes.
- Use a stub when only the return value matters; use a mock only when the *fact of the call* is the thing under test.
- Mock service/repository boundaries, not domain objects.
- One test verifies either state or interaction — not both — and keep double setup to only what the test actually exercises.

## Source

- https://docs.phpunit.de/en/12.5/test-doubles.html
