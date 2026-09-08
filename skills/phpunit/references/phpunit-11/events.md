# Events (PHPUnit 11)

PHPUnit 11 exposes its internal test-run lifecycle as a typed event stream (introduced in 10, this is its current shape) that extensions can subscribe to instead of hooking into TestListener-style APIs (removed in 10).

## Event categories & rough lifecycle order

```
Application    → Started
TestRunner     → Configured → BootstrapFinished → Started → ExecutionStarted
                 (ChildProcessStarted/Finished if --process-isolation)
TestSuite      → Loaded → Filtered → Sorted → Started
Test           → PreparationStarted → Prepared → ... → Passed/Failed/Errored/Skipped → Finished
TestRunner     → DeprecationTriggered / WarningTriggered (as they occur)
TestRunner     → ExecutionFinished (or ExecutionAborted) → Finished
Application    → Finished
```

~50+ individual event classes exist under `PHPUnit\Event\{Application,TestRunner,TestSuite,Test}\*`; each corresponds 1:1 with a `*Subscriber` interface with a single `notify(EventX $event): void` method.

## Writing an extension + subscriber

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
        print __METHOD__ . PHP_EOL . $this->message . PHP_EOL;
    }
}
```

Wire it up in `phpunit.xml`:

```xml
<extensions>
    <bootstrap class="Vendor\ExampleExtensionForPhpunit\ExampleExtension">
        <parameter name="message" value="the-message"/>
    </bootstrap>
</extensions>
```

## Practical notes

- One subscriber class = one event type (`implements XSubscriber`, one `notify(X $event)`), so a single extension typically registers several small subscriber objects rather than one god-object.
- `$facade->registerTracer(...)` is also available for lower-level tracing needs alongside subscribers.
- Extensions replace the old `TestListener` interface entirely — there is no bridge/adapter for legacy listeners in PHPUnit 10/11.
- Use `--log-events-text <file>` (see `cli-options.md`) to dump the raw event stream as plain text — handy for discovering exact event names/ordering without writing a subscriber.

Source: https://docs.phpunit.de/en/11.5/events.html, https://docs.phpunit.de/en/11.5/extending-phpunit.html
