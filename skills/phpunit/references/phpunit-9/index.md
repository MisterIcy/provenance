# PHPUnit 9 Reference — Index

Canonical source for this version: https://docs.phpunit.de/en/9.6/

| File | Topic |
|---|---|
| [writing-tests.md](writing-tests.md) | Test class/method structure, `@depends`, `@dataProvider`, exception/error/output expectations |
| [cli-runner.md](cli-runner.md) | Invoking `phpunit`, progress output, test selection, execution control, TestDox |
| [fixtures.md](fixtures.md) | `setUp`/`tearDown`, `setUpBeforeClass`/`tearDownAfterClass`, global-state backup, fixture-sharing pitfalls |
| [test-organization.md](test-organization.md) | Filesystem conventions, `phpunit.xml` `<testsuites>`, `@group` tagging, bootstrap/autoloading |
| [risky-incomplete-tests.md](risky-incomplete-tests.md) | Risky-test categories (useless, coverage, output, timeout, global state), `markTestIncomplete`/`markTestSkipped`, `@requires` |
| [test-doubles.md](test-doubles.md) | `createStub`/`createMock`, `getMockBuilder`, stub return values, mock invocation/argument matchers, doubling traits/abstracts, hard limitations |
| [coverage-analysis.md](coverage-analysis.md) | Coverage drivers, report formats, `@covers`/`@uses`/`@coversNothing`, `@codeCoverageIgnore`, `<coverage>` config |
| [assertions.md](assertions.md) | Assertion method catalog by category (equality, booleans, arrays, strings, types, files, objects) |
| [annotations.md](annotations.md) | Full doc-comment annotation reference table + PHP 8 attribute note (annotations are primary in 9.x) |
| [configuration-files.md](configuration-files.md) | `phpunit.xml` structure — root attributes, `<testsuites>`, `<coverage>`, `<php>`, `<listeners>`/`<extensions>` |
| [error-handling.md](error-handling.md) | PHP error/warning/deprecation-to-exception conversion and expectation methods — no dedicated 9.x doc page exists; content drawn from writing-tests-for-phpunit.html |
| [cli-options.md](cli-options.md) | Flat lookup table of every `phpunit` CLI flag |
| [events.md](events.md) | **No 9.x equivalent** — Events subsystem is PHPUnit 10+; covers 9.x's `TestListener`/Hook interfaces instead |

## Notes on coverage gaps

- **error-handling.md** and **events.md** have no corresponding page in the PHPUnit 9.6 manual (both topics only got a dedicated docs page starting with PHPUnit 10.x). Both files say so explicitly and reconstruct the relevant 9.x behavior from adjacent pages (`writing-tests-for-phpunit.html` for error handling; the 9.x `TestListener`/Hook extension mechanism for events) rather than being skipped.
- All other files map directly onto one or two pages under https://docs.phpunit.de/en/9.6/.
