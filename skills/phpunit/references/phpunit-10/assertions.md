# Assertions

Every assertion accepts an optional trailing `string $message` shown on failure — always worth adding for non-obvious assertions.

## Equality / identity
- `assertEquals($expected, $actual)` — loose (`==`) comparison; for objects, compares property values.
- `assertSame($expected, $actual)` — strict (`===`); use this by default, reach for `assertEquals` only when type coercion is genuinely intended.
- `assertNull($actual)` / `assertNotNull($actual)`

## Booleans
- `assertTrue($condition)` / `assertFalse($condition)`

## Types
- `assertInstanceOf(Class::class, $actual)`
- `assertIsArray`, `assertIsString`, `assertIsInt`, `assertIsBool`, `assertIsFloat`, `assertIsCallable`, `assertIsIterable`, `assertIsObject`, ... (one per PHP type)

## Collections
- `assertCount($expectedCount, $haystack)` — works on `Countable` and iterables
- `assertContains($needle, $haystack)` / `assertNotContains(...)`
- `assertArrayHasKey($key, $array)` / `assertArrayNotHasKey(...)`
- `assertEqualsCanonicalizing`, `assertContainsEquals` — order/type-insensitive variants when strict comparison is too brittle

## Strings
- `assertStringContainsString($needle, $haystack)` (and `assertStringContainsStringIgnoringCase`)
- `assertStringStartsWith` / `assertStringEndsWith`
- `assertMatchesRegularExpression($pattern, $string)`

## JSON
- `assertJson($actual)`
- `assertJsonStringEqualsJsonString($expectedJson, $actualJson)`

## Numeric
- `assertGreaterThan` / `assertGreaterThanOrEqual` / `assertLessThan` / `assertLessThanOrEqual`
- `assertEqualsWithDelta($expected, $actual, $delta)` — for float comparisons instead of `assertSame` on floats

## Files/directories
- `assertFileExists` / `assertFileDoesNotExist`
- `assertDirectoryExists`

## Exceptions (see writing-tests.md for full pattern)
`expectException(Class::class)`, `expectExceptionMessage()` (substring), `expectExceptionMessageMatches()` (regex), `expectExceptionCode()`.

## Deprecated in 10.x
`assertStringNotMatchesFormat()` and `assertStringNotMatchesFormatFile()` are soft-deprecated as of 10.4, slated for removal in PHPUnit 12 — avoid in new code.

## Gotchas
- Prefer `assertSame` over `assertEquals` unless you specifically want loose/type-coercing comparison — `assertEquals` on objects/arrays with unexpected types can pass when it shouldn't.
- For floats, never use `assertSame`/`assertEquals` directly — use `assertEqualsWithDelta`.
- `assertContains`/`assertArrayHasKey` failures show helpful diffs only when the haystack is reasonably small; for large structures consider narrowing the assertion first.

Source: https://docs.phpunit.de/en/10.5/assertions.html
