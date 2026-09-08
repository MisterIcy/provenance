# Events

PHPUnit 13 exposes its whole test-run lifecycle as a typed event stream (`PHPUnit\Event\*`), organized in layers:

- **Application** — `Started`, `Finished` (overall CLI process)
- **TestRunner** — configuration/bootstrap/extension loading, child-process management (process isolation, PHPT sections), `Started` → `ExecutionStarted` → `ExecutionFinished` → `Finished`
- **TestSuite** — `Loaded`, `Filtered`, `Sorted`, `Started`, `Finished`, `Skipped`
- **Test** — full per-test lifecycle: preparation, before/precondition hooks, execution, postcondition/after hooks, finished; outcome events `Passed`, `Failed`, `Errored`, `Skipped`, `Incomplete`; retry-specific `AttemptErrored`/`AttemptFailed` (new in 13, paired with `#[Retry]`); plus mock/stub creation and unexpected-output/risky/deprecation diagnostic events.

## Writing an extension + subscriber

An extension is a class implementing `PHPUnit\Runner\Extension\Extension`; its `bootstrap()` receives a `Facade` used to register one or more subscribers, each implementing the interface for exactly one event type:

```php
// Extension.php
final class MyExtension implements PHPUnit\Runner\Extension\Extension
{
    public function bootstrap(
        PHPUnit\TextUI\Configuration\Configuration $configuration,
        PHPUnit\Runner\Extension\Facade $facade,
        PHPUnit\Runner\Extension\ParameterCollection $parameters
    ): void {
        $facade->registerSubscriber(new TestPassedSubscriber());
    }
}

// TestPassedSubscriber.php
final class TestPassedSubscriber implements PHPUnit\Event\Test\PassedSubscriber
{
    public function notify(PHPUnit\Event\Test\Passed $event): void
    {
        echo 'Test passed: ' . $event->test()->id() . PHP_EOL;
    }
}
```

Register it in `phpunit.xml`:

```xml
<extensions>
    <bootstrap class="MyVendor\MyExtension\MyExtension">
        <parameter name="logLevel" value="debug"/>
    </bootstrap>
</extensions>
```

Use this for custom reporters, Slack/webhook notifications on failure, custom metrics collection, or driving external tooling off the test run — without patching PHPUnit itself.

## PHPUnit 13 changes

- `AttemptErrored`/`AttemptFailed` events are new, supporting the `#[Retry]`/`--retry` flaky-test feature.
- A number of issue-related events (`DeprecationTriggered`, `NoticeTriggered`, `WarningTriggered`) are slated to move under a `Phpunit`-prefixed namespace in PHPUnit 14 — don't hardcode deep namespace assumptions if you want the extension to survive an upgrade; check the changelog when bumping major versions.

## Source
- https://docs.phpunit.de/en/13.3/events.html
- https://docs.phpunit.de/en/13.3/extending-phpunit.html
