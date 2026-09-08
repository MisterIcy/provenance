# CLI Options Reference (PHPUnit 11)

Full option catalogue from the command-line test runner chapter (companion to `cli-runner.md`, which covers invocation basics/output conventions).

## Configuration
| Option | Purpose |
|---|---|
| `--bootstrap <file>` | PHP script loaded before tests (autoloader, etc.) |
| `-c\|--configuration <file>` | explicit XML config path |
| `--no-configuration` | ignore any `phpunit.xml` auto-discovery |
| `--no-extensions` | disable PHAR/registered extensions |
| `-d <key[=value]>` | `ini_set()` equivalent |
| `--cache-directory <dir>` | test-result & coverage cache location |
| `--generate-configuration` | scaffold a new XML config interactively |
| `--migrate-configuration` | upgrade an existing config to current schema |

## Test selection
| Option | Purpose |
|---|---|
| `--list-suites` / `--testsuite <name>` / `--exclude-testsuite <name>` | XML-defined suites |
| `--list-groups` / `--group <name>` (repeatable) / `--exclude-group <name>` | `#[Group]` filtering |
| `--covers <name>` / `--uses <name>` (repeatable) | filter by coverage metadata |
| `--filter <pattern>` (repeatable) | match by test/method name |
| `--list-tests` | print discovered tests |
| `--test-suffix <suffix>` | default `Test.php`, `.phpt` |

## Execution control
| Option | Purpose |
|---|---|
| `--process-isolation` | one PHP process per test |
| `--globals-backup` / `--static-backup` | see `fixtures.md` |
| `--strict-coverage` / `--strict-global-state` | risky-test strictness, see `risky-incomplete-tests.md` |
| `--disallow-test-output` | flag output-emitting tests as risky |
| `--enforce-time-limit` / `--default-time-limit <sec>` | size-based timeouts |

## Stop conditions
`--stop-on-defect|error|failure|warning|risky|deprecation|notice|skipped|incomplete`

## Fail-on (exit code) conditions
`--fail-on-warning|risky|deprecation|notice|incomplete|skipped|all-issues`, with `--do-not-fail-on-<type>` to carve out an exception when `--fail-on-all-issues` is set.

## Reporting / output
| Option | Purpose |
|---|---|
| `--colors <never\|auto\|always>` | |
| `--columns <n>` | progress line width |
| `--stderr` | write to stderr |
| `--no-progress` / `--no-results` / `--no-output` | suppress sections |
| `--display-incomplete\|skipped\|deprecations\|errors\|notices\|warnings\|all-issues` | verbose issue detail |
| `--teamcity` / `--testdox` | alternate output formats |
| `--reverse-list` | print defects in reverse (failures last-seen first) |

## Logging
`--log-junit <file>`, `--log-teamcity <file>`, `--testdox-html <file>`, `--testdox-text <file>`, `--log-events-text <file>`, `--no-logging` (ignore XML-configured logging)

## Code coverage
`--coverage-clover|cobertura|crap4j|html|php|text|xml <path>`, `--warm-coverage-cache`, `--coverage-filter <dir>`, `--path-coverage`, `--disable-coverage-ignore`, `--no-coverage`

Source: https://docs.phpunit.de/en/11.5/textui.html
