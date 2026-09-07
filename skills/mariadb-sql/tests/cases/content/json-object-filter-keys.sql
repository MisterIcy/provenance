-- version-features.md claims (11.4): "New JSON functions:
-- JSON_OBJECT_FILTER_KEYS, JSON_OBJECT_TO_ARRAY, JSON_ARRAY_INTERSECT,
-- JSON_KEY_VALUE, JSON_SCHEMA_VALID (consolidated here for the LTS
-- train)." Verify JSON_OBJECT_FILTER_KEYS keeps only the requested key
-- from the baseline schema's plain-LONGTEXT `metadata` column.
SELECT JSON_OBJECT_FILTER_KEYS(metadata, '["views"]') AS filtered
FROM articles
WHERE id = 1;
