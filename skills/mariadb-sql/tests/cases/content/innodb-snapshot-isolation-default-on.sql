-- version-features.md claims for 11.8: "innodb_snapshot_isolation now
-- defaults ON (was OFF) -- affects repeatable-read visibility semantics".
-- Verify the default value is actually 1 (ON) on a fresh 11.8 server.
SELECT @@innodb_snapshot_isolation;
