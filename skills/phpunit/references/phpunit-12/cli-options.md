# CLI Options Reference

## Configuration

`--bootstrap <file>` · `-c/--configuration <file>` · `--no-configuration` · `--extension <class>` · `--no-extensions` · `--include-path <path>` · `-d <key[=value]>` (php.ini override) · `--cache-directory <dir>` · `--generate-configuration` · `--migrate-configuration` · `--generate-baseline <file>` · `--use-baseline <file>` · `--ignore-baseline`

## Test selection

`--all` · `--list-suites` · `--testsuite <name>` · `--exclude-testsuite <name>` · `--list-groups` · `--group <name>` · `--exclude-group <name>` · `--covers <name>` · `--uses <name>` · `--requires-php-extension <name>` · `--list-test-files` · `--list-tests` · `--list-tests-xml <file>` · `--filter <pattern>` · `--exclude-filter <pattern>` · `--test-suffix <suffix>`

## Execution

`--process-isolation` · `--globals-backup` · `--static-backup` · `--strict-coverage` · `--strict-global-state` · `--disallow-test-output` · `--enforce-time-limit` · `--default-time-limit <sec>` · `--do-not-report-useless-tests` · `--stop-on-{defect,error,failure,warning,risky,deprecation,notice,skipped,incomplete}` · `--fail-on-*` / `--do-not-fail-on-*` (same suffix set, plus `--fail-on-all-issues` and `--fail-on-empty-test-suite`) · `--cache-result` / `--do-not-cache-result` · `--order-by <default|defects|depends|duration|no-depends|random|reverse|size>` · `--resolve-dependencies` · `--ignore-dependencies` · `--random-order` · `--random-order-seed <N>` · `--reverse-order`

## Reporting / console output

`--colors=<never|auto|always>` · `--columns <n>` (or `max`) · `--stderr` · `--no-progress` · `--no-results` · `--no-output` · `--display-{incomplete,skipped,deprecations,phpunit-deprecations,phpunit-notices,errors,notices,warnings,all-issues}` · `--reverse-list` · `--teamcity` · `--testdox` · `--testdox-summary` · `--debug` · `--with-telemetry`

## Logging

`--log-junit <file>` · `--log-otr <file>` · `--include-git-information` · `--log-teamcity <file>` · `--testdox-html <file>` · `--testdox-text <file>` · `--log-events-text <file>` · `--log-events-verbose-text <file>` · `--no-logging`

## Code coverage

`--coverage-clover <file>` · `--coverage-openclover <file>` · `--coverage-cobertura <file>` · `--coverage-crap4j <file>` · `--coverage-html <dir>` · `--coverage-php <file>` · `--coverage-text[=<file>]` · `--only-summary-for-coverage-text` · `--show-uncovered-for-coverage-text` · `--coverage-xml <dir>` · `--exclude-source-from-xml-coverage` · `--warm-coverage-cache` · `--coverage-filter <dir>` · `--path-coverage` · `--disable-coverage-ignore` · `--no-coverage`

## Misc

`-h/--help` · `--version` · `--atleast-version <min>` · `--check-version` · `--check-php-configuration`

## PHAR-only

`--manifest` (plain-text SBOM) · `--sbom` (CycloneDX XML) · `--composer-lock`

## Notes for PHPUnit 12

New/notable vs. earlier majors: the whole `--generate-baseline`/`--use-baseline`/`--ignore-baseline` family, `--log-otr`/`--include-git-information` (Open Test Reporting), expanded `--display-*` granularity, and `--path-coverage` for Xdebug branch/path analysis. When in doubt about an option's exact current spelling, `phpunit --help` on the installed version is authoritative — options do get renamed between minors.

## Source

- https://docs.phpunit.de/en/12.5/cli-options.html
- https://docs.phpunit.de/en/12.5/textui.html
