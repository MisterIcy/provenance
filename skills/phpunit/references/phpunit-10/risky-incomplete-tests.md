# Risky, Incomplete, and Skipped Tests

## Risky tests

PHPUnit marks a test **risky** ("R" in progress output) when it detects the test isn't trustworthy, even if it technically passed:

- **No assertions performed** and no mock expectations configured — an empty or purely-side-effecting test tells you nothing. Suppress deliberately with `#[DoesNotPerformAssertions]` when that's genuinely intended (e.g. "this must not throw").
- **Unintentionally covered code** — when `#[CoversClass]`/`#[CoversFunction]` names specific units but the test also executes code outside that set (and outside anything declared via `#[UsesClass]`/`#[UsesFunction]`), enabled via `--strict-coverage`.
- **Output during execution** (`print`, `echo`, etc., from test or production code) — flagged when `--disallow-test-output` / `beStrictAboutOutputDuringTests="true"` is set.
- **Exceeding size-based time limits** — `#[Small]` (default 1s), `#[Medium]` (10s), `#[Large]` (60s); thresholds are configurable (`timeoutForSmallTests`, etc.) and enforcement requires `--enforce-time-limit` plus the `pcntl` extension.
- **Global state manipulation** — flagged under `--strict-global-state` / `beStrictAboutChangesToGlobalState="true"`.

Disable the "no assertions" check globally with `--dont-report-useless-tests` or `beStrictAboutTestsThatDoNotTestAnything="false"`.

Use `requireCoverageMetadata="true"` (XML) to make tests lacking any `#[Covers*]` metadata risky too — useful for enforcing coverage-intent hygiene project-wide.

## Incomplete tests

For not-yet-implemented tests, prefer `markTestIncomplete()` over an empty test body (which risks being flagged as a useless/risky test) or commenting the test out (which silently loses it):

```php
public function testSomething(): void
{
    $this->markTestIncomplete('Not implemented yet.');
}
```
Shows as `I` in output; doesn't count as pass or fail.

## Skipped tests

```php
protected function setUp(): void
{
    if (!extension_loaded('pgsql')) {
        $this->markTestSkipped('pgsql extension not available.');
    }
}
```
Shows as `S`. Prefer the declarative requirement attributes (`#[RequiresPhpExtension]`, `#[RequiresPhp]`, `#[RequiresOperatingSystem]`, etc. — see `attributes.md`/`writing-tests.md`) over manual `markTestSkipped()` logic when the condition is a static fact about the environment.

## CLI/config knobs at a glance

| Behavior | CLI flag | XML attribute |
|---|---|---|
| Fail run on risky tests | `--fail-on-risky` | — |
| Stop run on first risky | `--stop-on-risky` | — |
| Require coverage metadata | — | `requireCoverageMetadata="true"` |
| Strict coverage checking | `--strict-coverage` | `beStrictAboutCoverageMetadata="true"` |
| Disallow output | `--disallow-test-output` | `beStrictAboutOutputDuringTests="true"` |
| Enforce time limits | `--enforce-time-limit` | `enforceTimeLimit="true"` |

Source: https://docs.phpunit.de/en/10.5/risky-tests.html, https://docs.phpunit.de/en/10.5/writing-tests-for-phpunit.html
