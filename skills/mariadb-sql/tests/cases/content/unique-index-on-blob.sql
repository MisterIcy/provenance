-- version-features.md claims: "Unique index/constraint now allowed on
-- BLOB/TEXT columns" (10.4), given an explicit prefix length. Verify
-- CREATE UNIQUE INDEX with a prefix length succeeds against the BLOB column
-- attachments.content_hash.
CREATE UNIQUE INDEX uq_attachments_content_hash ON attachments (content_hash(20));
SELECT INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'attachments' AND INDEX_NAME = 'uq_attachments_content_hash';
