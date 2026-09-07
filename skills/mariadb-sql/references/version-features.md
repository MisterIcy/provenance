# MariaDB feature availability by version

Use this to check whether a construct in the query under review is actually available at the target version, rather than assuming. Version numbers below mark when a feature was **introduced** — always confirm against the specific target. This plugin's `mariadb-dba` agent defaults to reviewing against **10.6** unless told otherwise, so 10.6-and-earlier is the common baseline; treat anything newer as "available if the target is confirmed to be newer." Sourced from MariaDB's own "Changes & Improvements" KB/docs pages per series (`mariadb.com/kb` / `mariadb.com/docs/release-notes`).

## Quick reference: commonly-checked features

| Feature | Introduced | Notes |
|---|---|---|
| Window functions (`OVER (...)`, `ROW_NUMBER()`, `RANK()`, etc.) | 10.2 | Frame-semantics caveat in `correctness.md`. |
| Common table expressions (`WITH`, `WITH RECURSIVE`) | 10.2 | No automatic cycle detection until the `CYCLE` clause (10.5). |
| `CYCLE` clause on recursive CTEs | 10.5 | Explicit cycle detection; absent below 10.5, a cycling recursive CTE just runs until `max_recursive_iterations` (or forever without a limit). |
| JSON functions (`JSON_EXTRACT`, `JSON_VALUE`, etc.) | 10.2 | MariaDB stores JSON as `LONGTEXT` with a `CHECK` constraint, not a native binary JSON type like MySQL's `JSON` — don't assume MySQL's storage/performance characteristics apply. |
| `JSON_TABLE` | 10.6 | Shape/edge-case behavior can still differ from MySQL's `JSON_TABLE`. |
| `JSON_ARRAYAGG` / `JSON_OBJECTAGG` | 10.5 | |
| `CHECK` constraints (enforced) | 10.2 | Earlier versions parsed but ignored `CHECK`. |
| Sequences (`CREATE SEQUENCE`, `NEXTVAL`/`PREVIOUS VALUE FOR`) | 10.3 | MariaDB-only — no MySQL equivalent. |
| System-versioned tables (`WITH SYSTEM VERSIONING`) | 10.3 | MariaDB-only (temporal tables); `WITHOUT OVERLAPS` for application-time periods added 10.5. |
| `RETURNING` clause on `INSERT`/`UPDATE`/`DELETE`/`REPLACE` | 10.5 | MariaDB-only; still a mutating statement — a reviewer never runs it, but should recognize the syntax when reviewing application code. |
| Invisible columns (`INVISIBLE`) | 10.3 | MariaDB-only. |
| Instant `ADD COLUMN` (`ALGORITHM=INSTANT`) | 10.3, extended 10.4 (`DROP COLUMN`, column reorder, `VARCHAR` extension), 10.4/10.6 further widened | Which `ALTER TABLE` changes qualify for `INSTANT` vs `NOLOCK` vs `INPLACE` vs full rebuild (`COPY`) depends on the exact change *and* version — always check current docs/behavior for the specific ALTER rather than assuming from memory. 11.2/11.4 further widened `ALGORITHM=COPY, LOCK=NONE` to "most operations." |
| `ONLY_FULL_GROUP_BY` / `STRICT_TRANS_TABLES` on by default | 10.2.4 | See `correctness.md` — a pre-10.2.4 or explicitly-reconfigured session may not have these. |
| Native `UUID` data type | 10.7 | Don't assume a native `UUID` type below 10.7 — earlier versions store UUIDs as `CHAR(36)`/`BINARY(16)`. |
| `UUID_v4()` / `UUID_v7()` generator functions | 11.7 | Version-specific UUID generation, not just the type. |
| Vector data type / vector indexing | 11.6 (type), 11.7 (Vector Search), 11.8 (`VEC_DISTANCE_*` functions, LTS-stable) | Introduced across three releases — don't assume full vector-search functionality on 11.6 alone; flag as unavailable on any 10.x/11.0–11.5 target. |
| `SET SESSION AUTHORIZATION` | 12.0 | Recent — flag unavailable below 12.0. |
| `IS JSON` predicate / `XML` data type / associative arrays (`DECLARE TYPE .. TABLE OF .. INDEX BY`) | 12.3 | Very recent — confirm target is 12.3+ before assuming availability. |

