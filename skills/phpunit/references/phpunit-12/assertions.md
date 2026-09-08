# Assertions

All assertions are available as `$this->assertX()`, `self::assertX()`, `PHPUnit\Framework\Assert::assertX()`, or a global `assertX()` function wrapper — pick one convention and stay consistent within a codebase.

## Most used

```php
assertTrue(bool $condition)
assertFalse(bool $condition)
assertNull(mixed $actual)

assertSame(mixed $expected, mixed $actual)     // === (type + value) — prefer this by default
assertEquals(mixed $expected, mixed $actual)   // == (loose) — only when loose equality is actually intended

assertInstanceOf(string $class, mixed $actual)

assertCount(int $expectedCount, Countable|iterable $haystack)
assertArrayHasKey(int|string $key, array|ArrayAccess $array)
assertContains(mixed $needle, iterable $haystack)
assertEmpty(mixed $actual)
assertSameSize(Countable|iterable $expected, Countable|iterable $actual)

assertIsArray(mixed $actual)
assertIsString(mixed $actual)
assertIsInt(mixed $actual)
assertIsBool(mixed $actual)
assertIsNumeric(mixed $actual)
assertIsIterable(mixed $actual)
assertIsScalar(mixed $actual)
assertIsList(mixed $actual)                    // consecutive int keys from 0

assertStringContainsString(string $needle, string $haystack)
assertStringContainsStringIgnoringCase(string $needle, string $haystack)
assertStringStartsWith(string $prefix, string $string)
assertStringEndsWith(string $suffix, string $string)
assertMatchesRegularExpression(string $pattern, string $string)

assertJson(string $actual)
assertJsonStringEqualsJsonString(string $expectedJson, string $actualJson)

assertGreaterThan(mixed $expected, mixed $actual)
assertLessThan(mixed $expected, mixed $actual)
assertGreaterThanOrEqual(mixed $expected, mixed $actual)
assertLessThanOrEqual(mixed $expected, mixed $actual)
assertEqualsWithDelta(float $expected, float $actual, float $delta) // float comparisons — never assertSame on floats
```

## Value objects

```php
assertObjectEquals(object $expected, object $actual, string $method = 'equals'); // uses the object's own equals() method
```

Handy when the object encapsulates its own equality logic instead of comparing every property manually.

## Common mistake

Don't chain many single-field assertions to check "the whole object is right" — assert the aggregate (array/DTO/object) once so a failure gives one clear diff instead of N near-duplicate failures, and so the "first failed assertion halts the test" rule (see `writing-tests.md`) doesn't hide the other mismatches.

## PHPUnit 12 changes

- `assertContainsOnly()` / `assertNotContainsOnly()` are **hard-deprecated** and slated for removal in PHPUnit 13 — use the specific typed variants (`assertContainsOnlyString()`, `assertContainsOnlyInt()`, etc.) instead.
- Newer/notable: `assertObjectEquals()`, `assertIsList()`, `assertArrayIsIdenticalToArrayOnlyConsideringListOfKeys()` (compare arrays ignoring keys you don't care about).

## Source

- https://docs.phpunit.de/en/12.5/assertions.html
