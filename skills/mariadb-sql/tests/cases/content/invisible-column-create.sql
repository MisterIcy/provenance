-- version-features.md ("### 10.3"): "Invisible columns (INVISIBLE),
-- excluded from SELECT *." Verify the INVISIBLE attribute added in
-- fixtures/10.3-delta.sql is actually persisted in the table definition.
SHOW CREATE TABLE articles;