## Per-series detail (10.2 → 12.3, plus 11.8 LTS)

### 10.2
- **Window functions** and **CTEs** (`WITH`, `WITH RECURSIVE`) introduced. New reserved words: `OVER`, `RECURSIVE`, `ROWS`.
- **`CHECK` constraints** now enforced (previously parsed but ignored).
- **JSON**: functions added; JSON stored as `LONGTEXT` with a `CHECK` constraint (not a binary type).
- `DEFAULT` clause accepts expressions; `BLOB`/`TEXT` columns can have `DEFAULT`s; virtual/computed column restrictions relaxed.
- `EXECUTE IMMEDIATE` (Oracle-style dynamic SQL); prepared statements understand most expressions.
- `ALTER USER`, `SHOW CREATE USER` added.
- Multiple triggers per table event, ordered via `FOLLOWS`/`PRECEDES`.
- Decimal precision increased from 30 to 38 digits.
- **`sql_mode` default changed** (10.2.4): `STRICT_TRANS_TABLES`, `ERROR_FOR_DIVISION_BY_ZERO`, `NO_AUTO_CREATE_USER`, `NO_ENGINE_SUBSTITUTION` — a `NOT NULL` column with no default no longer silently falls back to a dummy value on insert.
- InnoDB replaced XtraDB as the default engine; InnoDB gained spatial indexing; MyRocks added (later reached GA maturity in 10.2.14); TokuDB split into a separate package.
- EXPLAIN FORMAT=JSON gained `outer_ref_condition` / `sort_key`; condition pushdown into non-mergeable derived tables/views.

### 10.3
- **Sequences**: full `CREATE/ALTER/DROP SEQUENCE`, `NEXT VALUE FOR`, `PREVIOUS VALUE FOR`, `SETVAL()` (MariaDB-only).
- **System-versioned tables** (temporal `AS OF` queries, MariaDB-only).
- **Invisible columns** (`INVISIBLE`), excluded from `SELECT *`.
- **Instant `ADD COLUMN`**.
- Table value constructors (inline `VALUES (...), (...)` as a table expression); note `VALUES()` (the INSERT-context function) was renamed `VALUE()` to avoid clashing with this.
- `INTERSECT` / `EXCEPT` set operators (became reserved words).
- `FOR ... END FOR` loop in stored routines; `ROW` data type, `ROW TYPE OF` anchored types, parametric cursors.
- Oracle-compatible packages (`CREATE PACKAGE [BODY]`) under `sql_mode=ORACLE`.
- New functions: `PERCENTILE_CONT`, `PERCENTILE_DISC`, `MEDIAN` (window functions), Oracle-compatible `SUBSTR()`, `CHR()`, three-argument `DATE_FORMAT(date, format, locale)`.
- New `sql_mode` values: `EMPTY_STRING_IS_NULL`, `SIMULTANEOUS_ASSIGNMENT`, `ORACLE`.
- `GROUP_CONCAT()` accepts `LIMIT`; `UPDATE`/`DELETE` can reference the same table via a subquery; multi-table `UPDATE` supports `ORDER BY`/`LIMIT`; `TRUNCATE` now honors transactional locks.
- Condition pushdown through window-function `PARTITION BY`; long `IN` lists auto-convert to subqueries; lateral-derived-table optimization.

### 10.4
- **Instant `DROP COLUMN`** and instant column reorder; instant `VARCHAR` extension and charset/collation change for non-indexed columns.
- Parenthesized precedence in `UNION`/`EXCEPT`/`INTERSECT`.
- `CAST(x AS INTERVAL DAY_SECOND(N))`.
- Unique index/constraint now allowed on `BLOB`/`TEXT` columns.
- `INSTALL PLUGIN IF NOT EXISTS`, `UNINSTALL PLUGIN`/`UNINSTALL SONAME IF EXISTS`.
- Optimizer trace (`optimizer_trace`); Engine-Independent Table Statistics on by default (`use_stat_tables=PREFERABLY_FOR_QUERIES`, `optimizer_use_condition_selectivity=4`); histograms used (not yet collected) by default; condition pushdown into materialized `IN`-subqueries; `condition_pushdown_from_having`; rowid-filtering optimization (`rowid_filter` switch).
- `eq_range_index_dive_limit` default changed 0 → 200.
- Unix socket authentication becomes the default on Unix-like systems; user password expiry; account locking; `mysql.global_priv` replaces the old `mysql.user` layout.
- `BACKUP STAGE` for low-lock backups.
- `TIME_ROUND_FRACTIONAL` sql_mode flag added.

