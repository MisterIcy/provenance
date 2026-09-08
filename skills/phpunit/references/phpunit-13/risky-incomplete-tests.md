# Risky, Incomplete, Skipped, and Flaky Tests

## Risky tests

PHPUnit marks a test "risky" (`R` in output) when it looks like it provides false confidence, even if it "passes". Conditions, each independently toggleable:

| Condition | Enable via CLI | Enable via XML |
|---|---|---|
| No assertions/mock expectations made ("useless") | `--do-not-report-useless-tests` (disables) | `beStrictAboutTestsThatDoNotTestAnything="false"` (disables) |
| Unsealed mocks required | — | `requireSealedMockObjects="true"` |
| Covers unlisted code | `--strict-coverage` | `beStrictAboutCoverageMetadata="true"` (skipped for `#[Medium]`/`#[Large]`) |
| Missing coverage attribute | — | `requireCoverageMetadata="true"` |
| Covers-target code never executed | `--require-coverage-contribution` | `requireCoverageContribution="true"` |
| Emits output / mishandles output buffer | `--disallow-test-output` | `beStrictAboutOutputDuringTests="true"` |
| Exceeds time limit (needs `pcntl`) | `--enforce-time-limit` | `enforceTimeLimit="true"`, `timeoutForSmallTests`/`timeoutForMediumTests`/`timeoutForLargeTests` (default 1s/10s/60s, keyed off `#[Small]`/`#[Medium]`/`#[Large]`) |
| Mutates global state | `--strict-global-state` | `beStrictAboutChangesToGlobalState="true"` |
| Registers an error/exception handler and doesn't remove it (or removes one it didn't register) | always on | always on |
| A `#[Small]` test depends on a `#[Medium]`/`#[Large]` one | always on | always on |

Intentionally assertion-free test (e.g. "this doesn't throw")? Mark it `#[DoesNotPerformAssertions]` instead of disabling the whole check globally.

## Incomplete tests

Use for work-in-progress — the test runs but its outcome doesn't count as pass/fail:

```php
public function testSomethingNotYetImplemented(): void
{
    $this->markTestIncomplete('Not implemented yet.');
}
```
Shows as `I`; use `--display-incomplete` (or XML equivalent) to see the messages, not just a count.

## Skipped tests

Use for environment/requirement mismatches, never as a way to hide a real failure:

```php
public function testRequiresPgsql(): void
{
    if (!extension_loaded('pgsql')) {
        $this->markTestSkipped('pgsql extension not available.');
    }
}
```
Prefer the declarative requirement attributes over manual `if`/`markTestSkipped()` — they're evaluated before the test body even runs: `#[RequiresPhp('>= 8.3')]`, `#[RequiresPhpExtension('pgsql')]`, `#[RequiresOperatingSystemFamily('Linux')]`, `#[RequiresSetting(...)]`, `#[RequiresPhpunit('^13.0')]`, `#[RequiresFunction(...)]`, `#[RequiresEnvironmentVariable(...)]`.

## Flaky tests: repeat and retry

Both require the test method to declare `void` return type and to have no `#[Depends*]` attribute; otherwise it's ineligible and runs once (with a warning if repeat/retry attributes are present anyway).

- **Repeat** — run N times, stop at first *failure* (good for hunting intermittent bugs / stress-testing stateful code):
  `--repeat <N>` or `#[Repeat(100)]` / `#[Repeat(100, failureThreshold: 5)]`.
- **Retry** — run up to N times, stop at first *success* (for tests genuinely at the mercy of an unreliable external dependency):
  `--retry <N>` or `#[Retry(3)]`.

Method-level attributes override the CLI flag; `#[Repeat(1)]`/`#[Retry(1)]` opts a specific test out of a global `--repeat`/`--retry`. Retried tests still show their failed-attempt count in the summary — flakiness doesn't just disappear. Data providers repeat/retry per data set; test doubles/objects aren't cloned between attempts, so don't mutate a provider's arguments in the test body — put mutable state in `setUp()` instead. PHPT tests support repeat/retry only via CLI flags (no attributes available in `.phpt` files).

## Source
- https://docs.phpunit.de/en/13.3/risky-tests.html
- https://docs.phpunit.de/en/13.3/flaky-tests.html
- https://docs.phpunit.de/en/13.3/writing-tests-for-phpunit.html
