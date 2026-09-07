# Modernization rewrites by version

Pairs an **old pattern** (a workaround that predates a feature, or a generic-SQL idiom MariaDB has a purpose-built replacement for) with the **modern MariaDB construct** that replaces it, gated by the version the replacement requires. Use this when a query under review could be simplified, made safer, or sped up by a newer language feature — not just when it's outright wrong.

Every entry cross-references `version-features.md` for the introduction version. **Never suggest a rewrite without confirming the target version actually supports it** — an unconfirmed target makes the suggestion `unverified`, same as any other finding (see `sql-query-reviewer`'s output format). If the target is older than the feature, don't suggest it at all; note it as a "worth knowing for a future upgrade" remark at most, and only if asked.

## How to use this

1. Find the old pattern in the query under review (left column below, or something recognizably similar).
2. Check the confirmed or assumed target version against the **Requires** column.
3. If the target meets it, propose the rewrite — cite the version in the finding so the caller can verify it themselves.
4. If the target is below it, don't propose it as a fix. It's fine to mention "available if you upgrade to X" only if the caller is discussing an upgrade.

## Rewrites

| Old pattern | Modern replacement | Requires | Why it's better |
|---|---|---|---|
| App-side loop assigning row numbers via a session variable (`SET @rn := @rn + 1`) | `ROW_NUMBER() OVER (...)` | 10.2 | Set-based, no session-variable ordering hazard (MariaDB/MySQL never guaranteed variable-assignment order in a `SELECT`). |
| A counter table updated with `UPDATE ... SET val = val + 1` then re-read, wrapped in a transaction for concurrency safety | `CREATE SEQUENCE` + `NEXTVAL(seq)` | 10.3 | Purpose-built, contention-free counter; no read-modify-write race, no explicit transaction needed just to get a number. |
| A trigger-maintained `_history` shadow table (`INSERT INTO foo_history SELECT * FROM foo WHERE id = ...` on every `UPDATE`/`DELETE`) | `CREATE TABLE ... WITH SYSTEM VERSIONING` + `... FOR SYSTEM_TIME AS OF` / `ALL` | 10.3 | The engine maintains history automatically; no trigger to maintain, no risk of the trigger drifting from the table's real DML surface. |
| Separate `INSERT` then `SELECT LAST_INSERT_ID()` (or a full re-`SELECT` by a natural key) to get the row a statement just wrote | `INSERT ... RETURNING ...` (also `UPDATE`/`DELETE`/`REPLACE ... RETURNING`) | 10.5 | One round trip instead of two; no race if another session's write lands between the two statements. Still a mutating statement — a reviewer describes this, never executes it. |
| A recursive CTE with a hand-rolled path-tracking column and an app-level or `max_recursive_iterations`-only guard against cycles | `WITH RECURSIVE ... CYCLE <col> SET <flag> USING <path>` (MariaDB's supported form is `CYCLE <col_list> RESTRICT`, not the SQL-standard `SET ... USING ...` extension — see `correctness.md`) | 10.5 | Explicit, engine-enforced cycle detection instead of silently running until an iteration cap or forever. |
| Multiple round trips (or app-side JSON parsing) to flatten a JSON array column into rows | `JSON_TABLE(json_col, '$[*]' COLUMNS (...))` in a `FROM`/`JOIN` | 10.6 | Shreds JSON into relational rows inside the query itself; avoids fetching the whole document just to iterate it client-side. |
| `SELECT ... LIMIT x OFFSET y` (unclear at a glance which is the count and which is the skip, and mixes MariaDB-specific `LIMIT`/`OFFSET` order conventions) | `SELECT ... OFFSET y ROWS FETCH NEXT x ROWS ONLY` | 10.6 | SQL-standard, unambiguous pagination syntax — a stylistic modernization, not a correctness/perf fix; only worth suggesting if the caller already cares about standard-SQL portability. |
| App-side "if row is locked, skip it and try the next one" polling loop around `SELECT ... FOR UPDATE` | `SELECT ... FOR UPDATE SKIP LOCKED` | 10.6 | Push the skip-locked-rows semantics into the engine; removes a client-side retry loop and its associated round trips. |
| Storing a UUID as `CHAR(36)` (or `BINARY(16)` with manual pack/unpack) | Native `UUID` data type | 10.7 | Correct comparison/sort semantics and compact storage without app-side (un)packing — but confirm the target is 10.7+ before suggesting; below that, `CHAR(36)`/`BINARY(16)` is the only option and isn't itself a defect. |
| A chain of `JSON_EXTRACT`/`JSON_SET` calls to filter or restructure a JSON object's keys | `JSON_OBJECT_FILTER_KEYS()` / `JSON_OBJECT_TO_ARRAY()` | 11.2 (also present in the 11.4 LTS consolidation) | Purpose-built key-filtering/restructuring instead of stitching together generic extract/set calls. |
| Application code (or a UDF) computing cosine/Euclidean distance between embedding vectors stored as `TEXT`/`JSON` | Native `VECTOR` column type + `VEC_DISTANCE_COSINE()`/`VEC_DISTANCE_EUCLIDEAN()`/`VEC_DISTANCE()` with a vector index | 11.8 (type introduced 11.6, search 11.7, functions finalized/LTS-stable 11.8 — see `version-features.md`) | Distance computed and (with a vector index) approximately-nearest-neighbor-searched inside the engine, instead of pulling every row's vector to the client to compute distance there. |
| `JSON_VALID(col) = 1` used as a `WHERE`/`CHECK` predicate to test JSON-formedness | `col IS JSON` | 12.3 | SQL-standard predicate form; behaviorally equivalent to `JSON_VALID()` for well-formedness checks on 12.3+, so this is a readability/standards-conformance suggestion, not a bug fix — don't imply the old form was wrong. |

## Common mistakes to avoid

- Suggesting a rewrite as a **fix** for a correctness bug when it's really a modernization (style/ergonomics) — keep these findings in a distinct **modernization** category, not mixed into **correctness**/**performance**, so the caller can tell "this is broken" from "this could be nicer."
- Proposing a MariaDB-only construct (sequences, `RETURNING`, system versioning, vector type, `IS JSON`) against a target that turns out to be plain MySQL — cross-check `SKILL.md`'s "MariaDB vs MySQL" section first.
- Treating a version-gated rewrite as safe to propose just because it "should" be available — if the target version wasn't stated, mark the suggestion `unverified — needs target version confirmation`, exactly like any other unconfirmed finding.
- Suggesting the SQL-standard `CYCLE ... SET ... USING ...` form — MariaDB does not support it; only `CYCLE <col_list> RESTRICT` is valid (confirmed against a live 10.5 server; see the test harness's `recursive-cte-cycle-clause` case).
