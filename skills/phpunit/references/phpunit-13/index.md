# PHPUnit 13 Reference Index

Canonical source for this version: https://docs.phpunit.de/en/13.3/

| File | Covers |
|---|---|
| [writing-tests.md](writing-tests.md) | Test class/method structure, `#[Test]`, data providers, dependencies, Arrange-Act-Assert / Arrange-Expect-Act |
| [cli-runner.md](cli-runner.md) | Invoking `phpunit`, test selection/filtering, output modes, exit codes, CI logging |
| [fixtures.md](fixtures.md) | setUp/tearDown lifecycle, `#[Before]`/`#[After]` attributes, shared/expensive fixtures, isolation attributes |
| [test-organization.md](test-organization.md) | Filesystem layout, `<testsuites>`, `#[Group]`, running subsets |
| [risky-incomplete-tests.md](risky-incomplete-tests.md) | Risky-test conditions, `markTestIncomplete`/`markTestSkipped`, `#[Requires*]` attributes, flaky-test repeat/retry |
| [test-doubles.md](test-doubles.md) | Stubs vs. mocks, `createStub`/`createMock`, return-value configuration, call-count/order expectations, sealed doubles, PHP 8.4 property hooks |
| [coverage-analysis.md](coverage-analysis.md) | Xdebug/PCOV drivers, coverage report formats, `#[CoversClass]`/`#[UsesClass]`/`#[CoversNothing]`, source include/exclude |
| [assertions.md](assertions.md) | Categorized assertion method reference (equality, arrays, strings, types, comparisons, files) |
| [annotations.md](annotations.md) | Full attribute reference — attributes are the sole metadata mechanism in PHPUnit 13, no docblock annotations |
| [configuration-files.md](configuration-files.md) | `phpunit.xml` structure, config layering, minimal example, key root attributes |
| [error-handling.md](error-handling.md) | PHP error/deprecation-to-exception conversion, `#[IgnoreDeprecations]`, fail-on-issue gates, baselines |
| [cli-options.md](cli-options.md) | Flag-by-flag CLI reference (selection, output, coverage, config, execution control) |
| [events.md](events.md) | Event system layers, writing an extension + subscriber, registering via `<extensions>` |

## Source
- https://docs.phpunit.de/en/13.3/
