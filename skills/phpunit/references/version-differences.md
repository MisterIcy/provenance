# PHPUnit 9 → 13: cross-version differences

A quick map of the breaking changes and major shifts across the five supported
major lines. Use this when a repo is mid-upgrade, when advising on an upgrade
path, or when something that worked on one version doesn't on another. For
full detail on any single version, load that version's own
`references/phpunit-<major>/` directory.

## Metadata: annotations → attributes

The single biggest cross-version shift. PHPUnit moved from PHPDoc annotations
(`@test`, `@dataProvider`, `@covers`, `@group`, ...) to PHP 8 attributes
(`#[Test]`, `#[DataProvider]`, `#[CoversClass]`, `#[Group]`, ...).

| Version | State |
| --- | --- |
| 9 | Annotations are the native/primary mechanism. Attributes exist only as an early, partial, forward-compatible option. |
| 10 | Attributes become primary. Annotations are deprecated but still work; attributes win when both are present on the same target. |
| 11 | Annotations still deprecated and working, with an explicit removal notice for PHPUnit 12. |
| 12 | Annotations are **fully removed**. Attributes are the only mechanism. |
| 13 | Same as 12 — attributes only. |

**Standing exception across all versions**: `@codeCoverageIgnore`,
`@codeCoverageIgnoreStart`, `@codeCoverageIgnoreEnd` are doc-*comment*
directives, not test-metadata annotations, and remain supported indefinitely
— they were never part of the deprecation/removal.

**Practical implication**: a repo pinned to PHPUnit 9 or 10 can still use
either style; anything on 12+ must be pure attributes. If you see
`@dataProvider` in a PHPUnit 12/13 codebase, it's dead metadata (silently
ignored, not an error) — flag it as a bug, not a style choice.

## Event system

- **9**: no event system. Extension points are the deprecated `TestListener`
  interface (since 8.0) and `PHPUnit\Runner\*Hook` interfaces registered via
  `<extensions>` in XML config.
- **10**: the event system is introduced — `Application`/`TestRunner`/
  `TestSuite`/`Test` event categories, with an `Extension` + `Subscriber`
  registration model via `Facade::registerSubscriber()`.
- **11**: event system matures; same registration model, broader event
  coverage.
- **12**: stable, same shape as 11, with baseline/Open Test Reporting
  features (`--generate-baseline`, `--log-otr`) built on top of it.
- **13**: adds `#[Repeat]`/`#[Retry]`-related events (`AttemptErrored`,
  `AttemptFailed`) for flaky-test retry support.

**Practical implication**: `TestListener`-based extensions from a 9.x
codebase need a full rewrite (not a mechanical port) to the event/subscriber
model before the code will run on 10+.

## Test doubles / mocking

- **11**: `expects($this->any())` and calling `->with()` on a stub (not a
  mock) become deprecated.
- **12**: `#[RunClassInSeparateProcess]` is hard-deprecated (12.4).
- **13**: sealed test doubles (`seal()`, `requireSealedMockObjects`), PHP 8.4
  property-hook mocking support, and full removal of the legacy
  Prophecy-based mocking API.

## Assertions

- **11**: `assertContainsOnly()`, `assertNotContainsOnly()`,
  `assertStringNotMatchesFormat()`, and several `getMockBuilder()` methods are
  flagged for future removal.
- **12**: `assertContainsOnly()`/`assertNotContainsOnly()` are
  hard-deprecated (removal expected in 13). Newer assertions
  `assertObjectEquals()` and `assertIsList()` are current-generation
  additions worth preferring in new code.
- **13**: check the PHPUnit 13 assertions reference directly for the current
  removal state — the docs move fast here.

## Configuration schema

- **9**: `<filter>`/`<whitelist>` govern code-coverage source selection.
- **10+**: replaced by `<source>`. A 9.x `phpunit.xml` using `<filter>`/
  `<whitelist>` needs its coverage config rewritten, not just re-validated,
  when upgrading to 10+.
- **11.1+**: `restrictDeprecations` is deprecated in favor of three
  finer-grained flags — `ignoreSelfDeprecations`, `ignoreDirectDeprecations`,
  `ignoreIndirectDeprecations`.

## Risky-test defaults

Defaults have shifted release to release (which checks are on by default vs.
opt-in) — as of the 12.x line, only "useless test" detection and the
small-test-depends-on-large-test check are on by default; strict coverage,
strict global-state checks, output-disallow, and time-limit enforcement are
all opt-in. Don't assume a risky-test failure on one version reproduces
identically on another without checking that version's own
`risky-incomplete-tests.md`.

## Minimum PHP version

Each PHPUnit major line requires a higher PHP floor than the last — most
notably PHPUnit 12 requires PHP 8.3+. A PHP-version mismatch is a common
reason a `composer require` for a newer PHPUnit major fails outright; check
the target version's own docs (root URL in that version's `index.md`) for the
exact floor before assuming the upgrade is a pure code change.

## How to use this file

This is a summary of *known* shifts surfaced while building this skill, not
an exhaustive changelog. When advising on an actual upgrade, treat this as a
starting checklist and verify specifics against the two versions' own
`references/phpunit-<major>/` directories — especially `annotations.md`,
`events.md`, `configuration-files.md`, and `risky-incomplete-tests.md`, which
are where most breakage concentrates.

Sources: https://docs.phpunit.de/en/9.6/, https://docs.phpunit.de/en/10.5/,
https://docs.phpunit.de/en/11.5/, https://docs.phpunit.de/en/12.5/,
https://docs.phpunit.de/en/13.3/
