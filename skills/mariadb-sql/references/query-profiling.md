# MariaDB query profiling

How to actually measure a slow query at runtime, as distinct from reading a plan (`performance.md`) or reasoning about why the optimizer chose it (`optimizer-internals.md`). Load this when a caller wants to profile a live query or workload — timing, counters, in-flight state — not just critique its `EXPLAIN` output.

## `SHOW PROFILE` / `SHOW PROFILES`

```sql
SET profiling = 1;              -- session-scoped, off by default
<run the statement>
SHOW PROFILES;                  -- Query_ID, Duration, Query
SHOW PROFILE FOR QUERY <id>;    -- sequential stage breakdown with per-stage duration
```

Stages are sequential status states the statement passed through — e.g. for a `CREATE TABLE`: `starting`, `checking permissions`, `creating table`, `query end`, `freeing items`, `logging slow query`, `cleaning up`. Optional detail types: `ALL`, `BLOCK IO`, `CONTEXT SWITCHES`, `CPU`, `IPC`, `PAGE FAULTS`, `SOURCE` (function/file/line), `SWAPS` (`MEMORY` is accepted syntax but not implemented). History is a ring buffer sized by `profiling_history_size` (default 15, max 100) and is lost when the session ends — read it before disconnecting. Equivalent structured data is queryable from `information_schema.PROFILING`.

**Don't assume MySQL's deprecation applies here.** MySQL has deprecated `SHOW PROFILE`/`SHOW PROFILES` since 5.7 with removal planned; MariaDB's own current KB documents them as a live, complementary tool alongside Performance Schema — no deprecation notice. Verify against the specific target version if a migration depends on this, but don't flag `SHOW PROFILE` as deprecated on a MariaDB target by default.

## Performance Schema

Disabled by default (since 10.0.12, for the CPU/memory overhead) and startup-only — enabling requires `performance_schema=ON` in config and a restart, not a runtime `SET`. Once on, granular collection still needs consumers/instruments turned on, either at runtime:

```sql
UPDATE performance_schema.setup_consumers SET ENABLED='YES';
UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES';
```

or targeted in config (e.g. `performance-schema-instrument='stage/%=ON'` plus the matching `performance-schema-consumer-events-stages-*=ON`). Tables are in-memory, unindexed, and reset on restart.

Tables most relevant to profiling a query or workload:

- **`events_statements_summary_by_digest`** — per normalized-query-digest aggregates (count, min/max/avg wait, lock time, errors), capped by `performance_schema_digests_size`; overflow aggregates under a `NULL` digest. The right table for "which query shape is actually costing us the most," as opposed to one slow instance.
- **`events_statements_history`** (and `_long`) — recent individual statements per thread.
- **`events_stages_current`/`events_stages_history`** — per-stage timing within a statement, the Performance Schema equivalent of `SHOW PROFILE`'s stage breakdown.
- **`events_waits_current`/`events_waits_history`** — wait-event-level detail (I/O, locks).

MariaDB-specific notes: 10.5 added roughly 270 memory instruments and switched to dynamic (load-based) memory allocation for these tables, so it allocates less by default than MySQL 5.7's equivalent setup — but memory, once allocated, is never returned to the OS. MariaDB 10.5+ ships 80 Performance Schema tables. MariaDB's own docs largely defer to MySQL's Performance Schema manual for general behavior; MariaDB-specific instrumentation-coverage differences are not thoroughly documented on MariaDB's side — treat a claim about exact instrumentation coverage as unverified unless checked live.

## Slow query log

```
slow_query_log = 1                  -- renamed log_slow_query at 10.11 (old name still accepted)
long_query_time = 1                 -- seconds, fractional; renamed log_slow_query_time at 10.11
log_slow_verbosity = query_plan,explain
log_queries_not_using_indexes = 1
min_examined_row_limit = 0          -- renamed log_slow_min_examined_row_limit at 10.11
log_slow_rate_limit = 1             -- throttle: log only 1-in-N qualifying statements
```

`log_slow_verbosity` accepts a comma-separated set: `innodb`, `query_plan` (logs `Full_scan`, `Full_join`, `Tmp_table`, `Tmp_table_on_disk`, `Filesort`, `Filesort_on_disk`, merge-pass counts), `explain` (10.1.0+ — logs a full plan line prefixed `explain:` with `id, select_type, table, type, possible_keys, key, key_len, ref, rows, r_rows, r_filtered, filtered, Extra`; note `r_rows`/`r_filtered` — actual values from an internal `ANALYZE` — appear here even though a plain manual `EXPLAIN` never shows them), `engine` (storage-engine statistics), `warnings` (attached errors/warnings/notes, capped by `log_slow_max_warnings`). **`log_slow_verbosity`, and `explain` specifically, only work with file-based logging** (`log_output=FILE`, the default) — not with `log_output=TABLE`; check `log_output` before assuming verbose slow-log detail is actually being captured.

`mariadb-dumpslow` is MariaDB's bundled utility for summarizing the file-based slow log (grouping similar queries, sorting by total/average time). No MariaDB documentation references `pt-query-digest` for this workflow — don't assume it's part of a stock MariaDB setup.

## `EXPLAIN ANALYZE` / `ANALYZE FORMAT=JSON`

