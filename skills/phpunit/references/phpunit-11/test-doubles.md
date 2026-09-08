# Test Doubles (PHPUnit 11)

## Stubs vs. Mocks

- **Stub** — replaces a dependency with a canned return value; used to control *indirect input*. Create with `createStub()`.
- **Mock** — additionally *verifies* it was called as expected; used to assert *indirect output*. Create with `createMock()`.

Both auto-generate a double implementing the given interface/class — no separate fake class needed.

## Stub configuration

```php
$stub = $this->createStub(SomeInterface::class);

$stub->method('doSomething')->willReturn('fixed value');
$stub->method('getData')->willReturn(1, 2, 3);   // sequential returns per call
```

Available `will*` behaviors:
- `willReturn($value)`
- `willReturnArgument(int $index)`
- `willReturnCallback(callable $fn)`
- `willReturnSelf()` — for fluent APIs
- `willReturnMap(array $map)` — argument tuple → return value
- `willThrowException($exception)`

## Mock verification

```php
$mock = $this->createMock(Observer::class);

$mock->expects($this->once())
    ->method('update')
    ->with($this->identicalTo('value'));

$subject->attach($mock);
$subject->notify('value');   // verified automatically at end of test
```

Invocation-count matchers: `once()`, `never()`, `atLeastOnce()`, `exactly(int $n)`, `atMost(int $n)`, `any()`.

Argument constraints for `with()`: `identicalTo()`, `equalTo()`, and the broader `PHPUnit\Framework\Constraint\*` family.

## Shortcut for simple cases

```php
$stub = $this->createConfiguredStub(SomeInterface::class, [
    'doSomething'     => 'foo',
    'doSomethingElse' => 'bar',
]);
```

`createConfiguredMock()` is the mock equivalent.

## PHP 8.4 property hooks

```php
use PHPUnit\Framework\MockObject\Runtime\PropertyHook;

$stub->method(PropertyHook::get('property'))->willReturn('value');
$mock->expects($this->once())->method(PropertyHook::set('property'))->with('value');
```

## What you cannot double

`final` methods, `private` methods, `static` methods, and enums cannot be doubled. Prefer doubling interfaces over concrete classes — it's more robust to refactoring and side-steps most of these limits.

## `getMockBuilder()` is soft-deprecated

Since PHPUnit 10.1, `getMockBuilder()`'s fine-grained configuration methods are soft-deprecated (warnings in 11, planned removal in 12): `enableArgumentCloning()`/`disableArgumentCloning()`, `disallowMockingUnknownTypes()`/`allowMockingUnknownTypes()`, `disableAutoload()`/`enableAutoload()`, `enableProxyingToOriginalMethods()`/`setProxyTarget()`, `addMethods()`, `getMockForAbstractClass()`, `getMockForTrait()`, `getMockFromWsdl()`. Use `createStub()`/`createMock()` (plus the configured-* helpers) instead.

## Intersection types

```php
$stub = $this->createStubForIntersectionOfInterfaces([X::class, Y::class]);
```

## Gotcha

An interface/class with a method literally named `method()` is soft-deprecated for doubling (name collides with the double's own fluent configuration API).

Source: https://docs.phpunit.de/en/11.5/test-doubles.html
