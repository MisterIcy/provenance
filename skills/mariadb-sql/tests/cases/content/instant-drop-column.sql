-- version-features.md claims: "Instant DROP COLUMN" landed in 10.4, extending
-- 10.3's instant ADD COLUMN. Verify ALTER TABLE ... DROP COLUMN succeeds
-- without error against article_drafts.deprecated_note (a plain,
-- non-indexed column) on a 10.4+ server, and that the column is actually gone.
ALTER TABLE article_drafts DROP COLUMN deprecated_note;
SELECT COUNT(*) AS remaining FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'article_drafts' AND COLUMN_NAME = 'deprecated_note';
