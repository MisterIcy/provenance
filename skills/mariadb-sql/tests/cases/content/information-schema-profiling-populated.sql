-- query-profiling.md claims: "Equivalent structured data is queryable from
-- information_schema.PROFILING." Verify the table exists and is populated
-- with a row after enabling profiling and running a statement, in the same
-- session (profiling data is session-scoped). No .version tag -- this is
-- the same pre-10.2 functionality as SHOW PROFILE itself.
SET profiling = 1;
SELECT 1;
SELECT * FROM information_schema.PROFILING LIMIT 1;
