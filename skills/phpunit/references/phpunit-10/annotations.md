# Annotations (deprecated in favor of Attributes)

PHPUnit 10 made **PHP 8 attributes the primary metadata mechanism** (see `attributes.md`). Doc-comment annotations (`@test`, `@dataProvider`, etc.) are **deprecated** and will be removed in PHPUnit 12.

**Rule for new code: don't use annotations. Use attributes.**

If both are present on the same test, attributes win: "PHPUnit will first look for metadata in attributes before it looks for annotations in comments. When metadata is found in attributes, metadata in comments is ignored" — so a stray leftover annotation is silently ignored once an attribute exists, not an error, which can mask a mistaken migration.

## Migration map (old annotation → new attribute)

| Annotation | Attribute |
|---|---|
| `/** @test */` | `#[Test]` |
| `/** @dataProvider additionProvider */` | `#[DataProvider('additionProvider')]` |
| `/** @depends testSetup */` | `#[Depends('testSetup')]` |
| `/** @group regression */` | `#[Group('regression')]` |
| `/** @covers \ClassName */` | `#[CoversClass(ClassName::class)]` |
| `/** @coversNothing */` | `#[CoversNothing]` |
| `/** @small */ / @medium / @large` | `#[Small]` / `#[Medium]` / `#[Large]` |
| `/** @runInSeparateProcess */` | `#[RunInSeparateProcess]` |

## The one exception: still fully supported

The `@codeCoverageIgnore`, `@codeCoverageIgnoreStart`, `@codeCoverageIgnoreEnd` annotations (used **in production code**, not test code, to exclude blocks from coverage analysis) are **not deprecated** and have no removal timeline — there's no attribute equivalent for this since it targets arbitrary code blocks rather than whole methods/classes.

## Practical implication for an agent

When you encounter a codebase still using `@test`/`@dataProvider`-style annotations on PHPUnit 10, treat it as legacy-but-working — it'll run today but should be migrated before upgrading to PHPUnit 12. When writing *new* tests, always reach for the attribute form even if the surrounding file still uses old-style annotations.

Source: https://docs.phpunit.de/en/10.5/annotations.html, https://docs.phpunit.de/en/10.5/attributes.html
