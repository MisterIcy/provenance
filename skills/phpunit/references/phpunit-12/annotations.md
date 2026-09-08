# Annotations (docblock) — removed; use Attributes

**PHPUnit 12 has no docblock-annotation metadata support.** The old `@covers`, `@group`, `@depends`, `@dataProvider`, `@test`, etc. docblock syntax that PHPUnit 9/10 supported is gone. **PHP attributes (`#[...]`, from the `PHPUnit\Framework\Attributes` namespace) are the sole test-metadata mechanism in PHPUnit 12.** If you're porting an old test suite, every docblock annotation needs an attribute replacement before it will do anything under PHPUnit 12 — a stray `@covers` comment is now just a comment, silently ignored.

## Full attribute catalog

**Marking/naming tests**
```php
#[Test]                                    // method is a test without a test* name
#[TestDox('Adding $a to $b results in $expected')]
#[TestDoxFormatter('methodName')]
#[TestDoxFormatterExternal(ClassName::class, 'method')]
#[Group('billing')]
#[Ticket('JIRA-123')]                      // alias of Group
#[Small] #[Medium] #[Large]                // test size (affects risky-test timeout thresholds)
```

**Data providers**
```php
#[DataProvider('methodName')]
#[DataProviderExternal(ClassName::class, 'methodName')]
#[TestWith([0, 0, 0])]
#[TestWithJson('[0, 0, 0]')]
```

**Dependencies**
```php
#[Depends('testMethodName')]
#[DependsUsingDeepClone('testMethodName')]
#[DependsOnClass(ClassName::class)]
#[DependsExternal(ClassName::class, 'testMethodName')]
```

**Lifecycle** (all accept optional `int $priority`)
```php
#[BeforeClass]  #[AfterClass]              // static methods, once per class
#[Before]       #[After]                   // instance methods, per test
#[PreCondition] #[PostCondition]
```

**Code coverage**
```php
#[CoversClass(ClassName::class)]
#[CoversMethod(ClassName::class, 'methodName')]
#[CoversFunction('functionName')]
#[CoversTrait(TraitName::class)]
#[CoversNamespace('Namespace\Name')]
#[CoversNothing]
#[UsesClass(ClassName::class)] #[UsesMethod(...)] #[UsesFunction(...)]
```

**Isolation / environment**
```php
#[BackupGlobals(true)]
#[ExcludeGlobalVariableFromBackup('VAR_NAME')]
#[BackupStaticProperties(true)]
#[ExcludeStaticPropertyFromBackup(ClassName::class, 'property')]
#[RunInSeparateProcess]
#[RunTestsInSeparateProcesses]
#[PreserveGlobalState(true)]
#[WithEnvironmentVariable('VAR_NAME', 'value')]   // or omit value to unset it
```
`#[RunClassInSeparateProcess]` is hard-deprecated as of 12.4 — don't use it in new code.

**Conditional skipping**
```php
#[RequiresPhp('>= 8.3')]
#[RequiresPhpExtension('mysqli')]
#[RequiresPhpExtension('mysqli', '>= 8.3')]
#[RequiresSetting('setting', 'value')]
#[RequiresPhpunit('>= 12.0')]
#[RequiresFunction('functionName')]
#[RequiresMethod(ClassName::class, 'methodName')]
#[RequiresOperatingSystem('/Linux/')]         // regex
#[RequiresOperatingSystemFamily('Linux')]
#[RequiresEnvironmentVariable('VAR_NAME')]
#[RequiresEnvironmentVariable('VAR_NAME', 'expectedValue')]
```

**Mocks / error handling**
```php
#[AllowMockObjectsWithoutExpectations]
#[DisableReturnValueGenerationForTestDoubles]   // class-level only
#[DoesNotPerformAssertions]
#[IgnoreDeprecations]
#[IgnorePhpunitWarnings('messagePattern')]
#[WithoutErrorHandler]
```

## Example

```php
#[CoversClass(Calculator::class)]
final class CalculatorTest extends TestCase
{
    #[TestWith([1, 1, 2])]
    #[TestWith([2, 3, 5])]
    public function testAdd(int $a, int $b, int $expected): void
    {
        $this->assertSame($expected, (new Calculator())->add($a, $b));
    }
}
```

## Source

- https://docs.phpunit.de/en/12.5/attributes.html
