# Error Handling (PHPUnit 11)

PHPUnit installs its own error handler during test execution that intercepts `E_DEPRECATED`, `E_USER_DEPRECATED`, `E_NOTICE`, `E_USER_NOTICE`, `E_STRICT`, `E_WARNING`, `E_USER_WARNING` and turns them into **issues** (see `risky-incomplete-tests.md` and `cli-runner.md`), shown as `D`/`N`/`W` in progress output. The handler only runs during test execution and only for test code / code called from it — not PHPUnit's own internals.

## Scoping issues by first- vs. third-party code

The `<source>` element in `phpunit.xml` decides what counts as "your" code for issue-restriction purposes:

```xml
<source ignoreIndirectDeprecations="true"
        restrictNotices="true"
        restrictWarnings="true">
    <include>
        <directory>src</directory>
    </include>
</source>
```

- `ignoreSelfDeprecations` / `ignoreDirectDeprecations` / `ignoreIndirectDeprecations` — replace the deprecated `restrictDeprecations` (see `configuration-files.md`); control whether deprecations from your own code, direct calls into third-party code, or transitively-triggered deprecations are surfaced.
- `restrictNotices` / `restrictWarnings` — ignore notices/warnings originating outside the declared `<source>` boundary.
- `baseline` — point at a snapshot XML file of pre-existing issues to suppress (see below), so a legacy codebase can turn on strict issue-reporting without drowning in noise.

## CLI equivalents

```bash
vendor/bin/phpunit --display-deprecations --display-notices --display-warnings
vendor/bin/phpunit --generate-baseline baseline.xml   # snapshot current issues
vendor/bin/phpunit --use-baseline baseline.xml        # suppress anything in the snapshot
```

## The `@`-suppression operator

PHPUnit respects `@` suppression by default (a suppressed notice/warning/deprecation won't surface as an issue). To force PHPUnit to see through `@` anyway:

```
ignoreSuppressionOfDeprecations / ignoreSuppressionOfPhpDeprecations
ignoreSuppressionOfNotices      / ignoreSuppressionOfPhpNotices
ignoreSuppressionOfWarnings     / ignoreSuppressionOfPhpWarnings
```

## Test-level control

```php
$this->expectUserDeprecationMessage('message-text');
$this->expectUserDeprecationMessageMatches('/regex/');
```

```php
#[WithoutErrorHandler]
public function testOwnErrorHandler(): void
{
    // PHPUnit's error handler is disabled for this test only —
    // use when the code under test installs/asserts its own handler.
}
```

`#[IgnoreDeprecations]` (attribute list, see `annotations.md`) suppresses `E_DEPRECATED`/`E_USER_DEPRECATED` for a specific test without touching global config.

Source: https://docs.phpunit.de/en/11.5/error-handling.html
