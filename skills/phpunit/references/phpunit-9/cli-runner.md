# The Command-Line Test Runner

## Basic invocation

```bash
phpunit ArrayTest.php               # run a single file's tests
phpunit tests/                      # recursively run a directory
phpunit --testsuite unit            # run a named suite from phpunit.xml
vendor/bin/phpunit                  # typical Composer install location
```

If a `phpunit.xml` or `phpunit.xml.dist` exists in the CWD, it's auto-loaded unless `--no-configuration` or an explicit `-c`/`--configuration` is passed.

## Progress output

| Char | Meaning |
|---|---|
| `.` | pass |
| `F` | assertion failure |
| `E` | error (uncaught exception / PHP error) |
| `W` | warning |
| `R` | risky |
| `S` | skipped |
| `I` | incomplete |

PHPUnit distinguishes **failures** (a violated assertion) from **errors** (an unexpected exception or PHP fatal/warning) — useful when triaging: errors often mean broken test setup or an SUT bug the test didn't anticipate, not just a wrong expected value.

## Test selection

```bash
phpunit --filter testMethodName
phpunit --filter 'TestNamespace\\TestCaseClass::testMethod'
phpunit --filter 'testMethod#2'              # data set by index
phpunit --filter 'testMethod@my named data'  # named data set
phpunit --group regression --exclude-group slow
phpunit --list-groups
phpunit --list-tests
```

`--filter` takes a regex, matched against `Class::method` (and dataset suffix).

## Execution control

```bash
phpunit --stop-on-failure         # halt at first failure/error
phpunit --stop-on-defect          # halt at first non-passing result of any kind
phpunit --order-by=random --random-order-seed=1234
phpunit --repeat=10 SomeTest.php
phpunit --process-isolation       # run each test in its own PHP process (slow, isolates globals)
```

`--fail-on-incomplete`, `--fail-on-risky`, `--fail-on-skipped`, `--fail-on-warning` turn those statuses into a non-zero exit code — handy in CI where you don't want incomplete/skipped tests silently treated as "OK".

## Coverage & logging (see also coverage-analysis.md)

```bash
phpunit --coverage-html build/coverage
phpunit --coverage-clover build/clover.xml
phpunit --coverage-text
phpunit --log-junit build/junit.xml
```

## TestDox

Converts method names into readable sentences (`testBalanceIsInitiallyZero` → "Balance is initially zero"):

```bash
phpunit --testdox
phpunit --testdox-html report.html
```

## Misc useful flags

```bash
phpunit --bootstrap tests/bootstrap.php
phpunit -d memory_limit=512M
phpunit --colors=always
phpunit -v            # verbose: prints test names as they run
phpunit --debug        # even more verbose, includes each test's start
phpunit --generate-configuration   # interactively scaffold a phpunit.xml
```

## Exit codes

0 = all tests passed (and no `--fail-on-*` condition tripped); non-zero on any failure, error, or a triggered `--fail-on-*` flag. Exact numeric codes aren't itemized in the 9.6 manual — treat "non-zero" as the CI-relevant signal.

## Source

https://docs.phpunit.de/en/9.6/textui.html