### 10.5
- **`RETURNING`** clause on `INSERT`/`REPLACE` (joining `DELETE`, which already had it).
- `EXCEPT ALL` / `INTERSECT ALL`.
- `WITHOUT OVERLAPS` constraint for application-time period tables.
- `ALTER TABLE ... RENAME INDEX/KEY`, `ALTER TABLE ... RENAME COLUMN`; `ALTER TABLE`/`RENAME TABLE ... IF EXISTS`.
- `VISIBLE` index attribute.
- **`CYCLE`** clause for recursive-CTE cycle detection.
- `RELEASE_ALL_LOCKS()`.
- New functions: `JSON_ARRAYAGG`, `JSON_OBJECTAGG`.
- New `INET6` data type (native IPv6 storage).
- `innodb_adaptive_hash_index` now defaults **OFF**; `innodb_checksum_algorithm` now defaults to `full_crc32`; several legacy InnoDB concurrency/scrubbing variables removed.
- S3 storage engine (archive tables to S3-compatible storage); MariaDB ColumnStore included (Beta).
- Extended binlog row metadata (`binlog_row_metadata`); `slave_parallel_mode` defaults to `optimistic`; `REPLICA` becomes a valid synonym for `SLAVE`.
- `SUPER` privilege split into narrower privileges (`BINLOG ADMIN`, `CONNECTION ADMIN`, `READ_ONLY ADMIN`, etc.); `REPLICATION CLIENT` renamed `BINLOG MONITOR` (old name still accepted).
- Inferred `IS NOT NULL` predicates usable by the range optimizer; packed sort keys shrink temp-file sizes for `VARCHAR`/`CHAR`/`BLOB` sorts.

### 10.6 (baseline LTS — well-covered by design)
- **`SELECT ... OFFSET ... FETCH`** (SQL-standard pagination syntax).
- **`SELECT ... SKIP LOCKED`** (InnoDB only).
- **Ignored indexes** (index kept but hidden from the optimizer).
- **`JSON_TABLE`** — extracts JSON into a relational table shape.
- Oracle-mode additions: anonymous derived-table subqueries (no `AS` required), `ADD_MONTHS()`, `TO_CHAR()`, `SYS_GUID()`, `MINUS` mapped to `EXCEPT`, `ROWNUM`.
- **Atomic DDL**: `CREATE/ALTER/RENAME/DROP TABLE`, `DROP DATABASE` are now all-or-nothing.
- **Character set default flip**: `utf8` (and related collations) is now an alias for `utf8mb3` rather than the reverse; `old_mode` controls whether `utf8` implies `utf8mb4`. Don't assume `utf8` means `utf8mb4` on 10.6+ without checking `old_mode`.
- InnoDB: old MariaDB-5.5-era checksum algorithm removed (crc32 only); `SYS_TABLESPACES` reflects the filesystem directly, `SYS_DATAFILES` removed.
- TokuDB and CassandraSE storage engines removed; 23 deprecated InnoDB variables removed.
- `max_recursive_iterations` default reduced to 1000; `binlog_expire_logs_seconds` added for finer binlog-purge control.

### 10.7
- **Native `UUID` data type** (storage + comparison semantics distinct from `CHAR(36)`).
- New functions: `JSON_EQUALS`, `JSON_NORMALIZE`, `NATURAL_SORT_KEY`, `SFORMAT`.
- `ALTER TABLE ... CONVERT PARTITION ... TO TABLE` / `CONVERT TABLE ... TO PARTITION` (fast partition↔table conversion, one statement instead of CREATE/EXCHANGE/DROP).
- `GET DIAGNOSTICS` gains `ROW_NUMBER` condition property (identify which row of a multi-row `INSERT` failed).
- Multi-source replication gains MySQL-style `CHANNEL` syntax.
- Five compression provider plugins (bzip2, lzma, lz4, lzo, snappy); `password_reuse_check` validation plugin.
- `wsrep_replicate_myisam`, `wsrep_strict_ddl` removed.

