# Error Handling

## Mechanism

While a test runs, PHPUnit installs its own PHP error handler, intercepting `E_DEPRECATED`, `E_USER_DEPRECATED`, `E_NOTICE`, `E_USER_NOTICE`, `E_STRICT`, `E_WARNING`, `E_USER_WARNING` as "issues" attributed to that test — even ones raised deep in a library the test calls into. It only covers code reached *from* the running test (bootstrap-time issues bypass it entirely, and are reported separately, uncounted per-test).

An `E_USER_ERROR` gets converted into an exception, aborting the test immediately — this happens even under an `@`-suppression operator. Note PHP 8.4 itself deprecated `trigger_error($msg, E_USER_ERROR)`; prefer throwing exceptions directly.

## Testing deprecations on purpose

```php
#[IgnoreDeprecations(messagePattern: '/legacy behavior/')]
public function testDeprecatedPathStillWorks(): void
{
    $this->expectUserDeprecationMessage('legacy behavior is deprecated');
    // ... call the deprecated code
}
```

## Opting a test out entirely

`#[WithoutErrorHandler]` disables PHPUnit's handler for that test — required if you're testing your own error handler, or code that relies on `error_get_last()`/`error_reporting()`. Every feature below stops applying to that test.

## Making issues fail the build

By default these are just counted/displayed, not failures. Turn any of them into a failing exit code:

```xml
<phpunit failOnWarning="true"
         failOnDeprecation="true"
         failOnNotice="true"
         failOnAllIssues="true">
</phpunit>
```
Finer control by *who* triggered it: `failOnSelfDeprecation` (your code calling your code), `failOnDirectDeprecation` (your code calling third-party), `failOnIndirectDeprecation` (third-party calling third-party) — lets you fail on your own deprecated usage without being blocked by noise from a dependency's internals.

Visibility flags (show details, not just a count): `displayDetailsOnTestsThatTriggerDeprecations`, `...TriggerNotices`, `...TriggerWarnings`.

## Filtering third-party noise

```xml
<source ignoreIndirectDeprecations="true"
        restrictNotices="true"
        restrictWarnings="true"
        identifyIssueTrigger="true">
    <include><directory>src</directory></include>
</source>
```
`ignoreSelfDeprecations` / `ignoreDirectDeprecations` are the inverse-scoped siblings.

## Baselines

Snapshot today's known issues so only *new* ones fail the build:

```bash
phpunit --generate-baseline baseline.xml
phpunit --use-baseline baseline.xml
phpunit --ignore-baseline   # temporarily bypass
```
Or set it in XML: `<source baseline="baseline.xml">`. A baseline only captures issues seen *during test execution* — not PHPUnit-internal issues, not bootstrap-phase ones.

## Custom filtering / trigger resolution

Implement `PHPUnit\Runner\DeprecationFilter` for programmatic suppression logic:

```php
final class MyDeprecationFilter implements PHPUnit\Runner\DeprecationFilter
{
    public function ignores(string $message, string $file, int $line, IssueTrigger $trigger): bool
    {
        return str_contains($message, 'ignorable deprecation');
    }
}
```
Register via `<source><deprecationFilters><deprecationFilter className="App\Tests\MyDeprecationFilter"/></deprecationFilters></source>`.

Libraries that wrap `trigger_error`/deprecation reporting (Symfony's `trigger_deprecation()`, Doctrine's `Deprecation::trigger()`) need a `<deprecationTrigger>` declaration so PHPUnit attributes the issue to the *caller's* file/line, not the wrapper's:

```xml
<source>
    <deprecationTrigger>
        <function>trigger_deprecation</function>
        <method>Doctrine\Deprecations\Deprecation::trigger</method>
    </deprecationTrigger>
</source>
```

## Leaky-handler detection (risky test)

A test is flagged risky if it registers an error/exception handler and never removes it, or removes one it didn't register (including PHPUnit's own) — always on, except in `#[RunInSeparateProcess]` tests where it's meaningless.

## Source
- https://docs.phpunit.de/en/13.3/error-handling.html
