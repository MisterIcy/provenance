# Assertions

All assertion methods are static methods on `PHPUnit\Framework\Assert`, called via `$this->assert*()` inside a test. A test passes when every assertion holds, no expectation is violated, and no unexpected exception escapes.

## Equality vs identity

- `assertEquals($expected, $actual)` — loose (`==`-style) comparison; recurses into arrays/objects, compares `DateTime`s by value, etc. Prefer a more specific assertion when one exists — `assertEquals` hides type bugs.
- `assertSame($expected, $actual)` — strict (`===`); the default choice for scalars and object identity.
- `assertEqualsWithDelta($expected, $actual, $delta)` — float comparisons.
- `assertEqualsCanonicalizing()` — sorts before comparing (order-independent).
- `assertEqualsIgnoringCase()` — case-insensitive.
- `assertObjectEquals($expected, $actual, method: 'equals')` — delegate comparison to a method on the object itself, useful for value objects with custom equality.

## Arrays

- `assertArrayHasKey($key, $array)`
- `assertCount($n, $countable)` / `assertSameSize($a, $b)`
- `assertContains($needle, $haystack)` (strict) / `assertContainsEquals()` (loose)
- `assertContainsOnly*()` family — every element is of a given type
- `assertEmpty()` / `assertNotEmpty()`
- `assertIsList($array)` — sequential `0..n-1` integer keys (PHP 8.1+ `array_is_list()` semantics)
- New-ish, order/key-aware array comparisons: `assertArraysAreIdentical()`, `assertArraysAreIdenticalIgnoringOrder()`, `assertArraysHaveIdenticalValues()`, `assertArraysHaveIdenticalValuesIgnoringOrder()`, `assertArrayIsIdenticalToArrayOnlyConsideringListOfKeys()` — reach for these instead of hand-rolling `sort()` + `assertSame()` when order or a subset of keys shouldn't matter.

## Strings

- `assertStringContainsString()` / `assertStringContainsStringIgnoringCase()`
- `assertStringStartsWith()` / `assertStringEndsWith()`
- `assertStringEqualsStringIgnoringWhitespace()`
- `assertMatchesRegularExpression($pattern, $string)` — full PCRE
- `assertStringMatchesFormat($format, $string)` — sprintf-style placeholders (`%s`, `%d`, `%f`, `%i`, ...), handy for asserting against generated output without pinning every character

## Types / objects

- `assertIsArray()`, `assertIsBool()`, `assertIsInt()`, `assertIsString()`, `assertIsCallable()`, etc.
- `assertInstanceOf(Class::class, $obj)`
- `assertNull()` / `assertNotNull()`
- `assertObjectHasProperty($name, $obj)`

## Comparisons / booleans

- `assertGreaterThan()`, `assertLessThan()`, `assertGreaterThanOrEqual()`, `assertLessThanOrEqual()`
- `assertTrue()` / `assertFalse()` — for actual booleans, not truthy/falsy values (use `assertNotEmpty`/type asserts for those)

## Files

- `assertFileEquals()`, `assertFileEqualsCanonicalizing()`, `assertFileEqualsIgnoringCase()`, `assertFileEqualsFileIgnoringWhitespace()`
- `assertStringMatchesFormatFile()` / `assertFileMatchesFormat()`

## Exceptions

Set expectations before invoking the code under test (see `writing-tests.md`): `expectException()`, `expectExceptionCode()`, `expectExceptionMessage()`, `expectExceptionMessageMatches()`.

## Gotcha

Reach for the most specific assertion available (`assertSame` over `assertEquals`, `assertCount` over `assertSame(count($x), $n)`) — specific assertions produce far more useful diffs on failure.

## Source
- https://docs.phpunit.de/en/13.3/assertions.html
