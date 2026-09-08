# Test Doubles

**Stubs** control indirect *input* to the SUT (return canned values). **Mocks** verify indirect *output* (that a collaborator was called a certain way). A double only needs to satisfy the same API as the real dependency, not its behavior.

## Creating doubles

```php
$stub = $this->createStub(Database::class);
$mock = $this->createMock(Database::class);

// preconfigured in one call
$stub = $this->createConfiguredStub(Database::class, ['query' => [['id' => 1]]]);
$mock = $this->createConfiguredMock(Database::class, ['query' => [['id' => 1]]]);

// only double specific methods, real object otherwise
$service = $this->createPartialMock(Service::class, ['databaseQuery']);

// full control (e.g. disabling auto-generated return values)
$stub = $this->getStubBuilder(Database::class)
    ->onlyMethods(['query'])
    ->disableAutoReturnValueGeneration()
    ->getStub();
```
Works for interfaces, abstract classes, and (with `createPartialMock`) concrete classes/traits.

## Configuring return behavior

```php
$stub->method('query')->willReturn([['id' => 1]]);
$stub->method('query')->willReturn('first', 'second');       // sequential calls
$stub->method('query')->willReturnMap([                       // dispatch on args
    ['SELECT *', [['id' => 1]]],
    ['SELECT id', [['id' => 2]]],
]);
$stub->method('query')->willReturnStrictMap([[1, 'one'], [2, 'two']]); // throws if unmatched
$stub->method('transform')->willReturnCallback(static fn(string $s) => strtoupper($s));
$stub->method('setValue')->willReturnSelf();                  // fluent APIs
$stub->method('echo')->willReturnArgument(0);
$stub->method('query')->willThrowException(new DatabaseException('down'));
```

## Mock expectations

```php
$mock->expects($this->once())->method('save');
$mock->expects($this->exactly(3))->method('log');
$mock->expects($this->never())->method('delete');

$mock->expects($this->once())
    ->method('execute')
    ->with('INSERT INTO users VALUES (?, ?);', 'John', 25);

$mock->expects($this->once())
    ->method('save')
    ->with($this->isInstanceOf(User::class), $this->greaterThan(0));
```
`atLeastOnce()` and `any()` exist but are discouraged/soft-deprecated — prefer a stub, or `once()`/`exactly()`, for anything you actually need to assert.

### Call ordering

```php
$dispatcher->expects($this->exactly(2))->method('dispatch')
    ->withParameterSetsInOrder([new UserCreatedEvent], [new EmailSentEvent]);

$logger->expects($this->exactly(3))->method('log')
    ->withParameterSetsInAnyOrder(['info', 'a'], ['info', 'b'], ['info', 'c']);

// or pin ordering between two different methods
$mock->expects($this->once())->method('open')->id('connection-opened');
$mock->expects($this->once())->method('query')->after('connection-opened');
```

## Sealed doubles (strictness)

`->seal()` locks a double against further, unconfigured calls — a sealed mock implicitly asserts `never()` for anything not explicitly expected:

```php
$mock->expects($this->once())->method('save')->seal();
$mock->doSomethingElse(); // fails: not configured, double is sealed
```
Project-wide enforcement: `<phpunit requireSealedMockObjects="true" />` — makes any unsealed mock a risky test.

## PHP 8.4 property hooks

```php
use PHPUnit\Framework\MockObject\Runtime\PropertyHook;

$stub = $this->createStub(HasGetHookedProperty::class);
$stub->method(PropertyHook::get('property'))->willReturn('value');

$mock = $this->createMock(HasSetHookedProperty::class);
$mock->expects($this->once())->method(PropertyHook::set('property'))->with('new-value');
```
Plain (non-hooked) properties need opt-in doubling: `getStubBuilder(...)->doubleProperties(['status'])`.

## Notable in PHPUnit 13

- **Prophecy and other legacy mocking APIs are gone** — `createMock`/`createStub` (and the builder) are the only API.
- **Sealed test doubles** (`seal()`, `requireSealedMockObjects`) are new.
- **`withParameterSetsInOrder`/`InAnyOrder`/`InPartialOrder`** are the current call-argument-sequencing API.
- `any()` is marked for eventual removal; `id()`/`after()` are soft-deprecated in favor of the parameter-set methods above.

## Source
- https://docs.phpunit.de/en/13.3/test-doubles.html
