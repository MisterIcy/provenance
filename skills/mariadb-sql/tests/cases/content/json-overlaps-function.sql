-- version-features.md, 10.11 section: consolidates 10.9's "JSON_OVERLAPS
-- function" into the LTS train. Verify JSON_OVERLAPS() actually works
-- against the baseline articles.metadata LONGTEXT (JSON-as-text) column,
-- finding the shared "math" tag between article 1's tags and a literal.
SELECT JSON_OVERLAPS(JSON_EXTRACT(metadata, '$.tags'), '["math", "other"]') AS has_overlap
FROM articles WHERE id = 1;
