---
name: phpunit
description: PHPUnit knowledge for writing, running, debugging, and improving tests — writing tests, the CLI test runner, fixtures/setup-teardown, test organization, risky/incomplete/skipped tests, test doubles (mocks/stubs), code coverage analysis, assertions, attributes/annotations, XML configuration, error handling (errors/warnings/deprecations), CLI options, and the event system. Covers PHPUnit 9 through 13, version-gated (annotations vs. attributes, event system introduction, config schema changes, risky-test defaults, mocking API changes all differ by version). Use whenever the user is writing, running, or debugging PHPUnit tests, mentions "PHPUnit," `phpunit.xml`, `#[Test]`/`@test`, data providers, test doubles/mocks in a PHP context, or asks to improve/upgrade an existing PHPUnit test suite.
---

# PHPUnit

Reference knowledge for anyone writing, running, debugging, or improving
PHPUnit tests in a PHP codebase — not a general PHP testing tutorial, and not
for other PHP test frameworks (Pest, Codeception, Behat) even though some
share underlying concepts.

## Workflow

1. **Determine the PHPUnit major version in use.** Run:
   ```
   scripts/detect-phpunit-version.sh <path-to-project-root>
   ```
   It checks, in order: `composer.lock`'s resolved `phpunit/phpunit` version,
   then `composer.json`'s `phpunit/phpunit` constraint (require-dev or
   require), then `vendor/bin/phpunit --version` as a last resort. It prints
   a bare major version (`9`–`13`) on success. If it fails (no composer
   files, no vendor install, genuinely ambiguous constraint like `^9 || ^10`),
   ask the user which version to target, or default to the newest supported
   major (13) and say explicitly that you're assuming it.

   If the detected major isn't one of 9–13 (e.g. an EOL version like 8, or a
   version newer than what this skill has covered), use the nearest
   supported major's reference as a best-effort approximation and flag that
   explicitly — don't silently treat it as an exact match.

2. **Load that version's reference directory**: `references/phpunit-<major>/index.md`
   is the table of contents for that version — it lists all 13 topic files
   with a one-line description and the version's canonical docs root URL.
   Load the specific topic file(s) relevant to the task at hand from there;
   don't load all 13 for a single narrow question.

   Available topics per version: writing tests, CLI runner, fixtures, test
   organization, risky/incomplete tests, test doubles, coverage analysis,
   assertions, annotations (metadata mechanism), configuration files, error
   handling, CLI options, events.

3. **If the task spans two versions** (an upgrade, a compatibility question,
   "does this work on both 10 and 12?"), also read
   `references/version-differences.md` — it summarizes the major breaking
   changes across 9→13 (the annotations→attributes migration, the event
   system's introduction and evolution, config schema changes, mocking-API
   deprecations, risky-test default shifts) with pointers to which version
   directories have the full detail.

4. **Prefer this skill's condensed knowledge first**, but every topic file
   ends with a `Source` line linking to the exact docs.phpunit.de page(s) it
   was drawn from — fetch that page directly if you need more detail than
   the summary carries, or if the user reports behavior that contradicts
   what's written here (the summaries were accurate as of when this skill
   was built; PHPUnit's docs do change).

5. **Write/run/debug the actual tests** using the loaded version's
   conventions — e.g. don't write `@dataProvider` doc-comments for a
   PHPUnit 12/13 target (annotations are fully removed there; use
   `#[DataProvider]`), and don't assume a PHPUnit 9 target has an event
   system to hook into.

## Common mistakes to avoid

- Assuming annotation/attribute support is uniform across versions — it
  isn't (see `references/version-differences.md`); always confirm against
  the detected version's own `annotations.md`.
- Skipping version detection and defaulting straight to "current" PHPUnit
  conventions — a repo pinned to 9 or 10 will reject 12/13-only syntax.
  `composer.lock`, when present, reflects what's actually installed, not
  just what's requested — prefer it over `composer.json`'s constraint.
  Verify by opening `composer.lock` (or running `composer show
  phpunit/phpunit` if a shell is available) whenever the two might disagree,
  e.g. a loose constraint like `^9 || ^10`.
- Treating a risky-test failure, a config directive, or a mocking API call
  as portable across versions without checking that specific version's
  reference file — defaults and available options shift release to release.
- Loading every topic file for every question — load the version's
  `index.md` first, then only the topic file(s) the task actually needs.
- Confusing this skill with a general PHP testing tutorial — it assumes the
  reader already knows PHP and just needs PHPUnit-specific mechanics.
