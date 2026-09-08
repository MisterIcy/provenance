# Events

**PHPUnit 9.6 has no Events subsystem and no `events.html` documentation page.** The event-based extension architecture (`PHPUnit\Event\...`, a typed event bus for observing the test runner's lifecycle) is a **PHPUnit 10+ feature** — it does not exist in 9.x. Do not reference `PHPUnit\Event` classes or an event-subscriber API when working against PHPUnit 9.

## What 9.x has instead

PHPUnit 9's extension points for "observe/react to what the test runner is doing" are:

1. **`TestListener` interface** (`PHPUnit\Framework\TestListener`), wired up via `<listeners>` in `phpunit.xml`. Implement methods like `startTest()`, `endTest()`, `addError()`, `addFailure()`, `addRiskyTest()`, etc. This interface has been deprecated since PHPUnit 8.0 (still functional in 9.x, but on its way out) and was fully removed in PHPUnit 10.

2. **Hook interfaces** (`PHPUnit\Runner\BeforeFirstTestHook`, `AfterLastTestHook`, `BeforeTestHook`, `AfterTestHook`, etc.), registered via `<extensions>` in `phpunit.xml`. This was the more modern (pre-10) alternative to `TestListener` for the same kind of "run some code at a runner lifecycle point" need, without needing to implement the whole `TestListener` interface.

```xml
<extensions>
    <extension class="Vendor\MyExtension\MyHookImplementation"/>
</extensions>
```

```php
final class MyHookImplementation implements \PHPUnit\Runner\BeforeFirstTestHook, \PHPUnit\Runner\AfterLastTestHook
{
    public function executeBeforeFirstTest(): void { /* ... */ }
    public function executeAfterLastTest(): void { /* ... */ }
}
```

## If you're building something meant to survive the 9→10 upgrade

Prefer the Hook interfaces over `TestListener` when writing new 9.x extension code — Hooks are the closer conceptual match to what became the Events subsystem in 10, whereas `TestListener` was removed outright. There is no forward-compatible "use PHPUnit\Event in 9.x" option; migrating to the real Events API requires bumping to PHPUnit 10+.

## Source

No PHPUnit 9.6 equivalent page exists. Confirmed via https://docs.phpunit.de/en/9.6/ (no "Events" entry in the table of contents) and https://docs.phpunit.de/en/10.5/events.html (the first version where this subsystem and its docs appear).
