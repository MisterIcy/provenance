-- query-profiling.md claims: "InnoDB-level engine stats (r_engine_stats:
-- pages_accessed, pages_updated, pages_read_count,
-- pages_prefetch_read_count, pages_read_time_ms, old_rows_read) were added
-- across a set of point releases: 10.6.15, 10.8.8, ...". Live-checked
-- against this harness's 10.6 image (10.6.25-MariaDB, i.e. >= the 10.6.15
-- minimum) against the InnoDB `articles` table from the baseline schema:
-- r_engine_stats is present. Tagged 10.6, our nearest milestone at/above
-- the earliest documented per-series patch.
ANALYZE FORMAT=JSON SELECT * FROM articles WHERE author_id = 1;
