# CLI Options Reference

Quick-reference; see `cli-runner.md` for narrative usage and workflows.

## Test selection

| Flag | Effect |
|---|---|
| `--filter <pattern>` | Run tests matching name/class/data-set pattern (PCRE if pattern starts non-alphanumeric) |
| `--testsuite <name>` | Restrict to a configured `<testsuite>` |
| `--group <name>` / `--exclude-group <name>` | Include/exclude by `#[Group]` |
| `--covers <Class>` / `--uses <Class>` | Filter by coverage-attribute targets |
| `--list-tests` / `--list-suites` / `--list-groups` | Enumerate without executing |

## Output / reporting

| Flag | Effect |
|---|---|
| `--testdox` | Human-readable sentence output |
| `--compact` | Strip progress/timing/color noise |
| `--no-progress` | Hide progress dots, keep summary |
| `--colors=<never\|auto\|always>` | Control ANSI color |
| `--verbose` / `--debug` | More detail, up to per-event tracing |
| `--display-incomplete`, `--display-skipped`, `--display-deprecations`, `--display-warnings` | Show messages, not just counts |

## Coverage

| Flag | Effect |
|---|---|
| `--coverage-html <dir>` | Browsable HTML report |
| `--coverage-clover <file>` | Clover XML (CI tools) |
| `--coverage-cobertura <file>` | Cobertura XML |
| `--coverage-text[=<file>]` | Plain-text summary |
| `--coverage-php <file>` | Serialized data (merge across runs) |
| `--branch-coverage` / `--path-coverage` | Requires Xdebug |
| `--no-coverage` | Skip coverage entirely even if configured |

## Configuration

| Flag | Effect |
|---|---|
| `-c, --configuration <file>` | Use a specific XML config |
| `--no-configuration` | Ignore `phpunit.xml`/`.dist` entirely |
| `--bootstrap <file>` | PHP file included before any test runs |
| `--generate-baseline <file>` / `--use-baseline <file>` / `--ignore-baseline` | Deprecation/issue baseline workflow |

## Execution control

| Flag | Effect |
|---|---|
| `--stop-on-failure` / `--stop-on-error` / `--stop-on-defect` | Halt at first problem |
| `--order-by=<default\|defects\|random\|duration-ascending\|...>` | Execution ordering |
| `--random-order-seed=<n>` | Reproduce a random order |
| `--process-isolation` | Each test in its own PHP process |
| `--repeat <N>` / `--retry <N>` | Flaky-test repeat/retry (mutually exclusive) |

## Fail-on gates (turn issues into non-zero exit)

`--fail-on-warning`, `--fail-on-risky`, `--fail-on-deprecation`, `--fail-on-notice`, `--fail-on-incomplete`, `--fail-on-skipped` — each has an XML-attribute equivalent (`failOnWarning`, etc.) in `configuration-files.md`.

## Misc

| Flag | Effect |
|---|---|
| `--version` | Print installed version |
| `--help` | Full usage |
| `--check-php-configuration` | Validate php.ini against PHPUnit's recommendations |
| `--log-junit <file>` / `--log-otr <file>` | CI-consumable result logs |

## Source
- https://docs.phpunit.de/en/13.3/cli-options.html
- https://docs.phpunit.de/en/13.3/textui.html
