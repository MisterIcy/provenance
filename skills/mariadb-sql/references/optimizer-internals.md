# MariaDB optimizer internals — when the plan is wrong

`performance.md` covers reading `EXPLAIN` output. This is for the next question: *why did the optimizer choose that plan*, and what to check or adjust when it chose badly. Load this when a plan looks wrong despite reasonable indexes — not for routine `EXPLAIN` reading.

## Cost model

The optimizer picks among candidate plans by estimated total cost (I/O cost of rows fetched + CPU cost of rows compared/processed) — not by rules of thumb. Before **11.0**, most operations shared a poorly-calibrated flat cost, which made scan-vs-range-vs-index-vs-join-order decisions less reliable, especially cross-engine. **11.0's Optimizer Cost Model overhaul** rebaselined this: a generic storage-engine operation costs ~1ms, with per-engine costs (key lookup, row read, comparison, copy) now visible in `information_schema.optimizer_costs` — InnoDB's key-lookup cost is higher than a generic engine's, reflecting clustered-index indirection. Disk-read cost assumes a mid-tier SSD by default, tunable via `optimizer_disk_read_cost` (globally or per-engine). A pre-11.0 target's cost estimates are not directly comparable to an 11.0+ target's for the same query/statistics — don't assume a cost number carries across versions.

Cardinality/selectivity input comes from two independent sources, and which one the optimizer trusts is a config choice, not a constant:

- **Engine-derived stats** — InnoDB's own `n_rows`, `SHOW INDEX` cardinality. Always available, sampled, no cross-column correlation.
- **Engine-independent statistics (EITS)** — `mysql.table_stats`/`column_stats`/`index_stats`, populated by `ANALYZE TABLE ... PERSISTENT FOR ...`. Persist across restarts, unlike engine stats.

