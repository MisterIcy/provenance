# Error Handling

PHPUnit installs its own error handler for the duration of test execution, capturing `E_DEPRECATED`, `E_USER_DEPRECATED`, `E_NOTICE`, `E_USER_NOTICE`, `E_STRICT`, `E_WARNING`, and `E_USER_WARNING`. It only reacts during test execution and ignores issues from PHPUnit's own internals/dependencies.

**Gotcha:** if your code under test registers its own error handler (`set_error_handler()`), PHPUnit's handler is deactivated for that scope — all the behavior below stops working until control returns.

## Reading the output

Progress output shows `D` (deprecation), `N` (notice), `W` (warning) inline. Get detail with:

```bash
--display-deprecations
--display-errors
--display-notices
--display-warnings
--display-all-issues
```

## Scoping issues to first-party code

```xml
<source restrictNotices="true" restrictWarnings="true" ignoreIndirectDeprecations="true">
    <include><directory>src</directory></include>
</source>
```

This cuts vendor-dependency noise out of the report so you only see issues from your own code.

## Respecting (or not) the `@` suppression operator

PHPUnit honors `@`-suppressed errors by default. Override per category:

```
ignoreSuppressionOfDeprecations / ignoreSuppressionOfPhpDeprecations
ignoreSuppressionOfNotices      / ignoreSuppressionOfPhpNotices
ignoreSuppressionOfWarnings     / ignoreSuppressionOfPhpWarnings
```

(`Php*` variants target engine-raised issues; the non-`Php` variants target user-triggered `trigger_error()`/`trigger_deprecation()`-style issues.)

## Expecting a deprecation intentionally

```php
public function testEmitsDeprecation(): void
{
    $this->expectUserDeprecationMessage('Old API is deprecated, use X instead.');
    legacyFunction();
}
```

`expectUserDeprecationMessageMatches()` is the regex variant. Use `#[IgnoreDeprecations]` on a method/class to stop a deprecation from failing the test while still allowing you to assert on the message.

## Baselining existing issues

Adopting stricter checks on a legacy codebase without fixing everything at once:

```bash
phpunit --generate-baseline baseline.xml   # snapshot current issues
phpunit --use-baseline baseline.xml        # suppress only those going forward
phpunit --ignore-baseline                  # temporarily see everything again
```

## Disabling PHPUnit's handler for a specific test

```php
#[WithoutErrorHandler]
public function testCustomHandlerBehavior(): void { /* ... */ }
```

Needed when the test itself is verifying a custom error handler or specific triggering behavior that PHPUnit's handler would otherwise intercept.

## Source

- https://docs.phpunit.de/en/12.5/error-handling.html
