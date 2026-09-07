-- version-features.md claims JSON functions (JSON_EXTRACT, JSON_VALUE, etc.)
-- were introduced in 10.2, and that MariaDB stores JSON as LONGTEXT (no
-- native binary type). Verify JSON_EXTRACT works against the baseline
-- schema's plain-LONGTEXT `metadata` column on a MariaDB 10.2 server.
SELECT JSON_EXTRACT(metadata, '$.views') AS views
FROM articles
WHERE id = 1;
