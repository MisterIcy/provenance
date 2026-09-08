# Test Doubles

A test double replaces a real dependency (a "depended-on component") with a controllable substitute, so a test can isolate the unit under test.

## Quick creation: `createStub()` / `createMock()`

Both auto-generate a double implementing the given class/interface; constructor is not called, arguments aren't cloned by default.

```php
// Stub: controls indirect INPUT to the SUT
$stub = $this->createStub(SomeClass::class);
$stub->method('doSomething')->willReturn('foo');
$this->assertSame('foo', $stub->doSomething());

// Mock: verifies indirect OUTPUT (interaction) from the SUT
$observer = $this->createMock(Observer::class);
$observer->expects($this->once())
         ->method('update')
         ->with($this->equalTo('something'));

$subject->attach($observer);
$subject->doSomething(); // must call $observer->update('something') exactly once
```

**Stub vs mock, conceptually**: a stub only supplies canned return values (never fails the test by itself); a mock also asserts *how* it was called (fails the test if the expectation isn't met by the end of the test).

## Return value configuration (stubs)

- `willReturn($value)`
- `willReturnArgument($index)`
- `willReturnSelf()` — for fluent-interface doubles
- `willReturnMap([[arg1, arg2, ret], ...])`
- `willReturnCallback($callable)`
- `willThrowException($exception)`
- `onConsecutiveCalls($v1, $v2, ...)` — different value each successive call

## Invocation count matchers (mocks)

- `$this->any()` — 0+ times
- `$this->never()`
- `$this->atLeastOnce()`
- `$this->once()`
- `$this->exactly($n)`

## Argument constraints

`with($this->equalTo($x))`, `$this->identicalTo($x)`, `$this->anything()`, `$this->stringContains($s)`, `$this->greaterThan($n)`, `$this->callback(fn($arg) => ...)`.

## Full control: `getMockBuilder()`

```php
$mock = $this->getMockBuilder(SomeClass::class)
    ->onlyMethods(['methodName'])         // restrict which methods get doubled
    ->addMethods(['nonExistentMethod'])   // add methods not on the original class
    ->setConstructorArgs([$arg1, $arg2])
    ->disableOriginalConstructor()
    ->disableOriginalClone()
    ->setMockClassName('CustomDoubleName')
    ->getMock();
```

## Traits and abstract classes

```php
$mock = $this->getMockForTrait(SomeTrait::class);
$mock = $this->getMockForAbstractClass(AbstractClass::class);
```

Abstract methods are auto-mocked; concrete methods keep their real implementation (usable via `onlyMethods()` to selectively override).

## Hard limitations

- **final, private, and static methods cannot be doubled** — they run their real implementation; calling a doubled static method throws `BadMethodCallException`. If code relies on `final`/static heavily, consider wrapping it or extracting an interface instead of trying to mock around it.
- Doubles created via `createMock()`/`createStub()` disable the constructor by default — if the real constructor has required side effects your code depends on, use `getMockBuilder()` with `setConstructorArgs()` instead.

## Source

https://docs.phpunit.de/en/9.6/test-doubles.html
