# Command-Line Test Runner

Invoke via `vendor/bin/phpunit` (or `phpunit` if installed as a phar/global). With a `phpunit.xml` present in the cwd, running bare `phpunit` executes the configured test suite(s). You can also point directly at a file or directory:

```bash
vendor/bin/phpunit                       # uses phpunit.xml
vendor/bin/phpunit tests/Unit/EmailTest.php
vendor/bin/phpunit tests/Unit
```

PHPUnit discovers test classes by the `*Test.php` naming convention under configured directories; it also runs legacy `.phpt` script-based tests.

## Selecting tests

- `--filter <pattern>` — shortcut forms: `testMethodName`, `ClassName::testMethodName`, `testMethodName#3` (data set index), `testMethodName@label` (named data set). A pattern starting with a non-alphanumeric character is treated as a full PCRE regex (case-sensitive).
- `--testsuite <name>` — run only a named suite from XML config; `--list-suites` shows what's defined.
- `--group <name>` / `--exclude-group <name>` — filter by `#[Group]`.
- `--covers <Class>` / `--uses <Class>` — filter by coverage-targeting attributes.
- `--list-tests` — print what would run without running it.

## Output modes

- Default: dot progress (`.` pass, `F` fail, `E` error, `R` risky, `I` incomplete, `S` skipped, `W` warning).
- `--testdox` — human-readable sentences derived from method names.
- `--compact` — suppress progress/timing/color noise (good for CI logs).
- `--teamcity` — TeamCity/PhpStorm service messages.
- `--debug` — verbose per-event tracing, useful when a run hangs or crashes silently.
- `--display-incomplete`, `--display-skipped`, `--display-deprecations`, `--display-warnings` — surface details normally summarized only as counts.

## Execution control

- `--stop-on-failure` / `--stop-on-error` / `--stop-on-defect` — halt on first problem (fast feedback loop).
- `--order-by=defects` — reruns previously-failing tests first; `random` with `--random-order-seed=<n>` for reproducible shuffled runs (good for finding order-dependence bugs).
- `--process-isolation` — run every test in its own PHP process (slow, but hard isolation from global/static state).
- `--repeat <N>` / `--retry <N>` — see `risky-incomplete-tests.md` for flaky-test handling.

## Exit codes

`0` all passed, `1` at least one failure, `2` at least one error. Use `--fail-on-warning`, `--fail-on-risky`, `--fail-on-deprecation`, etc. to make CI fail on issues that wouldn't otherwise change the exit code.

## Logging for CI

- `--log-junit <file>` — JUnit XML (widely supported by CI dashboards).
- `--log-otr <file>` — Open Test Reporting XML (PHPUnit's newer, recommended format).
- `--testdox-html <file>` / `--testdox-text <file>` — human-readable reports.

## Source
- https://docs.phpunit.de/en/13.3/textui.html
- https://docs.phpunit.de/en/13.3/cli-options.html
