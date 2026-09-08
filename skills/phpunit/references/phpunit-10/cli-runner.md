# Command-Line Test Runner

## Basic invocation

```bash
./vendor/bin/phpunit                       # uses phpunit.xml / phpunit.xml.dist if present
./vendor/bin/phpunit tests/                # run everything under a directory
./vendor/bin/phpunit tests/ArrayTest.php    # run one file
./vendor/bin/phpunit --filter testArrayAdd  # run tests matching a name pattern
```

## Output sections

Up to four sections print per run: PHPUnit/PHP/config version info, a progress line of one character per test (`.` pass, `F` failure, `E` error, `R` risky, `S` skipped, `I` incomplete, `D`/`N`/`W` for deprecation/notice/warning), a detailed results section for anything non-passing, and a final summary line (`OK`, `OK, but there were issues!`, or `FAILURES!`/`ERRORS!`).

## Key flag groups

**Configuration selection**
- `--bootstrap <file>` — PHP file to require before anything else (autoloading, globals)
- `-c|--configuration <file>` / `--no-configuration`
- `--cache-directory <dir>` — where results/coverage cache lives

**Test selection**
- `--testsuite <name>` / `--exclude-testsuite <name>`
- `--group <name>` / `--exclude-group <name>`
- `--filter <pattern>` — matches test method name (supports regex)
- `--covers <name>` / `--uses <name>` — run only tests that (don't) cover a given unit
- `--list-tests` / `--list-suites` / `--list-groups`

**Execution behavior**
- `--process-isolation` — each test in its own PHP process (slow, but truly isolated)
- `--stop-on-failure`, `--stop-on-error`, `--stop-on-defect`, `--stop-on-risky`, `--stop-on-skipped`, `--stop-on-incomplete`, `--stop-on-deprecation`, `--stop-on-notice`, `--stop-on-warning`
- `--fail-on-*` equivalents (warning/risky/deprecation/notice/incomplete/skipped) turn those states into a non-zero exit code without stopping early

**Reporting / logging**
- `--colors=never|auto|always`, `--testdox`, `--teamcity`
- `--log-junit <file>` — JUnit XML for CI
- `--coverage-html <dir>`, `--coverage-clover <file>`, `--coverage-text`

## Examples

```bash
phpunit --testsuite unit --coverage-html ./coverage
phpunit --stop-on-failure --colors=always
phpunit --group regression --exclude-group slow
phpunit --log-junit build/junit.xml --coverage-clover build/clover.xml
```

## Gotchas

- `--filter` matches against the fully qualified test name including data provider dataset suffix (`ClassName::testMethod#0` / `... with data set "name"`), so filtering into a single dataset is possible: `--filter 'testAdd.*adding zeros'`.
- Without an explicit config file, PHPUnit auto-discovers `phpunit.xml` then `phpunit.xml.dist` in the current directory.
- Exit code is non-zero for failures/errors by default; risky/warning/deprecation/etc. only affect the exit code if the corresponding `--fail-on-*` flag (or XML equivalent) is set.

Source: https://docs.phpunit.de/en/10.5/textui.html
