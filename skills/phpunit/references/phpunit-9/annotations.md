# Annotations

PHPUnit 9 is annotation-native: metadata is expressed as doc-comment (`/** ... */`) tags, parsed from the comment immediately above a class or method. This is the **primary** way to configure test behavior in 9.x — PHP 8 attributes exist as a language feature but PHPUnit 9's own manual documents only the doc-comment annotation syntax; attribute support (as a *forward-compatible alternative*, ahead of PHPUnit 10 making attributes the norm) landed in later 9.x releases for a subset of annotations (notably `@test`, `@dataProvider`, `@depends`, `@group`, `@covers`) — if you see `#[Test]`, `#[DataProvider(...)]` etc. in a 9.x codebase, they're equivalent to the doc-comment forms below and both work side by side. Prefer the annotation form for anything targeting 9.x; don't assume every annotation has an attribute equivalent in 9.x.

## Reference table

| Annotation | Scope | Purpose |
|---|---|---|
| `@test` | method | Marks method as a test without a `test` prefix |
| `@dataProvider providerName` | method | Feeds the test multiple argument sets from a provider method |
| `@depends testName` | method | Declares a dependency on another test's return value |
| `@covers \Class` / `@covers ::function` | class/method | Declares which production code this test targets (coverage attribution) |
| `@coversDefaultClass \Namespace\Class` | class | Sets base for shorthand `@covers ::method` references |
| `@coversNothing` | class/method | Opts test out of coverage accounting |
| `@uses \Class` | class | Documents incidental code executed but not "covered" by this test |
| `@group name` | class/method | Tags for `--group`/`--exclude-group` filtering |
| `@author`, `@ticket` | class/method | Aliases for `@group` (filters by author/ticket ID) |
| `@small` / `@medium` / `@large` | class/method | Aliases for `@group small/medium/large`; sets a timeout (1s/10s/60s) when `--enforce-time-limit` is on |
| `@before` / `@after` | method | Runs before/after **each** test method (like a supplementary setUp/tearDown) |
| `@beforeClass` / `@afterClass` | static method | Runs once before/after all tests in the class |
| `@backupGlobals enabled\|disabled` | class/method | Toggle global variable backup/restore |
| `@backupStaticAttributes enabled\|disabled` | class/method | Toggle static property backup/restore |
| `@preserveGlobalState disabled` | method | With `@runInSeparateProcess`, skip serializing parent state into the child process |
| `@runInSeparateProcess` | method | Run this one test in its own PHP process |
| `@runTestsInSeparateProcesses` | class | Run every test in the class in its own PHP process |
| `@requires PHP >= 8.0` etc. | class/method | Skip unless a PHP version/extension/OS/function/setting precondition holds |
| `@doesNotPerformAssertions` | method | Suppress the "useless test" risky flag for an assertion-free test |
| `@testdox "..."` | method | Custom human-readable description for `--testdox` output |
| `@testWith [["a", 1], ["b", 2]]` | method | Inline JSON data provider (alternative to a separate provider method) |
| `@codeCoverageIgnore` / `Start` / `End` | line/block | Excludes code from coverage analysis |

## Examples

```php
/** @test */
public function itStartsEmpty(): void { /* ... */ }

/**
 * @dataProvider additionProvider
 * @small
 */
public function testAdd(int $a, int $b, int $expected): void { /* ... */ }

/** @testWith [[0, 0, 0], [1, 1, 2]] */
public function testAddInline(int $a, int $b, int $expected): void
{
    $this->assertSame($expected, $a + $b);
}

/** @requires extension redis >= 2.2.0 */
public function testRedisConnection(): void { /* ... */ }
```

`@testWith` data must be valid JSON per line — no trailing commas, and each line is one dataset (array of arguments).

## Source

https://docs.phpunit.de/en/9.6/annotations.html
