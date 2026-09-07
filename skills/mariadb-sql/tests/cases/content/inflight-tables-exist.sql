-- query-profiling.md claims PROCESSLIST, INNODB_TRX, and INNODB_LOCK_WAITS
-- are all available information_schema tables for catching a query in
-- flight. All predate our whole matrix (10.2+), so no .version tag.
-- Combined into one case since all three are simple existence checks.
SELECT * FROM information_schema.PROCESSLIST LIMIT 1;
SELECT * FROM information_schema.INNODB_TRX LIMIT 1;
SELECT * FROM information_schema.INNODB_LOCK_WAITS LIMIT 1;
