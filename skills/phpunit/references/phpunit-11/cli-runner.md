# Command-Line Test Runner (PHPUnit 11)

## Basic invocation

```bash
vendor/bin/phpunit                        # run everything the config discovers
vendor/bin/phpunit tests/ArrayTest.php    # run a single file
vendor/bin/phpunit --filter testAdd       # match by test/method name (repeatable)
vendor/bin/phpunit --testsuite unit       # run a named suite from XML config
vendor/bin/phpunit --group fast           # run tests tagged #[Group('fast')]
```

## Progress indicator characters

| Char | Meaning |
|---|---|
| `.` | pass, no issues |
| `F` | assertion failure |
| `E` | error/uncaught exception |
| `W` | warning |
| `R` | risky |
| `D` | deprecation |
| `N` | notice |
| `I` | incomplete |
| `S` | skipped |

## Outcome vs. Issues

PHPUnit 11 separates **outcome** (Passed/Failed/Errored/Incomplete/Skipped) from **issues** (warnings, deprecations, notices, risky-test flags) — a test can *pass* and still surface issues. See `risky-incomplete-tests.md` and `error-handling.md`.

## Summary line conventions

| Situation | Summary |
|---|---|
| everything clean | `OK` |
| any error | `ERRORED!` |
| failures, no errors | `FAILED!` |
| only skips | `OK, but some tests were skipped!` |
| issues but no failures/errors/skips | `OK, but there were issues!` |

## Exit codes and `--fail-on-*`

By default the process exit code reflects only Errored/Failed outcomes. To make otherwise-passing runs fail CI when issues are present, add:

```bash
--fail-on-warning --fail-on-risky --fail-on-deprecation \
--fail-on-notice --fail-on-incomplete --fail-on-skipped
# or the shorthand:
--fail-on-all-issues
--do-not-fail-on-deprecation   # carve an exception back out
```

## Stop-on-first-X

```bash
--stop-on-failure --stop-on-error --stop-on-defect --stop-on-risky \
--stop-on-warning --stop-on-deprecation --stop-on-notice \
--stop-on-skipped --stop-on-incomplete
```

`--stop-on-defect` is the broad one (any error/failure/warning/risky).

## Common practical commands

```bash
vendor/bin/phpunit --list-suites
vendor/bin/phpunit --list-groups
vendor/bin/phpunit --list-tests
vendor/bin/phpunit --testdox                       # human-readable output
vendor/bin/phpunit --colors=always
vendor/bin/phpunit --coverage-html coverage/        # needs Xdebug or PCOV
vendor/bin/phpunit --log-junit build/junit.xml
vendor/bin/phpunit -d memory_limit=-1
vendor/bin/phpunit --process-isolation              # each test in its own PHP process (slow)
```

Full option catalogue lives in `cli-options.md`.

Source: https://docs.phpunit.de/en/11.5/textui.html
