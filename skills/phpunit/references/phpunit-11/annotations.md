# Annotations vs. Attributes (PHPUnit 11)

## Current status: deprecated, not removed

PHPUnit 11 still parses doc-comment annotations (`/** @covers ... */` style), but the docs are explicit:

> "Support for annotations in comments in test code is deprecated and will be removed in PHPUnit 12. Use attributes instead."

> "Support for metadata in comments is closed for further development: bugs will be fixed, but no new functionality will be implemented based on annotations."

Precedence rule when both exist: **attributes win**. "PHPUnit will first look for metadata in attributes before it looks for annotations in comments. When metadata is found in attributes, metadata in comments is ignored." — so a stray leftover annotation is silently ignored once you add the equivalent attribute, not additive with it.

## One explicit exception: code-coverage ignore annotations

`@codeCoverageIgnore`, `@codeCoverageIgnoreStart`, `@codeCoverageIgnoreEnd` are **not** deprecated and have no planned removal — they have no PHP-attribute equivalent since they apply to code, not to test methods/classes. See `coverage-analysis.md`.

## Practical guidance for PHPUnit 11 code

- Write all new tests using attributes (`#[Test]`, `#[DataProvider]`, `#[CoversClass]`, `#[Group]`, `#[Depends]`, etc. — full list in `attributes.md`).
- If you inherit a codebase still using `@covers`, `@dataProvider`, `@depends`, `@group`, `@test`, `@testdox`, `@testWith`, `@requires`, `@before`, `@after`, `@author`, etc. in doc-comments, treat it as tech debt: it still runs in 11.x but will break on the PHPUnit 12 upgrade. Migrate opportunistically when touching a test file.
- Don't mix an annotation and its attribute equivalent on the same test expecting both to apply — only the attribute is honored.

Source: https://docs.phpunit.de/en/11.5/annotations.html
