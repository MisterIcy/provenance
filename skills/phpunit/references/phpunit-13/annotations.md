# Annotations (Attributes)

**PHPUnit 13 uses PHP attributes exclusively for test metadata.** The old docblock (`@annotation`) syntax from PHPUnit ≤9 is not the mechanism here — every piece of metadata below is a native PHP `#[...]` attribute. If you're porting tests from an old codebase that still uses `@dataProvider`, `@covers`, `@group`, `@depends`, etc. docblocks, convert each to its attribute equivalent listed here.

## Test declaration

- `#[Test]` — treat method as a test regardless of name.
- `#[DoesNotPerformAssertions]` — silence the "useless test" risky warning for a deliberately assertion-free test.

## Data providers

- `#[DataProvider('methodName')]`, `#[DataProviderExternal(Class::class, 'methodName')]`
- `#[TestWith([1, 2, 3])]` / `#[TestWithJson('[1,2,3]')]` — inline data sets without a separate provider method.

## Dependencies

- `#[Depends('testX')]`, `#[DependsUsingDeepClone('testX')]`, `#[DependsUsingShallowClone('testX')]`, `#[DependsExternal(Class::class, 'testX')]`.

## Coverage targeting

- `#[CoversClass]`, `#[CoversMethod]`, `#[CoversFunction]`, `#[CoversTrait]`, `#[CoversNamespace]`, `#[CoversFile]`, `#[CoversDirectory]`, `#[CoversDirectoryRecursively]`, `#[CoversNothing]`
- `#[UsesClass]`, `#[UsesMethod]`, `#[UsesTrait]`, `#[UsesFunction]`, `#[UsesNamespace]`, `#[UsesFile]`, `#[UsesDirectory]` — executed but not claimed as covered.

## Grouping / sizing

- `#[Group('name')]`, `#[Ticket('JIRA-123')]` (alias of Group)
- `#[Small]` / `#[Medium]` / `#[Large]` — affects risky-test time limits (1s/10s/60s default) and coverage strictness exemptions.

## TestDox

- `#[TestDox('human readable sentence')]`, `#[TestDoxFormatter('method')]`, `#[TestDoxFormatterExternal(Class::class, 'method')]`.

## Fixture lifecycle

- `#[BeforeClass]`, `#[Before]`, `#[PreCondition]`, `#[PostCondition]`, `#[After]`, `#[AfterClass]` — each takes an optional `priority: int` (higher runs first); multiple methods may share a role.

## Error handling

- `#[IgnoreDeprecations]` (optional `messagePattern`), `#[WithoutErrorHandler]`, `#[IgnorePhpunitWarnings]`.

## Isolation / environment

- `#[BackupGlobals(true)]`, `#[ExcludeGlobalVariableFromBackup('_SESSION')]`
- `#[BackupStaticProperties(true)]`, `#[ExcludeStaticPropertyFromBackup(Class::class, 'prop')]`
- `#[RunInSeparateProcess]`, `#[RunTestsInSeparateProcesses]`, `#[PreserveGlobalState(true)]`
- `#[WithEnvironmentVariable('KEY', 'value')]`

## Requirements (declarative skip conditions)

- `#[RequiresPhp('>= 8.3')]`, `#[RequiresPhpExtension('mysqli', '>= 8.0')]`, `#[RequiresSetting('display_errors', '1')]`
- `#[RequiresPhpunit('^13.0')]`, `#[RequiresPhpunitExtension(Class::class)]`
- `#[RequiresFunction('curl_init')]`, `#[RequiresMethod(Class::class, 'method')]`
- `#[RequiresOperatingSystem('/Linux/')]`, `#[RequiresOperatingSystemFamily('Linux')]`
- `#[RequiresEnvironmentVariable('CI', 'true')]`

## Flaky-test handling

- `#[Repeat(100)]` / `#[Repeat(100, failureThreshold: 5)]`, `#[Retry(3)]`

## Test doubles

- `#[AllowMockObjectsWithoutExpectations]`, `#[DisableReturnValueGenerationForTestDoubles]` (class-level)

## Source
- https://docs.phpunit.de/en/13.3/attributes.html
