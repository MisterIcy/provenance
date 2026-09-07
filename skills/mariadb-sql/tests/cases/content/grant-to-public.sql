-- version-features.md, 10.11 section: "GRANT ... TO PUBLIC (grant to all
-- users without creating an explicit account)" -- genuinely new at 10.11,
-- not a consolidation of an earlier version. Verify the statement succeeds
-- and the grant is actually recorded against the PUBLIC pseudo-role.
GRANT SELECT ON skilltest.articles TO PUBLIC;
SHOW GRANTS FOR PUBLIC;
