# PHPUnit 12 Reference

Canonical source for this version: https://docs.phpunit.de/en/12.5/

Requires PHP 8.3+. Docblock annotations are fully removed — PHP attributes (`PHPUnit\Framework\Attributes\*`) are the sole test-metadata mechanism.

- [writing-tests.md](writing-tests.md) — test class structure, assertions flow, data providers, dependencies, output testing, incomplete/skipped tests.
- [cli-runner.md](cli-runner.md) — invoking `phpunit`, selecting/filtering/ordering tests, exit codes, logging formats.
- [fixtures.md](fixtures.md) — setUp/tearDown, class-level fixtures, attribute-based lifecycle hooks, global/static state isolation.
- [test-organization.md](test-organization.md) — filesystem discovery vs. XML `<testsuites>` configuration.
- [risky-incomplete-tests.md](risky-incomplete-tests.md) — what makes a test risky, default vs. opt-in checks, incomplete/skipped test APIs.
- [test-doubles.md](test-doubles.md) — stubs vs. mocks, `createStub()`/`createMock()`, return/argument configuration, PHPUnit 12 deprecations.
- [coverage-analysis.md](coverage-analysis.md) — drivers (PCOV/Xdebug), coverage attributes, ignoring code, report formats, `match`-arm caveat.
- [assertions.md](assertions.md) — the common assertion method catalog plus PHPUnit 12 additions/deprecations.
- [annotations.md](annotations.md) — full attribute catalog; explicitly notes docblock annotations are removed in favor of attributes.
- [configuration-files.md](configuration-files.md) — `phpunit.xml` schema: `<testsuites>`, `<source>`, `<coverage>`, `<logging>`, `<php>`, `<groups>`, `<extensions>`.
- [error-handling.md](error-handling.md) — PHPUnit's error handler, deprecation expectations, suppression handling, baselining.
- [cli-options.md](cli-options.md) — full CLI flag reference by category.
- [events.md](events.md) — the test-runner event system and how to write a subscribing extension.
