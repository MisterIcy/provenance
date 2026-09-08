# Test Doubles

A test double replaces a real collaborator so the test controls its indirect inputs/outputs. **Stubs** configure return values; **mocks** additionally verify how they were called. Final, private, static, and readonly methods, and enums, cannot be doubled.

## Stubs

```php
$stub = $this->createStub(Dependency::class);
$stub->method('doSomething')->willReturn('foo');
```

Shortcuts:
```php
$stub = $this->createConfiguredStub(SomeInterface::class, [
    'doSomething'     => 'foo',
    'doSomethingElse' => 'bar',
]);

// PHP 8.1+ intersection types
$stub = $this->createStubForIntersectionOfInterfaces([X::class, Y::class]);
```

Behavior configuration methods (used the same way for stubs and mocks):
```php
$stub->method('doSomething')->willReturn('foo');
$stub->method('doSomething')->willReturn(1, 2, 3);       // successive calls
$stub->method('doSomething')->willThrowException(new Exception('err'));
$stub->method('doSomething')->willReturnArgument(0);
$stub->method('doSomething')->willReturnCallback('str_rot13');
$stub->method('doSomething')->willReturnSelf();           // fluent interfaces
$stub->method('doSomething')->willReturnMap([
    ['a', 'b', 'c', 'd'],   // args a,b,c -> returns d
    ['e', 'f', 'g', 'h'],
]);
```

## Mocks

```php
$mock = $this->createMock(Observer::class);
$mock->expects($this->once())
     ->method('update')
     ->with($this->identicalTo('something'));

$subject = new Subject;
$subject->attach($mock);
$subject->doSomething();
```

Invocation-count matchers: `$this->once()`, `never()`, `atLeastOnce()`, `atMost(3)`, `exactly(5)`. (`any()` accepts any call count.)

`createConfiguredMock(Interface::class, ['method' => 'returnValue'])` combines creation + stubbing in one call. `createMockForIntersectionOfInterfaces([...])` mirrors the stub version.

## Fine-grained control: `getMockBuilder()`

```php
$mock = $this->getMockBuilder(SomeClass::class)
    ->disableOriginalConstructor()
    ->onlyMethods(['doSomething'])
    ->getMock();
```
Other builder methods: `setConstructorArgs()`, `setMockClassName()`, `disableOriginalClone()`, `disableArgumentCloning()`, `disableAutoReturnValueGeneration()`.

## Abstract classes / traits

`getMockForAbstractClass()` and `getMockForTrait()` exist but are **deprecated since 10.1, removed in PHPUnit 12** — prefer doubling an interface, or extracting a concrete collaborator to double instead.

## Gotchas

- A method literally named `method` collides with the fluent stub/mock builder API.
- Static and private methods can't be intercepted — the real implementation always runs.
- Prefer doubling interfaces over concrete classes; it keeps the double honest about the contract and avoids constructor/side-effect surprises.
- Don't double types you don't own/understand well — you can end up asserting against a mock's imagined behavior instead of the real dependency's contract.

Source: https://docs.phpunit.de/en/10.5/test-doubles.html
