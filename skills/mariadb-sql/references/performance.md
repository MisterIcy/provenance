# MariaDB performance and the optimizer

How to read execution plans and judge index/query performance specifically on MariaDB.

## Reading `EXPLAIN`

- Prefer `EXPLAIN FORMAT=JSON` (or `ANALYZE FORMAT=JSON` for MariaDB ≥ 10.0.5, which runs the query and reports actual vs estimated rows) over the classic tabular `EXPLAIN` — the JSON form surfaces `attached_condition`, `using_index_for_group_by`, and cost estimates the tabular form hides.
- `type` column (tabular form), worst to best for a lookup: `ALL` (full table scan) → `index` (full index scan) → `range` → `ref`/`eq_ref` → `const`/`system`. `ALL` on any but the smallest table is a scan — check whether an index should exist.
- `rows` is an **estimate** from index statistics, not a fact — on a table with stale statistics (after a bulk load, or with `STATS_PERSISTENT` off/insufficient sampling) it can be wildly wrong. Prefer `ANALYZE FORMAT=JSON`'s `r_rows`/actual counts when you have them.
- `Extra: Using filesort` means a separate sort step outside index order — expected for an ad hoc `ORDER BY`, but a red flag if the same query runs frequently and could be served by an index matching the `ORDER BY`.
- `Extra: Using temporary` means MariaDB materializes an intermediate result set (common with `GROUP BY`/`DISTINCT`/some `UNION`s over non-indexed columns) — usually fine for small result sets, a real cost at scale.
- `Extra: Using index` (no `Using where` alongside it) means a covering index satisfied the query without touching the base table — the fast path; if you can get a hot query there by adding a column to an index, it's usually worth it.
- `Extra: Using index condition` = Index Condition Pushdown (ICP) is active — the storage engine evaluates part of the `WHERE` using the index itself before fetching the row. Good sign, not something to "fix."

## Sargability

A predicate is **non-sargable** (can't use an index range scan) when the indexed column is wrapped in a function or implicitly coerced:

- `WHERE YEAR(created_at) = 2024` — wrap the *literal* instead: `WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'`.
- `WHERE LOWER(email) = 'x@example.com'` against a non-functional-index column — either use a case-insensitive collation on the column (so no wrapping is needed) or add a functional index (`ALTER TABLE ... ADD INDEX ((LOWER(email)))`, MariaDB ≥ 10.2.13 for expressions on invisible/virtual columns, full functional-index syntax varies by version — check).
- Leading-wildcard `LIKE '%term'` cannot use a B-tree index at all; a trailing wildcard `LIKE 'term%'` can. If leading-wildcard search is a real requirement, that's a full-text or external-search-engine problem, not something a B-tree index fixes.
- Comparing a string column to a numeric literal, or vice versa (see correctness.md) also defeats index usage, on top of being a correctness risk.

## Index design

- InnoDB secondary indexes store the primary key as their "row pointer" — a wide or multi-column primary key inflates every secondary index. Keep primary keys narrow (an `AUTO_INCREMENT` surrogate is usually right) if the table has several secondary indexes.
- Composite index column order matters: an index on `(a, b, c)` serves lookups on `a`, `(a,b)`, and `(a,b,c)` prefixes, and can serve range scans on the last-used column, but does **not** serve a lookup on `b` or `c` alone. Check the actual `WHERE`/`JOIN`/`ORDER BY` columns against the index's leading columns, not just "there's an index on this table."
- `ORDER BY`/`GROUP BY` can use an index only if the sort direction and column order match the index (or its exact reverse, since MariaDB ≥ 10.something can scan an index backward). A `GROUP BY a, b ORDER BY b, a` won't reuse an `(a,b)` index for the sort.
- A low-cardinality column (e.g. a boolean or a `status` enum with 3 values) rarely benefits from its own index — the optimizer will often ignore it in favor of a table scan, correctly. It can still be useful as a non-leading column in a composite index.

## Joins and subqueries

- MariaDB's optimizer applies semi-join transformations (`Materialization`, `FirstMatch`, `LooseScan`, `DuplicateWeedout`) to rewrite `IN (subquery)`/`EXISTS` patterns — in modern MariaDB there is usually little performance difference between a well-formed `IN (SELECT ...)` and the equivalent `JOIN`, unlike much older MySQL/MariaDB where `IN` subqueries were reliably slow. Don't reflexively tell someone to rewrite `IN` as `JOIN` — check `EXPLAIN` first; if a semi-join strategy is already applied, the rewrite buys nothing.
- A correlated subquery in the `SELECT` list runs once per outer row — this is the one subquery form that's reliably worth rewriting as a `LEFT JOIN` (or a window function) when the table is non-trivially sized.
- Joining on columns of different types (e.g. `INT` to `VARCHAR`) or different collations both prevents index use and risks correctness issues (see correctness.md) — always flag a type/collation mismatch across a join condition.

## Storage engine matters

- InnoDB (default since MariaDB 10.2) clusters data by primary key — range scans on the primary key are fast; range scans on a secondary index require a second lookup per row unless the query is covered by that index alone. `Aria` (MariaDB's MyISAM successor) doesn't cluster and has different locking (table-level for writes in the classic case) — don't assume InnoDB locking/MVCC behavior applies to an `Aria`/`MyISAM` table.
- `SHOW ENGINE INNODB STATUS` and `information_schema.INNODB_*` tables are the source of truth for buffer-pool hit rate, lock waits, and deadlocks — prefer them over guessing from query text when investigating a live performance issue.
