# MariaDB correctness pitfalls

Semantics that differ from naive ANSI-SQL expectations, or that are easy to get wrong specifically on MariaDB.

## `sql_mode` changes what "correct" means

The single most important fact for reviewing MariaDB correctness: a query's validity depends on `sql_mode`, which is per-session/global config, not fixed by the engine version.

- **`ONLY_FULL_GROUP_BY`** (on by default since MariaDB 10.2.4): rejects a `SELECT` list or `HAVING` clause that references a non-aggregated column not in `GROUP BY` and not functionally dependent on one. Before that default change (or with the mode explicitly off), MariaDB silently picks an arbitrary row's value for such columns — a common source of "why did this column show the wrong value" bugs. If you see `SELECT a, b, MAX(c) FROM t GROUP BY a` with `b` not in the group list, flag it as non-deterministic *unless* `b` is provably functionally dependent on `a` (e.g. `a` is a primary key of the table `b` belongs to).
- **`STRICT_TRANS_TABLES`** (on by default since 10.2.4): without it, invalid/truncated values (a too-long string, an out-of-range number, inserting `NULL` into a `NOT NULL` column without a default) get silently coerced/truncated with a warning instead of raising an error. A query or migration that "works" in a non-strict session can fail — or worse, silently corrupt data — in a strict one. Always ask or check which mode applies before asserting a write statement is safe.
- Both are session-settable — a query reviewed as "correct" in one connection's mode can behave differently in another's. Treat the mode as unverified evidence you need, not something to assume.

## NULL semantics

- `NOT IN (subquery)` where the subquery can return a `NULL`: the whole expression evaluates to `NULL` (never `TRUE`) for every row, silently returning zero rows. This is standard SQL behavior, not MariaDB-specific, but it's the single most common "this query mysteriously returns nothing" bug — always check nullability of the subquery's column when you see `NOT IN`.
- `<=>` (NULL-safe equality) vs `=`: `NULL = NULL` is `NULL` (falsy), `NULL <=> NULL` is `1` (true). A `WHERE col = NULL` that should mean "col is null" is always a bug — it should be `IS NULL` or `<=>`.
- Unique indexes and `NULL`: MariaDB (like MySQL) allows multiple `NULL` values in a column with a `UNIQUE` index — `NULL` is never considered equal to another `NULL` for uniqueness purposes. Don't assume a unique index enforces "at most one row with this value" when the column is nullable.

## Collation and comparison

