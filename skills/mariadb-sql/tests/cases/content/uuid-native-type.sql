-- version-features.md, 10.11 section: consolidates 10.7's "Native UUID
-- data type (storage + comparison semantics distinct from CHAR(36))" into
-- the LTS train. Verify the fixtures/10.11-delta.sql `sessions.id` column
-- is actually stored as the native UUID column type, not CHAR(36).
SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sessions' AND COLUMN_NAME = 'id';
