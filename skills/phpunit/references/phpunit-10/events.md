# Events

PHPUnit 10 introduced a first-class **event system**: every meaningful moment in a test run (app start, config resolved, suite loaded, individual test prepared/passed/failed, run finished, ...) fires a typed, immutable event object that extensions can subscribe to. This is the mechanism behind TestDox output, JUnit logging, and any custom reporting/observability tooling built on PHPUnit 10+ — it replaced the more ad-hoc hook/listener system from PHPUnit 9.

## Event categories

- **Application** — CLI process start/finish (outermost lifecycle).
- **TestRunner** — `Configured`, `Started`, `ExecutionStarted`, `ExecutionFinished`, `Finished`, plus bootstrap/extension-loading and garbage-collection events.
- **TestSuite** — `Loaded`, `Filtered`, `Sorted`, `Started`, `Finished` for a suite as a whole.
- **Test** — the most granular: `PreparationStarted`/`Prepared`, assertion-related events, mock-object creation, and outcome events (`Passed`, `Failed`, `Errored`, `Skipped`, `MarkedIncomplete`).

## Test lifecycle order

`PreparationStarted` → `Prepared` → before-hooks (`#[Before]`/`setUp`) → preconditions → the test method itself (assertions/output/outcome determined) → postconditions → after-hooks (`tearDown`/`#[After]`) → outcome event.

## Writing an extension that subscribes to events

An extension is a class implementing `PHPUnit\Runner\Extension\Extension`, with a `bootstrap()` method PHPUnit calls once at startup:

```php
<?php declare(strict_types=1);
namespace Vendor\ExampleExtensionForPhpunit;

use PHPUnit\Runner\Extension\Extension;
use PHPUnit\Runner\Extension\Facade;
use PHPUnit\Runner\Extension\ParameterCollection;
use PHPUnit\TextUI\Configuration\Configuration;

final class ExampleExtension implements Extension
{
    public function bootstrap(
        Configuration $configuration,
        Facade $facade,
        ParameterCollection $parameters
    ): void {
        $message = $parameters->has('message')
            ? $parameters->get('message')
            : 'the-default-message';

        $facade->registerSubscriber(new ExampleSubscriber($message));
    }
}
```

A subscriber implements the specific `*Subscriber` interface for the event it cares about, with a single `notify()` method:

```php
<?php declare(strict_types=1);
namespace Vendor\ExampleExtensionForPhpunit;

use PHPUnit\Event\TestRunner\ExecutionFinished;
use PHPUnit\Event\TestRunner\ExecutionFinishedSubscriber;

final class ExampleSubscriber implements ExecutionFinishedSubscriber
{
    public function __construct(private readonly string $message) {}

    public function notify(ExecutionFinished $event): void
    {
        print $this->message . PHP_EOL;
    }
}
```

Register the extension in `phpunit.xml`:

```xml
<phpunit>
    <extensions>
        <bootstrap class="Vendor\ExampleExtensionForPhpunit\ExampleExtension">
            <parameter name="message" value="the-message"/>
        </bootstrap>
    </extensions>
</phpunit>
```

For PHAR-packaged extensions, set the root `<phpunit extensionsDirectory="...">` attribute instead.

## Practical uses

Custom test reporters/dashboards, sending results to an external system in real time, collecting timing/flakiness metrics per test, or building tooling that reacts to specific outcomes (e.g., auto-file a ticket when a test newly starts failing) — all without patching PHPUnit itself.

## Gotchas

- One subscriber class handles exactly one event type (the interface it implements pins the event class in `notify()`); register one subscriber instance per event of interest.
- Extensions run inside the same process as the test run, before any test executes — heavy work in `bootstrap()` slows every single invocation.
- This event API is unrelated to (and does not replace) `#[Before]`/`#[After]`/`setUp`/`tearDown` test-fixture hooks (see fixtures.md) — those are per-test-class fixture lifecycle; events are process-wide observability.

Source: https://docs.phpunit.de/en/10.5/events.html, https://docs.phpunit.de/en/10.5/extending-phpunit.html
