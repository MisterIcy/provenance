-- query-profiling.md claims: "slow_query_log = 1 -- renamed log_slow_query
-- at 10.11 (old name still accepted)" and similarly for
-- log_slow_query_time / log_slow_min_examined_row_limit. Live-checked
-- against this harness's 10.11 image: both the old and new variable names
-- coexist (old name not removed, per the doc's parenthetical). Assert the
-- new names resolve.
SHOW VARIABLES WHERE Variable_name IN ('log_slow_query', 'log_slow_query_time');
