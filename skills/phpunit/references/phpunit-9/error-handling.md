# Error Handling

PHPUnit 9.6's manual has **no dedicated "Error Handling" page** — that page (`error-handling.html`) was introduced starting with the PHPUnit 10.x manual. In 9.x, the equivalent behavior is documented as part of "Writing Tests for PHPUnit" (see writing-tests.md) and is worth summarizing here explicitly since it's a distinct, useful concept.

## What happens in 9.x

PHPUnit installs its own error handler while a test runs. PHP errors, warnings, notices, and deprecations triggered by code under test (native `trigger_error()` calls, deprecated-function usage, etc.) are converted into exceptions rather than merely printed — meaning a stray `E_WARNING` in your code under test surfaces as a **test error**, not something silently swallowed.

This is what makes error/warning/deprecation *expectations* possible from inside a normal test method:

```php
public function testTriggersDeprecation(): void
{
    $this->expectDeprecation();
    $this->expectDeprecationMessage('foo');

    trigger_error('foo', E_USER_DEPRECATED);
}

public function testTriggersWarning(): void
{
    $this->expectWarning();
    $this->expectWarningMessageMatches('/foo/');

    trigger_error('foo', E_USER_WARNING);
}
```

Available pairs: `expectNotice()`/`expectNoticeMessage()`, `expectWarning()`/`expectWarningMessage()`/`expectWarningMessageMatches()`, `expectDeprecation()`/`expectDeprecationMessage()`/`expectDeprecationMessageMatches()`, alongside the general `expectException()` family for actual thrown exceptions.

## Suppressing rather than asserting

If you don't want to assert on an error/warning but just need to allow it (e.g. calling something you know emits a benign warning), use PHP's `@` operator around the call:

```php
$this->assertFalse(@$writer->write('/invalid/path', 'stuff'));
```

## Practical implications

- A PHP `E_WARNING`/`E_NOTICE` from code under test **fails the test as an error** by default in 9.x, unless explicitly expected via the methods above — don't assume "the test ran without a thrown exception" means the code was warning-free.
- This is unrelated to risky-test "output during test" checks (which are about `echo`/`print`, not the PHP error handler) — see risky-incomplete-tests.md.
- If you're reading 10.x/11.x docs for more detail (e.g. `https://docs.phpunit.de/en/11.5/error-handling.html`), the mechanism is conceptually the same in 9.x; only the doc page's existence and some edge-case wording changed.

## Source

No PHPUnit 9.6 page exists for this topic. Content synthesized from https://docs.phpunit.de/en/9.6/writing-tests-for-phpunit.html (error/warning/deprecation expectation methods). For comparison, the dedicated page in later versions: https://docs.phpunit.de/en/10.5/error-handling.html
