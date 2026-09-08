# Command-Line Test Runner

```bash
./vendor/bin/phpunit                          # run configured suites (reads phpunit.xml)
./vendor/bin/phpunit tests/ExampleTest.php     # run one file
./vendor/bin/phpunit --testsuite unit          # run one named suite
```

`.phpt` files are auto-discovered alongside `*Test.php` files — useful for CLI end-to-end/regression tests.

## Selecting tests

- `--filter <pattern>` — partial match by default:
  - `testMethodName` (case-insensitive shortcut)
  - `ClassName::testMethodName`
  - `testMethodName#0` or `testMethodName#1-3` (dataset index/range)
  - `testMethodName@"dataset name"` (named dataset)
  - `/regex/modifiers` (PCRE, case-sensitive)
- `--testsuite <name>` / `--exclude-testsuite <name>`, `--list-suites`
- `--group <name>` / `--exclude-group <name>` (matches `#[Group]`), `--list-groups`
- `--covers <name>` / `--uses <name>` (matches `#[CoversClass]`/`#[UsesClass]` etc.)
- `--list-tests`, `--list-tests-xml <file>` — see what would run without running it

## Execution order

`--order-by=<value>` (comma-separable): `default`, `defects` (previously-failed first, needs result cache), `duration` (fastest first, needs result cache), `random` (`--random-order-seed <N>` for reproducibility), `reverse`, `size` (small/medium/large/unknown), `depends` (satisfy `#[Depends]`), `no-depends`.

Shortcuts: `--random-order`, `--reverse-order`, `--resolve-dependencies`, `--ignore-dependencies`.

## Exit codes

- `0` all passed
- `1` at least one failure
- `2` at least one error

Deprecations/notices/warnings/risky tests do **not** affect the exit code by default. Opt in with `--fail-on-warning`, `--fail-on-risky`, `--fail-on-deprecation`, `--fail-on-notice`, `--fail-on-skipped`, `--fail-on-incomplete`, `--fail-on-empty-test-suite`, or `--fail-on-all-issues` (all of the above). `--do-not-fail-on-*` overrides XML config and wins over `--fail-on-*`.

## Stopping early

`--stop-on-defect`, `--stop-on-error`, `--stop-on-failure`, `--stop-on-warning`, `--stop-on-risky`, `--stop-on-deprecation`, `--stop-on-notice`, `--stop-on-skipped`, `--stop-on-incomplete`.

## Logging

- `--log-otr <file>` — Open Test Reporting XML (the current recommended machine-readable format)
- `--log-junit <file>` — JUnit XML (legacy, kept for CI tools that expect it)
- `--log-teamcity <file>` — TeamCity format (PhpStorm)
- `--testdox-html <file>` / `--testdox-text <file>`
- `--log-events-text <file>` / `--log-events-verbose-text <file>` — dump every runner event
- `--no-logging` — suppress logging configured in XML

## Notes for PHPUnit 12

- PHPUnit 12.5 targets PHP 8.5 as its standard CI runtime, but only requires PHP 8.3+ to run.
- Diff output for failed array/object comparisons is now more targeted — it shows the relevant context rather than dumping the entire structure.
- `--generate-baseline`/`--use-baseline`/`--ignore-baseline` let you snapshot existing errors/deprecations/notices/warnings and suppress only the known ones going forward (useful when adopting stricter error-handling on a legacy codebase — see `error-handling.md`).

## Source

- https://docs.phpunit.de/en/12.5/textui.html
- https://docs.phpunit.de/en/12.5/cli-options.html