`use_stat_tables` picks the winner: `NEVER` (ignore EITS), `COMPLEMENTARY` (EITS fills gaps only), `PREFERABLY` (prefer EITS, fall back to engine stats), `PREFERABLY_FOR_QUERIES` (same preference, but scoped to query planning rather than `ANALYZE TABLE`'s own bookkeeping — the **default**), and `COMPLEMENTARY_FOR_QUERIES`. If a plan looks wrong and stats seem plausible, check which mode is active before assuming the stats themselves are stale.

## Histograms

Part of EITS, stored in `mysql.column_stats`; never auto-collected — require `ANALYZE TABLE ... PERSISTENT FOR COLUMNS (...) INDEXES (...)`, a full scan.

- `histogram_type`: `SINGLE_PREC_HB`/`DOUBLE_PREC_HB` (default from 10.4.3), or `JSON_HB` (10.8, preview in 10.7). `histogram_size` (0–255 for HB types) defaults to 0 — disabled — through 10.4.2.
- The optimizer only consults histograms when `optimizer_use_condition_selectivity` ≥ 4 (default since 10.4.1); level 5 extends histogram use to non-range predicates via record sampling. Below that threshold, or with no histogram on the column, it falls back to average/uniform selectivity — this matters most for skewed, low-cardinality, non-indexed `WHERE` columns, where "average selectivity" can be badly wrong for a specific value.

## Join order and search strategy

- `optimizer_search_depth` (default 62 — effectively exhaustive for most join sizes) bounds how deep the join-order permutation search goes before the optimizer greedily fixes a prefix and stops exploring. Lowering it trades plan optimality for planning speed on many-table joins; raising it rarely helps since 62 already covers realistic joins.
- `optimizer_prune_level` (on by default) discards provably-worse partial plans without fully costing them. Disabling it is a last resort for a suspected pruning-caused miss, not a general-purpose fix.
- Manual join-order control: `STRAIGHT_JOIN` (legacy, forces `FROM`-clause order for the whole query). **12.0+** adds scoped hint syntax: `/*+ JOIN_FIXED_ORDER() */` (alias for `STRAIGHT_JOIN`), `JOIN_ORDER(t1, t2, ...)` (pins named tables' relative order, others may interleave), `JOIN_PREFIX(...)`/`JOIN_SUFFIX(...)` (named tables lead/trail), all combinable and scopable per query block via `QB_NAME` (e.g. `JOIN_ORDER(t4@subq2, t1)`). Prefer the scoped 12.0+ hints over `STRAIGHT_JOIN` when the target supports them — they don't force the *entire* query's order, just the part that needs it.

## Semi-join strategies (`IN`/`EXISTS`/`=ANY` subqueries)

Governed by the top-level `optimizer_switch` flag `semijoin` (on since 5.3). The optimizer picks one of these per subquery, not one globally:

- **Table Pullout** — when the subquery's column is unique/PK-indexed, it's pulled directly into the outer join with no semi-join machinery at all. Tried first; cheapest when applicable.
- **FirstMatch** (`firstmatch`) — nested-loop join that stops at the first matching inner row per outer row. Fits correlated subqueries where an index makes the existence check fast.
- **LooseScan** (`loosescan`) — walks an index ordered so duplicate groups are contiguous, skipping to the next distinct value. Needs an index whose leading columns match the subquery's selected/grouped column.
- **Materialization** (`materialization`) — an uncorrelated `IN` subquery is run once into a deduplicated (possibly indexed) temp table, then joined against.
- **DuplicateWeedout** — converts to a regular inner join and removes duplicates via a temp table with a unique key. Handles correlated subqueries, but not one with meaningful `GROUP BY`/aggregates. No dedicated switch (only `semijoin=off` disables it); shows as `Start temporary`/`End temporary` in `EXPLAIN` `Extra`.
- `semijoin_with_cache` (on) combines semi-join execution with block-based join buffering when the driving side lacks a usable index.

If `EXPLAIN` shows a semi-join isn't being applied where you'd expect one, check whether the relevant switch is off before concluding the optimizer "got it wrong."

## Other `optimizer_switch` flags worth knowing

- `index_merge`, `index_merge_union`, `index_merge_intersection`, `index_merge_sort_union` — on since 5.1. `index_merge_sort_intersection` — **off** by default (5.3+; the added sort step usually isn't worth it).
- `mrr`, `mrr_cost_based` — **off** by default (5.3+). Multi-Range Read improves I/O locality for range/key-ref fetches but isn't reliably a win, hence off; worth testing on range-heavy queries against slow storage specifically.
- `index_condition_pushdown` — on (5.3+). Pushes non-covering `WHERE` conditions on indexed columns to the storage engine before the full row fetch (shows as `Using index condition` — see `performance.md`).
- `derived_merge` — on (5.3+). Merges a derived table/view into the outer query when safe (no aggregation/`DISTINCT`/`LIMIT` in the derived table).
- `condition_pushdown_for_derived` — on (10.2.2+). Pushes outer `WHERE` into a derived table that couldn't be merged, before materialization.
- `subquery_cache` — on (5.3+). Caches correlated-subquery input/output pairs.
- `rowid_filter` — on (10.4.3+). Builds a Bloom-filter-like rowid filter from a selective range index to prune InnoDB clustered-index lookups before they happen.

## `optimizer_trace`: when `EXPLAIN` isn't enough

`EXPLAIN`/`ANALYZE FORMAT=JSON` tell you *what* plan was chosen. `optimizer_trace` tells you *why* — what alternatives were considered and rejected, and on what cost basis.

```sql
SET optimizer_trace='enabled=on';
<run the statement>
SELECT * FROM information_schema.OPTIMIZER_TRACE;
```

Only one trace is retained per connection (the most recent `SELECT`/`UPDATE`/`DELETE`), returned as structured JSON: table-access-method choices, costs considered and rejected, transformations applied (subquery rewrites, which semi-join strategy won and why the others lost), the rewritten query, and the final estimated cost. Reach for it specifically when you need to explain a join-order choice, a rejected index, or a semi-join strategy pick that `EXPLAIN` alone doesn't justify — not as a routine step.

## Common "optimizer picked a bad plan" patterns

- **Stale or missing statistics** is the most common root cause of an unexpected scan or wrong join order. Check `mysql.table_stats`/`column_stats`/`index_stats` freshness (or `SHOW INDEX` cardinality if EITS isn't in use) before assuming the optimizer itself is wrong; re-run `ANALYZE TABLE`.
- **`eq_range_index_dive_limit`** (default changed 0 → 200 at **10.4.3**): for equality-range predicates exceeding this limit — a long app-generated `IN (...)` list is the classic trigger — the optimizer skips per-value index dives and falls back to average selectivity, which can badly misestimate cardinality in either direction. Raise the limit per-session or restructure the query (e.g. a temp-table join) rather than raising it globally.
- **Histogram/selectivity gaps** — see above: a skewed column with no histogram, or `optimizer_use_condition_selectivity` below 4, gets a uniform-distribution assumption that can be badly wrong for a specific value.
- **Function-wrapped or implicitly-coerced predicates** disable index range access/dives regardless of how good the stats are (see `correctness.md`/`performance.md`'s sargability section) — check `EXPLAIN`/the trace for an unexpected full scan before blaming statistics.
- **Index hints, as a last resort, not a fix**: `USE INDEX` narrows the candidate set; `IGNORE INDEX` excludes one index without disabling future ones (generally safer to ship than `USE`/`FORCE`); `FORCE INDEX` behaves like `USE INDEX` but also treats a table scan as very expensive, falling back to scan only if none of the forced indexes work. All three hard-code today's plan decision into code that will keep running as the data's size and shape change — flag a hint as a workaround needing a stats/schema fix behind it, not a resolved issue.
- **Scope a switch change to one statement** with `/*+ SET_VAR(optimizer_switch='materialization=off') */` rather than `SET SESSION optimizer_switch=...` — a session-wide change silently affects every other query on that connection. The 12.0+ join-order hints above serve the same per-statement-scoping purpose specifically for join order.