Covered structurally in `performance.md`; the profiling-relevant detail is what it adds beyond estimates. `ANALYZE FORMAT=JSON <stmt>` actually executes the statement and augments the `EXPLAIN FORMAT=JSON` tree with: `r_rows` (actual average rows read per execution at that node), `r_filtered` (% of rows surviving a condition), `r_loops` (JSON-only — times the node executed), `r_total_time_ms` (cumulative including subnodes; excludes commit time for `UPDATE`/`DELETE`), `r_buffer_size`. InnoDB-level engine stats (`r_engine_stats`: `pages_accessed`, `pages_updated`, `pages_read_count`, `pages_prefetch_read_count`, `pages_read_time_ms`, `old_rows_read`) were added across a set of point releases: **10.6.15, 10.8.8, 10.9.8, 10.10.6, 10.11.5, 11.0.3, 11.1.2, 11.2.1** — confirm the target is at or above its series' minimum before expecting `r_engine_stats` to appear. `SHOW ANALYZE FORMAT=JSON FOR <connection_id>` (10.9+) profiles a statement already running on another connection, without waiting for it to finish on the profiling connection.

Reading the gap: a large `rows` (estimate) vs `r_rows` (actual) divergence signals stale or insufficient statistics driving a cardinality misestimate — see `optimizer-internals.md`. A low `r_filtered` paired with a high `r_rows` flags a condition that isn't index-supported (the engine is reading far more rows than it ultimately keeps).

## `SHOW STATUS` counters for a workload or single query

- `Handler_read_key` — index-based reads; high is normally good.
- `Handler_read_next` — sequential index reads/range scans.
- `Handler_read_rnd` — position-based reads; high suggests a bad join plan or full scan.
- `Handler_read_rnd_next` — next-row scans; high suggests table scans or poor index use.
- `Created_tmp_tables` vs `Created_tmp_disk_tables` — in-memory vs disk-spilled temp tables; watch the ratio, not just the absolute count.
- `Select_scan` — joins doing a full scan of the first table. `Select_full_join` — joins with no usable index; nonzero is a real signal to check indexing.
- `Sort_merge_passes` — high values suggest raising `sort_buffer_size` or fixing the underlying index so a sort isn't needed at all.
- `Innodb_rows_read` — rows read from InnoDB tables.

To isolate one query's contribution: `FLUSH STATUS` (synonym `FLUSH SESSION STATUS`) folds the session's current counters into the global totals and resets the session's own values to zero — run it, execute the query, then read `SHOW SESSION STATUS`/`SHOW STATUS` for the delta attributable to just that statement. **From 11.5**, `FLUSH STATUS`'s global-reset behavior splits into a separate `FLUSH GLOBAL STATUS`; `FLUSH STATUS`/`FLUSH SESSION STATUS` becomes session-scoped only. Confirm which behavior the target version has before relying on `FLUSH STATUS` to reset anything beyond the current session.

## `information_schema` tables for catching a query in flight

- **`PROCESSLIST`** (`SHOW [FULL] PROCESSLIST`) — `Id, User, Host, db, Command, Time, State, Info, Progress`; `Info` truncates to 100 characters unless `FULL` is used; seeing other users' threads requires the `PROCESS` privilege. Querying the information_schema table itself takes a lock — prefer the Performance Schema `THREADS` table for repeated/scripted polling when Performance Schema is enabled.
- **`INNODB_TRX`** — one row per active InnoDB transaction; `TRX_STATE` of `RUNNING`/`LOCK WAIT`/`ROLLING BACK`/`COMMITTING` — a `LOCK WAIT` row points at the lock it's waiting on.
- **`INNODB_LOCK_WAITS`** — blocked/blocking transaction pairs, joined against `INNODB_LOCKS`, for diagnosing a specific lock wait or deadlock.
- **`INNODB_METRICS`** (10.0.0+) — instrumented counters (`NAME, SUBSYSTEM, COUNT, MAX/MIN/AVG_COUNT`, `*_RESET` variants, `TIME_ENABLED/DISABLED/ELAPSED/RESET`, `ENABLED`, `TYPE`, `COMMENT`); most counters are disabled by default, enable via `innodb_monitor_enable`; values are non-persistent (reset on restart); requires the `PROCESS` privilege. Note the `STATUS` column was renamed `ENABLED` (varchar → int) at **10.4** per MariaDB's docs — **live-checked against this skill's own test harness, the rename isn't visible until 10.5**: `SELECT ENABLED FROM information_schema.INNODB_METRICS` errors with "Unknown column 'ENABLED'" on a 10.4.34 image and only resolves from 10.5 onward there — confirm the live column name on a 10.4.x target rather than assuming the docs' stated version.

## Choosing a tool

- One query, ad hoc, right now → `SHOW PROFILE` or `ANALYZE FORMAT=JSON` (the latter also tells you *where* the time went, node by node, not just total duration).
- "Which query shape is costing us the most over time" → Performance Schema's `events_statements_summary_by_digest`, if enabled; otherwise the slow query log with `mariadb-dumpslow`.
- "Why is this specific connection stuck right now" → `PROCESSLIST`/`INNODB_TRX`/`INNODB_LOCK_WAITS`.
- "Is this workload doing more disk-spilling/full-scanning than it should" → `SHOW STATUS` counters, diffed with `FLUSH STATUS` around a representative run.
