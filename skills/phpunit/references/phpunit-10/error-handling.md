# Error Handling

## Core mechanism

PHPUnit installs its own error handler for the duration of each test run. It intercepts `E_DEPRECATED`, `E_USER_DEPRECATED`, `E_NOTICE`, `E_USER_NOTICE`, `E_STRICT`, `E_WARNING`, and `E_USER_WARNING` raised during test execution — but ignores errors originating from PHPUnit's own internals. These no longer need to be manually caught; they're converted into structured issue reports instead of silently logged or fataling.

Progress output marks these with single letters: `D` deprecation, `N` notice, `W` warning. Pass `--display-deprecations` (and siblings) for full detail instead of just the summary count.

## Scoping to "your" code

By default this applies broadly. Narrow attribution to your own source with `<source>` in `phpunit.xml` (the same element used for coverage — see configuration-files.md):

```xml
<source restrictDeprecations="true"
        restrictNotices="true"
        restrictWarnings="true">
    <include>
        <directory>src</directory>
    </include>
</source>
```
This filters out noise from vendor/third-party deprecations you can't fix.

## Respecting (or overriding) `@`-suppression

By default PHP's `@` operator still suppresses these from PHPUnit's view. Force PHPUnit to see them anyway with:
`ignoreSuppressionOfDeprecations`, `ignoreSuppressionOfPhpDeprecations`, `ignoreSuppressionOfNotices`, `ignoreSuppressionOfPhpNotices`, `ignoreSuppressionOfWarnings`, `ignoreSuppressionOfPhpWarnings` (all on `<source>`).

## Baselining legacy issues

For an existing codebase with many pre-existing deprecations you can't fix immediately:

```bash
phpunit --generate-baseline baseline.xml   # snapshot current issues
phpunit --use-baseline baseline.xml        # suppress only those going forward
```
Lets CI fail on *new* deprecations without blocking on the backlog.

## Disabling for a specific test

`#[WithoutErrorHandler]` on a test method turns off PHPUnit's error handler just for that test — needed when the test itself installs/exercises a custom error handler and PHPUnit's would interfere.

## Exceptions vs. errors

Note this page covers PHP *errors* (deprecations/notices/warnings), not thrown *exceptions* — exception assertions (`expectException`, etc.) are covered in writing-tests.md.

## Gotchas

- Turning on `--fail-on-deprecation`/`failOnDeprecation` (config) is how deprecations actually break a CI build; by default they're reported but don't fail the run.
- `restrictDeprecations`/`restrictNotices`/`restrictWarnings` require the `<source><include>` set to be accurate — an overly broad include re-introduces vendor noise.

Source: https://docs.phpunit.de/en/10.5/error-handling.html
