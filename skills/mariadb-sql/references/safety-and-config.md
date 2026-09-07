# MariaDB safety, config, and operational gotchas

Things that make a statement risky beyond its literal text — config-dependent behavior, replication, and engine-level footguns. Review-only: this file exists so a reviewer can flag risk, not to instruct running any mutating statement.

## `sql_mode` and error vs. silent-coercion behavior

Covered in `correctness.md`, but from a safety angle: a review that says "this `INSERT` is fine" is implicitly assuming a `sql_mode`. Without `STRICT_TRANS_TABLES`/`STRICT_ALL_TABLES`, an out-of-range or too-long value is truncated and **succeeds** with a warning instead of failing — silent data loss, not a crash. Always name the assumption in the review's Evidence line rather than asserting safety outright.

## Foreign keys

- Only InnoDB enforces declared foreign keys; `Aria`/`MyISAM` parse the `FOREIGN KEY` clause but silently ignore it. A schema migration adding a `REFERENCES` clause to a non-InnoDB table looks correct and enforces nothing — always check `ENGINE=` before trusting a foreign key constraint exists.
- `FOREIGN_KEY_CHECKS=0` (session or global) disables enforcement, often set temporarily during bulk loads/migrations — a mutating statement reviewed while this is off can introduce orphaned rows undetected. Flag any script that sets this without resetting it.
- Foreign keys require an index on the referencing column (MariaDB creates one automatically if missing) — but a wide `ON DELETE CASCADE`/`ON UPDATE CASCADE` chain across several tables can turn one `DELETE` into a large, hard-to-predict cascade. Flag cascading deletes on tables the caller didn't explicitly name.

## Replication and binlog safety

Even a statement that's correct standalone can be replication-unsafe:

- Statement-based replication (still the default in some setups; check `binlog_format`) can diverge on non-deterministic statements — `UPDATE ... ORDER BY RAND() LIMIT n`, anything reading `NOW()`/`UUID()`/`CONNECTION_ID()` without the value being fixed before use, or a multi-row update whose order affects the outcome. Row-based replication (`binlog_format=ROW`, common default in modern deployments) avoids most of this, but check which mode applies before waving off a non-determinism flag as "doesn't matter."
- `LIMIT` without `ORDER BY` in an `UPDATE`/`DELETE` is inherently non-deterministic about *which* rows are affected when more rows match than the limit — flag this even outside a replication context, since it's also a correctness risk under any concurrent write.

## Session-level footguns

- `sql_safe_updates` (when on) blocks an `UPDATE`/`DELETE` with neither a `WHERE` on a key column nor a `LIMIT` — a useful backstop, but it being on in one session and off in another is exactly the kind of environment difference that makes "it worked when I tested it" reviews unreliable. Don't treat its absence as approval to skip checking for a missing/broad `WHERE`.
- `autocommit` is on by default per session — a multi-statement mutation the caller assumes is one transaction may not be, unless wrapped explicitly in `START TRANSACTION`/`COMMIT` (or `BEGIN`/`COMMIT`). Flag a sequence of related mutating statements with no visible transaction boundary.
- `lock_wait_timeout`/`innodb_lock_wait_timeout` govern how long a statement waits on a row/table lock before erroring — relevant when diagnosing a hang, not something to change as a "fix" without understanding why the lock is being held.

## Character set and collation config

- `character_set_client`/`character_set_connection`/`character_set_results` can each differ from the column's stored charset — mismatches here are a common source of mojibake that looks like an application bug but is a connection-config issue. Not directly a SQL-review concern unless the query itself sets these (`SET NAMES ...`).

## DDL and online schema change

- Not every `ALTER TABLE` is safe to run against a live table under load: some MariaDB DDL operations still take a metadata lock or rebuild the table (algorithm `COPY`) depending on the specific change and storage engine/version, blocking reads and writes for the duration. `ALGORITHM=INSTANT`/`ALGORITHM=NOLOCK`/`ALGORITHM=INPLACE` availability is both version- and change-type-specific (see `version-features.md`) — never assert an `ALTER TABLE` is "instant" or "safe under load" without checking which algorithm actually applies to that specific change on that specific version. When in doubt, recommend the caller check with `ALTER TABLE ... ALGORITHM=INSTANT` (or their preferred explicit algorithm) so the statement fails loudly if the fast path isn't available, rather than silently falling back to a blocking rebuild.
- This skill's reviewer role is read-only — DDL safety here means *flagging* risk in a migration under review, never running the `ALTER TABLE` to find out.
