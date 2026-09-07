-- version-features.md ("### 10.3"): "System-versioned tables (temporal AS OF
-- queries, MariaDB-only)." Verify a WITH SYSTEM VERSIONING table (defined in
-- fixtures/10.3-delta.sql) retains a historical row version after an
-- UPDATE, queryable via FOR SYSTEM_TIME ALL.
UPDATE article_revisions SET title = 'Updated title' WHERE id = 1;
SELECT COUNT(*) AS system_versioning_history_count
FROM article_revisions FOR SYSTEM_TIME ALL
WHERE id = 1\G
