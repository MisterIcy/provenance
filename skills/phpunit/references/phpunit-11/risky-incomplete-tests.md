# Risky, Incomplete & Skipped Tests (PHPUnit 11)

PHPUnit separates the *outcome* of a test (passed/failed/errored/incomplete/skipped) from *issues* layered on top (risky, warning, deprecation, notice). A test can pass and still be flagged risky.

## What makes a test "risky"

1. **No assertions** — a test that runs but asserts nothing.
   - Flag: on by default (`beStrictAboutTestsThatDoNotTestAnything`, default `true`). Opt out: `--dont-report-useless-tests` or XML `beStrictAboutTestsThatDoNotTestAnything="false"`.
   - If a test genuinely has no assertions by design, mark it with `#[DoesNotPerformAssertions]` instead of disabling the check globally.

2. **Unintentional code coverage** — the test executes code not declared via `#[CoversClass]`/`#[UsesClass]` etc.
   - Flag: `--strict-coverage` / `beStrictAboutCoverageMetadata="true"`. Stricter still: `requireCoverageMetadata="true"` demands every test declare coverage metadata.

3. **Output during execution** — `print`/`echo` etc. from test or production code.
   - Flag: `--disallow-test-output` / `beStrictAboutOutputDuringTests="true"`.

4. **Exceeding size-based time limits** (requires the `pcntl` extension).
   - Defaults: `#[Small]` → 1s, `#[Medium]` → 10s, `#[Large]` → 60s.
   - Flag: `--enforce-time-limit` / `enforceTimeLimit="true"`; customize via `timeoutForSmallTests`, `timeoutForMediumTests`, `timeoutForLargeTests`.

5. **Global state manipulation** — modifying globals/statics without cleanup.
   - Flag: `--strict-global-state` / `beStrictAboutChangesToGlobalState="true"`.

Risky tests don't contribute to coverage metrics.

## Incomplete tests

```php
public function testNotYetImplemented(): void
{
    $this->markTestIncomplete('Not implemented yet.');
}
```

Shows as `I` in progress output; reported separately from failures.

## Skipped tests

```php
public function testRequiresExtension(): void
{
    if (! extension_loaded('xdebug')) {
        $this->markTestSkipped('xdebug required.');
    }
}
```

Prefer declarative `#[RequiresPhpExtension('xdebug')]` / `#[RequiresPhp('>=8.3')]` / `#[RequiresOperatingSystemFamily('Linux')]` etc. over manual `markTestSkipped()` where the condition is static — see `annotations.md` for the full requires-attribute list.

## Making any of these fail the whole run

```bash
--fail-on-risky --fail-on-incomplete --fail-on-skipped --fail-on-warning
```

Source: https://docs.phpunit.de/en/11.5/risky-tests.html
