# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-09-09

### Changed
- **BREAKING:** **hooks:** Port hook scripts from Python/Bash to TypeScript/Bun ([#24](https://github.com/MisterIcy/provenance/pull/24))

## [0.6.0] - 2026-09-08

### Added
- **phpunit:** Add PHPUnit skill with version 9-13 reference docs and evals ([#23](https://github.com/MisterIcy/provenance/pull/23))

### Fixed
- **hooks:** Stop git_guard.py false-triggering on multi-line commands ([#22](https://github.com/MisterIcy/provenance/pull/22))

## [0.5.0] - 2026-09-07

### Added
- **ci:** Add mariadb-tests workflow, CLAUDE.md pointer, README gaps note ([#19](https://github.com/MisterIcy/provenance/pull/19))
- **mariadb-sql:** Add optimizer-internals and query-profiling references ([#17](https://github.com/MisterIcy/provenance/pull/17))
- **agents:** Add ansi-sql-dba subagent, deepen correctness knowledge ([#16](https://github.com/MisterIcy/provenance/pull/16))
- **agents,skills:** Teach sql-query-reviewer to propose version-gated modernization rewrites ([#15](https://github.com/MisterIcy/provenance/pull/15))
- **agents,skills:** Trigger sql-query-reviewer and mariadb-sql on mere MariaDB mention ([#14](https://github.com/MisterIcy/provenance/pull/14))
- **agents:** Add sql-query-reviewer subagent with read-only SQL guard hook ([#12](https://github.com/MisterIcy/provenance/pull/12))
- **skills:** Add mariadb-sql dialect-reference skill with test harness ([#11](https://github.com/MisterIcy/provenance/pull/11))

### Fixed
- **hooks:** Only gate permission on git commit/push commands ([#18](https://github.com/MisterIcy/provenance/pull/18))

## [0.4.0] - 2026-08-30

### Added
- **monitors:** Add branch-merge-watch background monitor ([#9](https://github.com/MisterIcy/provenance/pull/9))
- **git-committer:** Gate commit/push on real PreToolUse hooks ([#8](https://github.com/MisterIcy/provenance/pull/8))
- **subagent-creator:** Scaffold and review Claude Code subagents ([#7](https://github.com/MisterIcy/provenance/pull/7))

### Fixed
- **skill-creator, subagent-creator:** Correct hook path variable in SKILL.md frontmatter ([#10](https://github.com/MisterIcy/provenance/pull/10))

## [0.3.1] - 2026-08-29

_No notable changes recorded for this release._

## [0.3.0] - 2026-08-29

### Added
- **pr-description-sync:** Add opt-in PR description drift sync ([#5](https://github.com/MisterIcy/provenance/pull/5))

## [0.2.0] - 2026-08-29

### Changed
- **skills:** Promote skill-creator to first-class plugin skill ([#4](https://github.com/MisterIcy/provenance/pull/4))
- Add Code of Conduct for human and agent contributors ([#3](https://github.com/MisterIcy/provenance/pull/3))
- Add repo onboarding docs (README, AGENTS.md, CLAUDE.md) ([#2](https://github.com/MisterIcy/provenance/pull/2))

## [0.1.0] - 2026-08-29

_No notable changes recorded for this release._

[Unreleased]: https://github.com/MisterIcy/provenance/compare/v0.6.1...HEAD
[0.6.1]: https://github.com/MisterIcy/provenance/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/MisterIcy/provenance/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/MisterIcy/provenance/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/MisterIcy/provenance/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/MisterIcy/provenance/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/MisterIcy/provenance/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MisterIcy/provenance/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MisterIcy/provenance/releases/tag/v0.1.0
