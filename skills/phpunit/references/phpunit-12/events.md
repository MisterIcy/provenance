# Events

PHPUnit exposes its entire test-runner lifecycle as a stream of typed events, which extensions subscribe to instead of monkey-patching the runner. This is the supported way to build custom reporters, tracers, or cross-cutting test infrastructure.

## Key event categories

- **Application**: `Application\Started`, `Application\Finished` — bracket the whole CLI process.
- **Test runner**: `TestRunner\Configured`, `TestRunner\Started`, `TestRunner\ExecutionStarted`, `TestRunner\ExecutionFinished`, `TestRunner\Finished`, plus bootstrap/extension/child-process/garbage-collection events.
- **Test suite**: loaded, filtered, sorted, started, skipped, finished.
- **Individual test**: `Test\PreparationStarted` → `Test\Prepared`, before/after method hooks, pre/post-condition hooks, and outcome events — `Test\Passed`, `Test\Failed`, `Test\Errored`, plus skipped/incomplete/risky classification and output/deprecation events.

Subscriptions are sealed once configuration completes (`EventFacadeSealed`) — register subscribers during bootstrap, before execution starts, or they're simply too late.

## Writing an extension

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
        $facade->registerSubscriber(new ExampleSubscriber());
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
    public function notify(ExecutionFinished $event): void
    {
        // react to the event
    }
}
```

Each event has a matching `*Subscriber` interface (e.g. `Test\Failed` ↔ `TestFailedSubscriber`) with a single `notify(EventType $event): void` method — implement the interface matching the event you care about and register an instance via `$facade->registerSubscriber(...)`.

## Registering the extension

```xml
<extensions>
    <bootstrap class="Vendor\ExampleExtensionForPhpunit\ExampleExtension">
        <parameter name="message" value="the-message"/>
    </bootstrap>
</extensions>
```

## Source

- https://docs.phpunit.de/en/12.5/events.html
- https://docs.phpunit.de/en/12.5/extending-phpunit.html
