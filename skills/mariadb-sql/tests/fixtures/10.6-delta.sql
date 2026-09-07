-- Additive schema/data for MariaDB 10.6, applied on top of
-- 00-baseline-schema.sql (no 10.3/10.4/10.5 delta files exist yet).
--
-- version-features.md, 10.6 section:
--   - "JSON_TABLE -- extracts JSON into a relational table shape" (also in
--     the Quick reference table: "JSON_TABLE | Introduced 10.6").
--
-- article_tags: a view over the baseline `articles.metadata` LONGTEXT
-- column (JSON-as-text, per 00-baseline-schema.sql), using JSON_TABLE to
-- shred the `tags` JSON array into one row per tag. JSON_TABLE requires
-- 10.6+, so this view is only valid from 10.6 onward -- do not add it to
-- the baseline or an earlier delta.
CREATE VIEW article_tags AS
SELECT
    a.id AS article_id,
    a.title,
    jt.tag
FROM articles a,
     JSON_TABLE(
         a.metadata,
         '$.tags[*]' COLUMNS (tag VARCHAR(64) PATH '$')
     ) AS jt
WHERE a.metadata IS NOT NULL;
