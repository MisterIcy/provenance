# Risky, Incomplete, and Skipped Tests

## Risky tests

A "risky" test is one whose result you shouldn't fully trust, even if it "passed." PHPUnit flags several patterns:

| Condition | Trigger | Default? |
|---|---|---|
| Useless test (no assertions/mock expectations) | always checked | **on by default**, disable with `--do-not-report-useless-tests` |
| `#[DoesNotPerformAssertions]` test that *does* assert | always checked | always enforced, cannot disable |
| Small test depends on a Medium/Large test | test-size mismatch | always enforced, cannot disable |
| Unintentionally covered code (executes code outside declared `#[Covers*]`) | `--strict-coverage` | off by default; skipped for Medium/Large tests |
| Missing coverage metadata entirely | `requireCoverageMetadata="true"` (XML) | off by default |
| Produces output (echo/print, mismanaged ob_start/ob_end) | `--disallow-test-output` | off by default |
| Exceeds size-based time limit (needs `pcntl`) | `--enforce-time-limit` | off by default |
| Mutates global state | `--strict-global-state` | off by default |

Time limits when `--enforce-time-limit` is on: Small ≤ 1s, Medium ≤ 10s, Large ≤ 60s (all configurable in XML via `<php>`-adjacent settings / `defaultTimeLimit`-style attributes).

Enable the optional checks in `phpunit.xml` (`<phpunit strictCoverage="true" enforceTimeLimit="true" ...>`) or via the matching CLI flags — see `cli-options.md`.

## Incomplete tests

Use when a test is a stub for work not yet done:

```php
$this->markTestIncomplete('Not yet implemented.');
```

Reported separately from failures; doesn't fail the build unless `--fail-on-incomplete` is passed.

## Skipped tests

Use for tests that can't run in the current environment:

```php
$this->markTestSkipped('PostgreSQL extension unavailable.');
```

Prefer the declarative `#[RequiresPhpExtension('pgsql')]`-family attributes (see `annotations.md`) over imperative `markTestSkipped()` calls when the condition is a static environment fact — they skip before the test body even runs and show up distinctly in output. Doesn't fail the build unless `--fail-on-skipped` is passed.

## Source

- https://docs.phpunit.de/en/12.5/risky-tests.html
- https://docs.phpunit.de/en/12.5/writing-tests-for-phpunit.html
