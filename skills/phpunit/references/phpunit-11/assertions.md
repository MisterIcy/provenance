# Assertions (PHPUnit 11)

All can be called as `$this->assertX(...)`, `self::assertX(...)`, or the global function `assertX(...)`.

## Booleans / null
`assertTrue()`, `assertFalse()`, `assertNotTrue()`, `assertNotFalse()`, `assertNull()`

## Identity vs. equality
- **Identity (`===`)**: `assertSame($expected, $actual)`
- **Equality (`==`, with tolerance helpers)**:
  - `assertEquals($expected, $actual)`
  - `assertEqualsWithDelta($expected, $actual, $delta)` — floats
  - `assertEqualsCanonicalizing()` — sorts arrays before comparing
  - `assertEqualsIgnoringCase()`
  - `assertObjectEquals($expected, $actual, $method = 'equals')` — delegates comparison to a method on the object

Rule of thumb: prefer `assertSame()` over `assertEquals()` unless you specifically need loose/tolerant comparison — `assertEquals()` on objects/arrays can mask type bugs.

## Type checks
`assertIsArray()`, `assertIsString()`, `assertIsInt()`, `assertIsFloat()`, `assertIsBool()`, `assertIsCallable()`, `assertIsObject()`, `assertIsResource()`, `assertIsNumeric()`, `assertIsScalar()`, `assertIsIterable()`, `assertIsList()`, `assertInstanceOf($class, $actual)`

## Arrays / collections
- `assertArrayHasKey($key, $array)`
- `assertContains($needle, $haystack)` (strict `===`) / `assertContainsEquals()` (loose)
- `assertCount($expectedCount, $haystack)`, `assertSameSize($a, $b)`, `assertEmpty($actual)`
- `assertContainsOnlyInstancesOf($class, $haystack)`, plus per-type `assertContainsOnly{Int,String,Bool,...}()`
- `assertArrayIsIdenticalToArrayOnlyConsideringListOfKeys()` / `...IgnoringListOfKeys()` — partial array comparisons
- **Deprecated**: `assertContainsOnly($type, $haystack, $isNativeType)` (soft-deprecated 11.5, warns in 12, removed in 13) — use the per-type variants instead.
- **Gotcha**: `assertCount()`, `assertEmpty()`, `assertSameSize()` don't support generators (single-use, non-cloneable).

## Comparisons
`assertGreaterThan()`, `assertGreaterThanOrEqual()`, `assertLessThan()`, `assertLessThanOrEqual()`

## Strings
`assertStringStartsWith()`, `assertStringEndsWith()`, `assertStringContainsString()`, `assertStringContainsStringIgnoringCase()`, `assertStringEqualsStringIgnoringLineEndings()`, `assertMatchesRegularExpression($pattern, $string)`, `assertStringMatchesFormat($format, $string)`
- **Deprecated**: `assertStringNotMatchesFormat()` (soft-deprecated 10.4, removed in 12).

## Files / filesystem
`assertFileExists()`, `assertFileEquals()` (+ `Canonicalizing`/`IgnoringCase` variants), `assertDirectoryExists()`, `assertStringEqualsFile()`

## JSON / XML
`assertJson($actual)`, `assertJsonStringEqualsJsonString()`, `assertJsonFileEqualsJsonFile()`, `assertJsonStringEqualsJsonFile()`, `assertXmlStringEqualsXmlString()`, `assertXmlFileEqualsXmlFile()`

## Objects
`assertObjectHasProperty($name, $object)`

## Exceptions (see writing-tests.md)
`expectException()`, `expectExceptionMessage()` (substring), `expectExceptionMessageMatches()`, `expectExceptionCode()`

Source: https://docs.phpunit.de/en/11.5/assertions.html