- Default collation moved to `utf8mb4_uni_ci`-family in recent MariaDB versions (varies by version — check the schema, don't assume); older schemas are frequently still `latin1`/`utf8mb3` with `_general_ci` or `_swedish_ci` (the historical default). A join or `WHERE` across columns with different collations either raises `Illegal mix of collations` or silently uses one column's collation for comparison — check `SHOW CREATE TABLE` when a cross-table string comparison looks suspicious.
- `_ci` (case-insensitive) collations mean `'a' = 'A'` is true and `WHERE name = 'Foo'` will match `'foo'` — this is by design, but a query that assumes case-sensitive matching over a `_ci` column is a correctness bug, not a MariaDB quirk.
- String-to-number comparisons (`WHERE varchar_col = 123`) trigger implicit type coercion: MariaDB casts the string side, and a non-numeric-looking string coerces to `0`, matching rows you didn't intend. Flag any comparison between a string column and a numeric literal (or vice versa).

## `GROUP BY` and implicit ordering

`GROUP BY` in MariaDB does **not** guarantee the same row ordering as pre-8.0 MySQL implied — never rely on `GROUP BY` alone for ordering; require an explicit `ORDER BY` whenever the caller needs a specific order out of a grouped query.

## `ON DUPLICATE KEY UPDATE` and `REPLACE INTO`

- `REPLACE INTO` is a `DELETE` + `INSERT`, not an `UPDATE` — it changes the row's `AUTO_INCREMENT`/rowid, fires `DELETE` triggers and cascades, and briefly removes the row (visible to concurrent readers in some isolation levels). It is very rarely the right choice over `INSERT ... ON DUPLICATE KEY UPDATE` or `INSERT ... ON DUPLICATE KEY UPDATE ... VALUES(...)`. Flag `REPLACE INTO` when foreign keys, triggers, or `AUTO_INCREMENT` stability matter.
- `ON DUPLICATE KEY UPDATE` triggers on **any** unique or primary key collision, not just the key you had in mind — if a table has more than one unique key, a write can silently update the "wrong" conflicting row from the caller's intent. Check all unique keys on the table before approving.

## Standard-SQL facts worth checking (not MariaDB-specific, but easy to miss)

These are ANSI/ISO SQL-mandated behaviors, not MariaDB quirks — call them out as standard facts, and separately flag anywhere MariaDB/InnoDB diverges from what the standard would otherwise allow.

- **`NOT EXISTS` over `NOT IN` when nullable.** `EXISTS`/`NOT EXISTS` is a pure existence test, unaffected by `NULL`s in the subquery's rows — unlike `NOT IN`, it never silently collapses to zero rows. Prefer a correlated `NOT EXISTS` as the fix (not just the diagnosis) whenever the `NOT IN` subquery's column may contain `NULL`.
- **Correlated subqueries must be scalar (or used with `EXISTS`/`IN`).** A correlated subquery is conceptually re-evaluated once per outer row with outer values bound as constants — there's no guaranteed join strategy, only equivalent results. `WHERE col = (correlated subquery)` is only well-defined if the subquery returns at most one row per outer row; if it can return more than one, this isn't just inefficient, it's a runtime error waiting to happen (MariaDB raises `Subquery returns more than 1 row` only when a given outer row actually triggers it — a case rewriting a correlated subquery to a join is silently *not* equivalent).
- **`CHECK` accepts `UNKNOWN`, not just `TRUE`.** A `CHECK` constraint rejects a row only when its condition evaluates to `FALSE` — `UNKNOWN` (i.e. a `NULL` operand) passes silently. `CHECK (discount > 0)` does **not** block `discount IS NULL`; if `NULL` should be disallowed, write `CHECK (discount > 0 AND discount IS NOT NULL)` or add `NOT NULL` directly. This is the single most commonly missed ANSI rule when reviewing constraint definitions.
- **`UNION`/`INTERSECT`/`EXCEPT` default to `DISTINCT`.** All three deduplicate result rows unless `ALL` is specified. An unqualified `UNION` between two row sets with legitimate duplicates silently drops rows — a correctness bug whenever duplicates carry meaning (e.g. counting), and the dedup pass is also a full sort/hash, an accidental-performance cost. Use `UNION ALL`/`INTERSECT ALL`/`EXCEPT ALL` whenever duplicates matter.
- **Isolation levels are defined by which anomalies they *permit*, not prevent.** Per the standard: `READ UNCOMMITTED` permits dirty, non-repeatable, and phantom reads; `READ COMMITTED` still permits non-repeatable and phantom reads; `REPEATABLE READ` still permits phantom reads (a `SELECT COUNT(*)` re-run inside the same transaction can return a different count purely from new matching rows); only `SERIALIZABLE` permits none. Don't assume "`REPEATABLE READ`" alone rules out phantoms — InnoDB's `REPEATABLE READ` happens to close that gap via MVCC/gap-locking, but that's a MariaDB-specific strengthening, not something the standard requires; a review that asserts phantom-safety from the isolation level name alone, without confirming it's InnoDB, is unverified.
- **`RESTRICT` vs `NO ACTION` timing (standard, not MariaDB).** The standard checks `NO ACTION` at end-of-statement (or end-of-transaction if declared `DEFERRABLE INITIALLY DEFERRED`), letting a same-statement compensating change satisfy it, while `RESTRICT` checks immediately and is never deferrable. MariaDB/InnoDB does not implement this distinction — both `ON DELETE RESTRICT` and `ON DELETE NO ACTION` are enforced immediately in MariaDB, so don't assume the standard's deferred-`NO ACTION` semantics apply here; treat the two as equivalent on this engine.

## Window functions and CTEs (available since 10.2)

- Frame semantics (`ROWS`/`RANGE BETWEEN`) default to `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` when an `ORDER BY` is present and no frame is specified — this can produce different results than expected for ties in the `ORDER BY` column (`RANGE` groups peer rows together; `ROWS` doesn't). If duplicate values in the order column matter to correctness, check whether the query needs an explicit `ROWS` frame.
- Recursive CTEs (`WITH RECURSIVE`) have no automatic cycle detection — an unbounded recursive CTE over cyclic data will hit `max_recursive_iterations` (or the connection will hang/OOM if unset appropriately). Flag a recursive CTE over self-referential data without a visited-set/depth guard.
