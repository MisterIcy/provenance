# Assertions

All assertion methods are static methods on `PHPUnit\Framework\Assert`, called via `$this->assert...()` inside a `TestCase`. Every assertion accepts an optional trailing `$message` string shown on failure.

## Equality / identity

- `assertEquals($expected, $actual)` — loose comparison (type juggling, e.g. `1 == '1'`, and deep object/array comparison ignoring property order).
- `assertSame($expected, $actual)` — strict (`===`): same type and value, same object identity for objects.
- `assertNotEquals()` / `assertNotSame()` — inverses.

**Default to `assertSame`.** Use `assertEquals` only when you deliberately want loose/deep comparison (e.g., comparing two differently-ordered arrays' values, or float-tolerant comparisons via the 4th `$delta` arg).

## Booleans / null

- `assertTrue()` / `assertFalse()`
- `assertNull()` / `assertNotNull()`

## Numeric comparisons

- `assertGreaterThan()`, `assertLessThan()`, `assertGreaterThanOrEqual()`, `assertLessThanOrEqual()`

## Arrays / countables

- `assertCount($expectedCount, $countable)`
- `assertContains($needle, $iterable)` / `assertNotContains()`
- `assertArrayHasKey($key, $array)` / `assertArrayNotHasKey()`
- `assertEmpty()` / `assertNotEmpty()`

## Strings

- `assertStringContainsString($needle, $haystack)` (case-sensitive) / `assertStringContainsStringIgnoringCase()`
- `assertStringStartsWith()` / `assertStringEndsWith()`
- `assertMatchesRegularExpression($pattern, $string)` (this replaced the deprecated `assertRegExp` in 9.x)

## Types / instances

- `assertInstanceOf(ClassOrInterface::class, $object)`
- `assertIsArray()`, `assertIsString()`, `assertIsInt()`, `assertIsBool()`, `assertIsFloat()`, `assertIsObject()`, `assertIsCallable()`, `assertIsIterable()`

## Files / filesystem

- `assertFileExists()` / `assertFileDoesNotExist()`
- `assertDirectoryExists()`
- `assertFileIsReadable()` / `assertFileIsWritable()`
- `assertFileEquals($expectedFile, $actualFile)` — byte-for-byte file comparison

## Objects / structured data

- `assertObjectHasProperty($name, $object)` (9.x may show as `assertObjectHasAttribute`, deprecated in later minor releases in favor of the "Property" naming)
- `assertJsonStringEqualsJsonString()`
- `assertXmlStringEqualsXmlString()`

## Exceptions (via expectation, not a plain assert call)

See writing-tests.md: `expectException()`, `expectExceptionMessage()`, `expectExceptionMessageMatches()`, `expectExceptionCode()` — set *before* the code under test runs, not asserted after the fact.

## Practical notes

- Argument order is always `assertX($expected, $actual, $message = '')` — reversing expected/actual doesn't break the test but produces a confusing diff on failure ("Failed asserting that X matches expected Y" reads backwards).
- On failure, PHPUnit prints a value diff for arrays/strings/objects — lean on `assertSame`/`assertEquals` for structured data rather than hand-rolling comparisons, specifically to get that diff.
- `assertEquals` on objects compares property values recursively (not object identity) unless the objects implement custom `equals` logic PHPUnit doesn't know about — it uses reflection-based comparison.

## Source

https://docs.phpunit.de/en/9.6/assertions.html