### 10.8
- Stored **functions** and **cursors** gain `IN`/`OUT`/`INOUT` parameter qualifiers (previously procedure-only for `OUT`/`INOUT`).
- Descending index columns: individual index columns can be declared `ASC`/`DESC` explicitly, letting certain `ORDER BY ... DESC` patterns use the index directly.
- `CRC32()`/new `CRC32C()` accept an optional chaining argument.
- **Replication lag reduction**: `ALTER TABLE` starts replicating (and executing on replicas) when it *starts* on the primary, not when it finishes.
- Histogram statistics stored as JSON (more precise) instead of binary.
- `keep_files_on_create` deprecated.

### 10.9
- `JSON_OVERLAPS` function; JSONPath gains negative indices and range notation (e.g. `[0:5]`).
- `SHOW ANALYZE [FORMAT=JSON]`; `SHOW EXPLAIN` gains `EXPLAIN FOR CONNECTION` form.
- `innodb_log_file_size` becomes dynamically changeable (no restart); `innodb_disallow_writes` removed.
- `old` variable folded into `old_mode`; `innodb_change_buffering` deprecated (buffer itself removed later, 11.0).

### 10.10
- New functions: `RANDOM_BYTES()`; new `INET4` data type (native IPv4 storage, pairs with 10.5's `INET6`).
- **`explicit_defaults_for_timestamp` default changed to `ON`** — check this before assuming a `TIMESTAMP` column auto-updates/defaults the old (pre-8.0-compat) way.
- `--ssl` becomes the default for the `mariadb` CLI.
- `CHANGE MASTER TO` defaults to GTID-based replication when the master supports it; `MASTER_USE_GTID=Current_Pos` deprecated in favor of `MASTER_DEMOTE_TO_SLAVE`; new `slave_max_statement_time`.
- Join optimization improved for many-table joins including `eq_ref` chains; table elimination now works across derived tables.
- `DES_ENCRYPT`/`DES_DECRYPT` deprecated; `innodb_version` removed; 8 `spider_*` variables removed.

### 10.11 (LTS, maintained to Feb 2028)
- `GRANT ... TO PUBLIC` (grant to all users without creating an explicit account).
- `bind_address` accepts a comma-separated list of addresses.
- `mariadb-binlog` gains `--gtid-strict-mode`, `--do-domain-ids`, `--ignore-domain-ids`, `--ignore-server-ids`.
- `system_versioning_insert_history` (permit modifying system-versioned history rows).
- Largely consolidates 10.7–10.10 features (UUID type, INET4/INET6, JSON_OVERLAPS, descending indexes, explicit_defaults_for_timestamp=ON, GTID-based replication defaults) into one LTS train — when a caller says "10.11" expect all of the above to be present.

### 11.0
- New function: `FORMAT_PICO_TIME()`.
- **InnoDB change buffer removed entirely** (affects write-amplification characteristics, not SQL syntax).
- `innodb_undo_tablespaces` default raised 0 → 3.
- Notable optimizer cost-model overhaul ("Optimizer Cost Model from MariaDB 11.0") — cost-based plan choices can differ from 10.x for the same query/statistics.
- Several `innodb_defragment*` variables deprecated; `innodb_change_buffer_max_size`/`innodb_change_buffering` removed (following the buffer's removal).

### 11.1
- `JSON_SCHEMA_VALID()` function.
- Semi-join subquery optimization strategies extended to single-table `UPDATE`/`DELETE` (previously `SELECT`-only) — an `UPDATE ... WHERE x IN (SELECT ...)` can now be planned like a semi-join.
- `DATE()`/`YEAR()` on a column become sargable against constants (e.g. `WHERE YEAR(a) = 2019` can use an index).
- `transaction_isolation` becomes the canonical system variable; `tx_isolation` deprecated.
- `mariadb-backup` output files renamed `mariadb_backup_*` (from `xtrabackup_*`).

### 11.2
- `ALTER TABLE` can perform most operations via `ALGORITHM=COPY, LOCK=NONE` by default — broadens which DDL avoids blocking concurrent DML, but doesn't change which `ALGORITHM=INSTANT`/`NOLOCK` list applies; still check the specific ALTER.
- `AES_ENCRYPT()`/`AES_DECRYPT()` support explicit IV and algorithm selection.
- New JSON functions: `JSON_OBJECT_FILTER_KEYS`, `JSON_OBJECT_TO_ARRAY`, `JSON_ARRAY_INTERSECT`, `JSON_KEY_VALUE`; `JSON_TABLE` can retrieve object keys during iteration.
- Temporary tables now appear in `INFORMATION_SCHEMA.TABLES`/`SHOW TABLES`/`SHOW TABLE STATUS` — a reviewer can no longer assume a temp table is invisible to schema introspection.
- InnoDB system tablespace reclaims unused space automatically at startup; `old_alter_table` removed.

### 11.3
- `DATE_FORMAT()` gains `%Z`/`%z` (timezone abbreviation / UTC offset).
- `START SLAVE UNTIL` gains `SQL_BEFORE_GTIDS`/`SQL_AFTER_GTIDS`.
- Case-insensitive index usage: `UCASE(varchar_col) = ...` becomes sargable via the new `sargable_casefold` optimizer switch.
- `INET4` values are castable to `INET6`, with automatic conversion in comparisons/inserts.
- Tables with `GEOMETRY` columns can now be partitioned.
- New `SHOW CREATE ROUTINE` privilege (database-level).
- Removed: `engine_condition_pushdown` optimizer switch, `date_format`/`datetime_format`/`time_format`/`max_tmp_tables` variables, `wsrep_causal_reads`, `sr_YU` locale.

### 11.4 (LTS, predecessor to 11.8)
- Semi-join optimization for single-table `UPDATE`/`DELETE` gains access to all subquery strategies (finishing what 11.1 started).
- Descending indexes now usable for `MIN()`/`MAX()`.
- `EXCHANGE PARTITION`/`CONVERT TABLE` gain `WITH VALIDATION`/`WITHOUT VALIDATION`.
- New JSON functions: `JSON_OBJECT_FILTER_KEYS`, `JSON_OBJECT_TO_ARRAY`, `JSON_ARRAY_INTERSECT`, `JSON_KEY_VALUE`, `JSON_SCHEMA_VALID` (consolidated here for the LTS train).
- **SSL enabled in the server by default** (auto-generated self-signed cert); clients default to `--ssl-verify-server-cert`; `transaction_isolation` fully replaces `tx_isolation`.
- Removed: `engine_condition_pushdown`, `date_format`/`datetime_format`/`time_format`/`max_tmp_tables`, `old_alter_table`, `innodb_defragment`, `wsrep_causal_reads`.

### 11.5
- `CREATE SEQUENCE ... AS <any INT type>` (including `BIGINT UNSIGNED`), widening prior `INT`-only sequence value types.
- **`TIMESTAMP` range extended** to `2106-02-07 06:28:15 UTC` on 64-bit platforms (from the 2038 limit) — storage format unchanged.
- `REPAIR TABLE ... FORCE`.
- Index condition pushdown now works on partitioned tables.
- **Default Unicode collation changed to `uca1400_ai_ci`** (better SMP-plane/emoji support) — a query relying on the old default collation's sort order may see different ordering after upgrade.
- `alter_algorithm` deprecated (ignored); `ANALYZE TABLE` on a sequence no longer attempts statistics collection.

### 11.6
- Single-table `DELETE` supports a table alias (`DELETE t FROM tbl t WHERE ...`).
- **Vector data type introduced** (storage only at this point — see 11.7/11.8 for search functionality).
- **Default character set changed from `latin1` to `utf8mb4`** for new databases/tables — a schema created without an explicit charset now gets `utf8mb4`, not `latin1`; check `CREATE TABLE`/`CREATE DATABASE` statements' explicit charset before assuming which applies.
- `SHOW ALL REPLICAS STATUS` / `INFORMATION_SCHEMA.SLAVE_STATUS` redefine `Seconds_Behind_Master`.

### 11.7
- **`UUID_v4()`, `UUID_v7()`** generator functions (distinct from the 10.7 `UUID` storage type).
- **Vector Search** functionality added (building on 11.6's vector type).
- Stored functions can return the `ROW` data type.
- Derived tables in `FROM` may declare an optional correlation column list.
- `SHOW CREATE SERVER`; `CREATE SERVER` accepts arbitrary options.
- **Semantic change**: `SESSION_USER()` no longer aliases `USER()` — it now reflects `CURRENT_USER()` as of session creation. A query assuming `SESSION_USER() == USER()` can now be wrong.
- `CURRENT_TIMESTAMP` return-type handling adjusted.
- Cost-based (not just rule-based) choice between subquery strategies for single-table `UPDATE`/`DELETE`; "Charset Narrowing Optimization" on by default.
- System-versioned tables: implicit `row_start`/`row_end` can be converted to explicit columns.

### 11.8 (current LTS — not in the requester's original version list, but the newest LTS and a likely real-world "confirmed newer" target)
- **Vector functions finalized**: `VEC_FromText`, `VEC_ToText`, `VEC_DISTANCE_COSINE`, `VEC_DISTANCE_EUCLIDEAN`, `VEC_DISTANCE` — this is the first fully-documented, stable vector-search surface.
- Consolidates 11.6/11.7: `utf8mb4` default charset, `uca1400_ai_ci` default collation, `UUID_v4()`/`UUID_v7()`, `ROW`-returning stored functions, `SESSION_USER()` semantic change, `SHOW CREATE SERVER`.
- Stored routine parameters may have default values; update triggers can specify a column list gating when they fire.
- New function: `FORMAT_BYTES()`.
- **`innodb_snapshot_isolation` now defaults `ON`** (was `OFF`) — affects repeatable-read visibility semantics; check this before assuming old snapshot behavior.
- New `innodb_index_shrink` variable (default `ON`) controls B-tree shrink-on-update behavior.
- `innodb_force_recovery=6` allows an 11.x server to read 10.x-format data for emergency recovery.
- Optimizer can use `SUBSTR(col, 1, n) = const_str` sargably; virtual-column optimizer support added.

### 12.0
- **`SET SESSION AUTHORIZATION`** (perform actions as another user).
- Large new set of **optimizer/join hints**: `JOIN_FIXED_ORDER`, `JOIN_ORDER`, `JOIN_PREFIX`, `JOIN_SUFFIX`, `QB_NAME`, `NO_RANGE_OPTIMIZATION`, `NO_ICP`, `[NO_]MRR`, `[NO_]BKA`, `[NO_]BNL`, `SEMIJOIN`, `SUBQUERY`, `MAX_EXECUTION_TIME`.
- Triggers can fire on multiple events (`INSERT OR UPDATE`-style single trigger).
- `TO_CHAR()` gains an `FM` format modifier to suppress padding.
- New GIS functions: `ST_Validate`, `MBRCoveredBy`, `ST_Simplify`, `ST_GeoHash`, `ST_LatFromGeoHash`, `ST_LongFromGeoHash`, `ST_PointFromGeoHash`, `ST_IsValid`, `ST_Collect`.
- `SYS_REFCURSOR` predefined weak cursor type (with `max_open_cursors`).
- Rowid filtering and index condition pushdown extended to reverse-ordered scans; loose index scan supports `DESC` key parts.
- **Correctness fix**: `ROW(stored_func(), 1) = ROW(1, 1)`-style comparisons no longer double-evaluate the stored function.
- **Correctness fix**: query plans no longer depend on table order when a join uses `USING`.
- Removed: `big_tables`, `large_page_size`, `storage_engine` (all long-deprecated).

### 12.1
- Oracle-mode `(+)` outer-join syntax.
- Associative arrays: `DECLARE TYPE .. TABLE OF .. INDEX BY` (Oracle-compatible procedural syntax).
- New `caching_sha2_password` authentication plugin (MySQL-compatibility login method).
- `GROUP BY`/`ORDER BY` can use indexes on virtual columns.
- More optimizer hints: `[NO_]JOIN_INDEX`, `[NO_]GROUP_INDEX`, `[NO_]ORDER_INDEX`, `[NO_]INDEX`, `[NO_]SPLIT_MATERIALIZED`, `[NO_]DERIVED_CONDITION_PUSHDOWN`, `[NO_]MERGE`.
- **Foreign key constraint names now only need to be unique per table, not per database** — a schema migration assuming database-wide FK-name uniqueness is no longer required to enforce that.
- `DROP USER` warns if the user has active sessions (fails outright in Oracle mode).
- `mariadb-dump` gains `-L`/`--wildcards`.

### 12.2
- Oracle-compatible `TO_NUMBER()`, `TRUNC()`.
- Join optimizer infers that a derived table with `GROUP BY` has distinct grouping columns (better selectivity estimates for queries joining against such a derived table).
- More hints: `[NO_]ROWID_FILTER`, `[NO_]INDEX_MERGE`; implicit query-block names simplify hint syntax.
- New `INFORMATION_SCHEMA.TRIGGERED_UPDATE_COLUMNS`; `INFORMATION_SCHEMA.PARAMETERS.PARAMETER_DEFAULT` column added.
- **JSON depth limit of 32 removed** from JSON functions — a deeply-nested JSON document that previously errored may now be processed.
- Global temporary tables and heterogeneous-table replication are preview-only, not production-ready as of 12.2.

### 12.3
- **`IS JSON`** predicate (SQL-standard JSON validation).
- **`SET PATH`** (SQL-standard search-path statement).
- **Basic `XML` data type**.
- `UPDATE`/`DELETE` can read from a CTE.
- Oracle-compatible `TO_DATE()`, `TO_NUMBER()`, `TRUNC()`; `TO_CHAR()` `FM` modifier; `(+)` outer-join syntax; associative arrays — 12.1/12.2's Oracle-compatibility features consolidated here.
- Cursors on prepared statements.
- Same optimizer-hint/rowid-filter/reverse-scan expansions as 12.0–12.2, plus `[NO_]INDEX_MERGE` and `optimizer_record_context` for richer optimizer-trace output.
- `caching_sha2_password` plugin (from 12.1) and `ssl_passphrase`-protected TDE keys.
- Foreign key constraint names: unique per table only (from 12.1), carried forward.
- Removed: `big_tables`, `large_page_size`, `storage_engine`.
- Known issue: `CHANGE MASTER TO ... master_use_gtid` could reset to `DEFAULT` across a 12.3.0–12.3.2 upgrade, fixed in 12.3.3 — not a SQL-semantics bug, but worth flagging if reviewing an upgrade script that touches replication config on 12.3.

## When the version is unstated

Ask (or, per the caller's boundaries, mark as an open question) rather than guessing. If forced to assume, assume the oldest still-supported LTS the surrounding context suggests (this plugin's paired `mariadb-dba` agent's stated baseline is 10.6) and mark any newer-feature finding **unverified — needs target version confirmation**.

## MariaDB vs MySQL feature drift

Beyond version gating within MariaDB, some features simply don't exist on one side at all (see `SKILL.md`'s "MariaDB vs MySQL" section):

- **MariaDB-only**: sequences, system versioning, `RETURNING`, invisible columns, native `UUID` type + `UUID_v4()`/`UUID_v7()`, `INET4`/`INET6` types, vector data type/search (11.6+), Oracle-mode packages/associative arrays/`(+)` joins, `XML` type (12.3+), `IS JSON`/`SET PATH` (12.3+).
- **MySQL-only** (do not assume in MariaDB): the `X`/document store, MySQL 8's native binary `JSON` type and its performance characteristics, MySQL's `caching_sha2_password` as the *default* auth plugin (MariaDB added it as an *optional* plugin only in 12.1), MySQL roles syntax differences.
- **Shared name, different history**: `JSON_TABLE` exists on both sides but landed in MariaDB 10.6 — much later than MySQL's; don't assume feature parity in edge-case behavior just because the function name matches.
- When the caller's dialect is ambiguous ("MySQL-compatible database"), don't assume either side's exclusive features are available.
