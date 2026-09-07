-- version-features.md, 10.11 section: consolidates 10.8's "Descending index
-- columns: individual index columns can be declared ASC/DESC explicitly"
-- into the LTS train. Verify fixtures/10.11-delta.sql's
-- idx_articles_created_at_desc was actually created with DESC collation
-- (INFORMATION_SCHEMA.STATISTICS reports 'D' for a descending column, 'A'
-- for ascending).
SELECT COLLATION FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'articles'
  AND INDEX_NAME = 'idx_articles_created_at_desc';
