# PHPUnit 10 Reference Index

Canonical source for this version: https://docs.phpunit.de/en/10.5/

| File | Covers |
|---|---|
| [writing-tests.md](writing-tests.md) | Test class structure, `#[Test]`, data providers, exception/output assertions, incomplete/skipped tests, `#[Depends]` |
| [cli-runner.md](cli-runner.md) | Invoking `phpunit`, output sections, flag groups by purpose, example commands |
| [fixtures.md](fixtures.md) | `setUp`/`tearDown`, `setUpBeforeClass`/`tearDownAfterClass`, `#[Before]`/`#[After]`, globals/statics backup |
| [test-organization.md](test-organization.md) | File/directory naming, test suites, `#[Group]`, filtering and listing tests |
| [risky-incomplete-tests.md](risky-incomplete-tests.md) | What makes a test risky, `markTestIncomplete`/`markTestSkipped`, related CLI/config flags |
| [test-doubles.md](test-doubles.md) | `createStub`/`createMock`, `willReturn*`, invocation matchers, `getMockBuilder` |
| [coverage-analysis.md](coverage-analysis.md) | Xdebug/PCOV drivers, `#[CoversClass]`/`#[UsesClass]`/`#[CoversNothing]`, report formats, `<source>`/`<coverage>` config |
| [assertions.md](assertions.md) | Most-used assertion methods by category, with signatures and gotchas |
| [annotations.md](annotations.md) | Doc-comment annotations, their deprecation in favor of attributes, migration map |
| [configuration-files.md](configuration-files.md) | XML config schema, all major elements, minimal working example, changes vs PHPUnit 9 |
| [error-handling.md](error-handling.md) | PHP error/deprecation/notice/warning handling, `<source>` scoping, baselining |
| [cli-options.md](cli-options.md) | Flat lookup table of all CLI flags by category |
| [events.md](events.md) | PHPUnit 10's event system: categories, lifecycle order, writing an extension/subscriber |

Each file ends with a "Source" line pointing to the exact docs.phpunit.de page(s) it was drawn from, for re-fetching current detail.
