---
name: mariadb-sql
description: MariaDB-specific SQL dialect knowledge — correctness pitfalls (NULL/GROUP BY/collation semantics), performance (optimizer, indexes, EXPLAIN reading), safety (sql_mode, FK/engine behavior), and feature-availability by version (window functions, CTEs, JSON, sequences, system-versioned tables). Use when reviewing, writing, or tuning SQL that targets MariaDB (as opposed to generic ANSI SQL, MySQL-only behavior, or another RDBMS), or when the target version/edition is unstated but the schema/tooling implies MariaDB (`mariadb`/`mariadb-admin` CLI, `my.cnf`, `aria`/`innodb`/`columnstore` storage-engine mentions, a `10.x`/`11.x`/`12.x` version string). Trigger on the user simply saying "MariaDB" in a SQL/database context, not only on an explicit review/tuning request — dialect detection alone is enough to load this reference.
disable-model-invocation: false
---

# MariaDB SQL

Dialect reference for anyone reviewing, writing, or tuning SQL against MariaDB. Written to be loaded by a reviewer (e.g. the `sql-query-reviewer` agent) once it knows the target dialect is MariaDB — not a general SQL tutorial.

## When to use this

- The caller names MariaDB explicitly, or the context implies it (a `mariadb`/`mysql` CLI invocation, `my.cnf`, storage-engine names like InnoDB/Aria, a `10.x`/`11.x` version string).
- Don't use it for plain MySQL-only review (see "MariaDB vs MySQL" below — most of this still applies, but a few sections are exclusively MariaDB) or for another RDBMS (Postgres, SQLite, SQL Server) — those have their own semantics.

## Workflow

1. **Pin the version if you can.** Behavior below is annotated by the MariaDB version it landed in. If the caller didn't state one, assume the newest LTS the caller's tooling suggests, and mark version-gated findings **unverified** rather than asserting a feature exists.
2. **Read `references/correctness.md`** for NULL/`GROUP BY`/collation/type-coercion pitfalls that are MariaDB-specific or differ from ANSI SQL.
3. **Read `references/performance.md`** for optimizer behavior, index usage, and how to read `EXPLAIN`/`EXPLAIN FORMAT=JSON`/`ANALYZE FORMAT=JSON` output.
4. **Read `references/safety-and-config.md`** for `sql_mode`, foreign-key/engine gotchas, and replication-safety concerns (statements that are fine standalone but break replication or backups).
5. **Read `references/version-features.md`** only when a query uses (or could use) a feature you need to confirm is available at the target version — window functions, CTEs, JSON functions, sequences, system-versioned tables, invisible columns, etc.

Don't load all four references for a trivial query — pull only the ones relevant to what you're actually checking.

## MariaDB vs MySQL

MariaDB forked from MySQL at 5.5 and the two have diverged. Most standard SQL and most InnoDB behavior described here applies to both, but do not assume a MySQL-specific feature exists in MariaDB or vice versa — call out anything you're not sure is shared. MariaDB-only: sequences, system-versioned tables, `RETURNING`, invisible columns, `Aria` storage engine, the optimizer's semi-join strategies as documented here. MySQL-only (do **not** assume in MariaDB): the `X`/document store, MySQL 8's `CTE`/window-function *syntax details* can differ subtly in edge cases, MySQL's `JSON_TABLE` behavior, MySQL roles syntax differences. When genuinely unsure which side a behavior falls on, flag it as unverified rather than asserting either way.

## Common mistakes to avoid

- Asserting a version-gated feature is or isn't available without checking `references/version-features.md` or being told the version.
- Treating MySQL documentation/behavior as automatically true for MariaDB (or vice versa) — they diverge more each release.
- Reviewing `GROUP BY`/`ORDER BY` implicit-column behavior against ANSI-only rules — MariaDB's default `sql_mode` historically allowed non-aggregated columns in `GROUP BY` that `ONLY_FULL_GROUP_BY` would reject; check which mode applies.
- Ignoring storage engine when judging transactional/locking behavior — `MyISAM`/`Aria` tables don't behave like `InnoDB` under concurrent writes or transactions.
