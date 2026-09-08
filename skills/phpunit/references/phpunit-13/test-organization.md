# Test Organization

## Filesystem layout

Mirror your source tree under a test root, one test class per SUT class:

```
src/Camera.php          -> tests/unit/CameraTest.php
src/Http/Client.php     -> tests/unit/Http/ClientTest.php
```
Common top-level split: `tests/unit`, `tests/integration` (sometimes `tests/e2e`), each its own `<testsuite>` in XML so they can be run/gated separately (unit tests fast and always-on in CI, integration tests maybe only on merge).

## Test suites (XML)

```xml
<testsuites>
    <testsuite name="unit">
        <directory>tests/unit</directory>
    </testsuite>
    <testsuite name="integration">
        <directory>tests/integration</directory>
    </testsuite>
</testsuites>
```
Run one: `phpunit --testsuite unit`. List configured suites: `phpunit --list-suites`.

## Grouping across the filesystem boundary

`#[Group('slow')]` (class- or method-level) lets you tag tests orthogonally to their directory, then include/exclude by tag:

```bash
phpunit --group slow
phpunit --exclude-group slow
```
XML equivalent: `<groups><include><group>default</group></include><exclude><group>slow</group></exclude></groups>`. `#[Ticket('JIRA-123')]` is an alias for `#[Group]`, useful for tracing tests back to an issue.

## Coverage-linkage attributes

`#[CoversClass]`, `#[CoversMethod]`, `#[UsesClass]`, etc. don't organize *test running* but do organize what a test is *claimed* to validate — see `coverage-analysis.md` and `annotations.md`.

## Running subsets ad hoc

Beyond suites/groups, `--filter` (see `cli-runner.md`) selects by test/class/data-set name without needing any XML setup — the quickest way to run "just this one test" during development.

## Note

The organizing-tests docs page is thin in 13.3 — it covers filesystem layout, `--filter`, and basic `<testsuites>` XML, but doesn't itself detail `#[Group]`/coverage attributes (those live in the attributes reference) or incomplete/skipped tests (those live under risky-tests/writing-tests).

## Source
- https://docs.phpunit.de/en/13.3/organizing-tests.html
- https://docs.phpunit.de/en/13.3/attributes.html
