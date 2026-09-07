-- query-profiling.md claims: "MySQL has deprecated SHOW PROFILE/SHOW
-- PROFILES since 5.7 with removal planned; MariaDB's own current KB
-- documents them as a live, complementary tool alongside Performance
-- Schema -- no deprecation notice." Verify the basic profiling round-trip
-- (SET profiling=1; run a statement; SHOW PROFILES) still works and
-- returns a recognizable header, i.e. it hasn't been removed on MariaDB.
-- Pre-10.2 functionality, so no .version tag -- applies across the whole
-- matrix.
SET profiling = 1;
SELECT 1;
SHOW PROFILES;
