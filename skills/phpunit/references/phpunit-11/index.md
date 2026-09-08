# PHPUnit 11 Reference Index

Canonical source for this version: https://docs.phpunit.de/en/11.5/

| File | Covers |
|---|---|
| [writing-tests.md](writing-tests.md) | Basic test class structure, exceptions, data providers, output testing, test dependencies |
| [cli-runner.md](cli-runner.md) | Invoking `phpunit`, progress indicators, outcome-vs-issues, exit codes, summary lines |
| [fixtures.md](fixtures.md) | `setUp`/`tearDown`, `#[Before]`/`#[After]`, class-level fixtures, global/static state backup |
| [test-organization.md](test-organization.md) | Directory/namespace mirroring, `<testsuites>`, `#[Group]`, filtering |
| [risky-incomplete-tests.md](risky-incomplete-tests.md) | What makes a test risky, incomplete/skipped tests, size-based timeouts |
| [test-doubles.md](test-doubles.md) | Stubs vs. mocks, `createStub`/`createMock`, matchers, deprecated `getMockBuilder()` APIs |
| [coverage-analysis.md](coverage-analysis.md) | Coverage drivers, `#[CoversClass]`/`#[UsesClass]`/`#[CoversNothing]`, `@codeCoverageIgnore`, reports |
| [assertions.md](assertions.md) | Categorized assertion method reference, deprecated assertions |
| [annotations.md](annotations.md) | Doc-comment annotations' deprecated status vs. PHP attributes, the `@codeCoverageIgnore*` exception |
| [configuration-files.md](configuration-files.md) | `phpunit.xml` structure, key root attributes/defaults, schema versioning |
| [error-handling.md](error-handling.md) | PHP error/deprecation/notice/warning handling, `<source>` scoping, baselines |
| [cli-options.md](cli-options.md) | Full CLI flag catalogue by category |
| [events.md](events.md) | Event system shape, writing extensions/subscribers, `registerSubscriber()` |

All 13 topics have direct coverage in the PHPUnit 11.5 docs; none required a "no equivalent" placeholder.
