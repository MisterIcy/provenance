# CLI Options Reference

Full flag reference for the `phpunit` binary (9.6). See cli-runner.md for narrative usage/workflow guidance — this file is the flat lookup table.

## Configuration

| Flag | Purpose |
|---|---|
| `-c, --configuration <file>` | Use a specific XML config file |
| `--no-configuration` | Ignore any `phpunit.xml`/`.dist` auto-detection |
| `--bootstrap <file>` | PHP file to load before tests |
| `--extensions <ext,...>` | Load specific PHPUnit extensions |
| `--no-extensions` | Skip loading any extensions |
| `--include-path <path(s)>` | Prepend to PHP `include_path` |
| `-d <key[=value]>` | Set a php.ini directive for the run |
| `--generate-configuration` | Interactively scaffold a `phpunit.xml` |

## Test selection

| Flag | Purpose |
|---|---|
| `--filter <pattern>` | Regex filter on `Class::method` (+ dataset suffix) |
| `--testsuite <name>` | Run only the named `<testsuite>` |
| `--group <name>` | Run only tests tagged with this `@group` |
| `--exclude-group <name>` | Exclude tests tagged with this `@group` |
| `--list-groups` | Print all known groups |
| `--list-suites` | Print all known testsuite names |
| `--list-tests` | Print all discoverable test names |
| `--test-suffix <suffixes>` | Override the `Test.php`/`.phpt` file-matching suffix |

## Execution behavior

| Flag | Purpose |
|---|---|
| `--stop-on-defect` | Halt on first non-passing result (any kind) |
| `--stop-on-error` | Halt on first error |
| `--stop-on-failure` | Halt on first failure or error |
| `--stop-on-warning` | Halt on first warning |
| `--stop-on-risky` | Halt on first risky test |
| `--stop-on-skipped` | Halt on first skipped test |
| `--stop-on-incomplete` | Halt on first incomplete test |
| `--fail-on-incomplete` | Non-zero exit if any test incomplete |
| `--fail-on-risky` | Non-zero exit if any test risky |
| `--fail-on-skipped` | Non-zero exit if any test skipped |
| `--fail-on-warning` | Non-zero exit if any test warned |
| `--dont-report-useless-tests` | Disable the zero-assertion risky check |
| `--strict-coverage` | Enable unintentionally-covered-code risky check |
| `--strict-global-state` | Enable global-state-mutation risky check |
| `--disallow-test-output` | Enable output-during-test risky check |
| `--disallow-resource-usage` | Restrict resource use for `@small` tests |
| `--enforce-time-limit` | Enable per-test-size timeout enforcement |
| `--default-time-limit <sec>` | Timeout for tests without a size annotation |
| `--disallow-todo-tests` | Fail tests annotated `@todo` |
| `--process-isolation` | Run every test in its own PHP process |
| `--globals-backup` | Backup/restore `$GLOBALS` per test |
| `--static-backup` | Backup/restore static properties per test |
| `--repeat <n>` | Run the whole selection `n` times |
| `--order-by <mode>` | `default\|defects\|duration\|random\|reverse\|size` |
| `--random-order-seed <n>` | Pin the seed for `--order-by=random` |
| `--cache-result` | Persist result cache to disk |
| `--do-not-cache-result` | Disable result caching |

## Output / reporting

| Flag | Purpose |
|---|---|
| `--colors <never\|auto\|always>` | Colored output |
| `--columns <n>` | Progress-output column width |
| `--stderr` | Write to STDERR instead of STDOUT |
| `-v, --verbose` | Print test names as they run |
| `--debug` | Extra-verbose debugging output |
| `--testdox` | Human-readable test descriptions |
| `--testdox-html <file>` / `--testdox-text <file>` / `--testdox-xml <file>` | TestDox report to file |
| `--log-junit <file>` | JUnit XML log |
| `--log-teamcity <file>` | TeamCity-format log |

## Coverage

| Flag | Purpose |
|---|---|
| `--coverage-html <dir>` | HTML report |
| `--coverage-clover <file>` | Clover XML |
| `--coverage-crap4j <file>` | Crap4J XML |
| `--coverage-php <file>` | Serialized `PHP_CodeCoverage` object |
| `--coverage-text[=<file>]` | Plain text summary |
| `--coverage-xml <dir>` | PHPUnit-native XML |
| `--coverage-filter <dir>` | Restrict analysis to a directory |
| `--no-coverage` | Skip coverage regardless of config |

## Misc

| Flag | Purpose |
|---|---|
| `-h, --help` | Usage help |
| `--version` | Print PHPUnit version |
| `--atleast-version <v>` | Exit 0 only if installed version ≥ `<v>` (for scripting) |
| `--check-version` | Check against latest released version |

## Source

https://docs.phpunit.de/en/9.6/textui.html
