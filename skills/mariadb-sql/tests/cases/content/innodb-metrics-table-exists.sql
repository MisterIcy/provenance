-- query-profiling.md claims: "INNODB_METRICS (10.0.0+) -- instrumented
-- counters (NAME, SUBSYSTEM, COUNT, ...)". 10.0.0 predates our whole
-- matrix (10.2+), so no .version tag. Verify the table exists and returns
-- a row.
SELECT * FROM information_schema.INNODB_METRICS LIMIT 1;
