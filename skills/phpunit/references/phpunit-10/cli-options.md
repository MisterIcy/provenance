# CLI Options Reference

Full flag reference for the `phpunit` binary, organized by purpose. See `cli-runner.md` for narrative usage and examples — this file is the flat lookup table.

## Configuration
| Flag | Purpose |
|---|---|
| `--bootstrap <file>` | PHP script required before anything else |
| `-c\|--configuration <file>` | Explicit XML config path |
| `--no-configuration` | Ignore any `phpunit.xml`/`.dist` auto-discovery |
| `--no-extensions` | Disable PHAR extensions |
| `--cache-directory <dir>` | Where result/coverage caches live |
| `-d <key[=value]>` | `ini_set()` equivalent |

## Test selection
| Flag | Purpose |
|---|---|
| `--testsuite <name>` / `--exclude-testsuite <name>` | Include/exclude a named suite |
| `--group <name>` / `--exclude-group <name>` | Include/exclude by `#[Group]` |
| `--filter <pattern>` | Match test name (regex-capable) |
| `--covers <name>` / `--uses <name>` | Only tests covering/using a given unit |
| `--list-tests` / `--list-suites` / `--list-groups` | Enumerate without running |

## Execution
| Flag | Purpose |
|---|---|
| `--process-isolation` | Each test in its own PHP process |
| `--globals-backup` / `--static-backup` | Backup/restore globals / static props between tests |
| `--strict-coverage` | Flag unintentionally-covered code as risky |
| `--strict-global-state` | Flag global-state mutation as risky |
| `--disallow-test-output` | Flag any test output as risky |
| `--enforce-time-limit` | Enforce `#[Small]`/`#[Medium]`/`#[Large]` timeouts (needs `pcntl`) |

## Stopping conditions
`--stop-on-defect`, `--stop-on-error`, `--stop-on-failure`, `--stop-on-warning`, `--stop-on-risky`, `--stop-on-deprecation`, `--stop-on-notice`, `--stop-on-skipped`, `--stop-on-incomplete` — halt the run at the first matching outcome.

## Exit-code control
`--fail-on-warning`, `--fail-on-risky`, `--fail-on-deprecation`, `--fail-on-notice`, `--fail-on-incomplete`, `--fail-on-skipped` — make an otherwise-"OK, but..." run exit non-zero (useful for CI gating without stopping mid-run).

## Reporting
`--colors=never|auto|always`, `--columns <n>`, `--no-progress`, `--no-results`, `--no-output`, `--display-all-issues`, `--teamcity`, `--testdox`.

## Logging & coverage
`--log-junit <file>`, `--testdox-html <file>`, `--testdox-text <file>`, `--coverage-clover <file>`, `--coverage-html <dir>`, `--coverage-text`, `--coverage-filter <dir>`, `--warm-coverage-cache`, `--path-coverage`.

## Error-baseline
`--generate-baseline <file>`, `--use-baseline <file>` (see error-handling.md), `--display-deprecations`, `--display-notices`, `--display-warnings`.

## Example invocations

```bash
phpunit --testsuite unit --coverage-html ./coverage
phpunit --stop-on-failure --colors=always
phpunit --filter testArrayAdd
phpunit --log-junit junit.xml --coverage-clover coverage.xml
phpunit --group regression --exclude-group slow --fail-on-risky
```

Source: https://docs.phpunit.de/en/10.5/textui.html
